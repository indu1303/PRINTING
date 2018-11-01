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
use Spreadsheet::WriteExcel;
my $self= Settings->new;
my $product='DIP';
my $LAFaxCert;
my $STCCert;
my $productId       = 1;
my $printingAPI     = 'DIP';
my $API;
my %opts;
my $CERT_THRESHOLD  = 300;
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
my $manifestIdTexasOffice= 0;
my $manifestIdCaliforniaOffice=0;
my $ping            = 1;
my $fedexManifest   = "";
my $driversEdDataUpdate   = "";
my $printManifest   = "";
my $stateList       = 0;
my $state           = "";
my $fleetId         = 0 ;
my $deliveryMode    = '';
my $jobPrintDate    = Settings::getDateTimeInANSI();
my $allDeliveryMode = { map { $_ => 1 } qw (PRINT FAX EMAIL DOWNLOAD) };
my $RUNDUPLICATE    = 0;
my $runSTC          = 0;
my $printMode       = 'Cron Run';
my $accompanyLetter='';
my $affidavit='';
my $deAffidavit='';
my $permitCerts='';
my $permitCertsDE='';
my $permitVoidCerts='';
my $partialTransfer='';
my $laCountyHardcopy  = 0;
my $dateRange = 0;
my $numMail = 0;
my $numAirBill = 0;
my $printNonTXPriorityUser=0;
my $numFax = 0;
my $printLog;
my $jobDate;
my $segment=0;
my $error_msg = undef;
my $type='PDF';
my $approved=1;
my %hashProcessCourse;
my @certificateArray;
my @dateviolationusers;
my @sellerServerWithoutSSNUsers;
my @TXTEENUSERPRINTED;
my $duplicatelicenseusers;
my $westCoastStates;
my $xlsFileName='';
my $returnMailJobs=0;
my %driversEdUsers;
my %driversEdCOTeenUsers;
my %driversEdNVTeenUsers;
my %driversEdCATeenUsers;
my %driversEdCAMatureUsers;
my %driversEdCOMatureUsers;
my %driversEdMNTeenUsers;
getopt('KpscitfldUB:', \%opts);
print "\nRunning IDS Printing Job\n";
print "Job running on $SERVER_NAME\n";
print "**************************\n\n";

################# process all incoming options
################# options are as follows:
#
#    -A          Run Accompany Letter
#    -c course   Run a perticular Course Id
#    -D          Dry Run
#    -V          Print Affidavit
#    -T          Print Permit Certificate
#    -d delmod   delivery Mode, Download for DE Students
#    -E          Display all users who will not print
#    -F          Do not process priority students
#    -f Run Perticular Fleet Company Identify by Fleet Id
#    -G          Only process priority students
#    -H          Print Hosted Affiliates
#    -h          Print out the help file
#    -K product  Product
#    -l num      Process the requested number of users
#    -P          Do not ping the printer
#    -p printer  Print to the (CA|TX) printer
#    -R          Run Duplicate
#    -Q          Run Duplicate for Retrun Mail
#    -S          Run STCs
#    -s          Run a single state only
#    -t          Print Mode(Cron Type, Manual Type)
#    -X		 Print DE Teen Attendance Records only(Can be CO Teen/TX Teen32 Attendance Logs)
#    -W		 Print NONTX Certificate for w/wo priority students
#    -U	 	 Print West Coast States Certificates : refer $WEST_COAST_STATES variable in Settings.pm

   ####  Get the Product Id
if($opts{K})
{
        $productId = ($self->{PRODUCT_ID}->{$opts{K}})?$self->{PRODUCT_ID}->{$opts{K}}:1;
        $printingAPI = ($self->{PRINTING_API}->{$opts{K}})?$self->{PRINTING_API}->{$opts{K}}:$product;
	$product=$opts{K};
	
}
if($opts{B})
{
        $segment = ($opts{B})?$opts{B}:0;

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

    -H              Process Hosted Affiliates

    -B              Only Segment Users

    -D              Perform a dry run.  Will display users who are eligible to print, their course id
                    and their delivery id only.  No printing or updating of accounts will occur

    -E              Display all filtered out users

    -V              Run Affidavit users

    -T              Run Permit Certificate Users

    -F              No priority delivery students will print

    -G              Only print priority delivery students

    -L              Print Los Angeles hard copies

    -l num          Specifies the number of users that will be processed by this
                    print job.  By default, all users will be processed

    -p printer      Print to the [$printerList] printer.  By default, all jobs will print to the
                        default printer for that particular course

    -P              The printer will not be ping'd

    -s state        run a single state only.  Use the two-letter state abbreviation or FLEET for
                    fleet certs

    -A              Run Accompany Letter

    -c courseId     Run a perticular Course Id

    -d del mode     delivery Mode(Email,Fax,Print,Download)

    -f fleetId      Run Perticular Fleet Company Identified by Fleet Id

    -Q          Run Duplicate for Retrun Mail

    -R              Run Duplicate

    -S              Run STCs

    -t mode         Print Mode (Cron Type, Manual Type)

    -K product      Product

    -X              Print DE CO Teen Attendance Records only

    -Z 		    Partial Transfer

    -Y              PermitVoidCerts

    -W		 Print NONTX Certificate for w/wo priority students based on Global state declare


OUT
    exit;
}

if ($opts{A})
{
    ##### Run accompany letters
    print "Accompany letters will be processed\n";
    $accompanyLetter = 1;
}

if ($opts{V})
{
    ##### Run accompany letters
    print "Teen Affidavits will be processed\n";
    $affidavit = 1;
}

if ($opts{X})
{
    ##### Run accompany letters
    print "DE CO Teen Attendance Records will be processed\n";
    $deAffidavit = 1;
}

if ($opts{T})
{
    ##### Run accompany letters
    print "Teen Permit Certificates will be processed\n";
    $permitCerts = 1;
    $permitCertsDE = 1;
}

if ($opts{Y})
{
    ##### Run accompany letters
    print "Teen Permit Void Certificates will be processed\n";
    $permitVoidCerts = 1;
}
if ($opts{Z})
{
    ##### Run accompany letters
    print "Teen Permit Certificates for Partial Transfer\n";
    $partialTransfer=1;
}

if ($opts{W})
{
    ##### Run NonTX Priprity Studwent Also
    print "Non TX Priority student  will be processed also\n";
    $printNonTXPriorityUser = 1;
}
######## Will non fedex users print?
if ($opts{F})
{
    $noFedex = 1;
    print "No priority students will print\n";
}

