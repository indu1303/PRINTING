#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrinter')
    -> handle;

package IDSPrinter;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::DIP;
use Printing::AAADIP;
use Certificate::PDF;
use Certificate::California;
use Certificate::AAA;
use Certificate::Delaware;
use Certificate::Texas;
use Certificate::NewYork;
use Certificate::CertForStudent;
use Certificate::AAADIPCertificate;
use Certificate::Oklahoma;
use Certificate::CAMature;
use Certificate::MatureCertificate;
use MysqlDB;
use Data::Dumper;

use strict;
no strict "refs";

sub new
{
    my $self = shift;
    my $class = ref($self) || $self;
    bless {} => $class;
}

sub printUser
{
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey, $printCheck) = @_;
    $API->{USERID} = $userId;
    $API->constructor;

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);
    my $productId=1;
    if($userData->{SEGMENT_ID_MAP}){
    	$productId=$userData->{SEGMENT_ID_MAP};
    }
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    if($userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA} eq '99'){
    	   return 0;  ################  Not to Print Cert if Cookie is set to 99
    }
    if($printCheck) { $userData->{PRINTCHECK}= 1; }
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID},$userData->{SEGMENT_NAME_MAP});
    my $cert;
    if($userData->{UPSELLEMAIL} || $userData->{UPSELLMAIL} || $userData->{UPSELLMAILFEDEXOVA} ||($userData->{COURSE_STATE} eq 'CA' && !$userData->{SEGMENT_NAME_MAP})){
	    use Certificate::CertForStudent;
    	    $cert = Certificate::CertForStudent->new($userId, $API->{PRODUCT});
    }else{
	if ($userData->{COURSE_STATE} eq 'OK' && $userData->{REGULATOR_ID} == $global->{OKLAHOMA_CITY_COURT})
	{
	    use Certificate::Oklahoma;
    	    $cert = Certificate::Oklahoma->new($userId, $API->{PRODUCT});
	}
	else
	{
    		eval("use Certificate::$certModule");
    		$cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
	}
    }		


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
	   $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,$productId);

           if ($userData->{COURSE_ID} == 200005 || $userData->{COURSE_ID} == 100005 || $userData->{COURSE_ID} == 400005)
    	   {
           	$cert->printCAMatureLabel($userId,$userData);
	   }


    	   return $pId;
}

sub printAccompanyLetter
{
    my $self = shift;
    my ($userId, $email) = @_;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    my $userData = $API->getUserData($userId);
    $userData->{EMAIL} = $email;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});


    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $printId =0;
    my $printCert=$cert;                             
    my $accompanyLetter=1;
    my $productId=1;
    my $printerKey ='CA';
    $printId=$printCert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId);
    return $printId;
}


sub printFaxUser
{
    my $self = shift;
    my ($userId, $certNumber, $printDate, $faxNumber) = @_;

    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $userData = $API->getUserData($userId);


    ###### fax the certificate to the user
    if(exists $global->{FAXCOURSE}->{DIP}->{$userData->{COURSE_ID}})
    {
    my $testCenterId = $API->getUserTestCenter($userId);
    my $testCenter = $API->getTestCenter($testCenterId);
    $faxNumber=($faxNumber)?$faxNumber:$testCenter->{FAX};
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    my $printId=0;
    my $printerKey='CA';
    my $accompanyLetter=0;
    my $productId=1;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    $printId=$cert->printCertificate($userId, $userData, {FAX => $faxNumber},$printId,$printerKey,$accompanyLetter,$productId);
    }elsif($userData->{REGULATOR_ID}==20021){
    my $regContact = $API->getRegulatorShippingAddress($userData->{REGULATOR_ID});
    $faxNumber=($faxNumber)?$faxNumber:$regContact->{FAX};
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    my $pId=0;
    my $pId_1=0;
    my $userData_1;
    my $userId_1;
    my $printerKey='CA';
    my $productId=1;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    $API->putAccompanyLetterUser($userId);
    my @printIdArr = $cert->printMultipleCertificate($userId, $userData, $pId, $userId_1, $userData_1, $pId_1, { FAX => $faxNumber}, $printerKey, 1);
    return @printIdArr;
    } elsif($userData->{RESIDENT_STATE} && $userData->{RESIDENT_STATE} eq 'NONOH') {
	##OH Non Resident - Fax the Certificate
	$faxNumber=($faxNumber)?$faxNumber:$global->{OH_NONRESIDENT_FAXNUMBER};
    	$userData->{CERTIFICATE_NUMBER}=$certNumber;
    	my $printId=0;
    	my $printerKey='CA';
    	my $accompanyLetter=0;
    	my $productId=1;
    	my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    	eval("use Certificate::$certModule");
    	my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    	$printId=$cert->printCertificate($userId, $userData, {FAX => $faxNumber},$printId,$printerKey,$accompanyLetter,$productId);
	return $printId;
    }

}

