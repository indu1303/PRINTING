#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintUsionline')
    -> handle;

package IDSPrintUsionline;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::USIOnline;
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
    my $API =Printing::USIOnline->new;
    $API->{PRODUCT}='USI_ONLINE';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='USI_ONLINE';
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
	   $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,31);
    	   return $pId;
}

sub printDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    #use Printing::DIP;
    #my $API =Printing::DIP->new;
    my $API =Printing::USIOnline->new;

    $API->{PRODUCT}='USI_ONLINE';
    $API->{USERID}=$userId;
    $API->constructor;

    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $API->getUserData($userId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printAccompanyLetter
{
    my $self = shift;
    my ($userId, $email) = @_;
    my $API =Printing::USIOnline->new;
    $API->{PRODUCT}='USI_ONLINE';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='USI_ONLINE';
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
    my $productId=31;
    my $printerKey ='CA';
    $printId=$printCert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$printId,$printerKey,$accompanyLetter,$productId);
    return $printId;
}



sub printRefaxUser
{
    my $self = shift;
    my ($userId,$faxNumber,$attention,$certNumber) = @_;
    my $API =Printing::USIOnline->new;
    $API->{PRODUCT}='USI_ONLINE';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='USI_ONLINE';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    ######## this function will be handled a little differently. We're going to connect and get the
    ######## course id for the user.  Based on the course id, we're going to send it to the
    ######## appropriate printing script
  
    my $userData = $API->getUserData($userId);
    $certNumber = ($certNumber)?$certNumber:$API->getNextCertificateNumber($userId);
    my $printerKey='CA';
	    my $pId = 0;
	    $userData->{CERTIFICATE_NUMBER}   = $certNumber;
	    $userData->{FAX}=($faxNumber)?$faxNumber:$userData->{FAX};
	    $attention=($attention)?$attention:' ';
	    $userData->{ATTENTION}=$attention;
	    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	    eval("use Certificate::$certModule");
	    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
            $pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,31);
	    return $pId;

	

}

sub emailUser
{
    my $self = shift;
    my ($userId, $certNumber,$emailAddress) = @_;
    my $API =Printing::USIOnline->new;
    $API->{PRODUCT}='USI_ONLINE';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='USI_ONLINE';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

   
    my $userData=$API->getUserData($userId);
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


sub printUserDuplicateFedexLabel
{
	my $self = shift;
	my ($userId,$duplicateId) = @_;

	use Printing::USIOnline;
	my $API =Printing::USIOnline->new;
	$API->{PRODUCT}='USI_ONLINE';
	$API->{USERID}=$userId;
	$API->constructor;

	my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
	my $shippingId = $userDupData->{SHIPPING_ID};
	my $retval = $API->pDuplicateFedexLabelPrint($shippingId);

	return $retval;
}

#my $idsPrint = IDSPrintUSIOnline->new;
#print Dumper($idsPrint->printNonTXDriverRecord('18104889'));
#print Dumper($idsPrint->submitCTSIUserData('8369909'));
#print Dumper($idsPrint->printRefaxUser('8326877','1111','111','hari@ed-ventures-online.com'));
#print Dumper($idsPrint->printAAADIPUser('365','20003:365'));

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class