######## Will Return Mail jobs print?
if ($opts{Q})
{
    $returnMailJobs = 1;
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
if ($opts{d})
{
        ### Check the delivery Mode;
        my $delMode  = uc $opts{d};
        $deliveryMode = (exists $allDeliveryMode->{$delMode}) ? $delMode : 0;
	if($delMode && $delMode eq 'DOWNLOAD' && $productId && $productId eq '41') {
        	$hashProcessCourse{DELIVERY_MODE} = ($delMode && $delMode eq 'DOWNLOAD') ? 'DWNLD' : '';
	}

        if (! $deliveryMode)
        {
                print "$delMode is not a valid delivery mode.\nExiting...\n";
                exit;
        }
        else
        {
                print "Only certificates to be $delMode" . "ed will be processed\n";
        }
}
if ($opts{L})
{
    ##### order a dry run of the system
    print "Running LA County Hard Copies\n";
    $laCountyHardcopy = 1;
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

if ($opts{s})
{
    ##### Check the requested state
    $stateList = {};
    my $stateAbbr = uc ($opts{s});
    my $allStates = $API->{STATES};
    $hashProcessCourse{STATE}= $stateAbbr; 
    if (exists $allStates->{$stateAbbr})
    {
        $state = $stateAbbr;
    }
    elsif (uc($opts{s}) eq 'FLEET')
    {
        $state = 'FC';
    }
    else
    {
        print "$opts{s} is not a valid state\n";
        exit;
    }

    ####### let's get all the associated courses available for this particular state
    my $course= $API->getCourseSelection($state);

    foreach my $cId(keys %$course)
    {
        $stateList->{$cId} = 1;
    }

    if ($state eq 'TX' && $product eq 'DIP')
    {
        $printerKey = 'TX';
    }

    print "Only $state certs will print.\n";
}

if($opts{c} && $opts{X} && $opts{c} eq 'C0000071') {
	if($opts{i} eq 'OTHERDS' || $opts{i} eq 'PARENTTAUGHTOPT' || $opts{i} eq 'PARENTTAUGHTCOURSE') {
		print "\nDE Teen 32 Hour Course Attendance sheets will be processed for Reason - $opts{i} \n";
	} else {
		print "\nDE Teen 32 Hour Course Attendance sheets will NOT be processed for Reason - $opts{i}\nExiting...\n";
		exit;
	}
}

if ($opts{c})
{
        #### Check the course Id #####
        $stateList = {};
        my $cId = $opts{c};
        $stateList->{$cId} = 1;
        $hashProcessCourse{COURSE}= $cId; 
	my $courses = $API->getCourseDescription($cId);
    if (exists $courses->{$cId})
    {
        print "Course $cId : $courses->{$cId}->{DEFINITION} will be processed\n";
    }
    else
    {
        print "Course Id $cId does not exist\nExiting...\n";
        exit;
    }
}

if ($opts{i})
{
        #### Check the reason #####
	### For DE TX Teen32 Certificate - DEDS / OTHERDS/ PARENTTAUGHTOPT / PARENTTAUGHTCOURSE reasons
        my $reason = $opts{i};
        $hashProcessCourse{COURSE_REASON}= $reason; 
	my $settings = Settings->new;
	if($reason && !$settings->{DE_TX_TEEN32_COC_REASONS}->{$reason}) {
		print "\nInvalid Reason given\nExiting...\n";
		exit;
	}
	if(!$reason) {
		print "\nNo Reasons given\nExiting...\n";
		exit;
	}
}


if($opts{f})
{
        ### Checking the Fleet Id
        $hashProcessCourse{STATE}= 'FC'; 
        $fleetId=$opts{f};
}

if($opts{R})
{
        #### Run Duplicates
    print "Running Duplicates\n";
        $RUNDUPLICATE=1;
}

if($opts{S})
{
        #### Run STCs
    print "Running STCs only\n";
        $hashProcessCourse{STC}= '1'; 
        $runSTC=1;
}
if($opts{t})
{
	$printMode=uc $opts{t};
        if(uc $printMode eq 'MANUAL')
        {
                $printMode = 'Manual Run';
        }
        elsif(uc $printMode eq 'INDIVIDUAL')
        {
                $printMode = 'Individual';
        }
        else
        {
                $printMode = 'Cron Run';
        }
}

if ($opts{U})
{
    ##### Run only West Coast States Certs
    print "West Coast States Certificates\n";
    $westCoastStates = $opts{U};
}

if(!$opts{R} && !$opts{c} && !$opts{s} && !$opts{A} && !$opts{S} && !$opts{f})
{
        $hashProcessCourse{COURSE}= 'ALLCAPRINT'; 
        $opts{c}='ALLCAPRINT';                    ######Print All CA Course ########
}

$processCourse = $opts{c};

##################### let's set up a couple of conditionals to see if we're allowed to print
if ($ping)
{
    my @AllPrinterIP=$API->getAllPrintersIP();
    my $failed=0;
    my $msgPing='';
    foreach my $printerIP( @AllPrinterIP){
	    ######### ping the printer, see if it's alive.
	    if(!Accessory::pPingTest($printerIP, $processCourse, $printerKey))
    		{
	        ###### send an alert to the CRM
	        print STDERR Settings::getDateTime(), " - COURSE $processCourse FAILED ON PING TEST : IP = $printerIP\n";
		$msgPing.=Settings::getDateTime() . " - COURSE $processCourse FAILED ON PING TEST : IP = $printerIP\n";
		$failed=1;
    	    }
    }
    if($failed){
		 Settings::pSendMail('support-it@ed-ventures-online.com,qa@ed-ventures-online.com,dev@ed-ventures-online.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Failed the Printing Ping", $msgPing);
#		exit;
    }
}

####### ASSERT:  No lock file exists and the printer properly passed the ping test.  Let's collect the
####### Required data and start the print job
my @processed = ();
my $users;

$startTime = time;

if(!$RUNDUPLICATE)
{
        if($accompanyLetter)
        {
                $users  =       $API->getAccompanyLetterUsers();
	}
        elsif($permitCerts)
	{
                $users  =       $API->getPermitCertsUsers($approved, $opts{c});
	}
        elsif($permitVoidCerts)
	{
                $users  =       $API->getVoidPermitCertsUsers();
	}
        elsif($partialTransfer)
	{
                $users  =       $API->getPartialTransferUsers($approved);
	}
        elsif($affidavit)
	{
                $users  =       $API->getAffidavitUsers();
	}
        elsif($deAffidavit)
	{
                $users  =       $API->getAffidavitUsers($opts{c}, $opts{i});
	}
        elsif ($laCountyHardcopy)
        {
        	$users  = $API->getLAUsers;
        }
        else
        {
	        $users =  $API->getCompleteUsers(\%hashProcessCourse);
        }
}
else
{
       $users = $API->getCertDuplicatePrint();
}
##For DE OH Teen + TX Teen32 HR, a special check
if($product && $opts{c} && $product eq 'DRIVERSED' && ($opts{c} eq 'C0000067' || $opts{c} eq 'C0000071')) {
	$permitCerts  = 0;
}
print "Users retrieved.  execution time:  " . int(time - $startTime) . " seconds\n";
print "Number of users retrieved:  " . (keys %$users) . "\n";
$startTime = time;

my %txUsers;
my %teenUsers;
my %aaateenUsers;
my %dipDVDUsers;
my %adultUsers;
my %matureUsers;
my %aaaSeniorUsers;
my %caUsers;
my %fleetUsers;
my $caUsers_STC;
my $hostedAffiliateUsers_STC;
my %hostedAffiliateUsers;
my %dupUsersTX;
my %dupUsersCA;
my $hostedAffiliates    ;
my %dsmsUsers;
my %ssUsers;
my %aarpUsers;
#= pGetAllHostedAffiliateCourses();
my $courseId;
my $deliveryId;
my @DIPFLUSERIDSNOTPRINTED;
my @TEENFLUSERIDSNOTPRINTED;
for my $key(keys %$users)
{
    my $uid=$key;
    my $userData;
    $courseId=0;
    my $userDuplData;
    if($RUNDUPLICATE)
    {
        ####### this is a different type of job.  Instead of going through the hash by way of the user ids
        ####### we go through the hash based on duplicate id.  Duplicate id contains the record information
        ####### such as user id, records to be duplicated, etc.
        my $dupId=$key;
        $uid=$users->{$key}->{USER_ID};
        $userData = $API->getUserData($uid);
        $userData->{DUPLICATE_ID} = $dupId;
        $courseId = $userData->{COURSE_ID};
                $userDuplData = $API->getUserCertDuplicateData($users->{$dupId}->{USER_ID}, $dupId, 1);
                my $dData=$userDuplData->{DATA};
                if(!exists $self->{TEXASPRINTING}->{$self->{PRODUCT}}->{$courseId}){
                        foreach(keys %$dData)
                        {
                                $userData->{$_} = $dData->{$_};
                        }
                }else{
                        foreach(keys %$userDuplData)
                        {
                                $userData->{$_} = $userDuplData->{$_};
                        }

                }
                $userData->{DATA} = $dData;
    }
    elsif ($accompanyLetter)
    {
        ###### finally, we're dealing w/ accompany letters.  If so, we'll have to manipulate
        ###### the certificate type
       	$userData = $API->getUserData($uid);
        my $courseId = $userData->{COURSE_ID};

        $userData->{CERT_1} = "STUDENT COPY";
        $caUsers{$uid}->{USER_DATA}    = $userData;
        $caUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
        $caUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
        $caUsers{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
        $caUsers{$uid}->{ACCOMPANY_LETTER} = 1;
    }
    elsif($affidavit){
        $userData = $API->getUserAffidavitData($uid);
        $teenUsers{$uid}->{USER_DATA}    = $userData;
        $teenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
        $teenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
        $teenUsers{$uid}->{AFFIDAVIT} = 1;
    }
    elsif($partialTransfer){
       	$userData = $API->getUserData($uid);
	$userData->{ISSUE_DATE}=$users->{$key}->{ISSUE_DATE};
	$courseId=$users->{$key}->{COURSE_ID};
   }
   elsif($permitCerts){
       	$userData = $API->getUserData($uid, $permitCerts);
	$userData->{SECTION_COMPLETE_DATE}=$users->{$key}->{SECTION_COMPLETE_DATE};
	$courseId=$users->{$key}->{COURSE_ID};
   }
   elsif($permitVoidCerts){
       	$userData = $API->getUserData($uid);
	$userData->{SECTION_COMPLETE_DATE}=$users->{$key}->{SECTION_COMPLETE_DATE};
	$courseId=$users->{$key}->{COURSE_ID};
    }
    elsif($deAffidavit){
	$userData = $API->getUserData($uid);
	$driversEdCOTeenUsers{$uid}->{USER_DATA}    = $userData;
	$driversEdCOTeenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
	$driversEdCOTeenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
        $driversEdCOTeenUsers{$uid}->{AFFIDAVIT} = 1;
    }

    else
    {
	if($product && $product eq 'DIPDVD'){
        	$userData = $users->{$key}->{USERDATA};
	}else{
        	$userData   =   $API->getUserData($uid);
	}
        $courseId   =   $userData->{COURSE_ID};
    }
    if (! $courseId)
    {
        next;
    }
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
        if(exists $self->{NOTARYCOURSES}->{$self->{PRODUCT}}->{$courseId} &&
                (!$userData->{THIRD_PARTY_DATA} || $userData->{THIRD_PARTY_DATA} != 1)) {
		 if (!($userData->{VOICE_VERIFICATION_STATUS} && $userData->{VOICE_VERIFICATION_STATUS} eq 'PASSED'))
        	{
	            	###### the user has not completed the notary requirement
        	    	if ($showError)
            		{
                		print "User id:  $uid - User has THIRD_PARTY_DATA set to $userData->{THIRD_PARTY_DATA}\n";
            		}
        	    	next;
		}
        }
	if($RUNDUPLICATE){
	    	my $settings1 = Settings->new;
	        if(exists $settings1->{NOPRINTFORRETURNMAIL}->{$product}->{$userData->{COURSE_ID}}){
			if($userData->{DATA}->{RETURN_MAIL_DATA} && !$returnMailJobs){
				if($showError)
                        	{	
                                	print "User id:  $uid - This user is return Mail users, it will not print with regular duplicate jobs \n";
                        	}
	                        next;	
			}
			if(!$userData->{DATA}->{RETURN_MAIL_DATA} && $returnMailJobs){
				if($showError)
                        	{	
                                	print "User id:  $uid - This user is not return Mail users, it will not print with regular duplicate jobs \n";
                        	}
	                        next;	
			}
         	}
	}
	
	if ((exists $self->{INDIANA_FLASHCOURSE}->{$courseId} || exists $self->{NEVADACOURSES}->{$courseId}) && $self->{PRODUCT} eq 'DIP' && defined $userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA}==99)
	{
            	###### the user has not completed the notary requirement
       	    	if ($showError)
		{
			print "User id:  $uid - User has THIRD_PARTY_DATA set to $userData->{THIRD_PARTY_DATA}\n";
		}
            	next;
	}
	if(exists $self->{TEXASPRINTING}->{$self->{PRODUCT}}->{$courseId} && $userData->{DELIVERY_ID}  && $userData->{DELIVERY_ID} eq '26')
        {
                ###### the user has not completed the notary requirement
                if ($showError)
                {
                        print "User id:  $uid - User has Electronic Delivery, certificate will not be printed\n";
                }
                next;
        } 
        if ($self->{KENTUCKY_FLASHCOURSE} == $courseId && $self->{PRODUCT} eq 'DIP' && defined $userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA}==99)
        {
                ###### the user has not completed the notary requirement
                if ($showError)
                {
                        print "User id:  $uid - User has THIRD_PARTY_DATA set to $userData->{THIRD_PARTY_DATA}\n";
                }
                next;
        } 
        if ($self->{TAKEHOME_KENTUCKY_FLASHCOURSE} == $courseId && $self->{PRODUCT} eq 'TAKEHOME' && defined $userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA}==99)
        {
                ###### the user has not completed the notary requirement
                if ($showError)
                {
                        print "User id:  $uid - User has THIRD_PARTY_DATA set to $userData->{THIRD_PARTY_DATA}\n";
                }
                next;
        } 
	if (exists $self->{TAKEHOME_INDIANA_FLASHCOURSE}->{$courseId} && $self->{PRODUCT} eq 'TAKEHOME' && defined $userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA}==99) {
		###### the user has not completed the notary requirement
                if ($showError)
                {
                        print "User id:  $uid - User has THIRD_PARTY_DATA set to $userData->{THIRD_PARTY_DATA}\n";
                }
                next;
	}
    	if ($self->{PRODUCT} eq 'SS' && defined $userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA}==99)
        {
                if ($showError)
                {
                        print "User id:  $uid - User has THIRD_PARTY_DATA set to $userData->{THIRD_PARTY_DATA}\n";
                }
                next;
        }

	if (($self->{PRODUCT} eq 'CLASS') && ($userData->{DRIVERS_LICENSE} =~ m/^DUP/)){
		if($$duplicatelicenseusers{$userData->{INSTRUCTOR_ID}}->{STUDENT_ID}){
			$$duplicatelicenseusers{$userData->{INSTRUCTOR_ID}}->{STUDENT_ID} .= $uid.':'; 
		}else{
			$$duplicatelicenseusers{$userData->{INSTRUCTOR_ID}}->{STUDENT_ID} = $uid.':';
			$$duplicatelicenseusers{$userData->{INSTRUCTOR_ID}}->{INSTRUCTOR_NAME} = $userData->{INSTRUCTOR_NAME};
		}
		print "User id:  $uid - Has Duplicate Driver's License\n";
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
        if (exists $self->{CADMVCOURSES}->{$self->{PRODUCT}}->{$courseId} )
        {
            #### The user is attached to a course that does not print
           if(!($self->{PRODUCT} && $userData->{DELIVERY_ID} && exists $self->{PREMIUMDELIVERY}->{$self->{PRODUCT}}->{$userData->{DELIVERY_ID}})){
	            if ($showError)
        	    {
                	print "User id:  $uid - $courseId is a non-printing course\n";
        	    }
	            next;
	   }
        }

        if (exists $self->{NO_PRINT_COURSE}->{$self->{PRODUCT}}->{$courseId}  || (!$userData->{PA_CERT_CAN_PRINT} && $userData->{COURSE_STATE} eq 'PA' && $self->{PRODUCT} eq 'TEEN'))
        {
		if ($showError)
        	{
                	print "User id:  $uid - $courseId is a non-printing course\n";
        	}
	        next;
        }
        if (exists $self->{NO_REGULARMAIL_PRINT_COURSE}->{$self->{PRODUCT}}->{$courseId} && $userData->{NO_PRINT_CERT})
        {
            #### The user is attached to a course that does not print
            if ($showError)
            {
                print "User id:  $uid - $courseId is a non-printing course\n";
            }
            next;
        }
        if (exists $self->{POC_COURSES}->{$self->{PRODUCT}}->{$courseId} && !($userData->{UPSELLMAIL} || $userData->{UPSELLEMAIL} || $userData->{UPSELLMAILFEDEXOVA}))
        {
            #### The user is attached to a course that does not print
            if ($showError)
            {
                print "User id:  $uid - $courseId is a non-printing course\n";
            }
            next;
        }
	if($self->{PRODUCT} eq 'DIP' && $userData->{DELIVERY_ID} eq '1' && $userData->{REGULATOR_ID} && ($userData->{REGULATOR_ID} eq '107028' || $userData->{REGULATOR_ID} eq '107770')){
            #### The user is attached to a course that does not print
            if ($showError)
            {
                print "User id:  $uid - $courseId is a non-printing regulator\n";
            }
            next;
	}
	if($userData->{CTSI_SCMS_USER}){
            #### The user is CTSI User, and this can not be print, because for CTSI users data will be post to court directly
            if ($showError)
            {
                print "User id:  $uid - $courseId is a non-printing CTSI/SCMS course\n";
            }
            next;
	}
        my $certId  = $userData->{CERT_PROCESSING_ID};
        $deliveryId = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID} : 1;
        ####### the next three checks will verify if the student is scheduled to be printed, faxed or emailed
        if($deliveryMode && $deliveryMode eq 'PRINT')
        {
            ######### Print only.  Check for any non-printing users
                if(($certId==11 || $certId==12 || $certId == 15 ||  $certId == 22 || ($self->{EMAIL_DELIVERY_ID}->{$self->{PRODUCT}}->{$deliveryId})) ||  exists $self->{FAXCOURSE}->{$self->{PRODUCT}}->{$courseId})
            {
                if ($showError)
                {
                    print "User id:  $uid - Job is set for Printing only.  No faxing / emailing will occur\n";
                }
                            next;
                    }
            }

        elsif($deliveryMode && $deliveryMode eq 'FAX')
        {
            #########  Fax only.  Check for any non-faxing users
                if(! ($certId==11 || $certId==12 || $certId == 15 || $certId == 22) && ! exists $self->{FAXCOURSE}->{$self->{PRODUCT}}->{$courseId})
            {
                if ($showError)
                {
                    print "User id:  $uid - Job is set for Faxing only.  No printing / emailing will occur\n";
                }
                next;
            }
        }
        elsif($deliveryMode && $deliveryMode eq 'EMAIL')
        {
            #########  Email only.  Check for any non-emailing users
                if(!$deliveryId || ($deliveryId && ! exists $self->{EMAIL_DELIVERY_ID}->{$self->{PRODUCT}}->{$deliveryId}))
            {
                if ($showError)
                {
                   print "User id:  $uid - Job is set for Email only.  No printing / Faxing will occur\n";
                }
                           next;
                }
        }
        elsif($deliveryMode && $deliveryMode eq 'DOWNLOAD')
        {
            #########  Download Delivery only.  Check for any non-emailing users, DE Students
                if(!$deliveryId || ($deliveryId && ! exists $self->{DOWNLOADCOURSE}->{$self->{PRODUCT}}->{$courseId}))
            {
                if ($showError)
                {
                   print "User id:  $uid - Job is set for Download only.  No printing / Faxing / emailing will occur\n";
                }
                           next;
                }
        }

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
	if($product eq 'DIP' && (($state && $state ne 'NM') || !$state) && $userData->{COURSE_STATE} eq 'NM' && $segment != 8){
            ######## user does not exist for the particular state.
            if ($showError)
            {
                print "User ID:  $uid : This script is running for non-NM state only\n";
            }
            next;


	}
	if($product eq 'TEEN' && (($state && $state ne 'GA') || !$state) && $userData->{COURSE_STATE} eq 'GA'){
            ######## user does not exist for the particular state.
                    if ($showError)
                    {
                        print "User ID:  $uid : This script is running for non-GA state only\n";
                  }
             next;
	}	
        ######## check if a particular fleet id was asked for
        if($fleetId && $userData->{ACCOUNT_ID} != $fleetId)
        {
            ############ the fleet id didn't match the requested id.
            if ($showError)
            {
                print "User ID:  $uid : Fleet Id $userData->{ACCOUNT_ID} was not called from this instance\n";
            }
            next;
        }
	if(exists $self->{NISNTSACOURSE}->{$product}->{$userData->{COURSE_ID}}){
  		if ($showError)
  	        {
  	        	print "User ID:  $uid : This is NIS/NTSA user\n";
                }
                next;
  	}
        if(($productId eq 'AAATEEN' || $product eq 'TEEN') && $userData->{TO_BE_CHARGE_INSTALLMENT_AMOUNT} && !$permitCerts && !$partialTransfer && !$permitVoidCerts){
  		if ($showError)
  	        {
  	        	print "User ID:  $uid : Need to be charge installment amount of \$$userData->{TO_BE_CHARGE_INSTALLMENT_AMOUNT}\n";
                }
                next;
	}
	if($product eq 'ADULT' && $userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA}==99){
		if ($showError)
		{
			print "User ID:  $uid : Need to fax the Notary Affidavit to IDS \n";
		}
		next;
	}
	if($product eq 'DIP' &&  exists $self->{FL_CERT_VERIFICATION_COURSE}->{$self->{PRODUCT}}->{$userData->{COURSE_ID}}  && !$userData->{CERTIFICATE_NUMBER}){
		if ($showError)
		{
			print "User ID:  $uid : Need to get certificate number from FL DHSMV \n";
		}
		push @DIPFLUSERIDSNOTPRINTED,$uid;	
		next;

	}
	if($product eq 'TEEN' &&  exists $self->{FL_CERT_VERIFICATION_COURSE}->{$self->{PRODUCT}}->{$userData->{COURSE_ID}}  && !$userData->{CERTIFICATE_NUMBER}){
		if ($showError)
		{
			print "User ID:  $uid : Need to get certificate number from FL DHSMV \n";
		}
		push @TEENFLUSERIDSNOTPRINTED,$uid;	
		next;

	}
	if($product eq 'TEEN' &&  exists $self->{TEEN32COURSES}->{$userData->{COURSE_ID}} && !$permitCerts && !$partialTransfer && !$permitVoidCerts){
		if(!$userData->{THIRD_PARTY_DATA} || $userData->{THIRD_PARTY_DATA} != 1) {
			if ($showError)
			{
				print "User ID:  $uid : Third Party Data need to set 1 \n";
			}
			next;
		}

	}
	if ($westCoastStates)
	{
		if ($westCoastStates eq 'CAOFFICE')
		{
			if ($userData->{COURSE_STATE} && !exists $self->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})
			{
				if ($showError)
				{
					print "User ID:  $uid : $userData->{COURSE_STATE} Not West Coast State \n";
				}
				next;
			}
		}
		else
		{
			if ($userData->{COURSE_STATE} && exists $self->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})
			{
				if ($showError)
				{
					print "User ID:  $uid : $userData->{COURSE_STATE} West Coast State \n";
				}
				next;
			}
		}
	}
	if($self->{PRODUCT} eq 'AARP' && $userData->{COURSE_STATE} && !($userData->{COURSE_STATE} eq 'NY' || $userData->{COURSE_STATE} eq 'CA') && (!$userData->{DELIVERY_ID} || $userData->{DELIVERY_ID} eq '9') && $userData->{NEW_DESIGN_USER})
        {
                if ($showError)
                {
                        print "User id:  $uid - User not selected delivery, need to pay or donwload delivery\n";
                }
                next;
        }

    	if ($self->{PRODUCT} eq 'SS' && $userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'TX' && !$userData->{CITATION}->{SSN})
        {
		push @sellerServerWithoutSSNUsers,$uid;
                if ($showError)
                {
                        print "User id:  $uid - User required SSN\n";
                }
                next;
        }
	if($product eq 'DIP' && !$userData->{SEGMENT_NAME_MAP} && $segment){       
        	if ($showError)                                                    
         	{                                                                 
                 print "User id:  $uid - Non Segment users not allowed\n"; 
        	 }                                                                 
	         next;                                                             
	}                                                                          
	 if($product eq 'DIP' && $userData->{SEGMENT_NAME_MAP} && !$segment){      
        	 if ($showError)                                                   
	         {      	                                                           
        	         print "User id:  $uid - segment users not allowed\n";     
	         }                                                                 
        	 next;                                                             
	}                                                                         

	if($partialTransfer){
        	$userData = $API->getUserData($uid);
		$userData->{PERMITCERTS}=1;
	        $teenUsers{$uid}->{USER_DATA}    = $userData;
        	$teenUsers{$uid}->{COURSE_ID}    = $users->{$key}->{COURSE_ID};
	        $teenUsers{$uid}->{DELIVERY_ID}  = ($users->{$key}->{DELIVERY_ID})?$users->{$key}->{DELIVERY_ID}:1;
        	$teenUsers{$uid}->{SHIPPING_ID}  = $users->{$key}->{SHIPPING_ID};
	        $teenUsers{$uid}->{PARTAILTRANSFER} = 1;
        	$userData->{DELIVERY_ID}=$teenUsers{$uid}->{DELIVERY_ID};
        	$userData->{ISSUE_DATE}=$users->{$uid}->{ISSUE_DATE};
	        $courseId=$teenUsers{$uid}->{COURSE_ID};
	}
	if($permitCerts){
        	$userData = $API->getUserData($uid,$permitCerts);
		$userData->{PERMITCERTS}=1;
	        $teenUsers{$uid}->{USER_DATA}    = $userData;
        	$teenUsers{$uid}->{COURSE_ID}    = $users->{$key}->{COURSE_ID};
	        $teenUsers{$uid}->{DELIVERY_ID}  = ($users->{$key}->{DELIVERY_ID})?$users->{$key}->{DELIVERY_ID}:1;
        	$teenUsers{$uid}->{SHIPPING_ID}  = $users->{$key}->{SHIPPING_ID};
	        $teenUsers{$uid}->{PERMITCERS} = 1;
        	$userData->{DELIVERY_ID}=$teenUsers{$uid}->{DELIVERY_ID};
        	$userData->{SECTION_COMPLETE_DATE}=$users->{$uid}->{SECTION_COMPLETE_DATE};
	        $courseId=$teenUsers{$uid}->{COURSE_ID};
	}
	if($permitVoidCerts){
        	$userData = $API->getUserData($uid);
		$userData->{PERMITCERTS}=1;
	        $teenUsers{$uid}->{USER_DATA}    = $userData;
        	$teenUsers{$uid}->{COURSE_ID}    = $users->{$key}->{COURSE_ID};
	        $teenUsers{$uid}->{DELIVERY_ID}  = ($users->{$key}->{DELIVERY_ID})?$users->{$key}->{DELIVERY_ID}:1;
        	$teenUsers{$uid}->{SHIPPING_ID}  = $users->{$key}->{SHIPPING_ID};
	        $teenUsers{$uid}->{PERMITCERS} = 1;
        	$userData->{DELIVERY_ID}=$teenUsers{$uid}->{DELIVERY_ID};
        	$userData->{VOID_DATE}=$users->{$uid}->{VOID_DATE};
	        $courseId=$teenUsers{$uid}->{COURSE_ID};
	}

        ####### the user is ok to print
        if( exists $self->{TEXASPRINTING}->{$self->{PRODUCT}}->{$courseId} && ! $accompanyLetter && !$runSTC & !$affidavit)
        {
            ######## we're dealing w/ Texas printing right now
            if(!$RUNDUPLICATE)
            {
                                $txUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                                $txUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
                                $txUsers{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
                                $txUsers{$uid}->{USER_DATA}    = $userData;
                        }
            else
            {
                    ######## ok, we're running duplicates
                    my $duId=$key;
                    my $userId = $users->{$duId}->{USER_ID};
                    $dupUsersTX{$duId}->{USERID} =                       $userId;
                    $dupUsersTX{$duId}->{DELIVERY_ID} =                  $userDuplData->{DELIVERY_ID};
                    $dupUsersTX{$duId}->{SHIPPING_ID} =                  $userDuplData->{SHIPPING_ID};
                    $dupUsersTX{$duId}->{COURSE_ID} =                    $userData->{COURSE_ID};
                    $dupUsersTX{$duId}->{DATA} =                         $userDuplData->{DATA};
                    $dupUsersTX{$duId}->{DATA}->{CERTIFICATE_REPLACED} = $userDuplData->{CERTIFICATE_REPLACED};
                    $dupUsersTX{$duId}->{DATA}->{USERID} =               $userDuplData->{CERTIFICATE_REPLACED};
                    $dupUsersTX{$duId}->{USER_DATA} =                    $userData;
            }
        }
        else
        {
            if ($RUNDUPLICATE)
            {
                my $duId=$key;
                my $userId = $users->{$duId}->{USER_ID};
                $dupUsersCA{$duId}->{USERID} =                       $userId;
	        $dupUsersCA{$duId}->{DELIVERY_ID} =                  ($userDuplData->{DATA}->{DELIVERY_ID})?$userDuplData->{DATA}->{DELIVERY_ID}:$userDuplData->{DELIVERY_ID};
  	        $dupUsersCA{$duId}->{SHIPPING_ID} =                  ($userDuplData->{DATA}->{SHIPPING_ID})?$userDuplData->{DATA}->{SHIPPING_ID}:$userDuplData->{SHIPPING_ID};      
  	        $dupUsersCA{$duId}->{COURSE_ID} =                    $userData->{COURSE_ID};      
                $dupUsersCA{$duId}->{DATA} =                         $userDuplData->{DATA};
                $dupUsersCA{$duId}->{DATA}->{CERTIFICATE_REPLACED} = $userDuplData->{CERTIFICATE_REPLACED};
                $dupUsersCA{$duId}->{DATA}->{USERID} =               $userDuplData->{CERTIFICATE_REPLACED};
		$userData->{DELIVERY_ID}	= ($dupUsersCA{$duId}->{DELIVERY_ID})?$dupUsersCA{$duId}->{DELIVERY_ID}:$userData->{DELIVERY_ID};
                $dupUsersCA{$duId}->{USER_DATA} =                    $userData;
            }elsif(($product eq 'FLEET' || $product eq 'AAAFLEET' || $product eq 'FLEET_CA') && $userData->{ACCOUNT_ID}){
		    my $accountId=$userData->{ACCOUNT_ID};
                    $fleetUsers{$accountId}->{$uid}->{USER_DATA}    = $userData;
                    $fleetUsers{$accountId}->{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $fleetUsers{$accountId}->{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
                    $fleetUsers{$accountId}->{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
            }elsif($product eq 'TEEN'){
                    $teenUsers{$uid}->{USER_DATA}    = $userData;
                    $teenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $teenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'AAATEEN'){
                    $aaateenUsers{$uid}->{USER_DATA}    = $userData;
                    $aaateenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $aaateenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'DIPDVD'){
                    $dipDVDUsers{$uid}->{USER_DATA}    = $userData;
                    $dipDVDUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $dipDVDUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'MATURE' || ($userData->{SEGMENT_NAME_MAP} && $userData->{SEGMENT_NAME_MAP} eq 'MATURE' && $segment)){
                    $matureUsers{$uid}->{USER_DATA}    = $userData;
                    $matureUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $matureUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'AAA_SENIORS'){
                    $aaaSeniorUsers{$uid}->{USER_DATA}    = $userData;
                    $aaaSeniorUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $aaaSeniorUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
	    }elsif($product eq 'DSMS' || $product eq 'DSMSBTW') {
		    ##DSMS
                    $dsmsUsers{$uid}->{USER_DATA}    = $userData;
                    $dsmsUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $dsmsUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'ADULT'){
                    $adultUsers{$uid}->{USER_DATA}    = $userData;
                    $adultUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $adultUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'DRIVERSED' && $userData->{COURSE_ID} && (exists $self->{DRIVERSED_COURSES}->{TXADULT}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{NVDIP}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{NMDIP}->{$userData->{COURSE_ID}}  || exists $self->{DRIVERSED_COURSES}->{NJDIP}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{TXDIP}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{OHTEEN}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{TXTEEN}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{TXTEENBTWTRANSFER}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{TXTEENBTWTRANSFER_INSURANCE}->{$userData->{COURSE_ID}}) ){
                    $driversEdUsers{$uid}->{USER_DATA}    = $userData;
                    $driversEdUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $driversEdUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'DRIVERSED' && $userData->{COURSE_ID} && exists $self->{DRIVERSED_COURSES}->{COTEEN}->{$userData->{COURSE_ID}}){
                    $driversEdCOTeenUsers{$uid}->{USER_DATA}    = $userData;
                    $driversEdCOTeenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $driversEdCOTeenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'DRIVERSED' && $userData->{COURSE_ID} && exists $self->{DRIVERSED_COURSES}->{NVTEEN}->{$userData->{COURSE_ID}}){
                    $driversEdNVTeenUsers{$uid}->{USER_DATA}    = $userData;
                    $driversEdNVTeenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $driversEdNVTeenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'DRIVERSED' && $userData->{COURSE_ID} && exists $self->{DRIVERSED_COURSES}->{CATEEN}->{$userData->{COURSE_ID}}){
                    $driversEdCATeenUsers{$uid}->{USER_DATA}    = $userData;
                    $driversEdCATeenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $driversEdCATeenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'DRIVERSED' && $userData->{COURSE_ID} && exists $self->{DRIVERSED_COURSES}->{CAMATURE}->{$userData->{COURSE_ID}}){
                    $driversEdCAMatureUsers{$uid}->{USER_DATA}    = $userData;
                    $driversEdCAMatureUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $driversEdCAMatureUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'DRIVERSED' && $userData->{COURSE_ID} && exists $self->{DRIVERSED_COURSES}->{COMATURE}->{$userData->{COURSE_ID}}){
                    $driversEdCOMatureUsers{$uid}->{USER_DATA}    = $userData;
                    $driversEdCOMatureUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $driversEdCOMatureUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'DRIVERSED' && $userData->{COURSE_ID} && (exists $self->{DRIVERSED_COURSES}->{MNTEEN}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{AZTEEN}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{OKTEEN}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{HSCTEEN}->{$userData->{COURSE_ID}} || exists $self->{DRIVERSED_COURSES}->{VATEEN}->{$userData->{COURSE_ID}})){
                    $driversEdMNTeenUsers{$uid}->{USER_DATA}    = $userData;
                    $driversEdMNTeenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $driversEdMNTeenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'SS'){
                    $ssUsers{$uid}->{USER_DATA}    = $userData;
                    $ssUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $ssUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
	    } elsif($product eq 'AARP' || $product eq 'AARP_CLASSROOM'){
                    $aarpUsers{$uid}->{USER_DATA}    = $userData;
                    $aarpUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $aarpUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif(((!$userData->{STC_USER_ID} || (!$API->isPrintableCourse($userData->{COURSE_ID}) && $product eq 'DIP') ) && $userData->{SEND_TO_REGULATOR} ne 'M') && !$accompanyLetter)
            {
                if (! $runSTC)
                {
                    $caUsers{$uid}->{USER_DATA}    = $userData;
                    $caUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $caUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
                    $caUsers{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
                }
            }
            elsif($userData->{STC_USER_ID} ||
                ($userData->{SEND_TO_REGULATOR} ne 'N' &&
                ($userData->{CERT_PROCESSING_ID} ==0 || $userData->{CERT_PROCESSING_ID}==3 ||
                 $userData->{CERT_PROCESSING_ID}==10 || $userData->{CERT_PROCESSING_ID}==11 ||
                 $userData->{CERT_PROCESSING_ID}==15 || $userData->{CERT_PROCESSING_ID}==12 || $userData->{CERT_PROCESSING_ID}==22)))
            {
                if ($runSTC || $laCountyHardcopy)
                {
                    $caUsers_STC->{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $caUsers_STC->{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
                    $caUsers_STC->{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
                    $caUsers_STC->{$uid}->{USER_DATA}    = $userData;
                }
            }
        }

    
}
print "Users processed.  execution time:  " . int(time - $startTime) . " seconds\n";
$startTime = time;
if(keys %txUsers)
{
        TXPrint(%txUsers);
}
if(keys %caUsers)
{
    CAPrint(\%caUsers,$hostedAffRun);
}
if(keys %$caUsers_STC)
{
    STCPrint($caUsers_STC,$hostedAffRun);
}
if(keys %dupUsersCA)
{
    DuplicatePrint(\%dupUsersCA, $state, $hostedAffRun);
}
if(keys %dupUsersTX)
{
    DuplicatePrint(\%dupUsersTX, 'TX');
}
if(keys %teenUsers)
{
        TeenPrint(\%teenUsers);
}
if(keys %aaateenUsers)
{
        AAATeenPrint(\%aaateenUsers);
}
if(keys %matureUsers)
{
        MaturePrint(\%matureUsers);
}
if(keys %fleetUsers)
{
    FLEETPrint(\%fleetUsers);
}
if(keys %dsmsUsers) {
    DSMSPrint(\%dsmsUsers);
}
if(keys %adultUsers)
{
        AdultPrint(\%adultUsers);
}
if(keys %driversEdUsers)
{
        DriversEdPrint(\%driversEdUsers);
}
if(keys %driversEdCOTeenUsers)
{
        DriversEdPrint(\%driversEdCOTeenUsers);
}
if(keys %driversEdNVTeenUsers)
{
        DriversEdPrint(\%driversEdNVTeenUsers);
}
if(keys %driversEdCATeenUsers)
{
        DriversEdPrint(\%driversEdCATeenUsers);
}
if(keys %driversEdCAMatureUsers)
{
        DriversEdMaturePrint(\%driversEdCAMatureUsers);
}
if(keys %driversEdCOMatureUsers)
{
        DriversEdMaturePrint(\%driversEdCOMatureUsers);
}
if(keys %driversEdMNTeenUsers)
{
        DriversEdPrint(\%driversEdMNTeenUsers);
}
if(keys %dipDVDUsers)
{
    DIPDVDPrint(\%dipDVDUsers);
}
if(keys %ssUsers) {
    SSPrint(\%ssUsers);
}
if(keys %aarpUsers) {
    AARPPrint(\%aarpUsers);
}
if(keys %aaaSeniorUsers)
{
        AAASeniorsPrint(\%aaaSeniorUsers);
}
print "Users Print processed.  execution time:  " . int(time - $startTime) . " seconds\n";
###send mail for date violated users for classroom course
my $violatedusercount = @dateviolationusers;
my $withoutSSNUsers=@sellerServerWithoutSSNUsers;
my @duplicatedluserscount = keys %$duplicatelicenseusers;
my $dipFLUserNotPrinted=@DIPFLUSERIDSNOTPRINTED;
my $teenFLUserNotPrinted=@TEENFLUSERIDSNOTPRINTED;
my $txTeenPrintJobCount=@TXTEENUSERPRINTED;
my $userListSSNotPrinted='';
my $userlist = "The following users have Completion Date Violation\n";
my $userlistFLNotPrintied = "The following FL users have Not Printed\n";
my $userData;
if(!$dryRun){
	if($dipFLUserNotPrinted>0){
		foreach(@DIPFLUSERIDSNOTPRINTED){
			$userlistFLNotPrintied .="$_ : 'DIP\n";
		}
	        Settings::pSendMail('sudheerb@edriving.com,hari@edriving.com,rajesh@edriving.com,sriman@edriving.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Not Printed DIP FL User List",$userlistFLNotPrintied);
	}
        if($txTeenPrintJobCount){
                open ">/tmp/TXTeenJob.xls";
                open (G, ">/tmp/TXTeenJob.xls") || die "unable to open file \n\n";
			print G "First Name\tLastName\tUSER ID\tCertificate Number\tCompletion Date\tIssue Date\n";
                foreach(@TXTEENUSERPRINTED){
                        print G "$_\n";
                }
                close G;
                my $subjectName="TX Teen Print Job (Completion)- ".Settings::getDateTime();
                my $msg = MIME::Lite->new(
                From    =>'I DRIVE SAFELY - Customer Service <reports@idrivesafely.com>',
                To      => 'fulfillment@idrivesafely.com',
                Subject =>"$subjectName",
                Type    =>'multipart/mixed'
);
                my $message = "TX Teen Certificate Completion Data";
                $msg->attach(   Type     => 'TEXT',
                        Data     => $message
                );
                my ($mime_type, $encoding) = ('application/xls', 'base64');
                $msg->attach(
                        Type     => $mime_type ,
                        Encoding => $encoding ,
                        Path     => "/tmp/TXTeenJob.xls",
                        Filename => "TXTeen_".Settings::getDateTime().".xls",
                        Disposition => 'attachment'
                );

                $msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');
                unlink "/tmp/TXTeenJob.xls";

        }
	if($teenFLUserNotPrinted>0){
		foreach(@TEENFLUSERIDSNOTPRINTED){
			$userlistFLNotPrintied .="$_ : 'TEEN\n";
		}
	        Settings::pSendMail('qa@ed-ventures-online.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Not Printed TEEN FL User List",$userlistFLNotPrintied);
	}
	if($violatedusercount>0){
		foreach(@dateviolationusers){
	 	   $userData = $API->getUserData($_);
 		   $userlist .= $_." ".$userData->{FIRST_NAME}." ".$userData->{LAST_NAME}."\n";
 	 	}
	         Settings::pSendMail('supportmanager@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Texas Print Job - $courseId:  User Completion Date Violation",$userlist);
	}
	if($withoutSSNUsers){
		foreach(@sellerServerWithoutSSNUsers){
                        $userListSSNotPrinted .="$_ : 'SS\n";
                }
                Settings::pSendMail('supportmanager@IDriveSafely.com,qa@ed-ventures-online.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Not Printed without SSN Seller Server TX User List",$userListSSNotPrinted);
	}
	if(scalar(@duplicatedluserscount)>0){
		foreach my $instructorId(%$duplicatelicenseusers){
			if(!$instructorId || !$$duplicatelicenseusers{$instructorId}->{INSTRUCTOR_NAME}){
				next;
			}
	                my $message  = "Dear $$duplicatelicenseusers{$instructorId}->{INSTRUCTOR_NAME}\n";
        	        $message .= "The Below mentioned students drivers license are not a valid New York Drivers
License, Please verify and update the drivers license\n\n";
                	$message .= "<table border=0><tr><td>Driver License</td><td>First Name</td><td>Last Name</td><td>Class Date</td></tr>";
			my $managerEmailId;
			$$duplicatelicenseusers{$instructorId}->{STUDENT_ID} = substr($$duplicatelicenseusers{$instructorId}->{STUDENT_ID},0,-1);
			if($$duplicatelicenseusers{$instructorId}->{STUDENT_ID} =~ m/:/){
				my @studentCount = split(':',$$duplicatelicenseusers{$instructorId}->{STUDENT_ID});
				foreach(@studentCount){
					$userData = $API->getUserData($_);
					$managerEmailId = $API->getManagerEmail($userData->{DA_ID});
					$message .= "<tr><td>$userData->{DRIVERS_LICENSE}</td><td>$userData->{FIRST_NAME}</td><td>$userData->{LAST_NAME}</td><td>$userData->{COURSE_COMMENCE_DATE}</td></tr></table>";
					$API->putInvalidDlEmail($_);

				}
			}else{
				$userData = $API->getUserData($$duplicatelicenseusers{$instructorId}->{STUDENT_ID});
				$managerEmailId = $API->getManagerEmail($userData->{DA_ID});
				$message .= "<tr><td>$userData->{DRIVERS_LICENSE}</td><td>$userData->{FIRST_NAME}</td><td>$userData->{LAST_NAME}</td><td>$userData->{COURSE_COMMENCE_DATE}</td></tr></table>";
				$API->putInvalidDlEmail($$duplicatelicenseusers{$instructorId}->{STUDENT_ID});
			}
			my $instructorEmail = $API->getInstructorEmail($instructorId);
			my $msg = MIME::Lite->new(From => 'reports@idrivesafely.com',
	                    To => "$instructorEmail",
        	            Cc => "wendy\@idrivesafely.com,$managerEmailId,qa\@ed-ventures-online.com",
                	    Subject => 'Invalid Newyork Drivers License',
	                    Type => 'TEXT', Data => $message);
			    $msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');
		}

	}
	if($printManifest)
	{
	   Settings::pSendMail('supportmanager@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Print Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", $printManifest);
	}

	if($fedexManifest)
	{
	    Settings::pSendMail(['supportmanager@IDriveSafely.com','sudheerb@edriving.com','rajesh@edriving.com'], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "FedEx Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", $fedexManifest);
	}
	if($driversEdDataUpdate)
	{
	    Settings::pSendMail(['supportmanager@IDriveSafely.com','rajesh@ed-ventures-online.com'], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "DriversEd Data Update Manifest: " . Settings::getDateTime() . " - $SERVER_NAME", $driversEdDataUpdate);
	    #Settings::pSendMail('supportmanager@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "DriversEd Data Update Manifest: " . Settings::getDateTime() . " - $SERVER_NAME", $driversEdDataUpdate);
	}
}
exit;
##################### Define the different script printing types

sub CAPrint
{

    my ($printUsers,$affiliateId)=@_;
    my %delUsers=%$printUsers;
    my $currentCertificate;
    $processCourse = 'CA';
    if($state){
	    $processCourse = $state;
    }
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 11 => 1, 2 => 2, 7 => 3, 1 => 4, 12 => 5);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':'REGULAR';
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':($accompanyLetter)?'ACMPNLTR':'REG';

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
	    elsif (($self->{PRODUCT} eq 'CLASS') && ($$uData{DRIVERS_LICENSE} =~ m/^DUP/))
	    {
		next;	
	
            }
            else
            {
    		my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
		if (($self->{PRODUCT} eq 'DIP' || $self->{PRODUCT} eq 'AAADIP') && $uData->{COURSE_STATE} eq 'OK' && $uData->{REGULATOR_ID} == $self->{OKLAHOMA_CITY_COURT})
		{
			$certModule = "Oklahoma";
		} 
		if ($uData->{UPSELLEMAIL} || $uData->{UPSELLMAIL} || $uData->{UPSELLMAILFEDEXOVA} || $uData->{COURSE_STATE} eq 'CA') {
			$certModule = "CertForStudent";
		}
		if ($certModule ne $lastModule)
		{
			eval("use Certificate::$certModule");
			$certificateArray[$certModule] = ("Certificate::$certModule")->new;
			$lastModule=$certModule;
		}
		my $cert = $certificateArray[$certModule];
                my $certNumber = ($uData->{CERTIFICATE_NUMBER}) ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    print "cert number:  $certNumber\n";
                    ######## we have a valid certificate number
                    ######## The following sequence:  1, 0, 0 define the folling (in order)
                    ######## 1:  print the lower portion of the certificate for the user's records only
                    ######## 2:  print the cert starting from the top (not STCs);
                    ######## 3:  the cert is not an STC
                    my $result = 0;
                    my $printId = 0;
	    	    if (!$API->isPrintableCourse($delUsers{$user}->{COURSE_ID}))
	    	    {
                        ##### the course needs to be printed manually.  For example, NM has to be loaded
                        ##### w/ the indivdual certs
		        $result = $API->MysqlDB::getNextId('contact_id');
                        ###### add the code for the CRM.  It has to be done here
                        my $fixedData=Certificate::_generateFixedData($uData);
                        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');

	    	    }elsif(exists $self->{FAXCOURSE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}} && !$accompanyLetter && $uData->{RESIDENT_STATE} ne 'NONOH')
                    {
                            my $testCenterId = $API->getUserTestCenter($user);
                            my $testCenter = $API->getTestCenter($testCenterId);
                            my $faxNumber=$testCenter->{FAX};
			    $result=$cert->printCertificate($user, $uData, {FAX => $faxNumber},$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
                    }elsif($accompanyLetter || ($delUsers{$user}->{DELIVERY_ID} && $delUsers{$user}->{DELIVERY_ID} == 12) || $uData->{UPSELLEMAIL}){
			my $printCert=$cert;
                            $result=$cert->printCertificate($user, $uData, { EMAIL => $uData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
		    }elsif($self->{PRODUCT} eq 'DIP' &&  $uData->{RESIDENT_STATE} && $uData->{RESIDENT_STATE} eq 'NONOH') {
				##OH Non Resident Users, Send the fax
				my $faxNumber = $self->{OH_NONRESIDENT_FAXNUMBER};
				$result=$cert->printCertificate($user, $uData, {FAX => $faxNumber},$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
		    }
                    else
                    {
                       	    $result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
                    }
                    if($result)
                    {
                        if($accompanyLetter)
                        {
                            $API->putAccompanyLetterUserPrint($user);
                        }
                        else
                        {
				if(!$laCountyHardcopy){
                                	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
					if($self->{PRODUCT} eq 'DIP' &&  $uData->{RESIDENT_STATE} && $uData->{RESIDENT_STATE} eq 'NONOH') {
					        my %ref;
				                $ref{USER_ID} = $user;
			                        $ref{SUPPORT_OPERATOR} = "AUTO FAX";
				                $ref{COMMENTS} = "Faxed student certificate to $self->{OH_NONRESIDENT_FAXNUMBER} Fax Number";
				                $API->putAdminComment(\%ref);
					}
				}
                        }
                        push @processed, $user;
                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                        my $printString = "Printed User:  $user : $certNumber : $name";
                        print $printLog Settings::getDateTime(), "$printString\n";
                        print "$printString\n\n";
                        $printManifest .= "$printString\n\n";
                 if(!(exists $self->{FAXCOURSE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}}  || $accompanyLetter || ($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} ==12))){
			    my $officeId=0;
			    if($uData->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
				    $officeId=1;
        	                    $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
			    }else{
				    $officeId=2;
	                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
			    }
                        }

                        ####### now print out a fedex label if required
			if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
			                $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
    			}

                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
                             $delUsers{$user}->{DELIVERY_ID} == 7 ||
                             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE && !$accompanyLetter)
                        {
			     $fedexManifest .= $API->printFedexLabel($user,1,$affiliateId);
			    
                        }
                        if (($delUsers{$user}->{DELIVERY_ID} == 22 || $delUsers{$user}->{DELIVERY_ID} == 23)  && !$RUNDUPLICATE && !$accompanyLetter)
                        {
			     $fedexManifest .= $API->printUSPSLabel($user,1,$affiliateId);
			    
                        }
			if($delUsers{$user}->{DELIVERY_ID} != 12 && $delUsers{$user}->{DELIVERY_ID} != 15 && $delUsers{$user}->{DELIVERY_ID} != 21 && $delUsers{$user}->{DELIVERY_ID} != 24) {
				$API->dbSendMailMarketo($productId, $user, 'DeliverySent','','','','COURSE_COMPLETE_EMAIL');
			}
                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub TeenPrint
{

    my ($printUsers)=@_;
    my %delUsers=%$printUsers;
    $processCourse = 'CA';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 4 => 1, 3 => 2, 3 => 3, 1 => 4);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':(($state && $state eq 'GA')?'GA-TEEN':'TEEN');
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':'REG';
    $printType=($affidavit)?'AFFIDAVIT':$printType;
    $printType=($permitCerts)?'PERMITCERTS':$printType;
    $printType=($permitVoidCerts)?'VOIDPERMITCERTS':$printType;
    $printType=($partialTransfer)?'PARTIALTRANSFER':$printType;

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
		my $txCerts='';
		if($permitCerts || $partialTransfer || $permitVoidCerts){
			$txCerts=1
		}
                my $certNumber = ($uData->{CERTIFICATE_NUMBER} && $uData->{COURSE_STATE} ne 'TX') ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user,'',$txCerts);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    my $result = 0;
                    my $printId = 0;
		    my $loginDate=$uData->{LOGIN_DATE};
		    $loginDate =~ s/(\-|\ |\:)//g;
          	    print "user id:  $user    Cert Number:  $certNumber   Name $uData->{FIRST_NAME} $uData->{LAST_NAME}\n";
		    if($affidavit){
			my $certModule='TeenAffidavit';
			if ($certModule ne $lastModule)
                        {
                                eval("use Affidavit::$certModule");
                                $certificateArray[$certModule] = ("Affidavit::$certModule")->new;
				$lastModule=$certModule;
                        }

                        my $cert = $certificateArray[$certModule];
			$result = $cert->printAffidavit($user, $uData,{PRINTER => 1},1);
	
		    }
		    elsif($permitCerts || $partialTransfer || $permitVoidCerts){
                        my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
                        eval("use Certificate::$certModule");
                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
                        my $cert = $certificateArray[$certModule];
			if (exists $self->{TEEN32COURSES}->{$delUsers{$user}->{COURSE_ID}}){
				if($permitVoidCerts){
	                        	$result=$cert->_generateNoticeOfCancellation($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId);

				}else{
	                        	$result=$cert->_generate6HRPermitCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId);
				}
			}else{
                        	$result=$cert->printCertificate($user, $uData, { EMAIL => $uData->{EMAIL}},$printId,$printerKey,$accompanyLetter,$productId);
			}
			if($result){
				if($permitCerts){
					$API->putUserPrintPermitCertRecord($user, $certNumber);
				}elsif($permitVoidCerts){
					$API->putUserVoidPermitCerts($user);
				}else{
					$API->putUserPrintPartialRecord($user, $certNumber);
				}
				if (exists $self->{TEEN32COURSES}->{$delUsers{$user}->{COURSE_ID}}){

                                        my $settings = Settings->new;
					my $thirdPartyCerts=0;
                                        my $officeId=0;
                                        if($uData->{COURSE_STATE} && exists $settings->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
                                            $officeId=1;
                                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                       $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId,$thirdPartyCerts);
                                        }else{
                                            $officeId=2;
                                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                       $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId,$thirdPartyCerts);
                                        }
                                }
		    }
               }
	       elsif ($API->isPrintableCourse($uData->{COURSE_ID}) || ($uData->{COURSE_STATE} && $uData->{COURSE_STATE} eq 'TX' && $loginDate<20121001000000 && !$permitCerts && !$partialTransfer))
        	    {
	                my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
			if($uData->{COURSE_STATE} eq 'TX' && $loginDate<20121001000000 && !$permitCerts && !$partialTransfer && !$permitVoidCerts){
	                	$certModule = 'Teen';
			}
        	        if ($certModule ne $lastModule)
                	{
                        	eval("use Certificate::$certModule");
	                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
        	        }

                	my $cert = $certificateArray[$certModule];
                       	$result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId);
			if(exists $self->{TEEN_COLORADO_COURSES}->{$delUsers{$user}->{COURSE_ID}} && $delUsers{$user}->{DELIVERY_ID} && ($delUsers{$user}->{DELIVERY_ID} == 1 || $delUsers{$user}->{DELIVERY_ID} == 18) ){
                        	use Certificate::COTeen;
	                        my $cert=Certificate::COTeen->new;
				$cert->printCOTeenLabel($user,$uData);
			}
            	    }else{
			if(exists $self->{TEEN_COLORADO_COURSES}->{$delUsers{$user}->{COURSE_ID}} && $delUsers{$user}->{DELIVERY_ID} && ($delUsers{$user}->{DELIVERY_ID} == 1 || $delUsers{$user}->{DELIVERY_ID} == 18) ){
                        	use Certificate::COTeen;
	                        my $cert=Certificate::COTeen->new;
				$cert->printCOTeenLabel($user,$uData);
			}
			### If TLSAE user update the Cert nyumber and Print Date and Act on POC ###
		       	if ($self->{FLTEENTLSAECOURSE}->{$delUsers{$user}->{COURSE_ID}})
		       	{
				#### Check if user took any of Proof Of Compeltions ## 
                        	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
	                        push @processed, $user;
        	                my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        	####### log all of this in the print log 
                	        my $printString = "Processed FL TLSAE User:  $user : $certNumber : $name";
                        	print $printLog Settings::getDateTime(), "$printString\n";
	                        print "$printString\n\n";
                    		my $pocResult = 0;
				if (defined $uData->{UPSELLDOWNLOAD} && $uData->{UPSELLDOWNLOAD})
				{
                    			$result = 1;
				}
				if (defined $uData->{UPSELLEMAIL} && $uData->{UPSELLEMAIL})
				{
                        		use Certificate::TeenCertForStudent;
	                        	my $cert=Certificate::TeenCertForStudent->new;
                       			$result=$cert->printCertificate($user, $uData, { EMAIL => $uData->{EMAIL}}, $printId, $printerKey, $accompanyLetter, $productId);
				}
				if ((defined $uData->{UPSELLMAIL} && $uData->{UPSELLMAIL}) || $uData->{UPSELLMAILFEDEXOVA})
				{
                        		use Certificate::TeenCertForStudent;
	                        	my $cert=Certificate::TeenCertForStudent->new;
                       			$result=$cert->printCertificate($user, $uData, { PRINTER => 1}, $printId, $printerKey, $accompanyLetter, $productId);
				}
				if ($result)
				{
		         		$API->putCookie($user, {'UPSELLCERTSENT'=>'YES', 'UPSELL_PROCESSED'=>'CRON'});
				}
			} 	
			else
			{
	               	##### the course needs to be printed manually.  For example, CA has to be loaded
	                ##### w/ the indivdual certs
                		$result = $API->MysqlDB::getNextId('contact_id');

	                ###### add the code for the CRM.  It has to be done here
				my $fixedData=Certificate::_generateFixedData($uData);
    				$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
				if(exists $self->{RGLPRINTLABELCOURSE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}} && $delUsers{$user}->{DELIVERY_ID} && $delUsers{$user}->{DELIVERY_ID} == 1 ){
                        		use Certificate::CATeen;
	                        	my $cert=Certificate::CATeen->new;
					$cert->printCATeenLabel($user,$uData);
				}
			}
            	    }
                    if($result && (!$self->{FLTEENTLSAECOURSE}->{$delUsers{$user}->{COURSE_ID}} || $uData->{UPSELLMAILFEDEXOVA}))
                    {
			if(!$affidavit && !$permitCerts && !$partialTransfer && !$permitVoidCerts){
                        	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
	                        push @processed, $user;
        	                my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";
				if($uData->{COURSE_STATE} && $uData->{COURSE_STATE} eq 'TX'){
                                	my $certReportData="$uData->{FIRST_NAME}\t$uData->{LAST_NAME}\t$user\t$certNumber\t$uData->{COMPLETION_DATE}\t".Settings::getDateFormat()."\n";
	                                push @TXTEENUSERPRINTED, $certReportData;
				}


                        ####### log all of this in the print log, print manifest and STDERR
                	        my $printString = "Printed User:  $user : $certNumber : $name";
                        	print $printLog Settings::getDateTime(), "$printString\n";
	                        print "$printString\n\n";
        	                $printManifest .= "$printString\n\n";
	        	         if(!($uData->{DELIVERY_ID} ==12)){
					my $thirdPartyCerts=0;
				     	if(exists $self->{THIRDPARTYCERTIFICATE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}}){
						$thirdPartyCerts=1;
					}
					my $settings = Settings->new;
					my $officeId=0;
			    		if($uData->{COURSE_STATE} && exists $settings->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
					    $officeId=1;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId,$thirdPartyCerts);
					}else{
					    $officeId=2;
					    if($uData->{COURSE_STATE} && $uData->{COURSE_STATE} eq 'CO'){
							$officeId=2;
					    }
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId,$thirdPartyCerts);
					}
                         	}

	                        ####### now print out a fedex label if required
        	                if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                	                        $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        	}
	                       	if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
	        	             $delUsers{$user}->{DELIVERY_ID} == 7 ||
        	                     $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE)
                	       	{
				     if(!exists $self->{THIRDPARTYCERTIFICATE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}}){
					     $fedexManifest .= $API->printFedexLabel($user,1,'');
				     }
				    
                	        }

				if($delUsers{$user}->{DELIVERY_ID} != 12 && $delUsers{$user}->{DELIVERY_ID} != 15 && $delUsers{$user}->{DELIVERY_ID} != 21 && $delUsers{$user}->{DELIVERY_ID} != 24) {
					$API->dbSendMailMarketo($productId, $user, 'DeliverySent','','','','COURSE_COMPLETE_EMAIL');
				}
			}elsif($affidavit){
			         my $WST = time();
			         $API->putCookie($user, {'CO_AFFIDAVIT_PRINTED'=>$WST});
                                 $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                   $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);
			}
                    }
                    else
                    {
                    	if(!$self->{FLTEENTLSAECOURSE}->{$delUsers{$user}->{COURSE_ID}})
			{
                        	print "$user:  Invalid certificate returned - Not Printed\n";
			}
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub AAATeenPrint
{

    my ($printUsers)=@_;
    my %delUsers=%$printUsers;
    $processCourse = 'CA';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 4 => 1, 3 => 2, 3 => 3, 1 => 4);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':(($state && $state eq 'GA')?'GA-AAATEEN':'AAATEEN');
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':'REG';
    $printType=($affidavit)?'AFFIDAVIT':$printType;
    $printType=($permitCerts)?'PERMITCERTS':$printType;

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
                my $certNumber = ($uData->{CERTIFICATE_NUMBER} && $uData->{COURSE_STATE} ne 'TX') ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user,'',$permitCerts);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    my $result = 0;
                    my $printId = 0;
		    my $loginDate=$uData->{LOGIN_DATE};
		    $loginDate =~ s/(\-|\ |\:)//g;
          	    print "user id:  $user    Cert Number:  $certNumber   Name $uData->{FIRST_NAME} $uData->{LAST_NAME}\n";
			### If TLSAE user update the Cert nyumber and Print Date and Act on POC ###
	               	##### the course needs to be printed manually.  For example, CA has to be loaded
	                ##### w/ the indivdual certs
	            if(!$API->isPrintableCourse($uData->{COURSE_ID}))
                    {

                		$result = $API->MysqlDB::getNextId('contact_id');

	                ###### add the code for the CRM.  It has to be done here
				my $fixedData=Certificate::_generateFixedData($uData);
    				$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
		    }else{
                                use Certificate::AAATeen;
                                my $cert=Certificate::AAATeen->new;
                                $result=$cert->printCertificate($user, $uData, { PRINTER => 1}, $printId, $printerKey, $accompanyLetter, $productId);
		    }
			
            	    
                    if($result)
                    {
			if(!$affidavit && !$permitCerts){
                        	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
	                        push @processed, $user;
        	                my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";
				if($uData->{COURSE_STATE} && $uData->{COURSE_STATE} eq 'TX'){
                                	my $certReportData="$uData->{FIRST_NAME}\t$uData->{LAST_NAME}\t$user\t$certNumber\t$uData->{COMPLETION_DATE}\t".Settings::getDateFormat()."\n";
	                                push @TXTEENUSERPRINTED, $certReportData;
				}


                        ####### log all of this in the print log, print manifest and STDERR
                	        my $printString = "Printed User:  $user : $certNumber : $name";
                        	print $printLog Settings::getDateTime(), "$printString\n";
	                        print "$printString\n\n";
        	                $printManifest .= "$printString\n\n";
	        	         if(!($uData->{DELIVERY_ID} ==12)){
					my $thirdPartyCerts=0;
				     	if(exists $self->{THIRDPARTYCERTIFICATE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}}){
						$thirdPartyCerts=1;
					}
					my $settings = Settings->new;
					my $officeId=0;
			    		if($uData->{COURSE_STATE} && exists $settings->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
					    $officeId=1;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId,$thirdPartyCerts);
					}else{
					    $officeId=2;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId,$thirdPartyCerts);
					}
                         	}

	                        ####### now print out a fedex label if required
        	                if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                	                        $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        	}
	                       	if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
	        	             $delUsers{$user}->{DELIVERY_ID} == 7 ||
        	                     $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE)
                	       	{
				     if(!exists $self->{THIRDPARTYCERTIFICATE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}}){
					     $fedexManifest .= $API->printFedexLabel($user,1,'');
				     }
				    
                	        }
			}elsif($affidavit){
			         my $WST = time();
			         $API->putCookie($user, {'CO_AFFIDAVIT_PRINTED'=>$WST});
                                 $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                   $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);
			}
                    }
                    else
                    {
                    	if(!$self->{FLTEENTLSAECOURSE}->{$delUsers{$user}->{COURSE_ID}})
			{
                        	print "$user:  Invalid certificate returned - Not Printed\n";
			}
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub TXPrint
{
    my %delUsers=@_;
    $processCourse = '1003';
    $processOnCourse = '1001';
    my $CERTSPRINTED = 0;
    my $CERTSTOPRINT = 1000;
    if ($opts{c})
    {
        if (exists $self->{TEXASPRINTING}->{$self->{PRODUCT}}->{$opts{c}})
        {
            $processCourse = $opts{c};
        }
        else
        {
            print "course id $opts{c} cannot print from this process\nexiting...\n";
            exit;
        }

        if (exists  $self->{OCPSCOURSE}->{$self->{PRODUCT}}->{$processCourse})
        {
            $processOnCourse = 1005;
        }
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }

	############### Get a lock file for this particular course
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
	##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    my %sort = ( 4 => 1, 3 => 2, 2 => 3, 1 => 4, 12 => 5);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType = "TX - $processCourse";
    my $certificateCategory='REG';

    print STDERR "num of users to process: " . @keys . " \n";


    if(@keys)
	{
        my $certsRemaining = $API->getCertificateCount($processOnCourse);

        if($CERT_THRESHOLD > $certsRemaining)
        {
            print "cert threshold coming close\n";
            Settings::pSendMail('support@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Texas Print Job - $processCourse:  Daily Process Error on $SERVER_NAME", "Less than $CERT_THRESHOLD certificates remaining for $processCourse...\n");
        }

        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_1003" or print STDERR "PRINT LOG ERROR: $!\n";;
        print $printLog "Job started at " . Settings::getDateTime() . "\n";

        my $priority = 1;
        for my $user(@keys)
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
                my $deliveryId = ($delUsers{$user}->{DELIVERY_ID}) ? $delUsers{$user}->{DELIVERY_ID} : 1;
                print "User ID:  $user   Delivery ID:  $deliveryId\n";
            }
            else
            {
                $certsRemaining = $API->getCertificateCount($processOnCourse);
                if($certsRemaining < 3)
                {
                    $API->MysqlDB::dbInsertAlerts(5);
                    Settings::pSendMail(['supportmanager@IDriveSafely.com'], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Texas Print Job - $processCourse:  Daily Process Error on $SERVER_NAME", "Less than $CERT_THRESHOLD certificates remaining for $processCourse...\n");
                    last;
                }
                else
                {
                        my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
                        if ($certModule ne $lastModule)
                        {
                                eval("use Certificate::$certModule");
                                $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
                        }

                        my $cert = $certificateArray[$certModule];

                    $priority++;

                     my $certNumber = $API->getNextCertificateNumber($user);
		     $uData->{CERTIFICATE_NUMBER}=$certNumber;
                     if ($certNumber)
                     {
                        ###### run the course on the appropriate certificate
                        my $result = 0;
			my $printId = 0;
			$result=$cert->printCertificate($user, $uData, { PRINTER => 1  },$printId,$printerKey,0,$productId);

                        if($result)
                        {
			    $API->putUserPrintRecord($user, $certNumber, 'PRINT');
                        }
                        push @processed, $user;
                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                        my $printString = "Printed User:  $user : $certNumber : $name";
                        print $printLog Settings::getDateTime(), "$printString\n";
                        print "$printString\n\n";
                        $printManifest .= "$printString\n\n";
			my $officeId=0;
	    		if($uData->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
			    $officeId=1;
                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $printMode,
                                                $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
			}else{
			    $officeId=2;
                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $printMode,
                                                $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
			}


                            sleep 3;
                        }
                        else
                        {
                            ### put cert number back
                        }
                        $CERTSPRINTED++;
                    }
                    if($CERTSPRINTED > $CERTSTOPRINT)
                    {
                        print "\nMaximum Certificate Printing Threshold Reached:  $CERTSPRINTED\nExiting....";
                        close $printLog;
                                    Accessory::pReleaseLock($processCourse, $lockFile);
                        exit;
                    }
    if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
		$delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
    }
                
    if($delUsers{$user}->{DELIVERY_ID} == 2 ||
                    $delUsers{$user}->{DELIVERY_ID} == 7 ||
                    $delUsers{$user}->{DELIVERY_ID} == 11)
                {
		     $fedexManifest .= $API->printFedexLabel($user,1,'TX');
                }
                if (($delUsers{$user}->{DELIVERY_ID} == 22 || $delUsers{$user}->{DELIVERY_ID} == 23)  && !$RUNDUPLICATE && !$accompanyLetter)
                {
	                 $fedexManifest .= $API->printUSPSLabel($user,1);
                }
		if($delUsers{$user}->{DELIVERY_ID} != 12 && $delUsers{$user}->{DELIVERY_ID} != 15 && $delUsers{$user}->{DELIVERY_ID} != 21 && $delUsers{$user}->{DELIVERY_ID} != 24) {
			$API->dbSendMailMarketo($productId, $user, 'DeliverySent','','','','COURSE_COMPLETE_EMAIL');
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub DuplicatePrint
{
    my ($dupUsers, $state, $affiliateId) = @_;
    $processCourse = 'DUPLICATES';
    if ($state eq 'TX')
    {
        $processCourse .= 'TX_' . $processCourse;
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {   
    ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit(); 
    } 
    my @keys = keys %$dupUsers;
    my $printType = "DUPLICATE";
    if($returnMailJobs){
    	$printType = "$state - Returned Mail";
    }
    my $certificateCategory='DUPL';

    print STDERR "num of users to process: " . @keys . " \n";
    if (@keys)
    {
        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_dups" or print STDERR "PRINT LOG ERROR: $!\n";
        print $printLog "Job started at " . Settings::getDateTime() . "\n";
        my $excelFile;
        my $worksheet;
        my $titleFormat;
        my $boldFormat;
        my $leftFont;
        my $boldFont;
	my $row=0;

        foreach my $dupId ( @keys )
        {
            my $userId = $dupUsers->{$dupId}->{USERID};
            my $uData  = $dupUsers->{$dupId}->{USER_DATA};
            if ($limitedRun && ! $runCounter)
            {
                ###### we're doing a limited run and that number has been reached.  Leave this loop
                last;
            }

            if ($dryRun)
            {
                ####### simply output the user and his delivery option.  No changes will be made to the database
                print "Processing User ID:  $userId - DuplicateId:  $dupId  Course ID:  $uData->{COURSE_ID}\n";
            }
            else
            {
                my $certModule = $self->getCertificateModule($self->{PRODUCT},$dupUsers->{$dupId}->{COURSE_ID},$uData->{SEGMENT_NAME_MAP});

                if ($certModule ne $lastModule)
                {
                        eval("use Certificate::$certModule");
                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
			$lastModule=$certModule;
                }

                my $cert = $certificateArray[$certModule];
		my $dup=0;
		if($product eq 'TEEN' && !$permitCerts && $uData->{COURSE_STATE} eq 'TX'){
			$dup=1;
		}
		my $certNumber=0;
		if($returnMailJobs){
			$certNumber=$uData->{DATA}->{CERTIFICATE_NUMBER};
		}else{
                	$certNumber = $API->getNextCertificateNumber($dupUsers->{$dupId}->{USERID},$dup);
		}
                if ($certNumber)
                {
		    $uData->{CERTIFICATE_NUMBER}=$certNumber;
                    my $result = 0;
		    my $printId=0;
		  
	    	    if (!$API->isPrintableCourse($uData->{COURSE_ID}))
	    	    {
                        ##### the course needs to be printed manually.  For example, NM has to be loaded
                        ##### w/ the indivdual certs
		        $result = $API->MysqlDB::getNextId('contact_id');
                        ###### add the code for the CRM.  It has to be done here
                        my $fixedData=Certificate::_generateFixedData($uData);
                        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
		    }elsif($API->isXLSPrintableCourse($uData->{COURSE_ID}) && $product eq 'SS' && !$returnMailJobs) {
			if(!$xlsFileName){
				my $currTime=time();
				$xlsFileName="/tmp/userslist_$currTime.xls";
				$excelFile = Spreadsheet::WriteExcel->new($xlsFileName);
				$worksheet = $excelFile->add_worksheet();
				## set the title format
				$titleFormat = $excelFile->add_format();
				$titleFormat->set_bold();
				$titleFormat->set_center_across();
				$titleFormat->set_bg_color('silver');

				$boldFormat = $excelFile->add_format();
				$boldFormat->set_bold();
				$boldFormat->set_center_across();

				## set the right align,left align and red color font
				my $leftFont   = $excelFile->add_format( font => 'Arial', size => 10, align => 'left');

				##set the column size
				$boldFont = $excelFile->add_format( font => 'Arial', size => 11);
				$worksheet->set_column('A1:A1',20);
				$worksheet->set_column('B1:B1',25);
				$worksheet->set_column('C1:C1',20);
				$worksheet->set_column('D1:D1',25);
				$worksheet->set_column('E1:E1',25);
				$worksheet->set_column('F1:F1',25);
				$worksheet->set_column('G1:G1',25);
				## write the headers
				$worksheet->write($row,0,'User ID',$titleFormat);
				$worksheet->write($row,1,'First Name',$titleFormat);
				$worksheet->write($row,2,'Photo',$titleFormat);
				$worksheet->write($row,3,'date issued',$titleFormat);
				$worksheet->write($row,4,'Date Issued',$titleFormat);
				$worksheet->write($row,5,'Expiration Date',$titleFormat);
				$worksheet->write($row,6,'Last Name',$titleFormat);

				## Get the registered users data for the previous month
			}
			$row++;
			#push @userIdArray,$userId;
			$uData->{EXPIRATION_DATE}=($uData->{EXPIRATION_DATE_4YEAR})?$uData->{EXPIRATION_DATE_4YEAR}:$uData->{EXPIRATION_DATE2_4YEAR};
			$worksheet->write($row,0,$userId,$leftFont);
			$worksheet->write($row,1,$uData->{FIRST_NAME},$leftFont);
			$worksheet->write($row,2,' ',$leftFont);
			$worksheet->write($row,3,' ',$leftFont);
			$worksheet->write($row,4,'Date Issued:     '.  $uData->{COMPLETION_DATE},$leftFont);
			$worksheet->write($row,5,'Expiration Date: '.  $uData->{EXPIRATION_DATE},$leftFont);
			$worksheet->write($row,6,$uData->{LAST_NAME},$leftFont);
                        $result = $API->MysqlDB::getNextId('contact_id');
                        ###### add the code for the CRM.  It has to be done here
                        my $fixedData=Certificate::_generateFixedData($uData);
                        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
		    }else{
			my $settings1 = Settings->new;
		        if(exists $settings1->{NOPRINTFORRETURNMAIL}->{$product}->{$uData->{COURSE_ID}} && $returnMailJobs){
                        	$result = $API->MysqlDB::getNextId('contact_id');
                        	my $fixedData=Certificate::_generateFixedData($uData);
	                        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');

            		}else{
		    		if($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} == 12 && $product && ($product eq 'DIP' || $product eq 'TAKEHOME' || $product eq 'AAADIP' || $product eq 'ADULT')){
                        		$result=$cert->printCertificate($userId, $uData, { EMAIL => $uData->{EMAIL} },$printId,$printerKey,0,$productId,$dupUsers->{$dupId}->{DATA},$hostedAffRun);
			    	}elsif($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} == 2 && $product && $product eq 'AARP'){
        	                	$result=$cert->printCertificate($userId, $uData, { EMAIL => $uData->{EMAIL} },$printId,$printerKey,0,$productId,$dupUsers->{$dupId}->{DATA},$hostedAffRun);
				}elsif($uData->{DELIVERY_ID} && ($uData->{DELIVERY_ID} == 12 || $uData->{DELIVERY_ID} == 23) && $product && $product eq 'SS'){
                                	$result=$cert->printCertificate($userId, $uData, { EMAIL => $uData->{EMAIL} },$printId,$printerKey,0,$productId,$dupUsers->{$dupId}->{DATA},$hostedAffRun);
				}else{
		        	    	$result=$cert->printCertificate($userId, $uData, { PRINTER => 1 },$printId,$printerKey,0,$productId,$dupUsers->{$dupId}->{DATA},$hostedAffRun);
		    		}
			 }
		    }
                    if($result)
                    {
		        $API->putUserPrintRecord($userId, $certNumber, "DUPLICATE", $dupId);
			if($dupUsers->{$dupId}->{DATA}->{RETURN_MAIL_DATA}){
				$API->MysqlDB::dbUpdateReturnMailStatus($dupUsers->{$dupId}->{DATA}->{RETURN_MAIL_DATA});
			}
                        push @processed, $userId;
                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                        my $printString = "Printed User:  $userId : $certNumber : $name";
                        print $printLog Settings::getDateTime(), "$printString\n";
                        print "$printString\n\n";
                        $printManifest .= "$printString\n\n";
                        ####### add this to the CRM manifest
                        my $officeId=0;
		    	if(!(($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} == 12 && $product && ($product eq 'DIP' || $product eq 'TAKEHOME' || $product eq 'AAADIP')) || ($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} == 12 && $product && $product eq 'AARP') || ($uData->{DELIVERY_ID} && ($uData->{DELIVERY_ID} == 12 || $uData->{DELIVERY_ID} == 23) && $product && $product eq 'SS') )){
		    		if($uData->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
					$officeId=1;
                	        	$API->MysqlDB::dbInsertPrintManifest($result,$printType, $printMode,
                                                $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $userId, $certificateCategory,$officeId);
				}else{
					$officeId=2;
					 if($product eq 'TEEN' && $uData->{COURSE_STATE} eq "CO"){
 					 $officeId=2;
					  }
	                        	$API->MysqlDB::dbInsertPrintManifest($result,$printType, $printMode,
        	                                $jobPrintDate, $productId, $manifestIdTexasOffice, $userId, $certificateCategory,$officeId);
				}
			}
                        sleep 3;
	 		    if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$dupUsers->{$dupId}->{DELIVERY_ID}}){
		                $dupUsers->{$dupId}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$dupUsers->{$dupId}->{DELIVERY_ID}};
    			    }
                         if($dupUsers->{$dupId}->{DELIVERY_ID} == 2 ||
  	                                     $dupUsers->{$dupId}->{DELIVERY_ID} == 7 ||
  	                                             $dupUsers->{$dupId}->{DELIVERY_ID} == 11)
  	                         {
  	                                my $shippingId = $dupUsers->{$dupId}->{SHIPPING_ID};
					my $reply=$API->pDuplicateFedexLabelPrint($shippingId,$printerKey,$uData);
					for(keys %$reply) {
			        	        if($_ eq 'TRACKINGNUMBER') {
                        				$fedexManifest .= "\t$_ : $$reply{$_}\n";
				                } else {
        	                			$fedexManifest .= "--------------------------------------------------------------------------\n";
			                        	$fedexManifest .= "\t$_ : $$reply{$_}\n";
                				}
        				}

  	                         }elsif($dupUsers->{$dupId}->{DELIVERY_ID} == 1){
					if($product && $product eq 'AARP'){
						my $settings1 = Settings->new;
					        if(exists $settings1->{NOPRINTFORRETURNMAIL}->{$product}->{$uData->{COURSE_ID}} && $returnMailJobs){
        	                        		use Certificate::AARPCA;
			                                my $labelCert=Certificate::AARPCA->new;
                			                $labelCert->printCAAARPLabel($userId,$uData);
						}

					}else{
						my $settings1 = Settings->new;
					        if(exists $settings1->{NOPRINTFORRETURNMAIL}->{$product}->{$uData->{COURSE_ID}} && $returnMailJobs){
        	                        		use Certificate::California;
			                                my $labelCert=Certificate::California->new;
                			                $labelCert->printRegularLabel($userId,$uData);
						}
					}
				}

				if($dupUsers->{$dupId}->{DELIVERY_ID} != 12 && $dupUsers->{$dupId}->{DELIVERY_ID} != 15 && $dupUsers->{$dupId}->{DELIVERY_ID} != 21 && $dupUsers->{$dupId}->{DELIVERY_ID} != 24) {
					$API->dbSendMailMarketo($productId, $userId, 'DeliverySent','','','','COURSE_COMPLETE_EMAIL','',$dupUsers->{$dupId}->{SHIPPING_ID});
				}

			}elsif($dupUsers->{$dupId}->{DELIVERY_ID} && ($dupUsers->{$dupId}->{DELIVERY_ID} ==1 || $dupUsers->{$dupId}->{DELIVERY_ID} == 16 )&& $xlsFileName && $API->isXLSPrintableCourse($dupUsers->{$dupId}->{COURSE_ID}) && $product eq 'SS'){
                                use Certificate::SellerServerTABC;
                                my $labelCert=Certificate::SellerServerTABC->new;
                                $labelCert->printRegularLabel($userId,$uData);
                        }
                }
                else
                {
                    $printManifest .=  $userId . ":  Invalid certificate number - Not Printed\n";
                }

                ++$certsPrinted;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
                    exit;
                }
            }

            if ($limitedRun)
            {
                ###### decrement the run counter
                --$runCounter;
            }
        }
        if($xlsFileName && $product eq 'SS'){
                $excelFile->close();
                ##send an email
                my $msg = MIME::Lite->new(
                From    =>'I DRIVE SAFELY - Customer Service <reports@idrivesafely.com>',
                To      => 'rebecca@idrivesafely.com, kami.mason@idrivesafely.com, chanda.chambliss@idrivesafely.com, Haidee.Hodge@iDriveSafely.com, Christie.Myrick@iDriveSafely.com',
                Subject =>"Seller Server NV Re-Print Certificate Data",
                Type    =>'multipart/mixed'
);
                my $message = "Seller Server NV Re-Print Certificate Data";
                $msg->attach(   Type     => 'TEXT',
                        Data     => $message
                );
                my ($mime_type, $encoding) = ('application/xls', 'base64');
                $msg->attach(
                        Type     => $mime_type ,
                        Encoding => $encoding ,
                        Path     => $xlsFileName,
                        Filename => "NVCertificateData_".Settings::getDateTime().".xls",
                        Disposition => 'attachment'
                );

		$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');
                unlink $xlsFileName;

        }
        close $printLog;
    }
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub MaturePrint
{
    my ($printUsers)=@_;
    my %delUsers=%$printUsers;
    my $pId=$productId;
    $processCourse = 'CA';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 4 => 1, 3 => 2, 3 => 3, 1 => 4);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':'MATURE';
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':'REG';
    $printType=($affidavit)?'AFFIDAVIT':$printType;

    print STDERR "num of users ready to process " . @keys . " \n";
    if(@keys)
    {
        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_ca" or print STDERR "PRINT LOG ERROR: $!\n";;
        print $printLog "Job started at " . Settings::getDateTime() . "\n";

        foreach my $user(@keys)
        {
	    my $segmentName='';
            my $uData=$delUsers{$user}->{USER_DATA};
	    if($uData->{SEGMENT_ID_MAP}){
		$pId=$uData->{SEGMENT_ID_MAP};
		$segmentName=$uData->{SEGMENT_NAME_MAP};
	    }else{
		$pId=$productId;
	    }
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
                my $certNumber = ($uData->{CERTIFICATE_NUMBER}) ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    my $result = 0;
                    my $printId = 0;
          	    print "user id:  $user    Cert Number:  $certNumber   Name $uData->{FIRST_NAME} $uData->{LAST_NAME}\n";
	            if ($API->isPrintableCourse($uData->{COURSE_ID}))
        	    {
	                my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID},$uData->{SEGMENT_NAME_MAP});
        	        if ($certModule ne $lastModule)
                	{
                        	eval("use Certificate::$certModule");
	                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
        	        }

                	my $cert = $certificateArray[$certModule];
                       	$result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$pId);
            	    }else{
	               ##### the course needs to be printed manually.  For example, CA has to be loaded
	                ##### w/ the indivdual certs
                	$result = $API->MysqlDB::getNextId('contact_id');

	                ###### add the code for the CRM.  It has to be done here
			my $fixedData=Certificate::_generateFixedData($uData);
    			$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
			
            	    }

                    if($result)
                    {
			if(!$affidavit){
                        	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
	                        push @processed, $user;
        	                my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

			 ####### log all of this in the print log, print manifest and STDERR
                	        my $printString = "Printed User:  $user : $certNumber : $name";
                        	print $printLog Settings::getDateTime(), "$printString\n";
	                        print "$printString\n\n";
        	                $printManifest .= "$printString\n\n";
	        	         if(!($uData->{DELIVERY_ID} ==12)){
					my $settings = Settings->new;
					my $officeId=0;  ##### This is for California;
	    				if($uData->{COURSE_STATE} && exists $settings->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
					    $officeId=1;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
					}else{
					    $officeId=2;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
					}
                         	}

	                        ####### now print out a fedex label if required
        	                if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                	                        $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        	}

	                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
        	                     $delUsers{$user}->{DELIVERY_ID} == 7 ||
                	             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE)
                        	{
				     $fedexManifest .= $API->printFedexLabel($user,1,'','','','',$segmentName);
				    
                	        }
				if($delUsers{$user}->{DELIVERY_ID} != 12 && $delUsers{$user}->{DELIVERY_ID} != 15 && $delUsers{$user}->{DELIVERY_ID} != 21 && $delUsers{$user}->{DELIVERY_ID} != 24) {
					$API->dbSendMailMarketo($productId, $user, 'DeliverySent','','','','COURSE_COMPLETE_EMAIL');
				}
			}else{
			         my $WST = time();
			         $API->putCookie($user, {'CO_AFFIDAVIT_PRINTED'=>$WST});
                                 $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                   $jobPrintDate, $pId, $manifestId, $user, $certificateCategory);
			}
                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}
