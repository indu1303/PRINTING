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
use Certificate::PDF;
use Certificate::California;
use Certificate::AAA;
use Certificate::Delaware;
use Certificate::Texas;
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
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new;


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
	   $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,1);
    	   return $pId;
}

sub printAccompanyLetter
{
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $email) = @_;

    my $userData = $API->getUserData($userId);
    $userData->{EMAIL} = $email;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new;


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
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $printDate, $faxNumber) = @_;
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
    my $cert = ("Certificate::$certModule")->new;
    $printId=$cert->printCertificate($userId, $userData, {FAX => $faxNumber},$printId,$printerKey,$accompanyLetter,$productId);
    }

}

sub printRefaxUser
{
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId,$faxNumber,$attention,$certNumber) = @_;

    ######## this function will be handled a little differently. We're going to connect and get the
    ######## course id for the user.  Based on the course id, we're going to send it to the
    ######## appropriate printing script
  
    my $userData = $API->getUserData($userId);
    $certNumber = ($certNumber)?$certNumber:$API->getNextCertificateNumber($userId);
    my $printerKey='CA';
    if($userData->{COURSE_ID} == 14 || $userData->{COURSE_ID}==17){
	    use Certificate::LosAngeles;
	    my $cert = Certificate::LosAngeles->new;
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
	    my $LACert=Certificate::LosAngeles->new;
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
	    my $cert = ("Certificate::$certModule")->new;
            $pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,1);
	    return $pId;

	
   }

}

sub printMultiSTCUser
{
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $pId,$userId_1, $certNumber_1, $pId_1, $printerKey) = @_;

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
    my $cert = ("Certificate::$certModule")->new($stc);
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
    my ($userId, $state, $reportDate, $printerKey) = @_;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $userData    = $API->getUserData($userId);

    my $userContact = $API->getUserContact($userId);
    $userData->{SEX} = $userContact->{SEX};
    my $cert=Report::UserStateReport->new();
    my $result = $cert->printStateReport($userId, $userData,{PRINTER => 1},$state, $reportDate, $printerKey);

    return $result;
}

sub emailUser
{
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber,$emailAddress) = @_;

   
    my $userData=$API->getUserData($userId);
    my $pId=0;
    my $printerKey='CA';
    $userData->{CERTIFICATE_NUMBER} = $certNumber;
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new;
    $pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,1);
    return $pId;
 
}

sub printTXUser
{
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $printId, $dup, $printerKey) = @_;

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
        my $cert = ("Certificate::$certModule")->new;
      ###### run the course on the appropriate certificate
        $result=$cert->printCertificate($userId, $userData, { PRINTER => 1  },$printId,$printerKey,0,1,$dup);

        if($result)
        {
            $API->putUserPrintRecord($userId, $certNumber, 'PRINT');
        }
     }
    
    return $result;
}

sub printNewYorkUser
{
    my $self = shift;
    my ($certNumber, $agencyId, $instructorId, $locationId, $studentId, $dl, $completionDate,
        $first, $last, $address, $city, $state, $zip, $today) = @_;

    use Certificate::NewYork;
    my $nyHandle = Certificate::NewYork->new;
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
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId,$printerKey) = @_;
    my $userData=$API->getDPSInformation($userId);
    my $pId=0;
    $printerKey=(!$printerKey)?'CA':$printerKey;
    use DriverRecord::DPS;
    my $cert = DriverRecord::DPS->new;
    $pId=$cert->printDRAppForm($userId, $userData, { PRINTER => 1 },$printerKey);
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

#my $idsPrint = IDSPrinter->new;
#print Dumper($idsPrint->printRefaxUser('8326877','1111','111','hari@ed-ventures-online.com'));
#print Dumper($idsPrint->printUserReport('7547349','MO','2006/12/12'));


my $idsPrint = IDSPrinter->new;
#print Dumper($idsPrint-> printUser('10384548', '09863049'));
print Dumper($idsPrint-> printUser('12546337', '10671786'));
######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
