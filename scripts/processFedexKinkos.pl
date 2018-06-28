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


    -s state        run a single state only.  Use the two-letter state abbreviation or FLEET for
                    fleet certs


    -c courseId     Run a perticular Course Id

    -d del mode     delivery Mode(Email,Fax,Print)


    -K product      Product


OUT
    exit;
}


$onlyFedex = 1;

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
    }elsif (uc($opts{s}) eq 'NONTX'){
	$state = 'FK';
    }else
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

if($opts{R})
{
        #### Run Duplicates
    print "Running Duplicates\n";
        $RUNDUPLICATE=1;
}

$processCourse = $opts{c};

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

$users =  $API->getCompleteUsers(\%hashProcessCourse);

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
    if($userData->{DRIVERS_LICENSE} =~ m/TEST/gi || ($address =~ /pobox/gi || $address =~ /postofficebox/gi)){
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
        if((exists $self->{TEXASPRINTING}->{$self->{PRODUCT}}->{$courseId} || $userData->{COURSE_STATE} eq 'TX') && ! $accompanyLetter && !$runSTC & !$affidavit)
        {
            ######## we're dealing w/ Texas printing right now
                                $txUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                                $txUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
                                $txUsers{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
                                $txUsers{$uid}->{USER_DATA}    = $userData;
        }elsif(exists $self->{FEDEXKINKOS}->{$self->{PRODUCT}}->{NONTX}->{$userData->{COURSE_STATE}} && ! $accompanyLetter && !$runSTC & !$affidavit && !$userData->{STC_USER_ID}){
		###### Non TX printing
		$caUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
                $caUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
                $caUsers{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
                $caUsers{$uid}->{USER_DATA}    = $userData;

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

sub TXPrint
{
    my %delUsers=@_;
    $processCourse = '1003';
    $processOnCourse = '1001';
    my $CERTSPRINTED = 0;
    my $CERTSTOPRINT = 1000;
    if ($opts{c})
    {
        if (exists $self->{TEXASPRINTING}->{$self->{PRODUCT}}->{$opts{c}} || $opts{c} == 1012)
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
    my $time = time();
    my ($day,$mon,$year) = (localtime($time))[3,4,5];
    $year +=1900;
    $mon = $mon+1;
    $mon = ($mon<10)?"0".$mon:$mon;
    $day = ($day<10)?"0".$day:$day;
    my $todayDate = "$year-$mon-$day";
    my $labelPdf = "Cert_Label_".$todayDate."_$manifestId".".pdf";

    my $certUsers;
    my $labelPdfUsers;


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
                    Settings::pSendMail(['supportmanager@IDriveSafely.com', 'dev@IDriveSafely.com'], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "Texas Print Job - $processCourse:  Daily Process Error on $SERVER_NAME", "Less than $CERT_THRESHOLD certificates remaining for $processCourse...\n");
                    last;
                }
                else
                {
			if($delUsers{$user}->{DELIVERY_ID} == 2 || $delUsers{$user}->{DELIVERY_ID} == 7 || $delUsers{$user}->{DELIVERY_ID} == 11){
        	                $fedexManifest .= $API->printFedexLabel($user,1,'TX','',$labelPdf);
				my $shippingData = $API->getUserShipping($user);
		                my $trackingNumber = $shippingData->{AIRBILL_NUMBER};
				if(!(-e "$printerSite::SITE_PNG_PATH/$trackingNumber.jpg")){
				    Settings::pSendMail('printmonitor@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "FedEx Manifest at: " . Settings::getDateTime() . " - $SERVER_NAME", "\nUSERID : $user\n--------------------------------------------------------------------------\n\t No tracking Number jpg found\n");
				}
				if(!$trackingNumber || !(-e "$printerSite::SITE_PNG_PATH/$trackingNumber.jpg")){
					next;
				}
                	        $labelPdfUsers->{$user} = $user;
	                }
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
			$result=$cert->printCertificate($user, $uData, { FILE => 1 },$printId,$printerKey,0,$productId);

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
                            Settings::pSendMail('dev@IDriveSafely.com', 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', 'TX CERTIFICATE PROBLEM', "Cert: $certNumber possibly unused");
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
    }            
            if ($limitedRun)
            {
                ###### decrement the run counter
                --$runCounter;
            }
        }
        close $printLog;
    }
    my @userCount =keys %$labelPdfUsers;
    if(@userCount != 0){
	    my $dir = "$printerSite::SITE_PNG_PATH/FEDEXKINKOS";
	    unless(-d $dir){
    		mkdir $dir or die;
	    }
	    
	    chdir "$dir";
	    mkdir "$todayDate";
	    chdir "$todayDate";
	    mkdir "$manifestId";
	    chdir "$manifestId";
	    my $hidetoolbar = '';
	    my $hidemenubar = '';
	    my $hidewindowui = '';
	    my $fitwindow = '';
	    my $centerwindow = '';
	    my $xwidth = '';
	    my $yheigth = '';
	    my $count = 1;
	    my $deleteUsers;

	    foreach my $userId(%$labelPdfUsers){
		if(!$deleteUsers->{$userId}){
			$certUsers->{$count}=$userId;
	    		prFile("/tmp/label_$userId.pdf",$hidetoolbar,$hidemenubar,$hidewindowui,$fitwindow,$centerwindow,$xwidth,$yheigth);
        		my $shippingData = $API->getUserShipping($userId);
	        	my $trackingNumber = $shippingData->{AIRBILL_NUMBER};
			my $file = "$printerSite::SITE_PNG_PATH/$trackingNumber.jpg";
		        my $info = image_info($file);
	        	my ($width, $height) = dim($info);    # Get the dimensions
		        my $intName = prJpeg("$file",         # Define the image
                	         $width,         # in the document
                        	 $height);

	        	$width=.40*$width*.95;
		        $height=.40*$height*.95;
			prPage();
		        my $str = "q\n";
        		$str   .= "$width 0 0 $height 38 10 cm\n";
	        	$str   .= "/$intName Do\n";
	        	$str   .= "Q\n";
		        prAdd($str);
			prEnd();
	        	$count++;
		}
		$deleteUsers->{$userId} = $userId;
    	    }

	    my $pdf = "Cert_Label_".$todayDate."_$manifestId".".pdf";
	    my $pdfFile = "/tmp/$pdf";
	    prFile($pdfFile);
	    my $pageCount = 1;
	    for(my $i=1;$i<=$count;$i++){
		my $outputFile = "/tmp/$certUsers->{$i}.pdf";
		if(-e $outputFile){
                	prDoc( { file  => $outputFile,});
	                unlink $outputFile;
        	}
		my $file = "/tmp/label_$certUsers->{$i}.pdf";
		if(-e $file){
                        prDoc( { file  => $file,
				 first => 2,
				 last  => 2 });
                        unlink $file;
                }
		if(exists $certUsers->{$i}){
			$API->MysqlDB::dbInsertLabelPageNumber($certUsers->{$i},$manifestId,$pageCount);
		}
		$pageCount = $pageCount+2;
	    }
	    prEnd();
	    system("cp $pdfFile $pdf");
	    system("chmod 777 $pdf");
	    unlink $pdfFile;
	    my $jobId = $API->MysqlDB::getNextId('job_id');
	    $API->MysqlDB::dbInsertFedexDesktopDetails($jobId,$manifestId,$pdf,$pdf,0,'TX');
	}
}

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
    my $time = time();
    my ($day,$mon,$year) = (localtime($time))[3,4,5];
    $year +=1900;
    $mon = $mon+1;
    $mon = ($mon<10)?"0".$mon:$mon;
    $day = ($day<10)?"0".$day:$day;
    my $todayDate = "$year-$mon-$day";
    my $labelPdf = "Cert_Label_".$todayDate."_$manifestId".".pdf";

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
			next;
                    }elsif($accompanyLetter || ($delUsers{$user}->{DELIVERY_ID} && $delUsers{$user}->{DELIVERY_ID} == 12)){
			next;
                    }
                    else
                    {
                        ####### now print out a fedex label if required
                        if(exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}}){
                                        $delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        }

                        if (($delUsers{$user}->{DELIVERY_ID} == 2 ||
                             $delUsers{$user}->{DELIVERY_ID} == 7 ||
                             $delUsers{$user}->{DELIVERY_ID} == 11) && !$RUNDUPLICATE && !$accompanyLetter)
                        {
                             $fedexManifest .= $API->printFedexLabel($user,1,$affiliateId,'',$labelPdf);
			     my $shippingData = $API->getUserShipping($user);
                             my $trackingNumber = $shippingData->{AIRBILL_NUMBER};
			     if(!$trackingNumber || !(-e "$printerSite::SITE_PNG_PATH/$trackingNumber.jpg")){
                                        next;
                             }
                             $labelPdfUsers->{$user} = $user;
                        }
                        $result=$cert->printCertificate($user, $uData, { FILE => 1},$printId,$printerKey,0,$productId,'',$hostedAffRun);
                    }
		    if($result)
                    {
			$API->putUserPrintRecord($user, $certNumber, 'PRINT');
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
	my @userCount =keys %$labelPdfUsers;
    	if(@userCount != 0){
            my $dir = "$printerSite::SITE_PNG_PATH/FEDEXKINKOS";
            unless(-d $dir){
                mkdir $dir or die;
            }

            chdir "$dir";
            mkdir "$todayDate";
            chdir "$todayDate";
            mkdir "$manifestId";
            chdir "$manifestId";
            my $hidetoolbar = '';
            my $hidemenubar = '';
            my $hidewindowui = '';
            my $fitwindow = '';
            my $centerwindow = '';
            my $xwidth = '';
            my $yheigth = '';
            my $count = 1;
            my $deleteUsers;

            foreach my $userId(%$labelPdfUsers){
                if(!$deleteUsers->{$userId}){
                        $certUsers->{$count}=$userId;
                        prFile("/tmp/label_$userId.pdf",$hidetoolbar,$hidemenubar,$hidewindowui,$fitwindow,$centerwindow,$xwidth,$yheigth);
                        my $shippingData = $API->getUserShipping($userId);
                        my $trackingNumber = $shippingData->{AIRBILL_NUMBER};
                        my $file = "$printerSite::SITE_PNG_PATH/$trackingNumber.jpg";
                        my $info = image_info($file);
                        my ($width, $height) = dim($info);    # Get the dimensions
                        my $intName = prJpeg("$file",         # Define the image
                                 $width,         # in the document
                                 $height);

                        $width=.40*$width*.95;
                        $height=.40*$height*.95;
                        prPage();
                        my $str = "q\n";
                        $str   .= "$width 0 0 $height 35 10 cm\n";
                        $str   .= "/$intName Do\n";
                        $str   .= "Q\n";
                        prAdd($str);
                        prEnd();
                        $count++;
                }
                $deleteUsers->{$userId} = $userId;
            }

            my $pdf = "Cert_Label_".$todayDate."_$manifestId".".pdf";
            my $pdfFile = "/tmp/$pdf";
            prFile($pdfFile);
            my $pageCount = 1;
            for(my $i=1;$i<=$count;$i++){
                my $outputFile = "/tmp/$certUsers->{$i}.pdf";
                if(-e $outputFile){
                        prDoc( { file  => $outputFile,});
                        unlink $outputFile;
                }
                my $file = "/tmp/label_$certUsers->{$i}.pdf";
                if(-e $file){
                        prDoc( { file  => $file,
                                 first => 2,
                                 last  => 2 });
                        unlink $file;
                }
                if(exists $certUsers->{$i}){
                        $API->MysqlDB::dbInsertLabelPageNumber($certUsers->{$i},$manifestId,$pageCount);
                }
                $pageCount = $pageCount+2;
            }
            prEnd();
            system("cp $pdfFile $pdf");
            system("chmod 777 $pdf");
            unlink $pdfFile;
            my $jobId = $API->MysqlDB::getNextId('job_id');
            $API->MysqlDB::dbInsertFedexDesktopDetails($jobId,$manifestId,$pdf,$pdf,0,'FK');
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