sub FLEETPrint
{

    my ($printUsers)=@_;
    my %fleetDelUsers=%$printUsers;
    my $currentCertificate;
    $processCourse = 'FC';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestId  =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 11 => 1, 2 => 2, 7 => 3, 1 => 4, 12 => 5);
    my @keys = sort keys %fleetDelUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':'REGULAR';
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':($accompanyLetter)?'ACMPNLTR':'REG';

    print STDERR "num of users ready to process " . @keys . " \n";
    if(@keys)
    {
        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_ca" or print STDERR "PRINT LOG ERROR: $!\n";;
        print $printLog "Job started at " . Settings::getDateTime() . "\n";
	foreach my $accountId(@keys){
	  my $noOfCert=0;
	  my $delUsers=$fleetDelUsers{$accountId};
	  my $accountData=$API->getAccountData($accountId);
          foreach my $user(keys %$delUsers)
          {
            my $uData=$$delUsers{$user}->{USER_DATA};
            if ($limitedRun && ! $runCounter)
            {
                ###### we're doing a limited run and that number has been reached.  Leave this loop
                last;
            }
            if ($dryRun)
            {
                ####### simply output the user and his delivery option.  No changes will be made to the database
                $deliveryId = ($$delUsers{$user}->{DELIVERY_ID}) ? $$delUsers{$user}->{DELIVERY_ID} : 1;
                $courseId   = $$delUsers{$user}->{COURSE_ID};
                print "User ID:  $user  Course:  $courseId   Delivery ID:  $deliveryId\n";
            }
	    elsif (!$API->isPrintableCourse($$delUsers{$user}->{COURSE_ID}))
	    {
                $courseId   = $$delUsers{$user}->{COURSE_ID};
                print "User ID:  $user  Course:  $courseId   Delivery ID:  $deliveryId : Not Printable Course\n";
		next;	
	    }
            else
	    {
            	my $accountDataByUser=$API->getAccountDataByUserId($user,$accountData->{ACCOUNT_ID});
		$accountData->{DELIVERY_ID}=($accountDataByUser->{DELIVERY_ID})?$accountDataByUser->{DELIVERY_ID}:$accountData->{DELIVERY_ID};
		$accountData->{ACCOUNT_SEND_CERTIFICATES}=($accountDataByUser->{ACCOUNT_SEND_CERTIFICATES})?$accountDataByUser->{ACCOUNT_SEND_CERTIFICATES}:$accountData->{ACCOUNT_SEND_CERTIFICATES};
    		my $certModule = $self->getCertificateModule($self->{PRODUCT},$$delUsers{$user}->{COURSE_ID});
		if ($certModule ne $lastModule)
		{
			eval("use Certificate::$certModule");
			$certificateArray[$certModule] = ("Certificate::$certModule")->new;
			$lastModule=$certModule;
		}

		my $cert = $certificateArray[$certModule];
                my $certNumber = ($uData->{CERTIFICATE_NUMBER}) ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    print "cert number:  $certNumber\n";
                    ######## we have a valid certificate number
                    ######## The following sequence:  1, 0, 0 define the folling (in order)
                    ######## 1:  print the lower portion of the certificate for the user's records only
                    ######## 2:  print the cert starting from the top (not STCs);
                    ######## 3:  the cert is not an STC
                    my $result = 0;
                    my $printId = 0;
		    if(exists $self->{FAXCOURSE}->{$self->{PRODUCT}}->{$$delUsers{$user}->{COURSE_ID}} && !$accompanyLetter)
                    {
                        my $faxNumber=$accountData->{FAX};
                        $result=$cert->printCertificate($user, $uData, {FAX => $faxNumber},$printId,$printerKey,$accompanyLetter,$productId,'',0);
                    }elsif($accountData->{DELIVERY_ID} && $accountData->{DELIVERY_ID}==12){
			$uData->{EMAIL}=($uData->{EMAIL})?$uData->{EMAIL}:$accountData->{EMAIL};
			if($accountData->{ACCOUNT_SEND_CERTIFICATES} && $accountData->{ACCOUNT_SEND_CERTIFICATES} eq 'Y' && $accountData->{EMAIL}){
				$result=$cert->printCertificate($user, $uData, { EMAIL => $accountData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId,'',0);
			}else{
				$result=$cert->printCertificate($user, $uData, { EMAIL => $uData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId,'',0);
			}
		    }else{
                    	$result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId,'',0);
		    }
                    if($result)
                    {
                        if(!exists $self->{FAXCOURSE}->{$self->{PRODUCT}}->{$$delUsers{$user}->{COURSE_ID}}){
                                $noOfCert++;
                        }
			if(!$laCountyHardcopy){
                             	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
			}
                        push @processed, $user;
                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                        my $printString = "Printed User:  $user : $certNumber : $name";
                        print $printLog Settings::getDateTime(), "$printString\n";
                        print "$printString\n\n";
                        $printManifest .= "$printString\n\n";
                 if(!(exists $self->{FAXCOURSE}->{$self->{PRODUCT}}->{$$delUsers{$user}->{COURSE_ID}}  || $accompanyLetter || ($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} ==12) || ($accountData->{DELIVERY_ID} && $accountData->{DELIVERY_ID}==12))){
			    my $officeId=1;
                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestId, $user, $certificateCategory, $officeId);
                        }

                        ####### now print out a fedex label if required
			if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$$delUsers{$user}->{DELIVERY_ID}}){
			                $$delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$$delUsers{$user}->{DELIVERY_ID}};
    			}

                        if (($$delUsers{$user}->{DELIVERY_ID} == 2 ||
                             $$delUsers{$user}->{DELIVERY_ID} == 7 ||
                             $$delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE && !$accompanyLetter)
                        {
			     $fedexManifest .= $API->printFedexLabel($user,1);
			    
                        }
                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
                    exit;
                }
            }

            if ($limitedRun)
            {
                ###### decrement the run counter
                --$runCounter;
            }
          }
	  if (!$dryRun && $accountData->{ACCOUNT_SEND_CERTIFICATES} && $accountData->{ACCOUNT_SEND_CERTIFICATES} eq 'Y'  && $noOfCert>0 && $accountId && $accountData->{DELIVERY_ID}!=12)
          {
		$accountData->{NO_OF_CERTIFICATES}=$noOfCert;
                use Certificate::FleetCertificate;
                my $cert = Certificate::FleetCertificate->new;
		$cert->printCoverSheet($accountId, $accountData);
          }

	}
        close $printLog;
    }
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub STCPrint
{
    my ($delUsers,$affiliateId)=@_;     
    $jobDate = Settings::getDateTimeInANSI();    
    $processCourse='STC';
    if(!$printerKey)
    {
            $printerKey = 'CA';
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }


    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {   
    ##### send an alert to the CRM
	   $API->MysqlDB::dbInsertAlerts(7);
           exit(); 
    } 

    $printLog = gensym;
    open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_stc" or print STDERR "PRINT LOG ERROR: $!\n";;
    print $printLog "Job started at " . Settings::getDateTime() . "\n";

    processSTC($delUsers);
    Accessory::pReleaseLock($processCourse, $lockFile);

    print "NUM MAIL = $numMail, NUMAIRBILL = $numAirBill, NUMFAX = $numFax\n";
        my $mess = "Please read the attached text file for STC Airbills and Faxes. Thanks.\n";
        my $msg = MIME::Lite->new(
                    From => 'I DRIVE SAFELY - Customer Service <reports@idrivesafely.com>',
                    To => 'supportmanager@idrivesafely.com',
            Subject => "STC  Airbills and Faxes",
            Type => 'multipart/mixed');

        $msg->attach(Type => 'TEXT', Data => $mess);
        $msg->attach(Type =>'TEXT',
                     Path =>"$printerSite::SITE_ADMIN_LOG_DIR/stcAir.txt",
                     Filename =>'stcAir.txt',
                     Disposition => 'attachment' );

        $msg->attach(Type =>'TEXT',
                     Path =>"$printerSite::SITE_ADMIN_LOG_DIR/stcFax.txt",
                     Filename =>'stcFax.txt',
                     Disposition => 'attachment' );

	$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');
    ############################################################################################

    close $printLog;
    if($error_msg)
    {
            my $msg = MIME::Lite->new(From => 'I DRIVE SAFELY - Customer Service <reports@idrivesafely.com>',
                    To => 'support@idrivesafely.com',
                    Subject => 'Error Daily STC printing: Cannot print Airbill. ',
                    Type => 'TEXT', Data => $error_msg);
	    $msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');
    }
}