sub printRefaxUser
{
    my $self = shift;
    my ($userId,$faxNumber,$attention,$certNumber) = @_;

    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    ######## this function will be handled a little differently. We're going to connect and get the
    ######## course id for the user.  Based on the course id, we're going to send it to the
    ######## appropriate printing script
  
    my $userData = $API->getUserData($userId);
    $certNumber = ($certNumber)?$certNumber:$API->getNextCertificateNumber($userId);
    my $printerKey='CA';
    if($userData->{COURSE_ID} == 14 || $userData->{COURSE_ID}==17 || $userData->{COURSE_ID}==27){
	    use Certificate::LosAngeles;
	    my $cert = Certificate::LosAngeles->new($userId,$API->{PRODUCT});
	    my $regContact = $API->getRegulatorShippingAddress($userData->{REGULATOR_ID});
	    $regContact->{FAX}=($faxNumber)?$faxNumber:$regContact->{FAX};
	    $attention=($attention)?$attention:' ';
	    my $courtName=$regContact->{NAME};
	    my $faxNum=$regContact->{FAX};
	    my @toFaxUsers;
	    $userData->{CERTIFICATE_NUMBER}   = $certNumber;
	    my $uHash;
	    $uHash->{USER_ID}=$userId;
	    $uHash->{USER_DATA}=$userData;
	    push (@toFaxUsers, $uHash);
	    my $LACert=Certificate::LosAngeles->new($userId,$API->{PRODUCT});
  	    $LACert->faxLACertificates(\@toFaxUsers, $faxNum, $courtName, 0, 0 );
	    return 1;
   }else{
	    my $pId = 0;
	    $userData->{CERTIFICATE_NUMBER}   = $certNumber;
	    $userData->{FAX}=($faxNumber)?$faxNumber:$userData->{FAX};
	    $attention=($attention)?$attention:' ';
	    $userData->{ATTENTION}=$attention;
	    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	    my $cert;
	    if($userData->{UPSELLEMAIL} || $userData->{UPSELLMAIL} || $userData->{COURSE_STATE} eq 'CA'){
		use Certificate::CertForStudent;
		$cert = Certificate::CertForStudent->new($userId, $API->{PRODUCT});
	    } else {
	    	eval("use Certificate::$certModule");
	    	$cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
	    }
            $pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,1);
	    return $pId;

	
   }

}

sub printMultiSTCUser
{
    my $self = shift;
    my ($userId, $certNumber, $pId,$userId_1, $certNumber_1, $pId_1, $printerKey) = @_;

    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    $pId_1        = ($pId_1) ? $pId_1 : 0;
    my $stc     = 1;

    my $userData    = $API->getUserData($userId);
    my $userData_1  = $API->getUserData($userId_1);
    $userData->{CERTIFICATE_NUMBER} = $certNumber;
    $userData_1->{CERTIFICATE_NUMBER} = $certNumber_1;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData_1->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    my @printIdArr = $cert->printMultipleCertificate($userId, $userData, $pId, $userId_1, $userData_1, $pId_1, { PRINTER => 1 }, $printerKey, 1);

    return join ('~',@printIdArr);
    
}

