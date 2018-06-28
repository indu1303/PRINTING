 #!/usr/bin/perl -I /ids/tools/PRINTING/lib

use strict;
use Symbol;
use printerSite;
use Settings;
use Accessory;
use Data::Dumper;
use Certificate;
use MysqlDB;
use Getopt::Std;
use PDF::Reuse;
use Net::FTP;
use Image::Info qw(image_info dim);

my $self= Settings->new;
my $product='DIP';
my $LAFaxCert;
my $STCCert;
my $productId       = 1;
my $printingAPI     = 'TEEN';
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
my $dryRun          = 0;
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
getopt('Kscl:', \%opts);
print "\nRunning IDS Printing Job\n";
print "Job running on $SERVER_NAME\n";
print "**************************\n\n";

################# process all incoming options
################# options are as follows:
#
#    -c course   Run a perticular Course Id
#    -D          Dry Run
#    -E          Display all users who will not print
#    -G          Only process priority students
#    -H          Print Hosted Affiliates
#    -h          Print out the help file
#    -K product  Product
#    -l num      Process the requested number of users
#    -R          Run Duplicate
#    -s          Run a single state only

   ####  Get the Product Id
if($opts{K})
{
        $productId = ($self->{PRODUCT_ID}->{$opts{K}})?$self->{PRODUCT_ID}->{$opts{K}}:1;
        $printingAPI = ($self->{PRINTING_API}->{$opts{K}})?$self->{PRINTING_API}->{$opts{K}}:$product;
	$product=$opts{K};
	
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
my $time = time();
my ($day,$mon,$year) = (localtime($time))[3,4,5];
$year +=1900;
$mon = $mon+1;
$mon = ($mon<10)?"0".$mon:$mon;
$day = ($day<10)?"0".$day:$day;
my $todayDate = "$year-$mon-$day";

my $printers = $API->{PRINTERS};

if(exists $self->{HOSTED_AFFILIATE_PRODUCT_ID}->{$product}){
	$hostedAffRun=$product;
}
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

    -F              No priority delivery students will print

    -G              Only print priority delivery students


    -l num          Specifies the number of users that will be processed by this
                    print job.  By default, all users will be processed


    -K product      Product


OUT
    exit;
}


####### check to see if a dry run was ordered.  If so, the system will only print out a list of students
####### who will print.
if ($opts{D})
{
    ##### order a dry run of the system
    print "Performing a Dry Run\n";
    $dryRun = 1;
}

######## are we doing a limited run?
if ($opts{l})
{
    $limitedRun = 1;
    $runCounter = $opts{l};
    print "Only $runCounter User(s) will be Processed\n";
}

######## Is the printer to be ping'd?
if ($opts{E})
{
    ##### order a dry run of the system
    print "Displaying all filtered out users\n";
    $showError = 1;
}


    print "Only GA certs will print.\n";

$processCourse = 'GA-Teen';

############### Get a lock file for this particular course
if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
{
    ##### send an alert to the CRM
    $API->MysqlDB::dbInsertAlerts(7);
    Settings::pSendMail('dev@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Daily Process Error - $SERVER_NAME",
                "Lock file exists $lockFile...\n");
  exit();
}

####### ASSERT:  No lock file exists and the printer properly passed the ping test.  Let's collect the
####### Required data and start the print job
my @processed = ();
my $users;

$startTime = time;
my $nonPrintedGAUsers=1;
$users =  $API->MysqlDB::dbGetManifestUserByErrorId('GA-Teen',$nonPrintedGAUsers,$productId);

print "Users retrieved.  execution time:  " . int(time - $startTime) . " seconds\n";
print "Number of users retrieved:  " . (keys %$users) . "\n";
$startTime = time;

my %txUsers;
my %teenUsers;
my %matureUsers;
my %gaUsers;
my %fleetUsers;
my $caUsers_STC;
my $hostedAffiliateUsers_STC;
my %hostedAffiliateUsers;
my %dupUsersTX;
my %dupUsersCA;
my $hostedAffiliates    ;
#= pGetAllHostedAffiliateCourses();
my $courseId;
my $deliveryId;
for my $key(keys %$users)
{
    my $uid=$key;
    my $printId=$users->{$key}->{PRINT_ID};
    my $printDate=$users->{$key}->{PRINT_DATE};
    my $userData;
    $courseId=0;
    my $userDuplData;
    $userData   =   $API->getUserData($uid);
    $courseId   =   $userData->{COURSE_ID};
    if (! $courseId)
    {
        next;
    }
    my $address = $userData->{ADDRESS_1};
    $address =~ s/\.//gi;
    $address =~ s/ //gi;
    $address =~ s/0/O/gi;
    ############ we now have the user data.  Let's start filtering out users who should not print
    ############ based on requirements for that particular state / regulator.
        if($userData->{LOCK_DATE})
        {
            ###### user's account is locked
            if ($showError)
            {
                print "User id:  $uid - The user's account is locked\n";
            }
            next;
        }

        if (exists $self->{PREMIUMDELIVERY}->{$self->{PRODUCT}}->{$userData->{DELIVERY_ID}} && $noFedex && ! $RUNDUPLICATE )
        {
            #### The user is a priority user and the job does not run priority
            if ($showError)
            {
                print "User id:  $uid - Priority user in a non-priority job\n";
            }
            next;
        }

        if (! exists $self->{PREMIUMDELIVERY}->{$self->{PRODUCT}}->{$userData->{DELIVERY_ID}} && $onlyFedex && ! $RUNDUPLICATE )
        {
            #### The user is not a priority user and the job only runs priority
            if ($showError)
            {
                print "User id:  $uid - Non Priority user in a priority job\n";
            }
            next;
        }

        if (exists $self->{NO_PRINT_COURSE}->{$self->{PRODUCT}}->{$courseId} )
        {
            #### The user is attached to a course that does not print
            if ($showError)
            {
                print "User id:  $uid - $courseId is a non-printing course\n";
            }
            next;
        }

        my $certId  = $userData->{CERT_PROCESSING_ID};
        $deliveryId = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID} : 1;

        ######## check if a particular state was asked for
        if ($stateList && ! exists $stateList->{$courseId})
        {
            ######## user does not exist for the particular state.
            if ($showError)
            {
                print "User ID:  $uid : This script is running for $state only\n";
            }
            next;
        }

	###### Non TX printing
	$gaUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
	$gaUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
	$gaUsers{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
	$gaUsers{$uid}->{PRINT_ID}     = $printId;
	$userData->{JOB_PRINT_DATE}   =  $printDate;
	$gaUsers{$uid}->{USER_DATA}    = $userData;
}