sub processSTC
{
    my $delUsers=shift;
    getSTCuids($delUsers);

    $numUsers = keys %stcHash;

    @userIds = sort { $user_court{$a} <=> $user_court{$b} } keys %user_court;
    
    if($laCountyHardcopy){
   	 my %rev=reverse  %user_court;
	    my @certIds=sort keys %rev;
	    @userIds=();
	    foreach(@certIds){
	    	push  @userIds,$rev{$_};
    	    }
    }
    
    $currentCourt = $stcHash{$userIds[0]}->{REGULATOR_ID};
    $currentFaxCourt = $stcHash{$userIds[0]}->{REGULATOR_ID};

    my $fedex = "";

    @Two = ();

    my $currentPrintCoverSheetCourt = 0;
    my @currentUserList;
    my %hashUser;

    for(my $i = 0; $i < $numUsers; $i++)
    {
        my $id = $userIds[$i];
        my $uData = $stcHash{$id}->{USER_DATA};

        if ($dryRun)
        {
            print "User ID:  $userIds[$i]    Regulator:  $stcHash{$id}->{REGULATOR_ID}  Course:  $stcHash{$id}->{COURSE_ID}\n";
        }
        else
        {
            if ($limitedRun && ! $runCounter)
            {
                ###### we're doing a limited run and that number has been reached.  Leave this loop
                last;
            }
            my $certID = $uData->{CERT_PROCESSING_ID};
            my $newCourt = $stcHash{$id}->{REGULATOR_ID};
            my $affiliate=$uData->{HOSTED_AFFILIATE};

                    if ($currentPrintCoverSheetCourt)
                    {
                            if ($currentPrintCoverSheetCourt == $newCourt)
                            {
                                    $hashUser{$id}=$uData;
                                    push @currentUserList, \%hashUser;
                            }
                            else
                            {
                                    #### the court has changed.  print out the current cover sheet and mail it out
                                    my $coverSheet;
            			    @currentUserList = ();
                                    %hashUser=();
                            }
                           ##### does the new court need a cover letter?
                            if (exists $self->{STCPRINTCOVER_REGS}->{$self->{PRODUCT}}->{$newCourt})     {    
				      $currentPrintCoverSheetCourt = $newCourt;  
		            }else{    
				      $currentPrintCoverSheetCourt = 0;       
			    }


                            ##### did we create a new cover sheet?  If so, add the user to the print list
                            if ($currentPrintCoverSheetCourt)  {   
					$hashUser{$id}=$uData;push @currentUserList, \%hashUser;                
			    }
                   }else{
                            ##### does the new court need a cover letter?
			    if (exists $self->{STCPRINTCOVER_REGS}->{$self->{PRODUCT}}->{$newCourt}){	
					$currentPrintCoverSheetCourt = $newCourt;   
			    }

                            ##### did we create a new cover sheet?  If so, add the user to the print list
                            if ($currentPrintCoverSheetCourt)      {  
					push @currentUserList, $id;      
			    }
                    }


            	 if(defined $certID && ($certID == 11 || $certID == 12 || $certID == 15 || $certID==22)) {
                            processFax($i);
		            $numFax++;
                 }
	         if(defined $certID && $certID != 11 && $certID != 15 && $certID!=22){
			    if(!$laCountyHardcopy){
                            	$fedex .= processAirbill($i);
			    }
                            processCert($i);
	                   $numMail++;
                 } 
	         if(!$laCountyHardcopy){
         		 $API->putAccompanyLetterUser($id);
		 }
                if($STOP == 1){
	                Settings::pSendMail(['supportmanager@idrivesafely.com' ], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Daily STC FEDEX EMAIL", " $fedex");
        	        Accessory::pReleaseLock($processCourse, $lockFile);
                	exit;
            	}

            	if ($limitedRun){
        	        ###### decrement the run counter
	                --$runCounter;
            	}
        }
    }
    ##### no more users are left.  make sure the cover sheet queue is done

    if(@Two) {                                                                 # catch the leftover certs
        printCert(\@Two) ;
        @Two = ();
    }
    if(@updatables && ! $laCountyHardcopy) {
                $fedex .= fedexPrint($currentCourt);
        @updatables = ();
        $numAirBill++;
    }
    if (@faxUsers) {
       faxCert($currentFaxCourt);
       @faxUsers = ();
    }
        if($STOP == 1) {
                Settings::pSendMail(['supportmanager@idrivesafely.com' ], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Daily STC FEDEX EMAIL", " $fedex");
                Accessory::pReleaseLock($processCourse, $lockFile);
                exit;
        }
        Settings::pSendMail(['supportmanager@idrivesafely.com'], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Daily STC FEDEX EMAIL", " $fedex");
} ### end sub processSTC()

sub processCert{ ########################################################################################################################
    my ($index) = @_;
    my $uid = $userIds[$index];

    push (@Two, $uid);
    my $len = @Two;
    if($len == 2) {
        printCert(\@Two);
        @Two = ();
    }
} ### end sub processCert()

sub processFax{ ########################################################################################################################
    my ($index) = @_;
    my $uid = $userIds[$index];
    my  $newFaxCourt = $stcHash{$uid}->{REGULATOR_ID};
    if($currentFaxCourt != $newFaxCourt) {
        if(@faxUsers) {
            faxCert($currentFaxCourt);
            @faxUsers = ();
        }
        $currentFaxCourt = $newFaxCourt;
    }
    my %hashUser;
    $hashUser{USER_ID}=$uid;
    $hashUser{USER_DATA}=$stcHash{$uid}->{USER_DATA};
    push (@faxUsers, \%hashUser) ;
} ### end sub processFax()

sub faxCert
{
    my ($regulatorID) = @_;
    my $aUid = $faxUsers[0]->{USER_ID};
    my $courtName=$stcHash{$aUid}->{USER_DATA}->{REGULATOR_DEF};
    my $faxNum=$stcHash{$aUid}->{USER_DATA}->{REGULATOR_FAX};
    my @toFaxUsers;
    ### Get reportid and report date ###
    my $reportId = $API->dbSelectReportId({REPORT_NAME=>'LA FAX', PRODUCT_ID => $self->{PRODUCT_ID}{$self->{PRODUCT}}  });
    my ($courseId, $certNumber);
    for my $uHash(@faxUsers)
    {
        my $uid=$uHash->{USER_ID};
        $courseId=$uHash->{COURSE_ID};
        my $uData = $uHash->{USER_DATA};
        $certNumber = $API->getNextCertificateNumber($uid);
        my $printDate  = Settings::getDateTime;

        $uHash->{USER_DATA}->{CERTIFICATE_NUMBER}   = $certNumber;
        push (@toFaxUsers, $uHash);

                if (! $laCountyHardcopy)
                {
                    $API->updatePrintDate($uid, $certNumber);
                    my %ref;
                    $ref{USER_ID} = $uid;
                    $ref{SUPPORT_OPERATOR} = "AUTO FAX";
                    $ref{COMMENTS} = "Faxed student certificate to court";
                    $API->putAdminComment(\%ref);
                }
	## Put LA User details in DB : reported to Court ##
    	if (!($regulatorID == 20021) && !$laCountyHardcopy) 
	{
		my $userData = $API->getUserData($uid);
    		$API->dbInsertReportDetails( { REPORTID => $reportId, USERID => $uid, USERDATA => \%$userData, PRODUCTID=>$self->{PRODUCT_ID}{$self->{PRODUCT}}  } );
	}
    }
    if($regulatorID == 20021) {
	##RT 3148, send the fax only
    	$userData->{CERTIFICATE_NUMBER}=$certNumber;
    	my $pId=0;
    	my $pId_1=0;
    	my $userData_1;
    	my $userId_1;
    	my $printerKey='CA';
    	my $productId=1;
	my $cId=$faxUsers[0]->{USER_DATA}->{COURSE_ID};
	my $uData=$faxUsers[0]->{USER_DATA};
    	my $certModule = $self->getCertificateModule($self->{PRODUCT},$cId);
    	eval("use Certificate::$certModule");
    	my $cert = ("Certificate::$certModule")->new;
    	my @printIdArr = $cert->printMultipleCertificate($aUid, $uData, $pId, $userId_1, $userData_1, $pId_1, { FAX => $faxNum}, $printerKey, 1);
    	return @printIdArr;
    } else {
	my $certModule = 'LosAngeles';
        if ($certModule ne $lastModule)
        {
	        eval("use Certificate::$certModule");
                $certificateArray[$certModule] = ("Certificate::$certModule")->new;
		$lastModule=$certModule;
        }

        my $cert = $certificateArray[$certModule];

        $cert->faxLACertificates(\@toFaxUsers, $faxNum, $courtName,  $hostedAffRun, $laCountyHardcopy );
    }
} ### end sub faxCert()
sub processAirbill{ ########################################################################################################################
    my ($index) = @_;
    my $uid = $userIds[$index];
    my $newCourt = $stcHash{$uid}->{REGULATOR_ID};
        my $fedex = "";

    if($currentCourt != $newCourt) {
        if(@updatables) {
                        $fedex = fedexPrint($currentCourt);
            @updatables = ();
                        $numAirBill++;
        }

        $currentCourt = $newCourt;
    }
    push (@updatables, $uid);
        return $fedex;
} ### end sub processAirbill()

sub printCert
{ ########################################################################################################################
    my ($myArray) = @_;
    my $message = '';
    my $count = 0;

    my @userIds;
    my @userDatas;
    my @certNumbers;
    my $ctrUser=0;
    for my $userId (@$myArray)
    {
        next if ( ! $userId ) ;

        return if ( printQueueIsFull());
        $priority++;
        my $uData=$stcHash{$userId}->{USER_DATA};
        my $affiliate=$uData->{HOSTED_AFFILIATE};
        my $lower=0;
        my $stc=1;
        my $certNumber = $API->getNextCertificateNumber( $userId );
        if ($certNumber)
        {
	    $uData->{CERTIFICATE_NUMBER}=$certNumber;
            $userIds[$ctrUser]=$userId;
            $certNumbers[$ctrUser]=$certNumber;
            $userDatas[$ctrUser]=$uData;
            $ctrUser++;


        }
        else
        {
                print $userId . ":  Invalid certificate returned - Not Printed\n";
        }
        sleep 1;
        $count++;
        last if ( $count >= 2 );
    }

    if (@userIds)
    {
        my $product = $productId;
            my $printId=0;
	    my $certModule = $self->getCertificateModule($self->{PRODUCT},$userDatas[0]->{COURSE_ID});
            if ($certModule ne $lastModule)
            {
                   eval("use Certificate::$certModule");
                   $certificateArray[$certModule] = ("Certificate::$certModule")->new;
		   $lastModule=$certModule;
            }
            my $cert = $certificateArray[$certModule];
	    my @printIdArr;
	    my $userIdsCount=@userIds;
	    if($userIdsCount == 2){
		my $userZone1=0;
		my $userZone2=0;
		if($userDatas[0]->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$userDatas[0]->{COURSE_STATE} }){
			$userZone1++;
		}else{
			$userZone2++;
		}
		if($userDatas[1]->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$userDatas[1]->{COURSE_STATE} }){
			$userZone1++;
		}else{
			$userZone2++;
		}

		if($userZone1  && $userZone1==1){
        	   	my @printIdArr1 = $cert->printMultipleCertificate($userIds[0], $userDatas[0],
                                        $printId, '','', $printId, { PRINTER => 1 }, $printerKey, $productId,$hostedAffRun);            
           		my @printIdArr2 = $cert->printMultipleCertificate($userIds[1], $userDatas[1],
                                        $printId, '','', $printId, { PRINTER => 1 }, $printerKey, $productId,$hostedAffRun);           
			push @printIdArr,$printIdArr1[0] ;
			push @printIdArr,$printIdArr2[0] ;

		}else{
           	 	@printIdArr = $cert->printMultipleCertificate($userIds[0], $userDatas[0],
                                        $printId, $userIds[1], $userDatas[1], $printId, { PRINTER => 1 }, $printerKey, $productId,$hostedAffRun);            
		}
	    }else{
           	 @printIdArr = $cert->printMultipleCertificate($userIds[0], $userDatas[0],
                                        $printId, $userIds[1], $userDatas[1], $printId, { PRINTER => 1 }, $printerKey, $productId,$hostedAffRun);            
            }
	    
	    
	if(@printIdArr)
            {
                for (my $i=0; $i < @printIdArr; ++$i)
                {
                    $message .= "Printing User: $userIds[$i] : $certNumbers[$i]\n";
		    if (! $laCountyHardcopy) {
			    $API->putUserPrintRecord($userIds[$i], $certNumbers[$i], 'PRINT');
		    }

                    my $name = "$userDatas[$i]->{FIRST_NAME} $userDatas[$i]->{LAST_NAME}";
                    push @processed, $userIds[$i];
                    print $printLog Settings::getDateTime(), ":$userIds[$i]:$certNumbers[$i]\n";
                    print "Printed User:  $userIds[$i] : $certNumbers[$i] : $name\n\n";
                    $printManifest .= "Printing User: $userIds[$i] : $certNumbers[$i] : $name\n";
		    my $officeId=0;
  	            if($userDatas[$i]->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$userDatas[$i]->{COURSE_STATE} }){
			    $officeId=1;
	                    $API->MysqlDB::dbInsertPrintManifest($printIdArr[$i], $self->{PRODUCT} . 'STC', $printMode, $jobDate,
                                            $productId, $manifestIdCaliforniaOffice, $userIds[$i], 'STC',$officeId);
		    }else{
			    $officeId=2;
	                    $API->MysqlDB::dbInsertPrintManifest($printIdArr[$i], $self->{PRODUCT} . 'STC', $printMode, $jobDate,
                                            $productId, $manifestIdTexasOffice, $userIds[$i], 'STC',$officeId);
		    }
                }
            }
    }
}
sub fedexPrint
{
        my ($regulatorID) = @_;

        my %GL_DELIVERY = ( 11 => 'EXP', 2 => 'NAS', 7 => 'SDS', 1 => 'REGULAR MAIL');

    if(printQueueIsFull())
    {
        $error_msg .= "Print Queue is full, NOT print AIRBILL for regulator: $regulatorID\n";
        return;
    }
    $priority++;
        my $delType = getBestDelType();

	##RT 10287 - for DADE county, this check is requested
        if( (!$delType || $delType eq '1') && $regulatorID && $regulatorID eq '20061') {
                $delType = 7;
        }
        my $fedex = "\nREGULATOR : $regHash{$regulatorID} ($regulatorID)\n";
        my $certCount = @updatables;
       	my $reply = $API->pRegulatorFedexPrint($regulatorID,$delType,$certCount, $hostedAffRun);


        my $TRACKINGNUMBER = '';
        for(keys %$reply) {
                if($_ eq 'TRACKINGNUMBER') {
                        $TRACKINGNUMBER = $$reply{$_};
                        $API->addSTCshippingRecord($TRACKINGNUMBER, \@updatables);
                        $fedex .= "\t$_ : $$reply{$_}\n";
                } else {
                        $fedex .= "--------------------------------------------------------------------------\n";
                        $fedex .= "\t$_ : $$reply{$_}\n";
                }
        }

        $fedex .= "\tUSERIDs : ";
        foreach (@updatables)
        {
                $fedex .= "$_ ";
        }
        return $fedex."\n";
}
sub printQueueIsFull
{
    if($priority > $MAX_PRIORITY)
    {
                my $dh = gensym;
                opendir $dh, $PRINT_QUEUE;
                my @files = grep /^xf/, readdir $dh;
                my %waitFiles = ();
                for my $file(@files){
                        my $fh = gensym;
                        open $fh, "$PRINT_QUEUE/$file" or die "$!";
                        my $printer = <$fh>;
                        chomp $printer;
                        close $fh;
                        if($printer eq 'hp8000-tx')
{
                                $waitFiles{$file} = 1;
                        }
                }

                my $wait = 0;
                while(keys %waitFiles){
                        for my $key(keys %waitFiles){
                        if(-e "$PRINT_QUEUE/$key"){
                                print "PRINT FILES EXIST...SLEEPING...\n";
                                if($wait < $MAX_WAIT){
                                        $wait += 5;
                                        sleep 5;
                                } else {
                                        print "WAITED TOO LONG FOR PRINT JOBS TO CLEAR\n";
                                        return 1;
                                }
                        } else {
                                delete $waitFiles{$key};
                        }
                        }
                }
                $priority = 1;
    }
    return 0;
}

