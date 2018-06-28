#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintTakeHome')
    -> handle;

package IDSPrintTakeHome;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::TakeHome;
use Certificate::PDF;
use Certificate::California;
use Certificate::AAA;
use Certificate::Delaware;
use Certificate::Texas;
use Certificate::NewYork;
use Certificate::CertForStudent;
use Certificate::Oklahoma;
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
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey, $printCheck) = @_;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};


    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    if($userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA} eq '99'){
           return 0;  ################  Not to Print Cert if Cookie is set to 99
    }
    if($printCheck) { $userData->{PRINTCHECK}= 1; }
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    if($userData->{UPSELLEMAIL} || $userData->{UPSELLMAIL}){
	    use Certificate::CertForStudent;
    	    $cert = Certificate::CertForStudent->new($userId,$API->{PRODUCT});
    }else{
	if ($userData->{COURSE_STATE} eq 'OK' && $userData->{REGULATOR_ID} == $global->{OKLAHOMA_CITY_COURT})
	{
	    use Certificate::Oklahoma;
    	    $cert = Certificate::Oklahoma->new($userId,$API->{PRODUCT});
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
	   $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,25);
    	   return $pId;
}

sub printAccompanyLetter
{
    my $self = shift;
    my ($userId, $email) = @_;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
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
    my $productId=25;
    my $printerKey ='CA';
    $printId=$printCert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId);
    return $printId;
}


sub printFaxUser
{
    my $self = shift;
    my ($userId, $certNumber, $printDate, $faxNumber) = @_;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $userData = $API->getUserData($userId);


    ###### fax the certificate to the user
    if(exists $global->{FAXCOURSE}->{TAKEHOME}->{$userData->{COURSE_ID}})
    {
    my $testCenterId = $API->getUserTestCenter($userId);
    my $testCenter = $API->getTestCenter($testCenterId);
    $faxNumber=($faxNumber)?$faxNumber:$testCenter->{FAX};
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    my $printId=0;
    my $printerKey='CA';
    my $accompanyLetter=0;
    my $productId=25;
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
    my $productId=25;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    $API->putAccompanyLetterUser($userId);
    my @printIdArr = $cert->printMultipleCertificate($userId, $userData, $pId, $userId_1, $userData_1, $pId_1, { FAX => $faxNumber}, $printerKey, 25);
    return @printIdArr;
    } elsif($userData->{RESIDENT_STATE} && $userData->{RESIDENT_STATE} eq 'NONOH') {
	##OH Non Resident - Fax the Certificate
	$faxNumber=($faxNumber)?$faxNumber:$global->{OH_NONRESIDENT_FAXNUMBER};
    	$userData->{CERTIFICATE_NUMBER}=$certNumber;
    	my $printId=0;
    	my $printerKey='CA';
    	my $accompanyLetter=0;
    	my $productId=25;
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
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
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
	    eval("use Certificate::$certModule");
	    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
            $pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,25);
	    return $pId;

	
   }

}

sub printMultiSTCUser
{
    my $self = shift;
    my ($userId, $certNumber, $pId,$userId_1, $certNumber_1, $pId_1, $printerKey) = @_;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
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
    my @printIdArr = $cert->printMultipleCertificate($userId, $userData, $pId, $userId_1, $userData_1, $pId_1, { PRINTER => 1 }, $printerKey, 25);

    return join ('~',@printIdArr);
    
}

sub printUserReport
{
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
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
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

   
    my $userData=$API->getUserData($userId);
    if($userData->{THIRD_PARTY_DATA} && $userData->{THIRD_PARTY_DATA} eq '99'){
           return 0;  ################  Not to Print Cert if Cookie is set to 99
    }
    my $pId=0;
    my $printerKey='CA';
    $userData->{CERTIFICATE_NUMBER} = $certNumber;
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    if($userData->{UPSELLEMAIL}){
	    use Certificate::CertForStudent;
    	    $cert = Certificate::CertForStudent->new($userId,$API->{PRODUCT});
    }else{
    	eval("use Certificate::$certModule");
    	$cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    }
    $pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,25);
    return $pId;
 
}

sub printTXUser
{
    my $self = shift;
    my ($userId, $certNumber, $printId, $dup, $printerKey) = @_;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
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
        $result=$cert->printCertificate($userId, $userData, { PRINTER => 1  },$printId,$printerKey,0,25,$dup);

    }
    
    return $result;
}

sub printNonTXDriverRecord
{
    my $self = shift;
    my ($userId,$printerKey) = @_;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}='TAKEHOME';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $userData=$API->getDPSInformation($userId);
    $userData->{PRODUCTID} = 25;
    my $pId=0;
    $printerKey=(!$printerKey)?'CA':$printerKey;
    use DriverRecord::DPS;
    my $cert = DriverRecord::DPS->new($userId,$API->{PRODUCT});
    $pId=$cert->_generateNonTXDriverRecord($userId, $userData);
    $pId=$cert->_generateNonTXDriverRecord($userId, $userData);
    if(!$userData->{DELIVERY_ID} || ($userData->{DELIVERY_ID} && ($userData->{DELIVERY_ID} == 1 || $userData->{DELIVERY_ID} == 16))){
	    $cert->printDRLabel($userId,$userData);
    }
    return $pId;
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

	use Printing::TakeHome;
	my $API =Printing::TakeHome->new;
	$API->{PRODUCT}='TAKEHOME';
	$API->constructor;

	my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
	my $shippingId = $userDupData->{SHIPPING_ID};
	my $retval = $API->pDuplicateFedexLabelPrint($shippingId);

	return $retval;
}

sub getUserCertificate
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey, $printCheck) = @_;

    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TAKEHOME';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};


    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);
    if($printCheck) { $userData->{PRINTCHECK}= 1; }
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    if($userData->{UPSELLEMAIL} || $userData->{UPSELLMAIL}){
            use Certificate::CertForStudent;
            $cert = Certificate::CertForStudent->new($userId,$API->{PRODUCT});
    }else{
                eval("use Certificate::$certModule");
                $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    }

           $userData->{NOMANIFEST}=1;
	   $userData->{DELIVERY_ID}=12;
           my $result=$cert->printCertificate($userId, $userData, { PDF => 1 },$pId,$printerKey,0,25);
           return $result;
}



#my $idsPrint = IDSPrintTakeHome->new;
#print Dumper($idsPrint->printNonTXDriverRecord('18104889'));
#print Dumper($idsPrint->submitCTSIUserData('8369909'));
#print Dumper($idsPrint->printRefaxUser('8326877','1111','111','hari@ed-ventures-online.com'));
#print Dumper($idsPrint->printAAADIPUser('365','20003:365'));

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class

