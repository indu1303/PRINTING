 #!/usr/bin/perl -I /ids/tools/PRINTING/lib

use strict;
use Symbol;
use printerSite;
use Settings;
use Accessory;
use Data::Dumper;
use Certificate;
use Certificate::CaliforniaEvaluation;
use MysqlDB;
use Getopt::Std;
use PDF::Reuse;
use Net::FTP;
use Image::Info qw(image_info dim);


my $dryRun          = 0;
my $time = time();
my ($day,$mon,$year) = (localtime($time))[3,4,5];
$year +=1900;
$mon = $mon+1;
$mon = ($mon<10)?"0".$mon:$mon;
$day = ($day<10)?"0".$day:$day;
my $todayDate = "$year-$mon-$day";
my ($certUsers,$excelFile,$outputFile);
my $count = 1;
my $totalUsers = 0;



my $self= Settings->new;
my $product='DIP';
my $LAFaxCert;
my $STCCert;
my $productId       = 1;
my $printingAPI     = 'DIP';
my $API;
my %opts;
my $CERT_THRESHOLD  = 200;
my $SLEEPTIME = 15;
my $MAX_PRIORITY = 12;
my $MAX_WAIT = 90;
my $PRINT_QUEUE = '/var/spool/print';
my $STOP = 0;
my %stcHash = ();
my %regHash = ();
my %user_court = ();
my @updatables = ();
my @faxUsers = ();
my $hostedAffiliateFlag;
my $lastModule='';
my (@userIds, @Two, $currentCourt, $currentFaxCourt, $numUsers);

my $SERVER_NAME     = (split(/\./,qx/uname -n/))[0];
my $printer         = '';
my $certsPrinted    = 0;
my $hostedAffRun    = 0;
my $showError       = 0;
my $printerKey      = 'CA';
my $processCourse   = '';
my $processOnCourse = 1001;
my $lockFile        = 0;
my $runCounter      = 0;
my $limitedRun      = 0;
my $priority        = 1;
my $noFedex         = 0;
my $onlyFedex       = 0;
my $manifestId      = 0;
my $ping            = 1;
my $fedexManifest   = "";
my $printManifest   = "";
my $stateList       = 0;
my $state           = "";
my $fleetId         = 0 ;
my $deliveryMode    = '';
my $jobPrintDate    = Settings::getDateTimeInANSI();
my $allDeliveryMode = { map { $_ => 1 } qw (PRINT FAX EMAIL) };
my $RUNDUPLICATE    = 0;
my $runSTC          = 0;
my $printMode       = 'Cron Run';
my $accompanyLetter='';
my $affidavit='';
my $laCountyHardcopy  = 0;
my $dateRange = 0;
my $numMail = 0;
my $numAirBill = 0;
my $numFax = 0;
my $printLog;
my $jobDate;
my $error_msg = undef;
my $type='PDF';
my %hashProcessCourse;
my @certificateArray;
my @dateviolationusers;
my $duplicatelicenseusers;
my $courseId;
my $deliveryId;
my $insuranceUser;
my $cnt = 0;
my ($worskSheet,$courseName,$worksheet,$row,$titleFormat,$boldFont,$smallFont);

### Now Loop the Products
getopt('Kscl:', \%opts);
print "\nRunning IDS Printing Job\n";
print "Job running on $SERVER_NAME\n";
print "**************************\n\n";

################# process all incoming options
################# options are as follows:
#
#    -D          Dry Run
#    -K product  Product


   ####  Get the Product Id
if($opts{K})
{
	$product=$opts{K};
        $productId = ($self->{PRODUCT_ID}->{$opts{K}})?$self->{PRODUCT_ID}->{$opts{K}}:1;
        $printingAPI = ($self->{PRINTING_API}->{$opts{K}})?$self->{PRINTING_API}->{$opts{K}}:$product;
}
my $startTime         = time;
my $totalTime         = time;
eval("use Printing::$printingAPI");
$API = ("Printing::$printingAPI")->new;
print "Database connection  time:  " . int(time - $startTime) . " seconds\n";
$API->{PRODUCT}=$product;
$self->{PRODUCT}=$product;
$self->{PRODUCT_CON}=$API->{PRODUCT_CON};
$self->{CRM_CON}=$API->{CRM_CON};
$API->constructor;

