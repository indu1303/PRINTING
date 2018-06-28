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
use Certificate::Teen;
use Certificate::INTeen;
use Certificate::COTeen;
use Certificate::CATeen;
use Certificate::PATeen;
use Certificate::TeenCertForStudent;
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
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    #my $teenAPI     = TeenPrinting->new;
    #my $userData    = $teenAPI->getUserData($userId);
    if($userData->{UPSELLMAIL} || $userData->{UPSELLMAILFEDEXOVA})
    {
	    use Certificate::TeenCertForStudent;
    	    my $cert = Certificate::TeenCertForStudent->new($userId,$API->{PRODUCT});
            $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,2);
	    if($pId && $userData->{UPSELLMAILFEDEXOVA} && !$userData->{MYACCOUNT_POC_CERT_LABEL_PRINT}) {
		my $idsPrint = IDSPrintTeen->new;
		$idsPrint->printFedexUserLabelTeenPOCUser($userId);
	    }
	    return $pId;
    }
    elsif ($userData->{COURSE_ID} == 5001 || $userData->{COURSE_ID} == 5002 || $userData->{COURSE_ID} == 5003)
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
   }
   elsif ($userData->{COURSE_STATE} eq 'GA')
   {
        	$printerKey='AD';
	        my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
            	use Certificate::GATeen;
	        my $cert = Certificate::GATeen->new($userId,$API->{PRODUCT});
                $pId=$cert->printCertificate($userId, $userData,$pId,2);
                return $pId;
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

             #   foreach my $dataKey(keys %{$userDupData})
		foreach my $dataKey(keys %{$userDupData->{DATA}})
                {
                    ###### ... and send these off to the printer
            	   # $userData->{$dataKey} = $userDupData->{$dataKey};
            	   if($dataKey ne 'CERTIFICATE_NUMBER' ){
		    $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
		   }
	           if($dataKey eq 'CERTIFICATE_NUMBER'){
                     $userData->{'CERTIFICATE_REPLACED'} = $userDupData->{DATA}->{$dataKey};
                  }
                }
            }
	   my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
           my $loginDate=$userData->{LOGIN_DATE};
           $loginDate =~ s/(\-|\ |\:)//g;
           if($userData->{COURSE_STATE} eq 'TX' && $loginDate<20121001000000){
           	$certModule = 'Teen';
           }
           if($userData->{COURSE_STATE} eq 'TX'  && ($userData->{COURSE_ID} eq '44006' || $userData->{COURSE_ID} eq '44007')){
		$certModule='TXTeen32';
	   }
	   
	   eval("use Certificate::$certModule");
	   my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,2);
           return $pId;

    }

    return 1;
}
sub emailUser
{
    my $self = shift;
    my ($userId, $certNumber,$emailAddress, $pocCheck) = @_;

    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    my $userData=$API->getUserData($userId);
    my $pId=0;
    my $printerKey='CA';
    $userData->{CERTIFICATE_NUMBER} = $certNumber;
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    if($userData->{UPSELLEMAIL} || ( $userData->{COURSE_STATE} eq 'CO' && ($pocCheck && $pocCheck == 1) ))
    {
	    use Certificate::TeenCertForStudent;
    	    my $cert = Certificate::TeenCertForStudent->new($userId,$API->{PRODUCT});
    	    $pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,2);
    }
    else
    {	
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

    	eval("use Certificate::$certModule");
    	my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    	$pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,2);
    }
    return $pId;

}

sub resendCOAffidavit {
    my $self = shift;
    my ($userId,$emailAddress) = @_;

    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    my $userData    = $API->getUserAffidavitData($userId);
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
  	         # Now Send the mail the user
  	         # Get the PDF Path, attach that to the mail and Send
    use Affidavit::TeenAffidavit;
    my $cert = Affidavit::TeenAffidavit->new($userId,$API->{PRODUCT});
    my $pdfPath = $cert->printAffidavit($userId, $userData,{EMAIL => $userData->{EMAIL}},0);
  	         
   return $pdfPath;
}
  	 
sub printCOTeenAffidavit {
    my $self = shift;
    my ($userId,$printId) = @_;
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;

    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $userData = $API->getUserAffidavitData($userId);
    use Affidavit::TeenAffidavit;
    my $cert = Affidavit::TeenAffidavit->new($userId,$API->{PRODUCT});
    my $pdfPath = $cert->printAffidavit($userId, $userData,{PRINTER => 1},1,$printId);
    if($pdfPath) {
	    my $WST = time();
	    $API->putCookie($userId, {'CO_AFFIDAVIT_PRINTED'=>$WST});
	    return 1;
    }
         return 0;
}
sub printTeenASIUser
{
    my $self = shift;
    my ($userId) = @_;

    my $cmd = "perl /ids/tools/PRINTING/scripts/tools/processTeenASI.pl $userId";
    qx/$cmd/;

    return 1;
}

sub printTeenUserDuplicateFedexLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::Teen;
    my $teenAPI = Printing::Teen->new;
    $teenAPI->{PRODUCT}='TEEN';
    $teenAPI->{USERID}=$userId;
    $teenAPI->constructor;
    my $userDupData = $teenAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{SHIPPING_ID};
#    my $uData=$teenAPI->getUserData($userId);
    my $retval = $teenAPI->pDuplicateFedexLabelPrint($shippingId,'',$userDupData);

    return $retval;
}

sub printTeenToBeAssignCert
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
    #my $teenAPI     = TeenPrinting->new;
    #my $userData    = $teenAPI->getUserData($userId);

	my $result = $API->MysqlDB::getNextId('contact_id');
	my $fixedData=Certificate::_generateFixedData($userData);
	$API->MysqlDB::dbInsertPrintManifestStudentInfo($result,$fixedData,'');
	return $result;

    return 1;
}

sub printTeenCOLabel {
	my $self = shift;
	my ($userId) = @_;
	use Printing::Teen;
	my $API = Printing::Teen->new;
	$API->{PRODUCT}='TEEN';
	$API->{USERID}=$userId;
	$API->constructor;
	my $userData = $API->getUserData($userId);

	use Certificate::COTeen;
	my $cert=Certificate::COTeen->new($userId,$API->{PRODUCT});
	$cert->printCOTeenLabel($userId,$userData);
	
	return 1;
}
sub printTeenPermitCert
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;

    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    $userData->{PERMITCERTS}=1;
    my ($printDate,$sectionCompleteDate)=$API->getPermitCertRecord($userId);
    $userData->{SECTION_COMPLETE_DATE} = $sectionCompleteDate;
    if ($printDate)
    {
	    my $duplicateId = $API->getUserCertDuplicateId($userId);
            my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId,1);
	    if($duplicateId){
                $userData->{DUPLICATE_PERMIT_CERTS}=1;
	    }
            foreach my $dataKey(keys %{$userDupData})
            {
        	    $userData->{$dataKey} = $userDupData->{$dataKey};
            }
    }
    use Certificate::TXTeen;
    my $cert = Certificate::TXTeen->new($userId,$API->{PRODUCT});
    $pId=$cert->printCertificate($userId, $userData, { EMAIL=> $userData->{EMAIL} },$pId,$printerKey,0,2);
    return $pId;

}

sub print6HRPermitCertificate
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;

    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    #my $teenAPI     = TeenPrinting->new;
    #my $userData    = $teenAPI->getUserData($userId);
    #if ($userData->{PRINT_DATE})
    my ($printDate,$sectionCompleteDate)=$API->getPermitCertRecord($userId);
    if ($printDate)
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
    use Certificate::TXTeen32;
    my $cert = Certificate::TXTeen32->new($userId,$API->{PRODUCT});
    $pId=$cert->_generate6HRPermitCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,2);
    return $pId;
    return 1;
}

sub printCancellationNotice
{
    my $self = shift;
    my ($userId, $certNumber, $pId, $printerKey) = @_;
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='TEEN';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    $certNumber=(!$certNumber)?$API->getNextCertificateNumber($userId):$certNumber;
    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;
    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    #my $teenAPI     = TeenPrinting->new;
    #my $userData    = $teenAPI->getUserData($userId);
    use Certificate::TXTeen32;
    my $cert = Certificate::TXTeen32->new($userId,$API->{PRODUCT});
    $pId=$cert->_generateNoticeOfCancellation($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,2);
    return $pId;
    return 1;
}
sub TEENprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::Teen;
    my $teenAPI = Printing::Teen->new;
    $teenAPI->{PRODUCT}='TEEN';
    $teenAPI->{USERID}=$userId;
    $teenAPI->constructor;
    my $userDupData = $teenAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
 #  my $uData=$teenAPI->getUserData($userId);
    my $retval = $teenAPI->pDuplicateFedexLabelPrint($shippingId,'',$userDupData);
    return $retval;
}

sub printFedexUserLabelTeenPOCUser
{
    my $self = shift;
    my ($userId) = @_;
    use Printing::Teen;
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}



#my $idsPrint = IDSPrintTeen->new;
#print Dumper($idsPrint->print6HRPermitCertificate('249768'));
#print Dumper($idsPrint->print6HRPermitCertificate('248396'));
#print Dumper($idsPrint->printCancellationNotice('248396'));
#print Dumper($idsPrint->printTeenCert('8908561'));
#print Dumper($idsPrint->emailUser('268402','111','aa@dd.com','1'));