print "Users processed.  execution time:  " . int(time - $startTime) . " seconds\n";
$startTime = time;
if(keys %gaUsers)
{
    GAPrint(\%gaUsers,$hostedAffRun);
}else{
	if (! $dryRun){
		use MIME::Lite;
                my $message = 'There are no TEEN GA Certificates today.';
                my $subject = "GA Teen Certificate - $todayDate";
		my $to = 'idcteen@ed-ventures-online.com';
                my $from = 'I DRIVE SAFELY <reports@idrivesafely.com>';

                my $Email = MIME::Lite->new(
                                        From => $from,
                                        To => $to,
                                        Subject => $subject,
                                	Type => 'multipart/mixed'
                                );
		$Email->attach(
                		Type => 'text/html',
                		Data => $message
              		);
		$Email->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');

	}
}
	

print "Users Print processed.  execution time:  " . int(time - $startTime) . " seconds\n";
###send mail for date violated users for classroom course
my $userData;
if(!$dryRun){
	if($printManifest)
	{
	    Settings::pSendMail('supportmanager@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <reports@idrivesafely.com>', "Print Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", $printManifest);
	}

	if($fedexManifest)
	{
	    Settings::pSendMail('supportmanager@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <reports@idrivesafely.com>', "FedEx Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", $fedexManifest);
	}
}
exit;
##################### Define the different script printing types

sub GAPrint
{

    	my ($printUsers,$affiliateId)=@_;
    	my %delUsers=%$printUsers;
    	my $currentCertificate;
    	$processCourse = 'GA';
    	if (!$printerKey)
    	{
    	    $printerKey = 'CA';
   	}
    	if (! ($lockFile = Accessory::pAcquireLock($processCourse)))
    	{
        	##### send an alert to the CRM
        	$API->MysqlDB::dbInsertAlerts(7);
        	exit();
    	}

    	######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    	my %sort = ( 11 => 1, 2 => 2, 7 => 3, 1 => 4, 12 => 5);
    	my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;

    	print STDERR "num of users ready to process " . @keys . " \n";

    	my $certUsers;
    	my $labelPdfUsers;

    	if(@keys)
    	{
        	$printLog = gensym;
        	open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_ca" or print STDERR "PRINT LOG ERROR: $!\n";;
        	print $printLog "Job started at " . Settings::getDateTime() . "\n";
	
        	foreach my $user(@keys)
        	{
            		my $uData=$delUsers{$user}->{USER_DATA};
            		if ($limitedRun && ! $runCounter)
            		{
                		###### we're doing a limited run and that number has been reached.  Leave this loop
                		last;
            		}
            		if ($dryRun)
            		{
                		####### simply output the user and his delivery option.  No changes will be made to the database
                		$deliveryId = ($delUsers{$user}->{DELIVERY_ID}) ? $delUsers{$user}->{DELIVERY_ID} : 1;
                		$courseId   = $delUsers{$user}->{COURSE_ID};
                		print "User ID:  $user  Course:  $courseId   Delivery ID:  $deliveryId\n";
            		}
            		else
            		{
                		#my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
				my $certModule = "GATeen";
                		if ($certModule ne $lastModule)
                		{
                        		eval("use Certificate::$certModule");
                        		$certificateArray[$certModule] = ("Certificate::$certModule")->new;
                        		$lastModule=$certModule;
                		}

                		my $cert = $certificateArray[$certModule];

                    			my $result = 0;
                    			my $printId = $delUsers{$user}->{PRINT_ID};
                       			$result=$cert->printCertificate($user, $uData,$printId,$productId);
		    			if($result)
                    			{
						$labelPdfUsers->{$user} = $user;
						$API->MysqlDB::dbUpdateManifestErrorCode($printId,0);
                        			print "$user:  Certificate File created\n";

						if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                                                	$delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                                		}

						if($delUsers{$user}->{DELIVERY_ID} && $delUsers{$user}->{DELIVERY_ID} == 1 ){
		                                        use Certificate::CATeen;
        		                                my $cert1=Certificate::CATeen->new;
                		                        $cert1->printCATeenLabel($user,$uData);
                        		        }elsif (($delUsers{$user}->{DELIVERY_ID} == 2 || $delUsers{$user}->{DELIVERY_ID} == 7 || $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE)
                                		{
		                                     $fedexManifest .= $API->printFedexLabel($user,1,'');

                		                }


                    			}
                    			else
                    			{
                        			print "$user:  Invalid certificate returned - Not Printed\n";
                    			}
                		$certsPrinted++;
            		}

            		if ($limitedRun)
            		{
               	 		###### decrement the run counter
                		--$runCounter;
            		}
        	}
        	close $printLog;
    	}

}


