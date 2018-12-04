#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrinterCLASSROOM')
    -> handle;

package IDSPrinterCLASSROOM;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::Classroom;
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
    my $API =Printing::Classroom->new;
    $API->{PRODUCT}='CLASSROOM';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='CLASSROOM';
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
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,5);

    return $pId;
}


sub printTXUser
{
    my $API =Printing::Classroom->new;
    $API->{PRODUCT}='CLASSROOM';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='CLASSROOM';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $printId, $dup, $printerKey) = @_;

    ##### set up the printer
    $printerKey = ($printerKey) ? $printerKey : 'TX';
    $printId    = ($printId) ? $printId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new;

    my $result = 0;
    if ($certNumber)
    {
      ###### run the course on the appropriate certificate
        $result=$cert->printCertificate($userId, $userData, { PRINTER => 1  },$printId,$printerKey,0,5);

        if($result)
        {
            $API->putUserPrintRecord($userId, $certNumber, 'PRINT');
        }
     }
    
    return $result;
}

sub printRefaxUser
{
    my $API =Printing::Classroom->new;
    $API->{PRODUCT}='CLASSROOM';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='CLASSROOM';
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
    $pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,1);
    return $pId;
}
my $idsPrint = IDSPrinterCLASSROOM->new;
print Dumper($idsPrint->printRefaxUser('8075063','7607443072',' '));
######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
