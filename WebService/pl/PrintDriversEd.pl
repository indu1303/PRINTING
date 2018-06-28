#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrinterDriversEd')
    -> handle;

package IDSPrinterDriversEd;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Printing::DriversEd;
use Settings;
use MysqlDB;
use Settings;
use Certificate::PDF;
use Certificate::DETXAdult;
use Certificate::DECOTeen;
use Certificate::DENVTeen;
use Certificate::DECATeen;
use Certificate::DETexas;
use Certificate::DETXTeen32;
use Certificate::DEBTWTXTeen32;
use Certificate::DEBTWTXTeen32Insurance;
use Certificate::DEDIP;
use Certificate::DEOHTeen;
use Data::Dumper;


use strict;
no strict "refs";

sub new
{
    my $self = shift;
    my $class = ref($self) || $self;
    bless {} => $class;
}

sub printCert
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey, $printCheck) = @_;
    my $API =Printing::DriversEd->new;
    $API->{PRODUCT}='DRIVERSED';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DRIVERSED';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};


    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    eval("use Certificate::$certModule");
    $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    if($userData->{COURSE_ID} eq 'C0000067') {
	##OH Teen, not required to print the certificate, only the certificate to fetch from webservice and submit for printing
	$pId = 1;
    } else {
   	$pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,41);
    }
   if($userData->{COURSE_ID} eq 'C0000013' && $userData->{CERTIFICATE_NUMBER} && $userData->{CERTIFICATE_NUMBER} ne '[TBA CO]'){
   	$API->updateDriveredData($userId);
        #use Certificate::DECOTeen;
        #my $cert1=Certificate::DECOTeen->new;
        #$cert1->printCOTeenLabel($userId,$userData);
   }
   if($userData->{COURSE_ID} eq 'C0000034' && $userData->{CERTIFICATE_NUMBER} && $userData->{CERTIFICATE_NUMBER} ne '[TBA CA]'){
        #$cert->printDECATeenLabel($userId,$userData);
   	$API->updateDriveredData($userId);
   } 
   if($userData->{COURSE_ID} eq 'C0000055' && $userData->{CERTIFICATE_NUMBER} && $userData->{CERTIFICATE_NUMBER} ne '[TBA CA MATURE]'){
        $cert->printDECAMatureLabel($userId,$userData);
   	$API->updateDriveredData($userId);
   }
   if($userData->{COURSE_ID} eq 'C0000067' && $userData->{CERTIFICATE_NUMBER}){
        use Certificate::DEOHTeen;
        my $cert1=Certificate::DEOHTeen->new($userId, $API->{PRODUCT});
        $cert1->printStudentOHCerts($userId,$userData,'REPRINT');
   }
   return $pId;
}

sub printTeenCOLabel {
        my $self = shift;
        my ($userId) = @_;
    	my $API =Printing::DriversEd->new;
        $API->{PRODUCT}='DRIVERSED';
        $API->constructor;
        my $userData = $API->getUserData($userId);

        use Certificate::DECOTeen;
        my $cert=Certificate::DECOTeen->new($userId, $API->{PRODUCT});
        $cert->printCOTeenLabel($userId,$userData);

        return 1;
}

sub printTeenCOAttedance {
        my $self = shift;
        my ($userId) = @_;
    	my $API =Printing::DriversEd->new;
        $API->{PRODUCT}='DRIVERSED';
        $API->constructor;
        my $userData = $API->getUserData($userId);

        use Certificate::DECOTeen;
        my $cert=Certificate::DECOTeen->new($userId, $API->{PRODUCT});
        my $ref = $cert->printCOTeenStudentAttedanceRecord($userId,$userData);

        return 1;
}

sub postCertData
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey, $printCheck) = @_;

    my $API =Printing::DriversEd->new;
    $API->{PRODUCT}='DRIVERSED';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DRIVERSED';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};


    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    eval("use Certificate::$certModule");
    $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
   if($userData->{COURSE_ID} eq 'C0000013' && $userData->{CERTIFICATE_NUMBER} && $userData->{CERTIFICATE_NUMBER} ne '[TBA CO]'){
        $API->updateDriveredData($userId);
   }
   if($userData->{COURSE_ID} eq 'C0000034' && $userData->{CERTIFICATE_NUMBER} && $userData->{CERTIFICATE_NUMBER} ne '[TBA CA]'){
        #$cert->printDECATeenLabel($userId,$userData);
        $API->updateDriveredData($userId);
   }
   if($userData->{COURSE_ID} eq 'C0000055' && $userData->{CERTIFICATE_NUMBER} && $userData->{CERTIFICATE_NUMBER} ne '[TBA CA MATURE]'){
        $cert->printDECAMatureLabel($userId,$userData);
        $API->updateDriveredData($userId);
   }
   if($userData->{COURSE_ID} eq 'C0000023_NM' && $userData->{CERTIFICATE_NUMBER} && $userData->{CERTIFICATE_NUMBER} ne '[TBA NM DIP]'){
        $API->updateDriveredData($userId);
        use Certificate::DECOTeen;
        my $cert1=Certificate::DECOTeen->new($userId,$API->{PRODUCT});
        $cert1->printCOTeenLabel($userId,$userData);
   }
   return $pId;
}


sub printTeen32StudentLog {
        my $self = shift;
        my ($userId) = @_;
        my $API =Printing::DriversEd->new;
        $API->{PRODUCT}='DRIVERSED';
        $API->constructor;
        my $userData = $API->getUserData($userId);

        use Certificate::DETXTeen32;
        my $cert=Certificate::DETXTeen32->new($userId, $API->{PRODUCT});
        my $ref = $cert->printTXTeenStudentLog($userId,$userData);

        return 1;
}

sub printRegularMail
{
    my $self = shift;
    my ($userId,$certNumber) = @_;
    my $API=Printing::DriversEd->new;
    $API->{PRODUCT}='DRIVERSED';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='DRIVERSED';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    ######## this function will be handled a little differently. We're going to connect and get the
    ######## course id for the user.  Based on the course id, we're going to send it to the
    ######## appropriate printing script

    my $userData = $API->getUserData($userId);
    my $printerKey='CA';
    my $pId = 0;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    use Certificate::DETXTeen32;
    my $cert = Certificate::DETXTeen32->new($userId,$API->{PRODUCT});
    $pId=$cert->printRegularLabel($userId, $userData);
    return 1;
}



#my $idsPrint = IDSPrinterDriversEd->new;
#print Dumper($idsPrint->printCert('15145','111'));
#print Dumper($idsPrint->printTeenCOLabel('395'));
#print Dumper($idsPrint->printTeenCOAttedance('15175'));
#my $idsPrint = IDSPrinterDriversEd->new;
#print Dumper($idsPrint->printCert('935','1111234'));
#print Dumper($idsPrint->postCertData('13420','RAJESH112'));

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
