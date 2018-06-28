#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrinterCLASS')
    -> handle;

package IDSPrinterCLASS;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::Class;
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
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;

    my $API =Printing::Class->new;
    $API->{PRODUCT}='CLASS';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='CLASS';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    $printerKey = ($printerKey) ? $printerKey : 'TX';
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
	    if($userDupData->{DATA}->{$dataKey}){ 
            	$userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
	    }
        }
    }
	    ##### ok, let's load up the @args array w/ the params to send into the
	    ##### print function
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,10);

    return $pId;
}


######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
