#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintDIPDVD')
    -> handle;

package IDSPrintDIPDVD;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::DIPDVD;
use Certificate::PDF;
use Certificate::CertForStudent;
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
    my $API =Printing::DIPDVD->new;
    $API->{PRODUCT}='DIPDVD';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DIPDVD';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $uData = $API->getUserData($userId);
    my $userData=$uData->{$userId}->{USERDATA};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    eval("use Certificate::$certModule");
    $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});


    ######## let's do a quick check for a dupliate request
    ######## if there is a duplicate request, we'll substitute any data
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
   $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,1);
   return $pId;
}

#my $idsPrint = IDSPrinter->new;
#print Dumper($idsPrint->submitCTSIUserData('8369909'));
#print Dumper($idsPrint->printRefaxUser('8326877','1111','111','hari@ed-ventures-online.com'));
#print Dumper($idsPrint->printAAADIPUser('365','20003:365'));

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
