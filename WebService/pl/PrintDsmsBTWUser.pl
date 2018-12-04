#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrinterDSMSBTW')
    -> handle;

package IDSPrinterDSMSBTW;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::DSMSBTW;
use Certificate::PDF;
use MysqlDB;
use Data::Dumper;
use PDF::Reuse;

use strict;
no strict "refs";


sub new
{
    my $self = shift;
    my $class = ref($self) || $self;
    bless {} => $class;
}

sub printUser {
	my $self = shift;
	my ($userId, $certNumber, $pId, $printerKey) = @_;

	my $API =Printing::DSMSBTW->new;
	$API->{PRODUCT}='DSMS';
	$API->{USERID}=$userId;
	$API->constructor;
	my $global= Settings->new;
	$global->{PRODUCT}='DSMSBTW';
	$global->{PRODUCT_CON}=$API->{PRODUCT_CON};
	$global->{CRM_CON}=$API->{CRM_CON};

	$printerKey = ($printerKey) ? $printerKey : 'CA';
	$pId        = ($pId) ? $pId : 0;

	my $userData = $API->getUserData($userId);
	$userData->{CERTIFICATE_NUMBER}=$certNumber;
	my $deliveryId = $userData->{DELIVERY_ID};
	my $airbillNumber = $userData->{AIRBILL_NUMBER};
	my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	eval("use Certificate::$certModule");
	my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});

	## We have not received any communication, feedback for reprinting the certificates and their charges,
	## the complete functionality is not being updated to us, so the re-printing the certificate will not come into picture now for DSMS
	######## let's do a quick check for a dupliate request
	######## if there is a duplicate request, we'll substitute any data

    	if ($userData->{PRINT_DATE}) {
		##### we're checking against print date as there will never be a request for
		##### a duplicate unless the user has already printed

	        ##### now, get the last bit of information for this user.  Take all data entries
        	##### from the user cert duplicate data tables
	        my $duplicateId = $API->getUserCertDuplicateId($userId);
        	my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId,1);
	        foreach my $dataKey(keys %{$userDupData->{DATA}}) {
	            ###### ... and send these off to the printer
        	    if($userDupData->{DATA}->{$dataKey}){
                	$userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
	            }
        	    if($userDupData->{$dataKey} && $userDupData->{DATA}->{$dataKey} && ($userDupData->{$dataKey} ne $userDupData->{DATA}->{$dataKey})){
                	$userData->{$dataKey} = $userDupData->{$dataKey};
	            }
        	}
	    }

	#For BTW User
	if (!$API->isPrintableCourse($userData->{COURSE_ID})) {
		my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
		eval("use Certificate::$certModule");
		my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
		#### this is a temporary hack just so I can id a CA course
		#### this issue will be fixed soon
		$pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,33);


		##Print the label
		$cert->printCADSMSLabel($userId,$userData);



	} else {

    	if ($userData->{PRINT_DATE}) {
	        ##### we're checking against print date as there will never be a request for
        	##### a duplicate unless the user has already printed

	        ##### now, get the last bit of information for this user.  Take all data entries
        	##### from the user cert duplicate data tables
		my $duplicateId = $API->getUserCertDuplicateId($userId);
        	my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
	        foreach my $dataKey(keys %{$userDupData->{DATA}})
        	{
	            ###### ... and send these off to the printer
		    if($userDupData->{DATA}->{$dataKey}){ 
        	    	$userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
		    }
		    if($userDupData->{$dataKey} && $userDupData->{DATA}->{$dataKey} && ($userDupData->{$dataKey} ne $userDupData->{DATA}->{$dataKey})){
        	    	$userData->{$dataKey} = $userDupData->{$dataKey};
	            }		     
        	}
	}

	##### ok, let's load up the @args array w/ the params to send into the
	##### print function
 	$certNumber = ($certNumber) ? $certNumber : $userData->{CERTIFICATE_NUMBER_ISSUED};
	if(!$certNumber) {
		$certNumber = $API->getNextCertificateNumber($userId);
	}

	$userData->{CERTIFICATE_NUMBER} = $certNumber;
	$userData->{EDUCATOR_ID} = $API->getInstructorCode($userId);
        $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,10);
	if($pId) {
		$API->putUserPrintRecord($userId, $certNumber, 'PRINT');
	}
	if($deliveryId && $deliveryId == 101 && !$airbillNumber) {
		##Print the lable for - OVERNIGHT AFTERNOON
		my $dsSchoolId = "$userData->{DS_SCHOOL_ID}:$userData->{CLASS_ID}"; 
		my $retval = $API->printFedexLabel($dsSchoolId,1,'');
	} 
    	return $pId;

	}
	return 1;
}

