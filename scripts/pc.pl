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
getopt('Kpsctfld:', \%opts);
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
#    -d delmod   delivery Mode
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
#    -S          Run STCs
#    -s          Run a single state only
#    -t          Print Mode(Cron Type, Manual Type)

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

    -H              Process Hosted Affiliates

    -D              Perform a dry run.  Will display users who are eligible to print, their course id
                    and their delivery id only.  No printing or updating of accounts will occur

    -E              Display all filtered out users

    -V              Run Affidavit users

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

    -d del mode     delivery Mode(Email,Fax,Print)

    -f fleetId      Run Perticular Fleet Company Identified by Fleet Id

    -R              Run Duplicate

    -S              Run STCs

    -t mode         Print Mode (Cron Type, Manual Type)

    -K product      Product


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
if ($opts{d})
{
        ### Check the delivery Mode;
        my $delMode  = uc $opts{d};
        $deliveryMode = (exists $allDeliveryMode->{$delMode}) ? $delMode : 0;

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


if(!$opts{R} && !$opts{c} && !$opts{s} && !$opts{A} && !$opts{S} && !$opts{f})
{
        $hashProcessCourse{COURSE}= 'ALLCAPRINT'; 
        $opts{c}='ALLCAPRINT';                    ######Print All CA Course ########
}

$processCourse = $opts{c};

##################### let's set up a couple of conditionals to see if we're allowed to print
if ($ping)
{
    ######### ping the printer, see if it's alive.
    if(!Accessory::pPingTest($printers->{$printerKey}->{$type}->{PRINTER_IP}, $processCourse, $printerKey))
    {
        ###### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(12);
        print STDERR Settings::getDateTime(), " - COURSE $processCourse FAILED ON PING TEST\n";
        exit;
    }
}

############### Get a lock file for this particular course
if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
{
    ##### send an alert to the CRM
    $API->MysqlDB::dbInsertAlerts(7);
    exit();
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
        }elsif($affidavit)
	{
                $users  =       $API->getAffidavitUsers();
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

print "Users retrieved.  execution time:  " . int(time - $startTime) . " seconds\n";
print "Number of users retrieved:  " . (keys %$users) . "\n";
$startTime = time;

my %txUsers;
my %teenUsers;
my %matureUsers;
my %caUsers;
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
                                #$userData->{$_} = $userDuplData->{$_};
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
    else
    {
        $userData   =   $API->getUserData($uid);
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

        if (exists $self->{NO_PRINT_COURSE}->{$self->{PRODUCT}}->{$courseId} )
        {
            #### The user is attached to a course that does not print
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
	if($product eq 'DIP' && (($state && $state ne 'NM') || !$state) && $userData->{COURSE_STATE} eq 'NM'){
            ######## user does not exist for the particular state.
            if ($showError)
            {
                print "User ID:  $uid : This script is running for non-NM state only\n";
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
        if($product eq 'TEEN' && $userData->{TO_BE_CHARGE_INSTALLMENT_AMOUNT}){
  		if ($showError)
  	        {
  	        	print "User ID:  $uid : Need to be charge installment amount of \$$userData->{TO_BE_CHARGE_INSTALLMENT_AMOUNT}\n";
                }
                next;
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
	print Dumper($userData);
            if ($RUNDUPLICATE)
            {
                my $duId=$key;
                my $userId = $users->{$duId}->{USER_ID};
                $dupUsersCA{$duId}->{USERID} =                       $userId;
	        $dupUsersCA{$duId}->{DELIVERY_ID} =                  $userDuplData->{DELIVERY_ID};
  	        $dupUsersCA{$duId}->{SHIPPING_ID} =                  $userDuplData->{SHIPPING_ID};      
  	        $dupUsersCA{$duId}->{COURSE_ID} =                    $userData->{COURSE_ID};      
                $dupUsersCA{$duId}->{DATA} =                         $userDuplData->{DATA};
                $dupUsersCA{$duId}->{DATA}->{CERTIFICATE_REPLACED} = $userDuplData->{CERTIFICATE_REPLACED};
                $dupUsersCA{$duId}->{DATA}->{USERID} =               $userDuplData->{CERTIFICATE_REPLACED};
                $dupUsersCA{$duId}->{USER_DATA} =                    $userData;
            }elsif($product eq 'FLEET' && $userData->{ACCOUNT_ID}){
		    my $accountId=$userData->{ACCOUNT_ID};
                    $fleetUsers{$accountId}->{$uid}->{USER_DATA}    = $userData;
                    $fleetUsers{$accountId}->{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $fleetUsers{$accountId}->{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
                    $fleetUsers{$accountId}->{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
            }elsif($product eq 'TEEN'){
                    $teenUsers{$uid}->{USER_DATA}    = $userData;
                    $teenUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $teenUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
            }elsif($product eq 'MATURE'){
                    $matureUsers{$uid}->{USER_DATA}    = $userData;
                    $matureUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                    $matureUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
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
    DuplicatePrint(\%dupUsersCA, 0, $hostedAffRun);
}
if(keys %dupUsersTX)
{
    DuplicatePrint(\%dupUsersTX, 'TX');
}
if(keys %teenUsers)
{
        TeenPrint(\%teenUsers);
}
if(keys %matureUsers)
{
        MaturePrint(\%matureUsers);
}
if(keys %fleetUsers)
{
    FLEETPrint(\%fleetUsers);
}
print "Users Print processed.  execution time:  " . int(time - $startTime) . " seconds\n";
###send mail for date violated users for classroom course
my $violatedusercount = @dateviolationusers;
my @duplicatedluserscount = keys %$duplicatelicenseusers;
my $userlist = "The folllowing users have Completion Date Violation\n";
my $userData;
if(!$dryRun){
	if($violatedusercount>0){
		foreach(@dateviolationusers){
	 	   $userData = $API->getUserData($_);
 		   $userlist .= $_." ".$userData->{FIRST_NAME}." ".$userData->{LAST_NAME}."\n";
 	 	}
	         Settings::pSendMail('printmonitor@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Texas Print Job - $courseId:  User Completion Date Violation",$userlist);
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
			my $msg = MIME::Lite->new(From => 'wecare@idrivesafely.com',
	                    To => "$instructorEmail",
        	            Cc => "wendy\@idrivesafely.com,$managerEmailId,qa\@ed-ventures-online.com",
                	    Subject => 'Invalid Newyork Drivers License',
	                    Type => 'TEXT', Data => $message);
        	        $msg->send;
		}

	}
	if($printManifest)
	{
	    Settings::pSendMail('printmonitor@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Print Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", $printManifest);
	}

	if($fedexManifest)
	{
	    Settings::pSendMail('printmonitor@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "FedEx Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", $fedexManifest);
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
                    }elsif($accompanyLetter || ($delUsers{$user}->{DELIVERY_ID} && $delUsers{$user}->{DELIVERY_ID} == 12)){
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
                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);
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
        $manifestId  =   $API->MysqlDB::getNextId('manifest_id');
    }
    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my %sort = ( 4 => 1, 3 => 2, 3 => 3, 1 => 4);
    my @keys = sort { $sort{$delUsers{$a}->{DELIVERY_ID}} <=> $sort{$delUsers{$b}->{DELIVERY_ID}} } keys %delUsers;
    my $printType=($RUNDUPLICATE)?'DUPLICATE':'TEEN';
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
	            elsif ($API->isPrintableCourse($uData->{COURSE_ID}))
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
			if(exists $self->{RGLPRINTLABELCOURSE}->{$self->{PRODUCT}}->{$delUsers{$user}->{COURSE_ID}} && $delUsers{$user}->{DELIVERY_ID} && $delUsers{$user}->{DELIVERY_ID} == 1 ){
                        	use Certificate::CATeen;
	                        my $cert=Certificate::CATeen->new;
				$cert->printCATeenLabel($user,$uData);
			}
			
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
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);
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
	$manifestId  =   $API->MysqlDB::getNextId('manifest_id');
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
                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $printMode,
                                                $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);


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
	$manifestId  =   $API->MysqlDB::getNextId('manifest_id');
    }

    my @keys = keys %$dupUsers;
    my $printType = "DUPLICATE";
    my $certificateCategory='DUPL';

    print STDERR "num of users to process: " . @keys . " \n";
    if (@keys)
    {
        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_dups" or print STDERR "PRINT LOG ERROR: $!\n";
        print $printLog "Job started at " . Settings::getDateTime() . "\n";

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
                my $certModule = $self->getCertificateModule($self->{PRODUCT},$dupUsers->{$dupId}->{COURSE_ID});

                if ($certModule ne $lastModule)
                {
                        eval("use Certificate::$certModule");
                        $certificateArray[$certModule] = ("Certificate::$certModule")->new;
			$lastModule=$certModule;
                }

                my $cert = $certificateArray[$certModule];

                my $certNumber = $API->getNextCertificateNumber($dupUsers->{$dupId}->{USERID});

                if ($certNumber)
                {
		    $uData->{CERTIFICATE_NUMBER}=$certNumber;
                    my $result = 0;
		    my $printId=0;
	            $result=$cert->printCertificate($userId, $uData, { PRINTER => 1 },$printId,$printerKey,0,$productId,$dupUsers->{$dupId}->{DATA},$hostedAffRun);
                    if($result)
                    {
		        $API->putUserPrintRecord($userId, $certNumber, "DUPLICATE", $dupId);
                        push @processed, $userId;
                        my $name = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";

                        ####### log all of this in the print log, print manifest and STDERR
                        my $printString = "Printed User:  $userId : $certNumber : $name";
                        print $printLog Settings::getDateTime(), "$printString\n";
                        print "$printString\n\n";
                        $printManifest .= "$printString\n\n";

                        ####### add this to the CRM manifest
                        $API->MysqlDB::dbInsertPrintManifest($result,$printType, $printMode,
                                                $jobPrintDate, $productId, $manifestId, $userId, $certificateCategory);
                        sleep 3;
	 		    if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$dupUsers->{$dupId}->{DELIVERY_ID}}){
		                $dupUsers->{$dupId}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$dupUsers->{$dupId}->{DELIVERY_ID}};
    			    }	

                         if($dupUsers->{$dupId}->{DELIVERY_ID} == 2 ||
  	                                     $dupUsers->{$dupId}->{DELIVERY_ID} == 7 ||
  	                                             $dupUsers->{$dupId}->{DELIVERY_ID} == 11)
  	                         {
  	                                my $shippingId = $dupUsers->{$dupId}->{SHIPPING_ID};
					my $reply=$API->pDuplicateFedexLabelPrint($shippingId,$printerKey);
					for(keys %$reply) {
			        	        if($_ eq 'TRACKINGNUMBER') {
                        				$fedexManifest .= "\t$_ : $$reply{$_}\n";
				                } else {
        	                			$fedexManifest .= "--------------------------------------------------------------------------\n";
			                        	$fedexManifest .= "\t$_ : $$reply{$_}\n";
                				}
        				}

  	                         }
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
        close $printLog;
    }
}

sub MaturePrint
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
        $manifestId  =   $API->MysqlDB::getNextId('manifest_id');
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
        	        	            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                	                               $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);
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
            	my $accountDataByUser=$API->getAccountDataByUserId($user);
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
                 if(!(exists $self->{FAXCOURSE}->{$self->{PRODUCT}}->{$$delUsers{$user}->{COURSE_ID}}  || $accompanyLetter || ($uData->{DELIVERY_ID} && $uData->{DELIVERY_ID} ==12))){
                            $API->MysqlDB::dbInsertPrintManifest($result,$printType, $deliveryMode,
                                                $jobPrintDate, $productId, $manifestId, $user, $certificateCategory);
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
	$manifestId  =   $API->MysqlDB::getNextId('manifest_id');
    }


    $printLog = gensym;
    open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_stc" or print STDERR "PRINT LOG ERROR: $!\n";;
    print $printLog "Job started at " . Settings::getDateTime() . "\n";

    processSTC($delUsers);
    Accessory::pReleaseLock($processCourse, $lockFile);

    print "NUM MAIL = $numMail, NUMAIRBILL = $numAirBill, NUMFAX = $numFax\n";
        my $mess = "Please read the attached text file for STC Airbills and Faxes. Thanks.\n";
        my $msg = MIME::Lite->new(
                    From => 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>',
                    To => 'printmonitor@idrivesafely.com',
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

        $msg->send;
    ############################################################################################

    close $printLog;
    if($error_msg)
    {
            my $msg = MIME::Lite->new(From => 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>',
                    To => 'support@idrivesafely.com',
                    Subject => 'Error Daily STC printing: Cannot print Airbill. ',
                    Type => 'TEXT', Data => $error_msg);
            $msg->send;
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
	                Settings::pSendMail(['printmonitor@IDriveSafely.com', 'printmonitor@idrivesafely.com' ], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Daily STC FEDEX EMAIL", " $fedex");
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
                Settings::pSendMail(['printmonitor@IDriveSafely.com', 'printmonitor@idrivesafely.com' ], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Daily STC FEDEX EMAIL", " $fedex");
                Accessory::pReleaseLock($processCourse, $lockFile);
                exit;
        }
        Settings::pSendMail(['printmonitor@IDriveSafely.com', 'printmonitor@idrivesafely.com'], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Daily STC FEDEX EMAIL", " $fedex");
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

	    
            my @printIdArr = $cert->printMultipleCertificate($userIds[0], $userDatas[0],
                                        $printId, $userIds[1], $userDatas[1], $printId, { PRINTER => 1 }, $printerKey, $productId,$hostedAffRun);            
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
                    $API->MysqlDB::dbInsertPrintManifest($printIdArr[$i], $self->{PRODUCT} . 'STC', $printMode, $jobDate,
                                            $productId, $manifestId, $userIds[$i], 'STC');
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