sub getSTCuids
{
    my $users = shift;
    for my $uid(keys %$users)
    {
        $stcHash{$uid}->{COURSE_ID}     = $users->{$uid}->{COURSE_ID};
        $stcHash{$uid}->{REGULATOR_ID}  = $users->{$uid}->{REGULATOR_ID};
        $stcHash{$uid}->{DELIVERY_ID}   = ($users->{$uid}->{DELIVERY_ID}) ?
                                        $users->{$uid}->{DELIVERY_ID} : 7;
        $stcHash{$uid}->{USER_DATA}     = $users->{$uid}->{USER_DATA};
        my $regulatorId                 = $users->{$uid}->{REGULATOR_ID};
        my $certPrintDate               = $users->{$uid}->{CERT_PRINT_DATE};
        my $certNumber                  = $users->{$uid}->{USER_DATA}->{CERTIFICATE_NUMBER};
        $regHash{$regulatorId}          = $users->{$uid}->{REGULATOR_DEF};
	if($laCountyHardcopy && $certNumber){
        	$user_court{$uid}               = $certNumber;
	}else{
        	$user_court{$uid}               = $regulatorId;
	}
    }
}

sub getBestDelType
{
    my $delType = 7;
    foreach (@updatables) {                                                             # all users for this regulator
        my $aType = $stcHash{$_}->{DELIVERY_ID};
        my %sort = ( 11 => 4, 2 => 3, 7 => 2, 1 => 1 );
        if($sort{$delType} < $sort{$aType}) {
            $delType = $aType;
        }
    }
    return $delType;
}


