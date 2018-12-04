#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintAAASeniors')
    -> handle;

package IDSPrintAAASeniors;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::AAASeniors;
use Certificate::PDF;
use Certificate::AAASeniors;
use Certificate::AAACASeniors;
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

sub printAAASeniorsCert
{
    my $API =Printing::AAASeniors->new;
    $API->{PRODUCT}='AAA_SENIORS';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AAA_SENIORS';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);    
    $certNumber      = $API->getNextCertificateNumber($userId, $userData->{COURSE_ID});
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    if ($userData->{COURSE_ID} == 5002) {
	##CA Certificate Printing
	    $printerKey='AD';
            my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
            eval("use Certificate::$certModule");
            my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
        ###### this is a temporary hack just so I can id a CA course
        ###### this issue will be fixed soon
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,38);
	$cert->printAAACASeniorsLabel($userId,$userData);
    ######## let's do a quick check for a dupliate request
    ######## if there is a duplicate request, we'll substitute any data
    }else{
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
	    $userData->{CERTIFICATE_NUMBER}=($userData->{CERTIFICATE_NUMBER})?$userData->{CERTIFICATE_NUMBER}:$API->getNextCertificateNumber($userId, $userData->{COURSE_ID});
	    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	    eval("use Certificate::$certModule");
	    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
	    $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,38);

	    return $pId;
    }

    return 1;
	    ##### ok, let's load up the @args array w/ the params to send into the
	    ##### print function
}

sub emailUser
{
 	  	     my $self = shift;
 	  	     my ($userId, $certNumber,$emailAddress) = @_;
 	  	     my $API =Printing::AAASeniors->new;
 	  	     $API->{PRODUCT}='AAA_SENIORS';
 	  	     $API->{USERID}=$userId;
 	  	     $API->constructor;
 	  	     my $global= Settings->new;
 	  	     $global->{PRODUCT}='AAA_SENIORS';
 	  	     $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
 	  	     $global->{CRM_CON}=$API->{CRM_CON};
 	  	 
 	  	     my $userData=$API->getUserData($userId);
 	  	     my $pId=0;
 	  	     my $printerKey='CA';
 	  	     $userData->{CERTIFICATE_NUMBER} = $certNumber;
 	  	     $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
 	  	     my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
 	  	     eval("use Certificate::$certModule");
 	  	     my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
 	  	     $pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,38);
 	  	     return $pId;
 	  	 
}

sub updateAAASeniorsCert
{
    my $API =Printing::AAASeniors->new;
    $API->{PRODUCT}='AAA_SENIORS';
    $API->constructor;
    my $self = shift;
    my ($userId, $certificate) = @_;

    $API->putUserPrintRecord($userId, $certificate);

    return 1;
}

sub printAAASeniorsUserDuplicateFedexLabel
{
	my $self = shift;
	my ($userId,$duplicateId) = @_;

	use Printing::AAASeniors;
	my $aaaSeniorsAPI = Printing::AAASeniors->new;
	$aaaSeniorsAPI->{PRODUCT}='AAA_SENIORS';
	$aaaSeniorsAPI->constructor;
	my $userDupData = $aaaSeniorsAPI->getUserCertDuplicateData($userId,$duplicateId);
	my $shippingId = $userDupData->{SHIPPING_ID};
	my $retval = $aaaSeniorsAPI->pDuplicateFedexLabelPrint($shippingId,'',$userDupData);

	return $retval;
}

sub printRefaxUser
{
    my $self = shift;
    my ($userId,$faxNumber,$attention,$certNumber) = @_;
    my $API =Printing::AAASeniors->new;
    $API->{PRODUCT}='AAA_SENIORS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $global= Settings->new;
    $global->{PRODUCT}='AAA_SENIORS';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    ######## this function will be handled a little differently. We're going to connect and get the
    ######## course id for the user.  Based on the course id, we're going to send it to the
    ######## appropriate printing script
  
    my $userData = $API->getUserData($userId);
    $certNumber = ($certNumber)?$certNumber:$API->getNextCertificateNumber($userId);
    my $printerKey='CA';
    my $pId = 0;
    if ($faxNumber)
    {	
    	$userData->{CERTIFICATE_NUMBER}   = $certNumber;
    	$userData->{FAX}=($faxNumber)?$faxNumber:'';
    	$attention=($attention)?$attention:' ';
    	$userData->{ATTENTION}=$attention;
    	my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    	eval("use Certificate::$certModule");
    	my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    	$pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,1);
    	return $pId;
    } 		
}

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
#my $idsPrint = IDSPrintAAASeniors->new;
#print Dumper($idsPrint->printAAASeniorsCert('503780', '5002:503780'));

