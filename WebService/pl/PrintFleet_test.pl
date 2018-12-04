#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintFleet')
    -> handle;

package IDSPrintFleet;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::Fleet;
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
    my $API =Printing::Fleet->new;
    $API->{PRODUCT}='FLEET';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='FLEET';
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
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,3);
	   if($userData->{ACCOUNT_ID} && $pId){
		my $accountData=$API->getAccountData($userData->{ACCOUNT_ID});
		if ($accountData->{ACCOUNT_SEND_CERTIFICATES} && $accountData->{ACCOUNT_SEND_CERTIFICATES} eq 'Y')
          	{
           	     $accountData->{NO_OF_CERTIFICATES}=1;
                     use Certificate::FleetCertificate;
	             my $cert = Certificate::FleetCertificate->new;
        	     $cert->printCoverSheet($userData->{ACCOUNT_ID}, $accountData);
          	}
	   }

    return $pId;
}

sub emailUserFleetCertificate
{
    my $API =Printing::Fleet->new;
    $API->{PRODUCT}='FLEET';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='FLEET';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $emailAddress) = @_;
    my $pId        =  0;
    my $printerKey='CA';
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=($certNumber)?$certNumber:$userData->{CERTIFICATE_NUMBER};
    $emailAddress=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new;

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
           $pId=$cert->printCertificate($userId, $userData, { EMAIL => $emailAddress },$pId,$printerKey,0,3);

    return $pId;
}

sub printRefaxUser
{
    my $API =Printing::Fleet->new;
    $API->{PRODUCT}='FLEET';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='FLEET';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId,$faxNumber,$attention) = @_;

    ######## this function will be handled a little differently. We're going to connect and get the
    ######## course id for the user.  Based on the course id, we're going to send it to the
    ######## appropriate printing script

    my $userData = $API->getUserData($userId);
    my $certNumber = $API->getNextCertificateNumber($userId);
    my $printerKey='CA';
    my $pId = 0;
    $userData->{CERTIFICATE_NUMBER}   = $certNumber;
    $userData->{FAX}=($faxNumber)?$faxNumber:$userData->{FAX};
    $attention=($attention)?$attention:' ';
    $userData->{ATTENTION}=$attention;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new;
    $pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,3);
    return $pId;

}

sub printFaxUser
{
    my $API =Printing::Fleet->new;
    $API->{PRODUCT}='FLEET';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='FLEET';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $printDate, $faxNumber) = @_;
    my $userData = $API->getUserData($userId);

    ###### fax the certificate to the user
    my $printId=0;
    if(exists $global->{FAXCOURSE}->{FLEET}->{$userData->{COURSE_ID}})
    {
	    if($userData->{ACCOUNT_ID}){
		    my $accountData=$API->getAccountData($userData->{ACCOUNT_ID});
		    $faxNumber=($faxNumber)?$faxNumber:$accountData->{FAX};
		    $userData->{CERTIFICATE_NUMBER}=$certNumber;
		    my $printerKey='CA';
		    my $accompanyLetter=0;
		    my $productId=3;
		    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
		    eval("use Certificate::$certModule");
		    my $cert = ("Certificate::$certModule")->new;
	    	    $printId=$cert->printCertificate($userId, $userData, {FAX => $faxNumber},$printId,$printerKey,$accompanyLetter,$productId);
    	    }
    }
    return $printId;

}

my $idsPrint = IDSPrintFleet->new;
#print Dumper($idsPrint-> printUser('8054395', '55003:8054395'));
print Dumper($idsPrint-> emailUserFleetCertificate('8054395', '55003:8054395','user@email.com'));

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