sub DSMSPrint
{
    my ($printUsers)=@_;
    my %dsmsUsers=%$printUsers;
    if (!$opts{c})
    {
            print "course id $opts{c} cannot print from this process\nexiting...\n";
            exit;
    }

    if (! $dryRun)
    {
	#$manifestId  =   $API->MysqlDB::getNextId('manifest_id');
	$manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
	$manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }

    my %sort = ( 4 => 1, 3 => 2, 2 => 3, 1 => 4, 12 => 5);
    my @keys = sort { $sort{$dsmsUsers{$a}->{DELIVERY_ID}} <=> $sort{$dsmsUsers{$b}->{DELIVERY_ID}} } keys %dsmsUsers;
    my $printType = "DSMS-REGULAR";
    my $certificateCategory='REG';

    print STDERR "num of users to process: " . @keys . " \n";
    my $studentDataDisplay;
    if(@keys) {
	foreach my $uid(@keys) {
		my %rowUsers;
		my $userData = $dsmsUsers{$uid}->{USER_DATA};
		my $cid = $userData->{CLASS_ID};
		$studentDataDisplay->{$cid}->{$uid} = $dsmsUsers{$uid}->{USER_DATA};
	}
    }

   my @studentData = keys %$studentDataDisplay; 

    if(@studentData)
	{
        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_ca" or print STDERR "PRINT LOG ERROR: $!\n";;
        print $printLog "Job started at " . Settings::getDateTime() . "\n";

        my $priority = 1;
	my $btwCoursePrinting = 0;
        for my $classId(@studentData)
        {
	    my $uData=$studentDataDisplay->{$classId};
	    my @studentInfo = keys %$uData;
	    if(@studentInfo) {
	
		foreach my $studentId(@studentInfo) {
		
			my $courseId = $uData->{$studentId}->{COURSE_ID};
			my $sInfo = $uData->{$studentId};
            		if ($limitedRun && ! $runCounter)
		        {
                	###### we're doing a limited run and that number has been reached.  Leave this loop
	                last;
        	    }

	            if ($dryRun)
        	    {
                	####### simply output the user and his delivery option.  No changes will be made to the database
	                my $deliveryId = ($uData->{$studentId}->{DELIVERY_ID}) ? $uData->{$studentId}->{DELIVERY_ID} : 1;
        	        print "User ID:  $studentId   Delivery ID:  $deliveryId\n";
	            }
        	    else
	            {
			my $certModule = $self->getCertificateModule($self->{PRODUCT},$uData->{$studentId}->{COURSE_ID});
                	if ($certModule ne $lastModule)
	                {
				eval("use Certificate::$certModule");
                	        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
			}

        	        my $cert = $certificateArray[$certModule];
	
        	        $priority++;

	                my $certNumber = $API->getNextCertificateNumber($studentId);
			$uData->{$studentId}->{CERTIFICATE_NUMBER}=$certNumber;
                	if ($certNumber)
	                {
        	                ###### run the course on the appropriate certificate
                	        my $result = 0;
				my $printId = 0;

				if (!$API->isPrintableCourse($dsmsUsers{$studentId}->{COURSE_ID})) {
					#### the course needs to be printed manually.  For example, NM has to be loaded
					####  w/ the indivdual certs
					$result = $API->MysqlDB::getNextId('contact_id');
					#### add the code for the CRM.  It has to be done here
					my $fixedData=Certificate::_generateFixedData($uData);
					$printType = "DSMS-BTW-REGULAR";
					$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
					$btwCoursePrinting++;
					$productId = 33; #For BTW
				} else {
					$result=$cert->printCertificate($studentId, $sInfo, { PRINTER => 1  },$printId,$printerKey,0,$productId);
				}

	                        if($result)
        	                {
				    $API->putUserPrintRecord($studentId, $certNumber, 'PRINT');
                        	}
	                        push @processed, $studentId;
        	                my $name = "$uData->{$studentId}->{FIRST_NAME} $uData->{$studentId}->{LAST_NAME}";

                	        ####### log all of this in the print log, print manifest and STDERR
	                        my $printString = "Printed User:  $studentId : $certNumber : $name";
        	                print $printLog Settings::getDateTime(), "$printString\n";
                	        print "$printString\n\n";
	                        $printManifest .= "$printString\n\n";
				my $officeId=0;
  	            		if($sInfo->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$sInfo->{COURSE_STATE} }){
					$officeId=1;
	        	                $API->MysqlDB::dbInsertPrintManifest($result,$printType, $printMode, $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $studentId, $certificateCategory,$officeId);
				}else{
					$officeId=2;
	        	                $API->MysqlDB::dbInsertPrintManifest($result,$printType, $printMode, $jobPrintDate, $productId, $manifestIdTexasOffice, $studentId, $certificateCategory,$officeId);
				}
				sleep 3;
	                      }
        	              else
                	      {
                        	    ### put cert number back
	                      }
    				if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$uData->{$studentId}->{DELIVERY_ID}}){
					$uData->{$studentId}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$uData->{$studentId}->{DELIVERY_ID}};
				}

	            }
		}
		if (!$dryRun && $btwCoursePrinting == 0){
			my $classDeliveryId = $API->getDeliveryId($classId);
			my $classInfo = $API->getClassInfo($classId);
			#For the class, if there is no airbill number, and all the students certificates are printed,
			#then only print the fedex label
			my $fedExLabelPrintingCheck = $API->getFedExPringingCheck($classId);
	    		if($fedExLabelPrintingCheck && $classDeliveryId == 101)
                	{
				$fedexManifest .= $API->printFedexLabel("$classInfo->{DS_SCHOOL_ID}:$classId",1,'');
			}
			my $lablePrintCheck = $API->getAirbillPringingCheck($classId);
			if($classDeliveryId == 2 && $lablePrintCheck) {
				#All the certs to be sent to school via regular mail, print address for the school.
				my $shippingInfo = $API->getUserShipping($classInfo->{DS_SCHOOL_ID});
				use Certificate::NewYork;
				my $cert = Certificate::NewYork->new; 
				my $clasStudentsCount = $API->getNYClassStudentsCount($classId);
				$cert->printDSMSRegulatorMailLabel($classId, $shippingInfo, $clasStudentsCount);
				$API->putClassAirbillInfo($classId);
			}

			##Once the class is printed, a blank certificate to be printed, as per the request at RT 7372
			use Certificate::NewYork;
			my $blankCert = Certificate::NewYork->new;
			$blankCert->printBlankCertificateForDSMS();
	    	}

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

