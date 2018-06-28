#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintAAATeen')
    -> handle;

package IDSPrintAAATeen;
use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::AAATeen;
use Certificate::PDF;
use MysqlDB;
use Data::Dumper;
use Certificate::AAACATeen;
use Certificate::Teen;
use Certificate::AAATeen;
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
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;

    my $API =Printing::AAATeen->new;
    $API->{PRODUCT}='AAATEEN';
    $API->{USERID}=$userId;
    $API->constructor;

    my $global= Settings->new;
    $global->{PRODUCT}='AAATEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    if($userData->{UPSELLMAIL})
    {
	    use Certificate::TeenCertForStudent;
    	    my $cert = Certificate::TeenCertForStudent->new($userId,$API->{PRODUCT});
            $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,2);
    }
    elsif ($userData->{COURSE_ID} == 5001 || $userData->{COURSE_ID} == 5002 || $userData->{COURSE_ID} == 5003 || $userData->{COURSE_ID} == 5013)
    {
	    $printerKey='AD';
	    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	    eval("use Certificate::$certModule");
	    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
        ###### this is a temporary hack just so I can id a CA course
        ###### this issue will be fixed soon
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,2);
           eval("use Certificate::$certModule");
           $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});

	   $cert->printCATeenLabel($userId,$userData);
    } else {
    		if ($userData->{COURSE_STATE} eq 'PA' && !$userData->{PA_CERT_CAN_PRINT}){
			return 0;
    		}
	    if ($userData->{PRINT_DATE})
            {
               ##### we're checking against print date as there will never be a request for
                ##### a duplicate unless the user has already printed

                ##### now, get the last bit of information for this user.  Take all data entries
                ##### from the user cert duplicate data tables
	        my $duplicateId = $API->getUserCertDuplicateId($userId);
	        my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId,1);
		if($duplicateId){
			my $permitDupId=$API->getUserPermitDuplicateId($userId,$duplicateId);
			if(!$permitDupId){
	                	$userData->{DUPLICATE_CERTS}=1;
			}
            	}	

                foreach my $dataKey(keys %{$userDupData})
                {
                    ###### ... and send these off to the printer
                    $userData->{$dataKey} = $userDupData->{$dataKey};
                }
            }
	   my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
           my $loginDate=$userData->{LOGIN_DATE};
           $loginDate =~ s/(\-|\ |\:)//g;
	   eval("use Certificate::$certModule");
	   my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,32);
           return $pId;

    }

    return 1;
}

sub printAAATeenUserDuplicateFedexLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::AAATeen;
    my $teenAPI = Printing::AAATeen->new;
    $teenAPI->{PRODUCT}='AAATEEN';
    $teenAPI->constructor;
    my $userDupData = $teenAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $uData=$teenAPI->getUserData($userId);
    my $retval = $teenAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printAAATeenToBeAssignCert
{
    my $API =Printing::AAATeen->new;
    $API->{PRODUCT}='AAATEEN';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AAATEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    #my $teenAPI     = TeenPrinting->new;
    #my $userData    = $teenAPI->getUserData($userId);

	my $result = $API->MysqlDB::getNextId('contact_id');
	my $fixedData=Certificate::_generateFixedData($userData);
	$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
	return $result;

    return 1;
}

#my $idsPrint = IDSPrintAAATeen->new;
#print Dumper($idsPrint->printTeenCert('226815', '5002:503780'));
#
#
