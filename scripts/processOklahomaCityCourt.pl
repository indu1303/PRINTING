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
use Spreadsheet::WriteExcel;


my $dryRun          = 0;
my @oklahomaProducts = ('DIP','AAADIP');
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
for(@oklahomaProducts){
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


if ($opts{c} && $_ eq 'DIP')
{
	$insuranceUser = 1;
	next;
}

$cnt += 1;
   ####  Get the Product Id
$opts{K} = $_;   
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

####### ASSERT:  No lock file exists and the printer properly passed the ping test.  Let's collect the
####### Required data and start the print job
my @processed = ();
my $users;

$startTime = time;

$users =  $API->getOKUsers(\%hashProcessCourse);

print "Users retrieved.  execution time:  " . int(time - $startTime) . " seconds\n";
print "Number of users retrieved:  " . (keys %$users) . "\n";
$startTime = time;

if($cnt == 1){
	if($insuranceUser == 1){
		$outputFile  = '/tmp/OklahomaInsuranceCompletion.xls';
		$worskSheet = "Oklahoma Insurance Completions";
		$courseName = 'AAA Oklahoma Online Motor Vehicle Crash Prevention Course for Insurance.';
	}else{
		$outputFile  = '/tmp/OklahomaCityCourtCompletion.xls';
		$worskSheet = "Oklahoma City Court Completions";
		$courseName = 'AAA Oklahoma Motor Vehicle Crash Prevention Course';
	}

	### xls generation
	$excelFile   = Spreadsheet::WriteExcel->new($outputFile);
	$worksheet   = $excelFile->add_worksheet("$worskSheet");
	$row         = 1;
	$titleFormat = $excelFile->add_format();
	$titleFormat->set_bold();
	$titleFormat->set_center_across();

	$smallFont = $excelFile->add_format( font => 'Arial', size => 8 );

	$boldFont = $excelFile->add_format( font => 'Arial', size => 8 );
	$boldFont->set_bold();
	$worksheet->write( 0, 2, $courseName, $boldFont );
	$worksheet->write( $row, 1, 'First Name', $boldFont );
	$worksheet->set_column( 0, 0, 10 );
	$worksheet->write( $row, 2, 'Last Name', $boldFont );
	$worksheet->set_column( 0, 0, 10 );
	$worksheet->write( $row, 3, 'DOB', $boldFont );
	$worksheet->set_column( 0, 0, 10 );
	$worksheet->write( $row, 4, 'Email Address', $boldFont );
	$worksheet->set_column( 0, 0, 10 );
	$worksheet->write( $row, 5, 'Phone', $boldFont );
	$worksheet->set_column( 0, 0, 10 );
	$worksheet->write( $row, 6, 'CT', $boldFont );
	$worksheet->set_column( 0, 0, 10 );
	if($insuranceUser == 1){
		$worksheet->write( $row, 7, 'Completion Date', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
		$worksheet->write( $row, 8, 'User Id', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
		$worksheet->write( $row, 9, 'Member', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
		$worksheet->write( $row, 10, 'Membership ID #', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
	}else{
		$worksheet->write( $row, 7, 'Citation #', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
		$worksheet->write( $row, 8, 'Completion Date', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
		$worksheet->write( $row, 9, 'User Id', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
		$worksheet->write( $row, 10, 'Member', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
		$worksheet->write( $row, 11, 'Membership ID #', $boldFont );
		$worksheet->set_column( 0, 0, 10 );
	}

	++$row;
}

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
    if($userData->{DRIVERS_LICENSE} =~ m/TEST/gi || $userData->{EMAIL} =~ m/TEST/gi || $userData->{EMAIL} =~ m/IDRIVESAFELY.COM/gi || $userData->{EMAIL} =~ m/ED-VENTURES-ONLINE.COM/gi || $userData->{EMAIL} =~ m/CONTINUEDED.COM/gi || $userData->{EMAIL} =~ m/PRADHITA.COM/gi){
	next;
    }
    ############ we now have the user data.  Let's start filtering out users who should not print
    ############ based on requirements for that particular state / regulator.

	my $userCitation=$userData->{CITATION};
	my $membershipId=$userCitation->{MEMBERSHIP_ID};
        my $member='N';
        if($membershipId){
		$member='Y';
        }
	my $compDate = $API->getCompletionDate($uid);
	my $aaaInsCall = $userData->{AAA_INS_CALL};
	$aaaInsCall = ($aaaInsCall)?($aaaInsCall):'N';	
        $worksheet->write( $row, 1, $userData->{FIRST_NAME}, $smallFont );
        $worksheet->write( $row, 2, $userData->{LAST_NAME}, $smallFont );
        $worksheet->write( $row, 3, $userData->{DATE_OF_BIRTH}, $smallFont );
        $worksheet->write( $row, 4, $userData->{EMAIL}, $smallFont );
        $worksheet->write( $row, 5, $userData->{PHONE}, $smallFont );
        $worksheet->write( $row, 6, $aaaInsCall, $smallFont );
	if($insuranceUser == 1){
	        $worksheet->write( $row, 7, $compDate, $smallFont );
        	$worksheet->write( $row, 8, $uid, $smallFont );
	        $worksheet->write( $row, 9, $member, $smallFont );
        	$worksheet->write_string( $row, 10, "$membershipId", $smallFont );
	}else{
        	$worksheet->write( $row, 7, $userCitation->{CITATION_NUMBER}, $smallFont );
	        $worksheet->write( $row, 8, $compDate, $smallFont );
        	$worksheet->write( $row, 9, $uid, $smallFont );
	        $worksheet->write( $row, 10, $member, $smallFont );
        	$worksheet->write_string( $row, 11, "$membershipId", $smallFont );
	}

        $row++;
        $totalUsers++;

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
	$caUsers{$uid}->{DELIVERY_ID}  = ($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;
	$caUsers{$uid}->{COURSE_ID}    = $userData->{COURSE_ID};
	$caUsers{$uid}->{REGULATOR_ID} = $userData->{REGULATOR_ID};
	$caUsers{$uid}->{USER_DATA}    = $userData;
}

print "Users processed.  execution time:  " . int(time - $startTime) . " seconds\n";
$startTime = time;
if(keys %caUsers)
{
    CAPrint(\%caUsers,$hostedAffRun);
}
	
print "Users Print processed.  execution time:  " . int(time - $startTime) . " seconds\n";
}### for loop ends here

my @userCount = keys %$certUsers;
if(@userCount != 0){
	my $pdf = ($insuranceUser == 1)?"OklahomaInsurance_".$todayDate.".pdf":"OklahomaCityCourt_".$todayDate.".pdf";
        my $pdfFile = "/tmp/$pdf";
        prFile($pdfFile);
        my $pageCount = 1;
        for (my $i=1; $i<=$count; $i++){
		my $outputFile = "/tmp/$certUsers->{$i}.pdf";
                if (-e $outputFile){
			prDoc( { file  => $outputFile,});
                        unlink $outputFile;
                }
                $pageCount = $pageCount+1;
         }
         prEnd();
         system("cp $pdfFile $pdf");
         system("chmod 777 $pdf");
         unlink $pdfFile;

        $excelFile->close();

	use MIME::Lite;
	my ($subject,$message,$from,$to,$cc,$bcc,$certFile,$reportFile);
       	$from = 'I DRIVE SAFELY <wecare@idrivesafely.com>';

	if($insuranceUser == 1){
		$subject = "Oklahoma Insurance Completion Report - $todayDate";

                $message = 'Attached please find the daily completion report containing all student information and details for the AAA Oklahoma Online Motor Vehicle Crash Prevention Course for Insurance.
	Sincerely,
	I Drive Safely';                             

                $to = 'Danial.Karnes@aaaok.org';
                $cc = 'gus.padilla@idrivesafely.com';
                $bcc = 'idcdr@ed-ventures-online.com';
		$certFile = "OklahomaInsuranceCompletionCertificate ".$todayDate.".pdf";
		$reportFile = "OklahomaInsuranceCompletionReport ".$todayDate.".xls";
	
	}else{
        	$subject = "Oklahoma City Daily Completion Report - $todayDate";

		$message = 'Attached please find the daily completion report containing all student information and details for the AAA Oklahoma  Online Motor Vehicle Crash Prevention Course. Please contact our offices should you have any questions.                             
	Sincerely,
        AAA Oklahoma.';

		$to = 'driving.school@okc.gov';
        	$cc = 'maryann.myers@okc.gov,Danial.Karnes@aaaok.org,Processing@idrivesafely.com,fulfillment@idrivesafely.com';
        	$bcc = 'gus.padilla@idrivesafely.com,idcdr@ed-ventures-online.com';
		$certFile = "OklahomaCityCourtCompletionCertificate ".$todayDate.".pdf";
		$reportFile = "OklahomaCityCourtCompletionReport ".$todayDate.".xls";

	}

        my $Email = MIME::Lite->new(
                                        From => $from,
                                        To => $to,
                                        Cc => $cc,
                                        Bcc => $bcc,
                                        Subject => $subject,
                                        Type => 'multipart/mixed'
                                );
         $Email->attach(
                                Type => 'text/html',
                                Data => $message
                        );
         if($pdf){
                        $Email->attach(
                                        Type    => 'application/pdf',
                                        Path    => $pdf,
                                        Filename => $certFile,
                                        Disposition => 'attachment'
                                );
          }
	  my ($mime_type, $encoding) = ('application/xls', 'base64');
	  if($totalUsers){
        	$Email->attach(
                        Type => $mime_type,
                        Encoding => $encoding,
                        Path     => $outputFile,
                        Filename => $reportFile,
                        Disposition => 'attachment'
                );
	   }
	   $Email->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f wecare@idrivesafely.com');

          unlink($pdf);
}else{
    	if (! $dryRun){
                use MIME::Lite;
		my ($subject,$message,$from,$to,$cc,$bcc);
       	       	$from = 'I DRIVE SAFELY <wecare@idrivesafely.com>';

		if($insuranceUser == 1){
			$subject = "Oklahoma Insurance Completion Report - $todayDate";

	                $message = 'No completions recorded today. 
        Sincerely,
        I Drive Safely';
	
                	$to = 'Danial.Karnes@aaaok.org';
	                $cc = 'gus.padilla@idrivesafely.com';
        	        $bcc = 'idcdr@ed-ventures-online.com';

		}else{
                	$message = 'No completions recorded today.
		Sincerely,                                                                                                                   
		AAA Oklahoma.';
		        $subject = "Oklahoma City Daily Completion Report - $todayDate";
		 	$to = 'driving.school@okc.gov';
                	$cc = 'maryann.myers@okc.gov,Danial.Karnes@aaaok.org,Processing@idrivesafely.com,fulfillment@idrivesafely.com';
                	$bcc = 'gus.padilla@idrivesafely.com,idcdr@ed-ventures-online.com';
		}

                my $Email = MIME::Lite->new(
                                        From => $from,
                                        To => $to,
                                        Cc => $cc,
                                        Bcc => $bcc,
                                        Subject => $subject,
                                        Type => 'multipart/mixed'
                                );
                $Email->attach(
                                Type => 'text/html',
                                Data => $message
                        );
		$Email->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f wecare@idrivesafely.com');
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
    	if (!$printerKey)
    	{
    	    $printerKey = 'CA';
   	}
#    	if (! ($lockFile = Accessory::pAcquireLock($processCourse)))
#    	{
        	##### send an alert to the CRM
#        	$API->MysqlDB::dbInsertAlerts(7);
#        	exit();
#    	}

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
				my $certModule = "Oklahoma";
                		if($delUsers{$user}->{COURSE_ID} == 42004){
                			$certModule = $self->getCertificateModule($self->{PRODUCT},$delUsers{$user}->{COURSE_ID});
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
                    			}
                    			else
                    			{
                        			####### now print out a fedex label if required
                        			if (exists $self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}})
						{
                                        		$delUsers{$user}->{DELIVERY_ID}=$self->{DELIVERYMAP}->{$self->{PRODUCT}}->{$delUsers{$user}->{DELIVERY_ID}};
                        			}
						$uData->{DELIVERY_ID}=1;  ###### This is only for reporting purpose
                        			$result=$cert->printCertificate($user, $uData, { FILE => 1},$printId,$printerKey,0,$productId,'',$hostedAffRun);
                    			}
		    			if($result)
                    			{
						$labelPdfUsers->{$user} = $user;
                        			print "$user:  Certificate File created\n";
                    			}
                    			else
                    			{
                        			print "$user:  Invalid certificate returned - Not Printed\n";
                    			}
                		}
				else
				{
                       			print "$user:  Invalid certificate Nos. - Not Printed\n";
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

	my @userCount = keys %$labelPdfUsers;
    	if(@userCount != 0)
	{
            	my $deleteUsers;

            	foreach my $userId(%$labelPdfUsers)
	    	{
                	if (!$deleteUsers->{$userId})
			{
				$certUsers->{$count}=$userId;
                        	$count++;
                	}
                	$deleteUsers->{$userId} = $userId;
            	}

	}	
}