sub printUserReport
{
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    use Report::UserStateReport;
    my $self = shift;
    my ($userId, $state, $reportDate, $printerKey, $officeId) = @_;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $userData    = $API->getUserData($userId);
    my $printingState = ($officeId && $officeId==1) ? 'CA' : '';

    my $userContact = $API->getUserContact($userId);
    $userData->{SEX} = $userContact->{SEX};
    my $cert=Report::UserStateReport->new($userId,$API->{PRODUCT});
    my $result = $cert->printStateReport($userId, $userData,{PRINTER => 1},$state, $reportDate, $printerKey, $printingState);

    return $result;
}

sub emailUser
{
    my $self = shift;
    my ($userId, $certNumber,$emailAddress) = @_;

    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
   
    my $userData=$API->getUserData($userId);
    my $pId=0;
    my $printerKey='CA';
    if($userData->{SEGMENT_ID_MAP}){
        $pId=$userData->{SEGMENT_ID_MAP};
    }
    $userData->{CERTIFICATE_NUMBER} = $certNumber;
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
    if($userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA} eq '99'){
    	   return 0;  ################  Not to Print Cert if Cookie is set to 99
    }
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID},$userData->{SEGMENT_NAME_MAP});
    my $cert;
   if($userData->{UPSELLEMAIL} || $userData->{UPSELLMAIL} || ($userData->{COURSE_STATE} eq 'CA' && !$userData->{SEGMENT_NAME_MAP})){
	    use Certificate::CertForStudent;
    	    $cert = Certificate::CertForStudent->new($userId,$API->{PRODUCT});
    }else{
    	eval("use Certificate::$certModule");
    	$cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    }
    $pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,1);
    return $pId;
 
}

sub printTXUser
{
    my $self = shift;
    my ($userId, $certNumber, $printId, $dup, $printerKey) = @_;

    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    ##### set up the printer
    $printerKey = ($printerKey) ? $printerKey : 'TX';
    $printId    = ($printId) ? $printId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
        ######## let's do a quick check for a dupliate request
    ######## if there is a duplicate request, we'll substitute any data
    if ($userData->{PRINT_DATE})
    {
        ##### we're checking against print date as there will never be a request for
        ##### a duplicate unless the user has already printed
                                                                                                                             
        ##### now, get the last bit of information for this user.  Take all data entries
        ##### from the user cert duplicate data tables
        my $duplicateId = $API->getUserCertDuplicateId($userId);
        my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId,1);
	$dup=$userDupData->{DATA};
                                                                                                                             
        foreach my $dataKey(keys %{$userDupData->{DATA}})
        {
            ###### ... and send these off to the printer
            $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
        }
    }
    my $result = 0;
    if ($certNumber)
    {
        my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
        eval("use Certificate::$certModule");
        my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
      ###### run the course on the appropriate certificate
        $result=$cert->printCertificate($userId, $userData, { PRINTER => 1  },$printId,$printerKey,0,1,$dup);

    }
    
    return $result;
}

sub printNewYorkUser
{
    my $self = shift;
    my ($certNumber, $agencyId, $instructorId, $locationId, $studentId, $dl, $completionDate,
        $first, $last, $address, $city, $state, $zip, $today) = @_;

    use Certificate::NY;
    my $nyHandle = Certificate::NY->new;
    return $nyHandle->generateCertificate(  -first              => $first, 
                                            -last               => $last, 
                                            -address            => $address, 
                                            -city               => $city,
                                            -state              => $state,
                                            -zipcode            => $zip,
                                            -agency_no          => $agencyId,
                                            -location_id        => $locationId,
                                            -license_no         => $dl,
                                            -instructor_no      => $instructorId,
                                            -completion_date    => $completionDate,
                                            -certificate        => $certNumber,
                                            -student_id         => $studentId,
                                            -certificate_no     => $certNumber,
                                            -today              => $today);
}