my $printers = $API->{PRINTERS};

#my $mysqlAPI = MysqlDB->new;
if (exists $opts{h})
{
    ######### First, get the available printers:
    my $printerList = join('|', sort keys %$printers);
    print <<OUT;
usage: processCertificate.pl [options]
Options:
    -h              this screen


    -D              Perform a dry run.  Will display users who are eligible to print, their course id
                    and their delivery id only.  No printing or updating of accounts will occur

    -K product      Product


OUT
    exit;
}


if ($opts{D})
{
    ##### order a dry run of the system
    print "Performing a Dry Run\n";
    $dryRun = 1;
}



####### ASSERT:  No lock file exists and the printer properly passed the ping test.  Let's collect the
####### Required data and start the print job
my @processed = ();
my $users;
my %caUsers;
$startTime = time;

$users =  $API->getCACourseEvaluationUsers();

print "Users retrieved.  execution time:  " . int(time - $startTime) . " seconds\n";
print "Number of users retrieved:  " . (keys %$users) . "\n";
$startTime = time;

for my $key(keys %$users)
{
    my $uid=$key;
    my $userData;
    $userData   =   $API->getUserData($uid);
    if($userData->{DRIVERS_LICENSE} =~ m/TEST/gi || $userData->{EMAIL} =~ m/TEST/gi || $userData->{EMAIL} =~ m/IDRIVESAFELY.COM/gi || $userData->{EMAIL} =~ m/ED-VENTURES-ONLINE.COM/gi || $userData->{EMAIL} =~ m/CONTINUEDED.COM/gi || $userData->{EMAIL} =~ m/PRADHITA.COM/gi){
#	next;
    }
    ############ we now have the user data.  Let's start filtering out users who should not print
    ############ based on requirements for that particular state / regulator.

	###### Non TX printing
	$caUsers{$uid}->{USER_DATA}    = $userData;
	$caUsers{$uid}->{EVAL_DATA}    = $users->{$key}->{EVAL_DATA};
}

print "Users processed.  execution time:  " . int(time - $startTime) . " seconds\n";
$startTime = time;
if(keys %caUsers)
{
    CAPrint(\%caUsers,$hostedAffRun);
}
	
print "Users Print processed.  execution time:  " . int(time - $startTime) . " seconds\n";
exit;

sub CAPrint
{

    	my ($printUsers)=@_;
    	my %delUsers=%$printUsers;
    	my $currentCertificate;
    	$processCourse = 'CA';
    	if (!$printerKey)
    	{
    	    $printerKey = 'CA';
   	}

    	my @keys = sort keys %delUsers;
    	print STDERR "num of users ready to process " . @keys . " \n";

    	if(@keys)
    	{
        	$printLog = gensym;
        	open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_ca_evaluation" or print STDERR "PRINT LOG ERROR: $!\n";;
        	print $printLog "Job started at " . Settings::getDateTime() . "\n";
        	foreach my $user(@keys)
        	{
			my $uData=$delUsers{$user}->{USER_DATA}	;
			my $evalData=$delUsers{$user}->{EVAL_DATA}	;
            		if ($dryRun)
            		{
                		####### simply output the user and his delivery option.  No changes will be made to the database
                		$deliveryId = ($delUsers{$user}->{DELIVERY_ID}) ? $delUsers{$user}->{DELIVERY_ID} : 1;
                		$courseId   = $delUsers{$user}->{COURSE_ID};
                		print "User ID:  $user  Course:  $courseId   Delivery ID:  $deliveryId\n";
            		}
            		else
			{
                		my $cert = Certificate::CaliforniaEvaluation->new;
               			my $result = 0;
               			$result=$cert->printCourseEvaluation($user, $uData, $evalData, { PRINTER => 1},$printerKey);
		    			if($result)
                    			{
                        			print "$user:  Course Evaluation Printed\n";
                    			}
                    			else
                    			{
                        			print "$user:   Not Printed\n";
                    			}
                		$certsPrinted++;
            		}

        	}
        	close $printLog;
    	}

}