sub AdultPrint
{
    my ($printUsers)=@_;
    my %delUsers=%$printUsers;
    $processCourse = 'ADULT';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 4 => 1, 3 => 2, 3 => 3, 1 => 4);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'ADULT-TX-DUPLICATE':'ADULT-TEXAS-REGULAR';
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':'REG';
    $printType=($affidavit)?'ADULT-TX-AFFIDAVIT':$printType;
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
                my $certNumber = ($uData->{CERTIFICATE_NUMBER}) ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    my $result = 0;
                    my $printId = 0;
          	    print "user id:  $user    Cert Number:  $certNumber   Name $uData->{FIRST_NAME} $uData->{LAST_NAME}\n";
	            if ($API->isPrintableCourse($uData->{COURSE_ID}))
        	    {
	                my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
        	        if ($certModule ne $lastModule)
                	{
                        	eval("use Certificate::$certModule");
	                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
        	        }

                	my $cert = $certificateArray[$certModule];
			if($uData->{DELIVERY_ID} && ($uData->{DELIVERY_ID} == 12 || $uData->{DELIVERY_ID} == 5)){
				$result=$cert->printCertificate($user, $uData, { EMAIL => $uData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId);
			} else {
				$result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId);
			}
            	    }else{
	               ##### the course needs to be printed manually.  For example, CA has to be loaded
	                ##### w/ the indivdual certs
                	$result = $API->MysqlDB::getNextId('contact_id');

	                ###### add the code for the CRM.  It has to be done here
			my $fixedData=Certificate::_generateFixedData($uData);
    			$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
			if(exists $self->{RGLPRINTLABELCOURSE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}} && $delUsers{$user}->{DELIVERY_ID} && $delUsers{$user}->{DELIVERY_ID} == 1 ){
                        	use Certificate::TXAdult;
	                        my $cert=Certificate::TXAdult->new;
				$cert->printAdultLabel($user,$uData);
			}
			
            	    }
                    if($result)
                    {
                        	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
	                        push @processed, $user;
        	                my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                	        my $printString = "Printed User:  $user : $certNumber : $name";
                        	print $printLog Settings::getDateTime(), "$printString\n";
	                        print "$printString\n\n";
        	                $printManifest .= "$printString\n\n";
	        	         if(!($uData->{DELIVERY_ID} ==12)){
					 my $settings = Settings->new;
        	                         my $officeId=0;
                	                 if($uData->{COURSE_STATE} && exists $settings->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
						$officeId=1;
        	        		        $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
					}else{
						$officeId=2;
        		      	                $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                        $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
					}


                         	}

	                        ####### now print out a fedex label if required
        	                if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                	                        $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        	}

	                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
        	                     $delUsers{$user}->{DELIVERY_ID} == 7 ||
                	             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE)
                        	{
				     $fedexManifest .= $API->printFedexLabel($user,1,'AD');
				    
				}

				if($delUsers{$user}->{DELIVERY_ID} != 12 && $delUsers{$user}->{DELIVERY_ID} != 15 && $delUsers{$user}->{DELIVERY_ID} != 21 && $delUsers{$user}->{DELIVERY_ID} != 24) {
					$API->dbSendMailMarketo($productId, $user, 'DeliverySent','','','','COURSE_COMPLETE_EMAIL');
				}
                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub DriversEdPrint
{
    my ($printUsers)=@_;
    my %delUsers=%$printUsers;
    $processCourse = 'DRIVERSED';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my $DRIVERSED_BTW_OFFERED_STATES = { map { $_ => 1 } qw(CA) };
    my %sort = ( 11 => 1, 2 => 2, 7 => 3, 22 => 4, 1 => 5);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType='DRIVERSED';
    my $certificateCategory='REG';
    print STDERR "num of users ready to process " . @keys . " \n";
    my $needBTWManifestId = 0;
    my $noNeedBTWManifestId = 0;
    my $btwManifestCheck = 0;
    my $ohTeenCounter = 1;
    my $btwPrintType = 'DRIVERSED';
    if(@keys)
    {
        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_ca" or print STDERR "PRINT LOG ERROR: $!\n";;
        print $printLog "Job started at " . Settings::getDateTime() . "\n";

        foreach my $user(@keys)
        {
            my $uData=$delUsers{$user}->{USER_DATA};
	    my $needsBTW = $uData->{NEEDBTW};
	    my $courseState = $uData->{COURSE_STATE};
	    my $courseSegment = ucfirst lc $uData->{COURSE_SEGMENT};
    	    $printType='DriversEd';
	    $printType = "$printType $courseSegment";
	    ###CRM-409 - Start
  	    if($courseState && $courseState eq 'TX' && $uData->{COURSE_SEGMENT} && $uData->{COURSE_SEGMENT} eq 'TEEN') {
		if($uData->{COURSE_ID} && $uData->{COURSE_ID} eq 'C0000071') {
			if($permitCertsDE) {
				$printType = "DriversEd $courseSegment CPCC/Permit Cron";
			} else {
				if($uData->{COURSE_REASON} && $uData->{COURSE_REASON} eq 'DEDS') {
					$printType = "DriversEd $courseSegment COC Cron";
				} else {
					$printType = "DriversEd $courseSegment COC Transfer Cron";
				}
			}
		}
		if($uData->{COURSE_ID} && $uData->{COURSE_ID} eq 'BTWTMINI03') {
			$printType = "DriversEd Teen Transfer";
		}
		if($uData->{COURSE_ID} && $uData->{COURSE_ID} eq 'BTWTMINI03_I') {
			$printType = "DriversEd Teen Insurance";
		}
 	    }
	    ###CRM-409 - End
	    if(($courseState && exists $DRIVERSED_BTW_OFFERED_STATES->{$courseState})){
		$btwManifestCheck = 1;
		if($needsBTW && $needsBTW eq 'Y' && !$needBTWManifestId) {
			$needBTWManifestId = $API->MysqlDB::getNextId('manifest_id');
			$btwPrintType = "DRIVERSED-NEED-BTW";	
		}
		if($needsBTW && $needsBTW eq 'N' && !$noNeedBTWManifestId) {
			$noNeedBTWManifestId = $API->MysqlDB::getNextId('manifest_id');
			$btwPrintType = "DRIVERSED-NONEED-BTW";	
		}
	    }
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
                my $certNumber = ($uData->{CERTIFICATE_NUMBER}) ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

		##DE CO Teen Attendance Records alone, or the rest of the cronjobs
		if($deAffidavit && $deAffidavit == 1 && $uData->{PRODUCT_ID} eq 'C0000013') {
			##For CO Teen, fetch the Student sttendance record and print the record
			use Certificate::DECOTeen;
			my $cert=Certificate::DECOTeen->new;
			$cert->printCOTeenStudentAttedanceRecord($user, $uData);

		} elsif($deAffidavit && $deAffidavit == 1 && $uData->{PRODUCT_ID} eq 'C0000071') {
			##For TX Teen - Attendance sheet printing
			use Certificate::DETXTeen32;
			my $cert = Certificate::DETXTeen32->new;
			$cert->printTXTeenStudentLog($user, $uData);
		} else {
                if ($certNumber)
                {
                    my $result = 0;
                    my $printId = 0;
          	    print "user id:  $user    Cert Number:  $certNumber   Name $uData->{FIRST_NAME} $uData->{LAST_NAME}\n";
		    if($permitCertsDE && $uData->{COURSE_ID} && $uData->{COURSE_ID} eq 'C0000071') {
	                my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
        	        if ($certModule ne $lastModule)
                	{
                        	eval("use Certificate::$certModule");
	                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
        	        }

                	my $cert = $certificateArray[$certModule];
			$result=$cert->_generate6HRPermitCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId);	
	            } elsif ($API->isPrintableCourse($uData->{COURSE_ID}))
        	    {
	                my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
        	        if ($certModule ne $lastModule)
                	{
                        	eval("use Certificate::$certModule");
	                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
        	        }

                	my $cert = $certificateArray[$certModule];
			if($deliveryMode && $deliveryMode eq 'DOWNLOAD') {
                       		$result=$cert->printCertificate($user, $uData, { DOWNLOAD => 1},$printId,$printerKey,$accompanyLetter,$productId);
			} else {
                       		$result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId);
			}
            	    }else{
	               ##### the course needs to be printed manually.  For example, CA has to be loaded
	                ##### w/ the indivdual certs
                	$result = $API->MysqlDB::getNextId('contact_id');

	                ###### add the code for the CRM.  It has to be done here
			my $fixedData=Certificate::_generateFixedData($uData);
    			$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
			if(exists $self->{RGLPRINTLABELCOURSE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}} && $delUsers{$user}->{DELIVERY_ID} && $delUsers{$user}->{DELIVERY_ID} == 1 ){
				if($uData->{PRODUCT_ID} eq 'C0000013') {
					use Certificate::DECOTeen;
					my $cert=Certificate::DECOTeen->new;
					$cert->printCOTeenLabel($user,$uData);
				} elsif($uData->{PRODUCT_ID} eq 'C0000067') {
					use Certificate::DEOHTeen;
					my $cert=Certificate::DEOHTeen->new;
					$cert->printOHTeenLabel($user,$uData);
				} elsif($uData->{PRODUCT_ID} eq 'C0000034') {
					use Certificate::DECATeen;
					my $cert=Certificate::DECATeen->new;
					$cert->printDECATeenLabel($user,$uData);
				}
			}
			##STOPPED CO TEEN Attendance Sheets - From the cron
			#if(exists $self->{RGLPRINTLABELCOURSE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}} && $uData->{PRODUCT_ID} eq 'C0000013') {
				###For CO Teen, fetch the Student sttendance record and print the record
				#use Certificate::DECOTeen;
				#my $cert=Certificate::DECOTeen->new;
				#$cert->printCOTeenStudentAttedanceRecord($user, $userData);
			#}
			if($uData->{PRODUCT_ID} eq 'C0000067' && $ohTeenCounter == 1) {
				#Get the enrollment pdf and submit for printing, the function to be called one time for that run. 
				use Certificate::DEOHTeen;
				my $cert = Certificate::DEOHTeen->new;
				$cert->printStudentOHCerts($user, $uData); ##Based on the user type, pull the permit cert pdfs or the completion pdfs and submit for printing
				#$ohTeenCounter++;
			}
            	    }
                    if($result)
                    {
                        	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
	                        push @processed, $user;
        	                my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                	        my $printString = "Printed User:  $user : $certNumber : $name";
                        	print $printLog Settings::getDateTime(), "$printString\n";
	                        print "$printString\n\n";
        	                $printManifest .= "$printString\n\n";
	        	         if(!($uData->{DELIVERY_ID} ==12)){
					 my $settings = Settings->new;
        	                         my $officeId=0;
                	                 if(($uData->{COURSE_STATE} && exists $settings->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }) || ($uData->{PRODUCT_ID} eq 'C0000013' || $uData->{PRODUCT_ID} eq 'C0000034')){
						$officeId=2;
						if($uData->{PRODUCT_ID} eq 'C0000018' || $uData->{PRODUCT_ID} eq 'C0000057' || $uData->{PRODUCT_ID} eq 'C0000056' || $uData->{PRODUCT_ID} eq 'C0000013') {
							$officeId=2;
						}
						if($needBTWManifestId) {
							$manifestIdCaliforniaOffice = $needBTWManifestId;
							$printType = $btwPrintType;
						}
						if($noNeedBTWManifestId) {
							$manifestIdCaliforniaOffice = $noNeedBTWManifestId;
							$printType = $btwPrintType;
						}
						if($deliveryMode && $deliveryMode eq 'DOWNLOAD') {
							##Download Delivery, No Manifest Details
						} else {
        	        		        $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
						}
					}else{
						$officeId=2;
						if($deliveryMode && $deliveryMode eq 'DOWNLOAD') {
							##Download Delivery, No Manifest Details
						} else {
        		      	                $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                        $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
						}
					}


                         	}

	                        ####### now print out a fedex label if required
        	                if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                	                        $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        	}

	                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
        	                     $delUsers{$user}->{DELIVERY_ID} == 7 ||
                	             $delUsers{$user}->{DELIVERY_ID} == 11 || $delUsers{$user}->{DELIVERY_ID} == 26) && !$RUNDUPLICATE)
                        	{
				     $fedexManifest .= $API->printFedexLabel($user,1,'AD');
				    
				}
	                        if (($delUsers{$user}->{DELIVERY_ID} == 22 || $delUsers{$user}->{DELIVERY_ID} == 23 || $delUsers{$user}->{DELIVERY_ID} == 24)  && !$RUNDUPLICATE && !$accompanyLetter)
	                        {
        	                     $fedexManifest .= $API->printUSPSLabel($user,1);
                	        }
				if(!($uData->{COURSE_ID} && ($uData->{COURSE_ID} eq 'C0000013' || $uData->{COURSE_ID} eq 'C0000034' || $uData->{COURSE_ID} eq 'C0000023_NM'))){
					$driversEdDataUpdate .= $API->updateDriveredData($user);
				}
				###### Call Update Data

                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub DIPDVDPrint
{
    my ($printUsers,$affiliateId)=@_;
    my %delUsers=%$printUsers;
    my $currentCertificate;
    $processCourse = 'DVDNY';
    $state = 'NY';
    if($state){
	    $processCourse = $state;
    }
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 11 => 1, 2 => 2, 7 => 3, 1 => 4, 12 => 5);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':'REGULAR';
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':($accompanyLetter)?'ACMPNLTR':'REG';

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
    		my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
		if ($certModule ne $lastModule)
		{
			eval("use Certificate::$certModule");
			$certificateArray[$certModule] = ("Certificate::$certModule")->new;
			$lastModule=$certModule;
		}

		my $cert = $certificateArray[$certModule];
                my $certNumber = ($uData->{CERTIFICATE_NUMBER}) ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user,$delUsers{$user}->{COURSE_ID});
		$uData->{CERTIFICATE_NUMBER}=$certNumber;
                if ($certNumber)
                {
                    print "cert number:  $certNumber\n";
                    ######## we have a valid certificate number
                    ######## The following sequence:  1, 0, 0 define the folling (in order)
                    ######## 1:  print the lower portion of the certificate for the user's records only
                    ######## 2:  print the cert starting from the top (not STCs);
                    ######## 3:  the cert is not an STC
                    my $result = 0;
                    my $printId = 0;
	    	    if (!$API->isPrintableCourse($delUsers{$user}->{COURSE_ID}))
	    	    {
                        ##### the course needs to be printed manually.  For example, NM has to be loaded
                        ##### w/ the indivdual certs
		        $result = $API->MysqlDB::getNextId('contact_id');
                        ###### add the code for the CRM.  It has to be done here
                        my $fixedData=Certificate::_generateFixedData($uData);
                        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');

		    }
                    else
                    {
                       	    $result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
                    }
                    if($result)
                    {
			if(!$laCountyHardcopy){
                               	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
			}
                        push @processed, $user;
                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                        my $printString = "Printed User:  $user : $certNumber : $name";
                        print $printLog Settings::getDateTime(), "$printString\n";
                        print "$printString\n\n";
                        $printManifest .= "$printString\n\n";
			    my $officeId=0;
			    if($uData->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
				    $officeId=1;
        	                    $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
			    }else{
				    $officeId=2;
	                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
			    }

                        ####### now print out a fedex label if required
			if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
			                $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
    			}

                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
                             $delUsers{$user}->{DELIVERY_ID} == 7 ||
                             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE && !$accompanyLetter)
                        {
			     my ($manifestReturn,$tracking) = $API->printFedexLabel($user,$uData,'','');
			     $fedexManifest .= $manifestReturn;
			    if($tracking){
				 $API->MysqlDB::dbUpdateTrackingInfo($result,$tracking);
			    }
			     
			    
                        }
                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}
