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
my $self= Settings->new;
my $product='DIP';
my $productId       = 1;
my $printingAPI     = 'DIP';
my $API;
my %opts;
my $CERT_THRESHOLD  = 200;
my $lastModule='';
my $SERVER_NAME     = (split(/\./,qx/uname -n/))[0];
my $printer         = '';
my $certsPrinted    = 0;
my $hostedAffRun    = 0;
my $dryRun          = 0;
my $showError       = 0;
my $printerKey      = 'CA';
my $lockFile        = 0;
my $runCounter      = 0;
my $limitedRun      = 0;
my $priority        = 1;
my $noFedex         = 0;
my $onlyFedex       = 0;
my $ping            = 1;
my $fedexManifest   = "";
my $printManifest   = "";
my $stateList       = 0;
my $state           = "";
my $printLog;
my $type='PDF';
my %hashProcessCourse;
my @certificateArray;
my $duplicatelicenseusers;
getopt('Kpl:', \%opts);
print "\nRunning IDS Printing Job\n";
print "Job running on $SERVER_NAME\n";
print "**************************\n\n";

################# process all incoming options
################# options are as follows:
#
#    -D          Dry Run
#    -E          Display all users who will not print
#    -F          Do not process priority students
#    -G          Only process priority students
#    -h          Print out the help file
#    -K product  Product
#    -l num      Process the requested number of users
#    -P          Do not ping the printer
#    -p printer  Print to the (CA|TX) printer

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

    -E              Display all filtered out users

    -F              No priority delivery students will print

    -G              Only print priority delivery students

    -l num          Specifies the number of users that will be processed by this
                    print job.  By default, all users will be processed
    -p printer      Print to the [$printerList] printer.  By default, all jobs will print to the
                        default printer for that particular course

    -P              The printer will not be ping'd

    -K product      Product


OUT
    exit;
}

######## Will non fedex users print?
if ($opts{F})
{
    $noFedex = 1;
    print "No priority students will print\n";
}

