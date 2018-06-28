#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintMature')
    -> handle;

package IDSPrintMature;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::Mature;
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

sub printMatureCert
{
    my $API =Printing::Mature->new;
    $API->{PRODUCT}='MATURE';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='MATURE';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);    
    $certNumber      = $API->getNextCertificateNumber($userId, $userData->{COURSE_ID});
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    if ($userData->{COURSE_ID} == 200005 || $userData->{COURSE_ID} == 100005)
    {
            my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
            eval("use Certificate::$certModule");
            my $cert = ("Certificate::$certModule")->new;
        ###### this is a temporary hack just so I can id a CA course
        ###### this issue will be fixed soon
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,8);
	$cert->printCAMatureLabel($userId,$userData);
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
	    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	    eval("use Certificate::$certModule");
	    my $cert = ("Certificate::$certModule")->new;
	    $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,8);

	    return $pId;
    }

    return 1;
	    ##### ok, let's load up the @args array w/ the params to send into the
	    ##### print function
}

sub updateMatureCert
{
    my $API =Printing::Mature->new;
    $API->{PRODUCT}='MATURE';
    $API->constructor;
    my $self = shift;
    my ($userId, $certificate) = @_;

    $API->putUserPrintRecord($userId, $certificate);

    return 1;
}

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class

my $idsPrint = IDSPrintMature->new;
print Dumper($idsPrint-> printMatureCert('197643', '200007:197643'));