sub printUserDPSAppForm
{
    my $self = shift;
    my ($userId,$printerKey) = @_;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $userData=$API->getDPSInformation($userId);
    my $pId=0;
    $printerKey=(!$printerKey)?'CA':$printerKey;
    use DriverRecord::DPS;
    my $cert = DriverRecord::DPS->new($userId, $API->{PRODUCT});
    $pId=$cert->printDRAppForm($userId, $userData, { PRINTER => 1 },$printerKey);
    return $pId;

}

sub printNonTXDriverRecord
{
    my $self = shift;
    my ($userId,$printerKey) = @_;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $userData=$API->getDPSInformation($userId);
    my $pId=0;
    $printerKey=(!$printerKey)?'CA':$printerKey;
    use DriverRecord::DPS;
    my $cert = DriverRecord::DPS->new($userId, $API->{PRODUCT});
    $pId=$cert->_generateNonTXDriverRecord($userId, $userData);
    if(!$userData->{DELIVERY_ID} || ($userData->{DELIVERY_ID} && ($userData->{DELIVERY_ID} == 1 || $userData->{DELIVERY_ID} == 16))){
	    $cert->printDRLabel($userId,$userData);
    }
    return $pId;
}

sub printASIUser
{
    my $self = shift;
    my ($userId) = @_;

    my $cmd = "perl /ids/tools/PRINTING/scripts/tools/processASI.pl $userId";
    qx/$cmd/;

    return 1;
}

sub submitCTSIUserData
{
    my $self = shift;
    my ($userId, $providerId, $providerKey, $providerUrl, $productId) = @_;

    my $cmd = "perl /ids/tools/PRINTING/scripts/tools/processSubmitCTSIUserData.pl $userId $providerId $providerKey $providerUrl $productId";
    my $message = qx/$cmd/;
    my ($error, $comm) = split(/\:/, $message);
    my $request = Settings->new;
    if($error){
	    if(exists $request->{CTSI_SUBMISSION_ERRORS}->{$error}){
		    $message = "$error:$request->{CTSI_SUBMISSION_ERRORS}->{$error}";
	    }	    
    }
    return $message;
}

sub printUserDuplicateFedexLabel
{
	my $self = shift;
	my ($userId,$duplicateId) = @_;

	use Printing::DIP;
	my $API =Printing::DIP->new;
	$API->{PRODUCT}='DIP';
	$API->{USERID}=$userId;
	$API->constructor;

	my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
	my $shippingId = $userDupData->{SHIPPING_ID};
	my $retval = $API->pDuplicateFedexLabelPrint($shippingId);

	return $retval;
}

sub printAAADIPUser
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey,$dupId) = @_;

    my $API =Printing::AAADIP->new;
    $API->{PRODUCT}='AAADIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AAADIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    $dupId      = ($dupId)? $dupId :0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    ######## let's do a quick check for a dupliate request
    ######## if there is a duplicate request, we'll substitute any data
    if ($userData->{PRINT_DATE})
    {
        ##### we're checking against print date as there will never be a request for
        ##### a duplicate unless the user has already printed

        ##### now, get the last bit of information for this user.  Take all data entries
        ##### from the user cert duplicate data tables
	my $duplicateId = $API->getUserCertDuplicateId($userId);
	$duplicateId=($dupId)?$dupId:$duplicateId; 
        my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);

        foreach my $dataKey(keys %{$userDupData->{DATA}})
        {
            ###### ... and send these off to the printer
            $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
        }
    }

	    ##### ok, let's load up the @args array w/ the params to send into the
	    ##### print function
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,21,'','AAADIP');

    return $pId;
}