sub SSPrint
{

    my ($printUsers,$affiliateId)=@_;
    my %delUsers=%$printUsers;
    my $currentCertificate;
    $processCourse = 'SS_CA';
    if($state){
	    $processCourse = 'SS_'.$state;
    }
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 11 => 1, 2 => 2, 7 => 3, 1 => 4, 12 => 5);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':'REGULAR';
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':($accompanyLetter)?'ACMPNLTR':'REG';

    print STDERR "num of users ready to process " . @keys . " \n";
    my $row = 0;
    if(@keys)
    {
        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_ca" or print STDERR "PRINT LOG ERROR: $!\n";;
        print $printLog "Job started at " . Settings::getDateTime() . "\n";
        my $excelFile;
        my $worksheet;
        my $titleFormat;
        my $boldFormat;
        my $leftFont;
        my $boldFont;


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
    		my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
		if ($certModule ne $lastModule)
		{
			eval("use Certificate::$certModule");
			$certificateArray[$certModule] = ("Certificate::$certModule")->new;
			$lastModule=$certModule;
		}

		my $cert = $certificateArray[$certModule];
                my $certNumber = $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    print "cert number:  $certNumber\n";
                    ######## we have a valid certificate number
                    ######## The following sequence:  1, 0, 0 define the folling (in order)
                    ######## 1:  print the lower portion of the certificate for the user's records only
                    ######## 2:  print the cert starting from the top (not STCs);
                    ######## 3:  the cert is not an STC
                    my $result = 0;
                    my $printId = 0;
	    	    if (!$API->isPrintableCourse($delUsers{$user}->{COURSE_ID}))
	    	    {
                        ##### the course needs to be printed manually.  For example, NM has to be loaded
                        ##### w/ the indivdual certs
		        $result = $API->MysqlDB::getNextId('contact_id');
                        ###### add the code for the CRM.  It has to be done here
                        my $fixedData=Certificate::_generateFixedData($uData);
                        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
		    }elsif($API->isXLSPrintableCourse($delUsers{$user}->{COURSE_ID})) {
			if(!$xlsFileName){
				my $currTime=time();
				$xlsFileName="/tmp/userslist_$currTime.xls";
				$excelFile = Spreadsheet::WriteExcel->new($xlsFileName);
				$worksheet = $excelFile->add_worksheet();
				## set the title format
				$titleFormat = $excelFile->add_format();
				$titleFormat->set_bold();
				$titleFormat->set_center_across();
				$titleFormat->set_bg_color('silver');

				$boldFormat = $excelFile->add_format();
				$boldFormat->set_bold();
				$boldFormat->set_center_across();

				## set the right align,left align and red color font
				my $leftFont   = $excelFile->add_format( font => 'Arial', size => 10, align => 'left');

				##set the column size
				$boldFont = $excelFile->add_format( font => 'Arial', size => 11);
				$worksheet->set_column('A1:A1',20);
				$worksheet->set_column('B1:B1',25);
				$worksheet->set_column('C1:C1',20);
				$worksheet->set_column('D1:D1',25);
				$worksheet->set_column('E1:E1',25);
				$worksheet->set_column('F1:F1',25);
				$worksheet->set_column('G1:G1',25);
				## write the headers
				$worksheet->write($row,0,'User ID',$titleFormat);
				$worksheet->write($row,1,'First Name',$titleFormat);
				$worksheet->write($row,2,'Photo',$titleFormat);
				$worksheet->write($row,3,'date issued',$titleFormat);
				$worksheet->write($row,4,'Date Issued',$titleFormat);
				$worksheet->write($row,5,'Expiration Date',$titleFormat);
				$worksheet->write($row,6,'Last Name',$titleFormat);

				## Get the registered users data for the previous month
			}
			$row++;
			#push @userIdArray,$userId;
			$uData->{EXPIRATION_DATE}=($uData->{EXPIRATION_DATE_4YEAR})?$uData->{EXPIRATION_DATE_4YEAR}:$uData->{EXPIRATION_DATE2_4YEAR};
			$worksheet->write($row,0,$user,$leftFont);
			$worksheet->write($row,1,$uData->{FIRST_NAME},$leftFont);
			$worksheet->write($row,2,' ',$leftFont);
			$worksheet->write($row,3,' ',$leftFont);
			$worksheet->write($row,4,'Date Issued:     '.  $uData->{COMPLETION_DATE},$leftFont);
			$worksheet->write($row,5,'Expiration Date: '.  $uData->{EXPIRATION_DATE},$leftFont);
			$worksheet->write($row,6,$uData->{LAST_NAME},$leftFont);
                        $result = $API->MysqlDB::getNextId('contact_id');
                        ###### add the code for the CRM.  It has to be done here
                        my $fixedData=Certificate::_generateFixedData($uData);
                        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');

                    }elsif($delUsers{$user}->{DELIVERY_ID} && ($delUsers{$user}->{DELIVERY_ID} == 12 || $delUsers{$user}->{DELIVERY_ID} == 23)){
			my $printCert=$cert;
                            $result=$cert->printCertificate($user, $uData, { EMAIL => $uData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
		    }
                    else
                    {
                       	    $result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
                    }
                    if($result)
                    {
                        $API->putUserPrintRecord($user, $certNumber, 'PRINT');
                        push @processed, $user;
                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                        my $printString = "Printed User:  $user : $certNumber : $name";
                        print $printLog Settings::getDateTime(), "$printString\n";
                        print "$printString\n\n";
                        $printManifest .= "$printString\n\n";

			if($userData->{SEND_CERT_TO_DISTRIBUTOR} && $userData->{DISTRIBUTOR_EMAIL}){
				$API->putCookie($user, {'CERT_SENT_VIA_EMAIL_TO_DISTRIBUTOR'=>'1'});
			}
	                if(!($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} ==12 || $uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} ==23)){
			    $API->putCookie($user, {'CERT_SENT_VIA_EMAIL'=>'1'});
			    my $officeId=0;
			    if($uData->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
				    $officeId=1;
        	                    $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
			    }else{
				    $officeId=2;
	                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
			    }
                        }

                        ####### now print out a fedex label if required
			if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
			                $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
    			}
                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
                             $delUsers{$user}->{DELIVERY_ID} == 7 ||
                             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE && !$accompanyLetter)
                        {
			     $fedexManifest .= $API->printFedexLabel($user,1,$affiliateId);
			    
                        }elsif($delUsers{$user}->{DELIVERY_ID} && ($delUsers{$user}->{DELIVERY_ID} ==1 || $delUsers{$user}->{DELIVERY_ID} ==16) && $xlsFileName && $API->isXLSPrintableCourse($delUsers{$user}->{COURSE_ID})){
				use Certificate::SellerServerTABC;
		                my $labelCert=Certificate::SellerServerTABC->new;
				$labelCert->printRegularLabel($user,$uData);
			}
		    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
                    exit;
                }
            }

            if ($limitedRun)
            {
                ###### decrement the run counter
                --$runCounter;
            }
        }
	if($xlsFileName){
		$excelFile->close();
		##send an email
		my $msg = MIME::Lite->new(
	        From    =>'I DRIVE SAFELY - Customer Service <reports@idrivesafely.com>',
        	To      => 'rebecca@idrivesafely.com, kami.mason@idrivesafely.com, Haidee.Hodge@iDriveSafely.com, Christie.Myrick@iDriveSafely.com',
        	Subject =>"Seller Server NV Certificate Data",
	        Type    =>'multipart/mixed'
);
		my $message = "Seller Server NV Certificate Data";
		$msg->attach(   Type     => 'TEXT',
                	Data     => $message
             	);
		my ($mime_type, $encoding) = ('application/xls', 'base64');
		$msg->attach(
                        Type     => $mime_type ,
                        Encoding => $encoding ,
                        Path     => $xlsFileName,
                        Filename => "NVCertficateData_".Settings::getDateTime().".xls",
                        Disposition => 'attachment'
            	);

		$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');
		unlink $xlsFileName;
		
	}
        close $printLog;
    }
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub AARPPrint
{

    my ($printUsers,$affiliateId)=@_;
    my %delUsers=%$printUsers;
    my $currentCertificate;
    if ($opts{s} && $opts{s} eq 'CA') {
	$processCourse = $opts{s};
    }else{
	$processCourse = "AARP";
    }
    if($state){
	    $processCourse = $state;
    }
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 6 => 1, 5 => 2, 4 => 3, 1 => 4, 2 => 5);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':"REGULAR - $processCourse";
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':($accompanyLetter)?'ACMPNLTR':'REG';

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
    		my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
		if ($certModule ne $lastModule)
		{
			eval("use Certificate::$certModule");
			$certificateArray[$certModule] = ("Certificate::$certModule")->new;
			$lastModule=$certModule;
		}

		my $cert = $certificateArray[$certModule];
                my $certNumber = $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    print "cert number:  $certNumber\n";
                    ######## we have a valid certificate number
                    ######## The following sequence:  1, 0, 0 define the folling (in order)
                    ######## 1:  print the lower portion of the certificate for the user's records only
                    ######## 2:  print the cert starting from the top (not STCs);
                    ######## 3:  the cert is not an STC
                    my $result = 0;
                    my $printId = 0;
	    	    if (!$API->isPrintableCourse($delUsers{$user}->{COURSE_ID}))
	    	    {
                        ##### the course needs to be printed manually.  For example, NM has to be loaded
                        ##### w/ the indivdual certs
		        $result = $API->MysqlDB::getNextId('contact_id');
                        ###### add the code for the CRM.  It has to be done here
                        my $fixedData=Certificate::_generateFixedData($uData);
                        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');

                    }elsif($delUsers{$user}->{DELIVERY_ID} && ($delUsers{$user}->{DELIVERY_ID} == 2)){
			my $printCert=$cert;
                            $result=$cert->printCertificate($user, $uData, { EMAIL => $uData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
		    }
                    else
                    {
                       	    $result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId,'',$hostedAffRun);
                    }
                    if($result)
                    {
                        $API->putUserPrintRecord($user, $certNumber, 'PRINT');
                        push @processed, $user;
                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                        my $printString = "Printed User:  $user : $certNumber : $name";
                        print $printLog Settings::getDateTime(), "$printString\n";
                        print "$printString\n\n";
                        $printManifest .= "$printString\n\n";
	                if(!($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} ==2)){
			    my $officeId=0;
			    if($uData->{COURSE_STATE} && exists $cert->{SETTINGS}->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
				    $officeId=1;
        	                    $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
			    }else{
				    $officeId=2;
	                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
			    }
                        }

                        ####### now print out a fedex label if required
			if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
			                $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
    			}

                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
                             $delUsers{$user}->{DELIVERY_ID} == 7 ||
                             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE && !$accompanyLetter)
                        {
			     $fedexManifest .= $API->printFedexLabel($user,1,$affiliateId);
			    
                        }
                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

		##Removed 200 cert rule check
                #if ($certsPrinted > $CERT_THRESHOLD)
                #{
                #    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                #    close $printLog;
                #    Accessory::pReleaseLock($processCourse, $lockFile);
                #    exit;
                #}
            }

            if ($limitedRun)
            {
                ###### decrement the run counter
                --$runCounter;
            }
        }
        close $printLog;
    }
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub AAASeniorsPrint
{

    my ($printUsers)=@_;
    my %delUsers=%$printUsers;
    $processCourse = 'CA';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 4 => 1, 3 => 2, 3 => 3, 1 => 4);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':'AAA_SENIORS';
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':'REG';
    $printType=($affidavit)?'AFFIDAVIT':$printType;

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
                my $certNumber = ($uData->{CERTIFICATE_NUMBER}) ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    my $result = 0;
                    my $printId = 0;
          	    print "user id:  $user    Cert Number:  $certNumber   Name $uData->{FIRST_NAME} $uData->{LAST_NAME}\n";
	            if ($API->isPrintableCourse($uData->{COURSE_ID}))
        	    {
	                my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
        	        if ($certModule ne $lastModule)
                	{
                        	eval("use Certificate::$certModule");
	                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
        	        }

                	my $cert = $certificateArray[$certModule];
                       	$result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId);
            	    }else{
	               ##### the course needs to be printed manually.  For example, CA has to be loaded
	                ##### w/ the indivdual certs
                	$result = $API->MysqlDB::getNextId('contact_id');

	                ###### add the code for the CRM.  It has to be done here
			my $fixedData=Certificate::_generateFixedData($uData);
    			$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
			
            	    }

                    if($result)
                    {
			if(!$affidavit){
                        	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
	                        push @processed, $user;
        	                my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

			 ####### log all of this in the print log, print manifest and STDERR
                	        my $printString = "Printed User:  $user : $certNumber : $name";
                        	print $printLog Settings::getDateTime(), "$printString\n";
	                        print "$printString\n\n";
        	                $printManifest .= "$printString\n\n";
	        	         if(!($uData->{DELIVERY_ID} ==12)){
					my $settings = Settings->new;
					my $officeId=0;  ##### This is for California;
	    				if($uData->{COURSE_STATE} && exists $settings->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
					    $officeId=1;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
					}else{
					    $officeId=2;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
					}
                         	}

	                        ####### now print out a fedex label if required
        	                if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                	                        $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        	}

	                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
        	                     $delUsers{$user}->{DELIVERY_ID} == 7 ||
                	             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE)
                        	{
				     $fedexManifest .= $API->printFedexLabel($user,1,'');
				    
                	        }
			}else{
			         my $WST = time();
			         $API->putCookie($user, {'CO_AFFIDAVIT_PRINTED'=>$WST});
                                 $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                   $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);
			}
                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}

sub DriversEdMaturePrint
{

    my ($printUsers)=@_;
    my %delUsers=%$printUsers;
    $processCourse = 'DRIVERSED';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    if (! $dryRun)
    {
        $manifestIdCaliforniaOffice =   $API->MysqlDB::getNextId('manifest_id');
        $manifestIdTexasOffice      =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 4 => 1, 3 => 2, 3 => 3, 1 => 4);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':'DRIVERSED-MATURE';
    my $certificateCategory=($RUNDUPLICATE)?'DUPL':'REG';
    $printType=($affidavit)?'AFFIDAVIT':$printType;

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
                my $certNumber = ($uData->{CERTIFICATE_NUMBER}) ? $uData->{CERTIFICATE_NUMBER}
                                : $API->getNextCertificateNumber($user);
		$uData->{CERTIFICATE_NUMBER}=$certNumber;

                if ($certNumber)
                {
                    my $result = 0;
                    my $printId = 0;
          	    print "user id:  $user    Cert Number:  $certNumber   Name $uData->{FIRST_NAME} $uData->{LAST_NAME}\n";
	            if ($API->isPrintableCourse($uData->{COURSE_ID}))
        	    {
	                my $certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
        	        if ($certModule ne $lastModule)
                	{
                        	eval("use Certificate::$certModule");
	                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
				$lastModule=$certModule;
        	        }

                	my $cert = $certificateArray[$certModule];
                       	$result=$cert->printCertificate($user, $uData, { PRINTER => 1},$printId,$printerKey,$accompanyLetter,$productId);
            	    }else{
	               ##### the course needs to be printed manually.  For example, CA has to be loaded
	                ##### w/ the indivdual certs
                	$result = $API->MysqlDB::getNextId('contact_id');

	                ###### add the code for the CRM.  It has to be done here
			my $fixedData=Certificate::_generateFixedData($uData);
    			$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
			
            	    }

                    if($result)
                    {
			if(!$affidavit){
                        	$API->putUserPrintRecord($user, $certNumber, 'PRINT');
	                        push @processed, $user;
        	                my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

			 ####### log all of this in the print log, print manifest and STDERR
                	        my $printString = "Printed User:  $user : $certNumber : $name";
                        	print $printLog Settings::getDateTime(), "$printString\n";
	                        print "$printString\n\n";
        	                $printManifest .= "$printString\n\n";
	        	         if(!($uData->{DELIVERY_ID} ==12)){
					my $settings = Settings->new;
					my $officeId=0;  ##### This is for California;
	    				if($uData->{COURSE_STATE} && exists $settings->{WEST_COAST_STATES}->{$uData->{COURSE_STATE} }){
					    $officeId=1;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdCaliforniaOffice, $user, $certificateCategory,$officeId);
					}else{
					    $officeId=2;
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestIdTexasOffice, $user, $certificateCategory,$officeId);
					}
                         	}

	                        ####### now print out a fedex label if required
        	                if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                	                        $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        	}

	                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
        	                     $delUsers{$user}->{DELIVERY_ID} == 7 ||
                	             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE)
                        	{
				     $fedexManifest .= $API->printFedexLabel($user,1,'');
				    
                	        }
				if (($delUsers{$user}->{DELIVERY_ID} == 22 || $delUsers{$user}->{DELIVERY_ID} == 23)  && !$RUNDUPLICATE && !$accompanyLetter)
	                        {
        	                     $fedexManifest .= $API->printUSPSLabel($user,1);

                	        }
				if(!($uData->{COURSE_ID} && $uData->{COURSE_ID} eq 'C0000055')){
					$driversEdDataUpdate .= $API->updateDriveredData($user);
				}
			}else{
			         my $WST = time();
			         $API->putCookie($user, {'CO_AFFIDAVIT_PRINTED'=>$WST});
                                 $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                   $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);
			}
                    }
                    else
                    {
                        print "$user:  Invalid certificate returned - Not Printed\n";
                    }

                }else{
                        print "$user:  Invalid certificate Nos. - Not Printed\n";
		}

                $certsPrinted++;

                if ($certsPrinted > $CERT_THRESHOLD)
                {
                    print "\nMaximum Certificate Printing Threshold Reached:  $certsPrinted\nExiting....";
                    close $printLog;
                    Accessory::pReleaseLock($processCourse, $lockFile);
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
    Accessory::pReleaseLock($processCourse, $lockFile);
}


