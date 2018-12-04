#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintAHST')
    -> handle;

package IDSPrintAHST;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::AHST;
use Certificate::PDF;
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
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AHST';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey,$dupId) = @_;

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    $dupId      = ($dupId)? $dupId :0;
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
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,12,'','AHST');

    return $pId;
}

sub printAccompanyLetter
{
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AHST';
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
    my $productId=12;
    my $printerKey ='CA';
    $printId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId,'','AHST');
    return $printId;
}

sub printRefaxUser
{
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AHST';
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
    if($userData->{COURSE_ID} == 90004 || $userData->{COURSE_ID} == 90008 || $userData->{COURSE_ID} == 90014 || $userData->{COURSE_ID} == 90018){
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
	    use Certificate::LosAngeles;
	    my $LACert=Certificate::LosAngeles->new;
  	    $LACert->faxLACertificates(\@toFaxUsers, $faxNum, $courtName, 'AHST', 0 );
	    return 1;
   }else{
	    $userData->{CERTIFICATE_NUMBER}   = $certNumber;
	    $userData->{FAX}=($faxNumber)?$faxNumber:$userData->{FAX};
            $attention=($attention)?$attention:' ';
            $userData->{ATTENTION}=$attention;

	    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	    eval("use Certificate::$certModule");
	    my $cert = ("Certificate::$certModule")->new;
	    my $pId = 0;
            $pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,12,'','AHST');
	    return $pId;

	
   }

}

sub printMultiSTCUser
{
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AHST';
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
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new;
    $userData->{CERTIFICATE_NUMBER} = $certNumber;
    $userData_1->{CERTIFICATE_NUMBER} = $certNumber_1;
    my @printIdArr = $cert->printMultipleCertificate($userId, $userData, $pId, $userId_1, $userData_1, $pId_1, { PRINTER => 1 }, $printerKey, 12,'AHST');

    return join ('~',@printIdArr);
    
}

sub printLabel
{
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AHST';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON}; 
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId,$printerKey) = @_;
    my $userData=$API->getUserData($userId);
    my $pId=0;
    $printerKey=(!$printerKey)?'CA':$printerKey;
    use Certificate::AHSTCertificate;
    my $cert = Certificate::AHSTCertificate->new;
    $cert->printRegularLabel($userId,$userData);
}

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