sub printBlankPage
{
        my $self = shift;

        use Certificate::NewYork;
        my $blankCert = Certificate::NewYork->new;
        $blankCert->printBlankCertificateForDSMS();
	return 1;
}

sub printDSMSUsers {
	my $API =Printing::DSMS->new;
	$API->{PRODUCT}='DSMS';
	$API->constructor;
	my $global= Settings->new;
	$global->{PRODUCT}='DSMS';
	$global->{PRODUCT_CON}=$API->{PRODUCT_CON};
	$global->{CRM_CON}=$API->{CRM_CON};
	my $self = shift;
	my ($classId) = @_;
	my $printerKey =  'TX';
	my $pId   = 0;

	my $classStudents  = $API->getClassStudents($classId);
	my $schoolId= '';
	my $deliveryId=$API->getDeliveryId($classId);
	my $classInfo = $API->getClassInfo($classId);
	$schoolId = $classInfo->{DS_SCHOOL_ID};	
	foreach my $userId(sort keys %$classStudents) {
		my $userData = $API->getUserData($userId);
		#$deliveryId = $userData->{DELIVERY_ID};
		#$schoolId=$userData->{DS_SCHOOL_ID};
		my $airbillNumber = $userData->{AIRBILL_NUMBER};
		my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
		eval("use Certificate::$certModule");
		my $cert = ("Certificate::$certModule")->new;

		## We have not received any communication, feedback for reprinting the certificates and their charges,
		## the complete functionality is not being updated to us, so the re-printing the certificate will not come into picture now for DSMS
		######## let's do a quick check for a dupliate request
		######## if there is a duplicate request, we'll substitute any data
		if ($userData->{PRINT_DATE}) {
			##### we're checking against print date as there will never be a request for
			##### a duplicate unless the user has already printed
			##### now, get the last bit of information for this user.  Take all data entries
			##### from the user cert duplicate data tables
			my $duplicateId = $API->getUserCertDuplicateId($userId);
			my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
			foreach my $dataKey(keys %{$userDupData->{DATA}}) {
				###### ... and send these off to the printer
				if($userDupData->{DATA}->{$dataKey}){ 
					$userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
				}
				if($userDupData->{$dataKey} && $userDupData->{DATA}->{$dataKey} && ($userDupData->{$dataKey} ne $userDupData->{DATA}->{$dataKey})){
					$userData->{$dataKey} = $userDupData->{$dataKey};
				}		     
			}
		}

		##### ok, let's load up the @args array w/ the params to send into the
		##### print function
		my $certNumber = $API->getNextCertificateNumber($userId);

		$userData->{CERTIFICATE_NUMBER} = $certNumber;
		$userData->{EDUCATOR_ID} = $API->getInstructorCode($userId);
		$pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,10);
		if($pId) {
			$API->putUserPrintRecord($userId, $certNumber, 'PRINT');
		}

	}

	if($deliveryId && $deliveryId == 101) {
		##Print the lable for - OVERNIGHT AFTERNOON
		my $dsSchoolId = "$schoolId:$classId"; 
		my $retval = $API->printFedexLabel($dsSchoolId,1,'');
	} elsif($deliveryId && $deliveryId == 2) {
		##Print the table on white paper for school/DA for regular mail
		my $shippingInfo = $API->getUserShipping($schoolId);
		use Certificate::NewYork;
		my $cert = Certificate::NewYork->new;
		my $clasStudentsCount = $API->getNYClassStudentsCount($classId);
		$cert->printDSMSRegulatorMailLabel($classId, $shippingInfo, $clasStudentsCount);
		$API->putClassAirbillInfo($classId);
	}
	return 1;
}