######## Will non fedex users print?
if ($opts{G})
{
    $onlyFedex = 1;
    print "Only priority students will print\n";
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
if ($opts{P})
{
    ##### Do not ping the printer
    print "Printer will not be ping'd\n";
    $ping = 0;
}
####### now let's set up the printer
if ($opts{p})
{
    ###### a printer option has been passed in.  Let's make sure this is a valid entry
    my $printk = uc($opts{p});

    if (exists $printers->{$printk})
    {
        $printerKey = $printk;
        print "Printing to the $printk printer\n";
    }
    else
    {
        print "$printk is not a valid printer\n";
    }
}

if ($opts{E})
{
    ##### order a dry run of the system
    print "Displaying all filtered out users\n";
    $showError = 1;
}

$hashProcessCourse{STATE}= 'ALLPRINT'; 

##################### let's set up a couple of conditionals to see if we're allowed to print
if ($ping)
{
    my @AllPrinterIP=$API->getAllPrintersIP();
    my $failed=0;
    foreach my $printerIP( @AllPrinterIP){
            if(!Accessory::pPingTest($printerIP, $hashProcessCourse{STATE}, $printerKey))
                {
                print STDERR Settings::getDateTime(), " - COURSE $hashProcessCourse{STATE} FAILED ON PING TEST : IP = $printerIP\n";
                $failed=1;
            }
    }
    if($failed){
                $API->MysqlDB::dbInsertAlerts(12);
                exit;
    }
}

####### ASSERT:  No lock file exists and the printer properly passed the ping test.  Let's collect the
####### Required data and start the print job
my @processed = ();
my $users;

$startTime = time;

$users =  $API->getWorkbookUsers(\%hashProcessCourse);

print "Users retrieved.  execution time:  " . int(time - $startTime) . " seconds\n";
print "Number of users retrieved:  " . (keys %$users) . "\n";
$startTime = time;
my %caUsers;
my $hostedAffiliates    ;
my $courseId;
my $deliveryId;
for my $key(keys %$users)
{
    my $uid=$key;
    my $userData = $API->getUserData($uid);;
    $courseId=0;
    ############ we now have the user data.  Let's start filtering out users who should not print
    ############ based on requirements for that particular state / regulator.
        if (exists $self->{PREMIUMDELIVERY}->{$self->{PRODUCT}}->{$users->{$uid}->{DELIVERY_ID}} && $noFedex)
        {
            #### The user is a priority user and the job does not run priority
            if ($showError)
            {
                print "User id:  $uid - Priority user in a non-priority job\n";
            }
            next;
        }

        if (! exists $self->{PREMIUMDELIVERY}->{$self->{PRODUCT}}->{$users->{$uid}->{DELIVERY_ID}} && $onlyFedex)
        {
            #### The user is not a priority user and the job only runs priority
            if ($showError)
            {
                print "User id:  $uid - Non Priority user in a priority job\n";
            }
            next;
        }

        $deliveryId = ($users->{$uid}->{DELIVERY_ID})?$users->{$uid}->{DELIVERY_ID} : 1;

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
        $caUsers{$uid}->{USER_DATA}    = $userData;
        $caUsers{$uid}->{DELIVERY_ID}  = ($users->{$uid}->{DELIVERY_ID})?$users->{$uid}->{DELIVERY_ID}:1;

    
}
print "Users processed.  execution time:  " . int(time - $startTime) . " seconds\n";
$startTime = time;
if(keys %caUsers)
{
    WorkBookLabelPrint(\%caUsers,$hostedAffRun);
}
print "Users Print processed.  execution time:  " . int(time - $startTime) . " seconds\n";
###send mail for date violated users for classroom course
my @duplicatedluserscount = keys %$duplicatelicenseusers;
my $userlist = "The folllowing users have Completion Date Violation\n";
my $userData;
if(!$dryRun){
	if($printManifest)
	{
	    Settings::pSendMail('printmonitor@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Workbook Regular Label Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", $printManifest);
	}

	if($fedexManifest)
	{
	    Settings::pSendMail('printmonitor@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Workbook FedEx Label Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", $fedexManifest);
	}
}
exit;
##################### Define the different script printing types

sub WorkBookLabelPrint
{

    my ($printUsers,$affiliateId)=@_;
    my %delUsers=%$printUsers;
    my $currentCertificate;
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($hashProcessCourse{STATE})))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 11 => 1, 2 => 2, 7 => 3, 1 => 4, 12 => 5);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    print STDERR "num of users ready to process " . @keys . " \n";
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
	            if ($delUsers{$user}->{DELIVERY_ID} == 2 ||  $delUsers{$user}->{DELIVERY_ID} == 7 ||  $delUsers{$user}->{DELIVERY_ID} == 11) {
				$fedexManifest .= $API->pFedexLabelPrintForWorkbook({NAME => "$uData->{FIRST_NAME} $uData->{LAST_NAME}",ATTENTION => "", ADDRESS => $uData->{ADDRESS_1}, ADDRESS_2 =>  $uData->{ADDRESS_2}, CITY => $uData->{CITY}, STATE => $uData->{STATE}, ZIp => $uData->{ZIP}, PHONE => $uData->{PHONE}, DESCRIPTION =>"For WB $user", SIGNATURE => '', DELIVERY_ID => $delUsers{$user}->{DELIVERY_ID}, PRINTCATEGORYID=>1, USER_ID=>$user, COURSE_STATE => $uData->{COURSE_STATE}  });
                    }else{
    		    		my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
				if ($certModule ne $lastModule) {
					eval("use Certificate::$certModule");
					$certificateArray[$certModule] = ("Certificate::$certModule")->new;
					$lastModule=$certModule;
				}
				my $cert = $certificateArray[$certModule];
                	        $cert->printRegularLabel($user,$uData);
				$API->updateUserWorkbookProcess($user,0);
	                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

        	                ####### log all of this in the print log, print manifest and STDERR
                	        my $printString = "Printed Workbook Label User:  $user : $name";
	                        print $printLog Settings::getDateTime(), "$printString\n";
        	                print "$printString\n\n";
                	        $printManifest .= "$printString\n\n";

		   }
                   $certsPrinted++;

                   if ($certsPrinted > $CERT_THRESHOLD)
                   {
                   	print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
	                close $printLog;
        	        Accessory::pReleaseLock($hashProcessCourse{STATE}, $lockFile);
                	exit;
                   }
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
