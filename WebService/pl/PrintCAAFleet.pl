#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintCAAFleet')
    -> handle;

package IDSPrintCAAFleet;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::CAAFleet;
use Certificate::PDF;
use Certificate::CAAFleetCertificate;
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
    my ($userId, $certNumber, $pId, $printerKey) = @_;
    my $API =Printing::CAAFleet->new;
    $API->{PRODUCT}='CAAFLEET';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='CAAFLEET';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

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
        my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);

        foreach my $dataKey(keys %{$userDupData->{DATA}})
        {
            ###### ... and send these off to the printer
            $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
        }
    }

	    ##### ok, let's load up the @args array w/ the params to send into the
	    ##### print function
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,26);
	   if($userData->{ACCOUNT_ID} && $pId){
		my $accountData=$API->getAccountData($userData->{ACCOUNT_ID});
		if ($accountData->{ACCOUNT_SEND_CERTIFICATES} && $accountData->{ACCOUNT_SEND_CERTIFICATES} eq 'Y')
          	{
           	     $accountData->{NO_OF_CERTIFICATES}=1;
                     use Certificate::FleetCertificate;
	             my $cert = Certificate::FleetCertificate->new($userId,$API->{PRODUCT});
        	     $cert->printCoverSheet($userData->{ACCOUNT_ID}, $accountData);
          	}
	   }

    return $pId;
}

sub emailUserFleetCertificate
{
    my $self = shift;
    my ($userId, $certNumber, $emailAddress) = @_;
    my $API =Printing::CAAFleet->new;
    $API->{PRODUCT}='CAAFLEET';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='CAAFLEET';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $pId        =  0;
    my $printerKey='CA';
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=($certNumber)?$certNumber:$userData->{CERTIFICATE_NUMBER};
    $emailAddress=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    $userData->{DELIVERY_ID} = 12; ##### Email Certificate Delivery

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
           $pId=$cert->printCertificate($userId, $userData, { EMAIL => $emailAddress },$pId,$printerKey,0,26);

    return $pId;
}


######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
#my $idsPrint = IDSPrintCAAFleet->new;
#print Dumper($idsPrint->printUser('102513', '55022:102513'));
#print Dumper($idsPrint->emailUserFleetCertificate('8190328', '55022:8190328'));
