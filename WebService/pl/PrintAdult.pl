#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintAdult')
    -> handle;

package IDSPrintAdult;
use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::Adult;
use Certificate::PDF;
use MysqlDB;
use Data::Dumper;
use Certificate::TXAdult;
use strict;
no strict "refs";



sub new
{
    my $self = shift;
    my $class = ref($self) || $self;
    bless {} => $class;
}


sub printAdultCert
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;
    my $API =Printing::Adult->new;
    $API->{PRODUCT}='ADULT';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='ADULT';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $dup;
    my $userData = $API->getUserData($userId);
    if ($userData->{COURSE_ID} == 44004 || $userData->{COURSE_ID} == 44005 || $userData->{COURSE_ID} == 44006 || $userData->{COURSE_ID} == 44007 || $userData->{COURSE_ID} == 44014 ||  $userData->{COURSE_ID} == 44015 )
    {
	    $printerKey='AD';
	    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	    eval("use Certificate::$certModule");
	    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
	    if ($userData->{PRINT_DATE})
            {
               ##### we're checking against print date as there will never be a request for
                ##### a duplicate unless the user has already printed

                ##### now, get the last bit of information for this user.  Take all data entries
                ##### from the user cert duplicate data tables
	        my $duplicateId = $API->getUserCertDuplicateId($userId);
	        my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId,1);
		$dup=$userDupData->{DATA};

                foreach my $dataKey(keys %{$userDupData->{DATA}})
                {
                    ###### ... and send these off to the printer
                    $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
                }
            }
        ###### this is a temporary hack just so I can id a CA course
        ###### this issue will be fixed soon
    	   $userData->{CERTIFICATE_NUMBER}=$certNumber;
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,18,$dup);
		return $pId;
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
	   my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,18);
           return $pId;

    }

    return 1;
}

sub printAdultToBeAssignCert
{
	my $API =Printing::Adult->new;
	$API->{PRODUCT}='ADULT';
	$API->constructor;
	my $global= Settings->new;
	$global->{PRODUCT}='ADULT';
	$global->{PRODUCT_CON}=$API->{PRODUCT_CON};
	$global->{CRM_CON}=$API->{CRM_CON};
	my $self = shift;
	my ($userId, $certNumber, $pId, $printerKey) = @_;
	$certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
	$printerKey = ($printerKey) ? $printerKey : 'CA';
	$pId        = ($pId) ? $pId : 0;
	my $userData = $API->getUserData($userId);
	$userData->{CERTIFICATE_NUMBER}=$certNumber;

	my $result = $API->MysqlDB::getNextId('contact_id');
        my $fixedData=Certificate::_generateFixedData($userData);
        $API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
        return $result;
	return 1;
}

sub printAdultRegularLabel
{
    my $self = shift;
    my ($userId, $printerKey) = @_;
    my $API =Printing::Adult->new;
    $API->{PRODUCT}='ADULT';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='ADULT';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    my $dup;
    my $userData = $API->getUserData($userId);
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    $cert->printAdultLabel($userId, $userData);
    return 1;


}

sub emailUser {
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;
    my $API =Printing::Adult->new;
    $API->{PRODUCT}='ADULT';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='ADULT';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $dup;
    my $userData = $API->getUserData($userId);
    if ($userData->{COURSE_ID} == 44004 || $userData->{COURSE_ID} == 44005 || $userData->{COURSE_ID} == 44006 || $userData->{COURSE_ID} == 44007 || $userData->{COURSE_ID} == 44014 ||  $userData->{COURSE_ID} == 44015 )
    {
	    my $duplicateId = $API->getUserCertDuplicateId($userId);
	    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId,1);
	    foreach my $dataKey(keys %{$userDupData->{DATA}}) {
	     	   ###### ... and send these off to the printer
	 	   $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
	    }

            $printerKey='AD';
            my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
            eval("use Certificate::$certModule");
            my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
        ###### this is a temporary hack just so I can id a CA course
        ###### this issue will be fixed soon
           $userData->{CERTIFICATE_NUMBER}=$certNumber;
           $pId=$cert->printCertificate($userId, $userData, { EMAIL => 1 },$pId,$printerKey,0,18,$dup);
                return $pId;
    } else {
           my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
           eval("use Certificate::$certModule");
           my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
           $pId=$cert->printCertificate($userId, $userData, { EMAIL => 1 },$pId,$printerKey,0,18);
           return $pId;

    }

    return 1;
}


#my $idsPrint = IDSPrintAdult->new;
#print Dumper($idsPrint->printAdultCert('4593795','12344'));
#print Dumper($idsPrint->emailUser('4598443','12344'));