sub printOrderForm
{
	my $API = Printing::DIP->new;
    	$API->{PRODUCT}='DIP';
    	$API->constructor;
    	my $global= Settings->new;
    	$global->{PRODUCT}='DIP';
    	$global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    	$global->{CRM_CON}=$API->{CRM_CON};
	my $WST = time();
	my $CURYEAR = ((localtime($WST))[5]) + 1900;
	my $DATE = ((localtime($WST))[3]);
	my $MONTH = ((localtime($WST))[4]) + 1;
	my $x= "$MONTH/$DATE/$CURYEAR";
    	my $self = shift;
    	my ($itemId, $orderId, $pId, $printerKey) = @_;

    	$printerKey = ($printerKey) ? $printerKey : 'CA';
    	$pId        = ($pId) ? $pId : 0;

    	my $userData = $API->getItemOrderDetails($itemId, $orderId);
	if ($userData->{ITEMS_PER_PACKAGE} > 0 && $userData->{PACKAGES_PER_BOX} > 0)
	{
		$userData->{ORDERED_STOCK} = ($userData->{QUANTITY} * $userData->{PACKAGES_PER_BOX} * $userData->{ITEMS_PER_PACKAGE});
	}
	elsif ($userData->{PACKAGES_PER_BOX} == 0 &&  $userData->{ITEMS_PER_PACKAGE} > 0)
	{
		$userData->{ORDERED_STOCK} = ($userData->{QUANTITY} * $userData->{ITEMS_PER_PACKAGE});
	}
	elsif ($userData->{PACKAGES_PER_BOX} == 0 && $userData->{ITEMS_PER_PACKAGE} == 0)
	{
		$userData->{ORDERED_STOCK} = ($userData->{QUANTITY});
	}

	my $doc='';
	open (IN, "<$global->{TEMPLATESPATH}/printing/$userData->{ORDER_TEMPLATE}");
	foreach my $line(readline(*IN))
	{
	        $line =~ s/\[!IDS::NAME!\]/$userData->{ITEM_NAME}/g;
	        $line =~ s/\[!IDS::VENDORNAME!\]/$userData->{VENDOR_NAME}/g;
	        $line =~ s/\[!IDS::ORDEREDSTOCK!\]/$userData->{ORDERED_STOCK}/g;
	        $line =~ s/\[!IDS::COSTPERITEM!\]/\$$userData->{COST_PER_ITEM}/g;
	        $line =~ s/\[!IDS::TOTALCOST!\]/\$$userData->{TOTAL_COST}/g;
	        $line =~ s/\[!IDS::ORDEREDDATE!\]/$userData->{ORDER_DATE}/g;
	        $line =~ s/\[!IDS::CURDATE!\]/$x/g;
	        $doc .= $line;
	}
	my $data = $doc;
	my $htmlFileName="/tmp/Order_$orderId.html";
	open W ,">$htmlFileName" || die "unable to write to file \n";
	print W $data;
	close W;

	my $pdfFileName="/tmp/Order_$orderId.pdf";
	##### convert this file to PDF
	my $cmd = <<CMD;
		/usr/bin/htmldoc -f $pdfFileName --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 $htmlFileName
CMD
	$ENV{TMPDIR}='/tmp/';
	$ENV{HTMLDOC_NOCGI}=1;
	system($cmd);
	if (-e $htmlFileName)
	{
		unlink ($htmlFileName);
	}

	## Print Order Form ##
	my $printer = "HP-PDF-HOU01";
	if (-e $pdfFileName)
	{
            system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=Tray4 $pdfFileName");
	}
	if (-e $pdfFileName)
	{
		unlink($pdfFileName);
    		return 1;
	}
    	return 0;
}

