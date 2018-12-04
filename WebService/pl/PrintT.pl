#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintTeen')
    -> handle;

package IDSPrintTeen;
use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::Teen;
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


sub printTeenCert
{
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    print Dumper($userData);
    #my $teenAPI     = TeenPrinting->new;
    #my $userData    = $teenAPI->getUserData($userId);
    if ($userData->{COURSE_ID} == 5001)
    {
	    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	    eval("use Certificate::$certModule");
	    my $cert = ("Certificate::$certModule")->new;
        ###### this is a temporary hack just so I can id a CA course
        ###### this issue will be fixed soon
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,2);
	   $cert->printCATeenLabel($userId,$userData);
    } else {
	    if ($userData->{PRINT_DATE})
            {
               ##### we're checking against print date as there will never be a request for
                ##### a duplicate unless the user has already printed

                ##### now, get the last bit of information for this user.  Take all data entries
                ##### from the user cert duplicate data tables
	        my $duplicateId = $API->getUserCertDuplicateId($userId);
	        my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId,1);

                foreach my $dataKey(keys %{$userDupData->{DATA}})
                {
                    ###### ... and send these off to the printer
                    $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
                }
            }
	   my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	   eval("use Certificate::$certModule");
	   my $cert = ("Certificate::$certModule")->new;
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,2);
           return $pId;

    }

    return 1;
}
sub emailUser
{
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber,$emailAddress) = @_;

    my $userData=$API->getUserData($userId);
    my $pId=0;
    my $printerKey='CA';
    $userData->{CERTIFICATE_NUMBER} = $certNumber;
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new;
    $pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,2);
    return $pId;

}

sub resendCOAffidavit {
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    my $self = shift;
    my ($userId,$emailAddress) = @_;
    my $userData    = $API->getUserAffidavitData($userId);
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
  	         # Now Send the mail the user
  	         # Get the PDF Path, attach that to the mail and Send
    use Affidavit::TeenAffidavit;
    my $cert = Affidavit::TeenAffidavit->new;
    my $pdfPath = $cert->printAffidavit($userId, $userData,{EMAIL => $userData->{EMAIL}},0);
  	         
   return $pdfPath;
}
  	 
sub printCOTeenAffidavit {
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId) = @_;
    my $userData = $API->getUserAffidavitData($userId);
    use Affidavit::TeenAffidavit;
    my $cert = Affidavit::TeenAffidavit->new;
    my $pdfPath = $cert->printAffidavit($userId, $userData,{PRINTER => 1},1);
    if($pdfPath) {
	    my $WST = time();
	    $API->putCookie($userId, {'CO_AFFIDAVIT_PRINTED'=>$WST});
	    return 1;
    }
         return 0;
}
my $idsPrint = IDSPrintTeen->new;
print Dumper($idsPrint->printTeenCert(1149453,'6001:1149453'));