sub printCOACerts {
	my $self = shift;
	my ($schoolId, $instructorId) = @_;
	my $API =Printing::DSMS->new;
        $API->{PRODUCT}='DSMS';
        $API->constructor;
	my $schoolInfo = $API->TCdbGetDrivingSchoolDetails($schoolId);
        my $school_name = $schoolInfo->{SCHOOL_NAME};
	my $school_ownername = $schoolInfo->{OWNER_FIRST_NAME}." ".$schoolInfo->{OWNER_LAST_NAME};
	my $school_code = $schoolInfo->{SCHOOL_CODE};
	my $school_startdate = $schoolInfo->{DATE_CREATED_FORMAT};
	my $school_address1 = $schoolInfo->{ADDRESS_1};
	my $school_address2 = $schoolInfo->{ADDRESS_2};
	my $school_city = $schoolInfo->{CITY};
	my $school_state = $schoolInfo->{STATE};
	my $school_zip = $schoolInfo->{ZIP};
        my $pdfSchoolFileName = "/ids/tools/PRINTING/templates/printing/DSMS_COA_School.pdf";
        my $pdfFileName = "";
	if(-e $pdfSchoolFileName) {
		$pdfFileName = "/tmp/COA_School_$schoolId.pdf";
		prFile($pdfFileName);
		prFont('Helvetica-Bold');
		prFontSize(11);
		prText(20, 575, $school_name);
		prText(20, 560, $school_address1);
		prText(20, 545, "$school_city $school_state, $school_zip");
		prFont('Helvetica');
		prText(210, 240, $school_name);
		prText(460, 240, $school_code);
		prText(350, 151, $school_startdate);
		prDoc( { file  => $pdfSchoolFileName,});
		prEnd();
	}

	use Certificate::NewYork;
        my $COACert = Certificate::NewYork->new;
	if (-e $pdfFileName) {	
        	$COACert->prinCOAForDSMS($pdfFileName);
		unlink ($pdfFileName);
	}

	my @instructorIds = split(/\,/, $instructorId);	
	my $k = 0;
	foreach (@instructorIds) {
		my $insId = $instructorIds[$k];
		my $pdfInstructorFileName = "/ids/tools/PRINTING/templates/printing/DSMS_COA_Instructor.pdf";
                my $pdfFile = ""; 
		my $insInfo = $API->TCdbGetInstructorDetails($insId);
		my $ins_name = $insInfo->{FIRST_NAME}." ".$insInfo->{LAST_NAME};
		my $ins_code = $insInfo->{INSTRUCTOR_CODE};
		my $ins_startdate = $insInfo->{START_DATE};
		my $ins_enddate = $insInfo->{EXPIRE_DATE};
		my $ins_address1 = $insInfo->{ADDRESS_1};
		my $ins_city = $insInfo->{CITY};
		my $ins_state = $insInfo->{STATE};
		my $ins_zip = $insInfo->{ZIP};

        	if(-e $pdfInstructorFileName) {
                	$pdfFile = "/tmp/COA_Instructor_$insId.pdf";
	                prFile($pdfFile);
        	        prFont('Helvetica-Bold');
                	prFontSize(11);
	                prText(20, 575, $ins_name);
        	        prText(20, 560, $ins_address1);
                	prText(20, 545, "$ins_city $ins_state, $ins_zip");
	                prFont('Helvetica');
        	        prText(250, 237, "$ins_name # $ins_code");
                	prText(340, 137, $ins_enddate);
        	        prDoc( { file  => $pdfInstructorFileName,});
        		prEnd();
	        }
		if(-e $pdfFile) {
                        $COACert->prinCOAForDSMS($pdfFile);
                        unlink ($pdfFile);
                }
		$k++;
	}
	return 1;
}

sub printFedexUserLabel
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::DSMSBTW;
    my $API =Printing::DSMSBTW->new;
    $API->{PRODUCT}='DSMS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub emailBTWUserAdultCertificate
{
    my $self = shift;
    my ($userId, $certNumber, $emailAddress) = @_;
    my $API =Printing::DSMSBTW->new;
    $API->{PRODUCT}='DSMS';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DSMSBTW';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $pId        =  0;
    my $printerKey='CA';
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=($certNumber)?$certNumber:$userData->{CERTIFICATE_NUMBER};
    $emailAddress=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    $certModule = 'CAAdultDSMS';
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});

    $userData->{DELIVERY_ID}=12;  #####Since Certificate delivery by Email, set the delivery id as 12

    ######## let's do a quick check for a dupliate request
    ######## if there is a duplicate request, we'll substitute any data
    if ($userData->{PRINT_DATE})
    {
        ##### we're checking against print date as there will never be a request for
        ##### a duplicate unless the user has already printed

        ##### now, get the last bit of information for this user.  Take all data entries
        ##### from the user cert duplicate data tables
        my $duplicateId = $API->getUserCertDuplicateId($userId);
        my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);

        foreach my $dataKey(keys %{$userDupData->{DATA}})
        {
            ###### ... and send these off to the printer
            $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
        }
    }

            ##### ok, let's load up the @args array w/ the params to send into the
            ##### print function
           $pId=$cert->printCertificate($userId, $userData, { EMAIL => $emailAddress },$pId,$printerKey,0,33);

    return $pId;
}



######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
#my $idsPrint = IDSPrinterDSMSBTW->new;
#print Dumper($idsPrint->emailBTWUserAdultCertificate(1173520,'621:1173520','rajesh@google.com'));
#print Dumper($idsPrint->printFedexUserLabel(1134054));
#print Dumper($idsPrint->printUser(1135818));
#print Dumper($idsPrint->printCOACerts(11, 106055));
#print Dumper($idsPrint->printDSMSUsers(949));