sub printCRMReport
{
	my $self = shift;
	my ($fileName, $path, $state, $filePath) = @_;
    	my $global= Settings->new;
    	$global->{PRODUCT}='DIP';

	use LWP::Simple;	
	my $reportUrl="$global->{CRMURL}->{NEW}/$path/$fileName";
	my $retVal=0;
	if($filePath) {
		my $file = get($filePath);
		if($file) {
			my $printReport = "/tmp/NV-DIP.pdf";
	                open(FILE, ">$printReport") || die "$printReport: $!";
        	        print FILE $file;
                	close FILE;
		
			my $printer='HP-PDF';
			if ($state eq 'TX') {
				$printer='HP-PDF-HOU01';
			}
			if (-e $printReport) {
				system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=Tray4 $printReport");
				$retVal=1;
			}
			## File Printed ##
			if (-e $printReport) {
				unlink($printReport);
			}
		}   
		##Received the file, 
	} else {
	my $file = get($reportUrl);
	if ($file) {
		my $printReport = "/tmp/printReport.pdf";
		open(FILE, ">/tmp/$fileName") || die "$fileName: $!";
          	print FILE $file;
          	close FILE;		
		my $filePrint = "/tmp/$fileName";
		my $cmd = <<CMD;
/usr/bin/htmldoc -f $printReport --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 --landscape --size letter $filePrint
CMD
         	$ENV{TMPDIR}='/tmp/';
         	$ENV{HTMLDOC_NOCGI}=1;
         	system($cmd);	
		my $printer='HP-PDF';
		if ($state eq 'TX')
		{
			$printer='HP-PDF-HOU01';
		}
		if (-e $printReport)
		{
			system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=Tray4 --landscape $printReport");
			$retVal=1;
		}
		## File Printed ##
		if (-e $printReport)
		{
			unlink($printReport);
			unlink($filePrint);
		}
	}
	}
	return $retVal;
}

sub printCRMAARPReport
{
        my $self = shift;
        my ($fileName, $path, $state) = @_;
        my $global= Settings->new;
        $global->{PRODUCT}='DIP';

        use LWP::Simple;
        my $reportUrl="$global->{CRMURL}->{NEW}/$path/$fileName";
        my $file = get($reportUrl);
        my $retVal=0;
        if ($file)
        {
                my $printReport = "/tmp/printReport.pdf";
                open(FILE, ">/tmp/$fileName") || die "$fileName: $!";
                print FILE $file;
                close FILE;
                my $filePrint = "/tmp/$fileName";
                my $cmd = <<CMD;
/usr/bin/htmldoc -f $printReport --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 --landscape --size letter $filePrint
CMD
                $ENV{TMPDIR}='/tmp/';
                $ENV{HTMLDOC_NOCGI}=1;
                system($cmd);
                my $printer='HP-PDF-HOU04';
                if (-e $printReport)
                {
                        system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=Tray4 --landscape $printReport");
                        $retVal=1;
                }
                ## File Printed ##
                if (-e $printReport)
                {
                        unlink($printReport);
                        unlink($filePrint);
                }
        }
        return $retVal;
}
sub getUserCertificate
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey, $printCheck,$onlyCert) = @_;

    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};


    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);
    if($printCheck) { $userData->{PRINTCHECK}= 1; }
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    if(($userData->{UPSELLEMAIL} || $userData->{UPSELLMAIL}) && !$onlyCert){
            use Certificate::CertForStudent;
            $cert = Certificate::CertForStudent->new($userId,$API->{PRODUCT});
    }else{
        if ($userData->{COURSE_STATE} eq 'OK' && $userData->{REGULATOR_ID} == $global->{OKLAHOMA_CITY_COURT})
        {
            use Certificate::Oklahoma;
            $cert = Certificate::Oklahoma->new($userId, $API->{PRODUCT});
        }
        else
        {
                eval("use Certificate::$certModule");
                $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
        }
    }

	   $userData->{NOMANIFEST}=1;
	   $userData->{DELIVERY_ID}=12;
           my $result=$cert->printCertificate($userId, $userData, { PDF => 1 },$pId,$printerKey,0,1);
           return $result;
}


#my $idsPrint = IDSPrinter->new;
#print Dumper($idsPrint->submitCTSIUserData('8369909'));
#print Dumper($idsPrint->printRefaxUser('8326877','1111','111','hari@ed-ventures-online.com'));
#print Dumper($idsPrint->printAAADIPUser('365','20003:365'));

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
