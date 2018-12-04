#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrinterAARP')
    -> handle;

package IDSPrinterAARP;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::AARP;
use Certificate::PDF;
use Certificate::AARP;
use Certificate::AARPCA;
use Certificate::AARPNY;
use Certificate::AARPVA;
use Certificate::CertForStudent;
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
    my ($userId, $certNumber, $pId, $printerKey, $printCheck) = @_;

    my $API =Printing::AARP->new;
    $API->{PRODUCT}='AARP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AARP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};


    $printerKey = ($printerKey) ? $printerKey : 'CA';
    $pId        = ($pId) ? $pId : 0;

    my $userData = $API->getUserData($userId);
    $userData->{CERTIFICATE_NUMBER}=$certNumber;
    if($printCheck) { $userData->{PRINTCHECK}= 1; }
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    if($userData->{UPSELLEMAIL} || $userData->{UPSELLMAIL}){
	    use Certificate::CertForStudent;
    	    $cert = Certificate::CertForStudent->new($userId,$API->{PRODUCT});
    }else{
    		eval("use Certificate::$certModule");
    		$cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    }		

    if ($userData->{COURSE_ID} == 5001 || $userData->{COURSE_ID} == 5002 || $userData->{COURSE_ID} == 5003 || $userData->{COURSE_ID} == 5011 || $userData->{COURSE_ID} == 5012)
    {
            $printerKey='AD';
            my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
            eval("use Certificate::$certModule");
            my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
        ###### this is a temporary hack just so I can id a CA course
        ###### this issue will be fixed soon
		if ($userData->{PRINT_DATE})
            	{
                	##### we're checking against print date as there will never be a request for
	                ##### a duplicate unless the user has already printed
	
        	        ##### now, get the last bit of information for this user.  Take all data entries
                	##### from the user cert duplicate data tables
	                my $duplicateId = $API->getUserCertDuplicateId($userId);
        	        my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
			my ($dupfirstname,$duplastname);				
        	        foreach my $dataKey(keys %{$userDupData->{DATA}})
                	{
	                    ###### ... and send these off to the printer
        	            $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
			    if ($dataKey eq 'FIRST_NAME') {
				$dupfirstname = $userDupData->{DATA}->{$dataKey};
			    }
			    if ($dataKey eq 'LAST_NAME') {
				$duplastname = $userDupData->{DATA}->{$dataKey};
			    }
                	}
			if ($dupfirstname || $duplastname) {
				$dupfirstname = ($dupfirstname) ? $dupfirstname : $userData->{FIRST_NAME};
				$duplastname = ($duplastname) ? $duplastname : $userData->{LAST_NAME};
				$userData->{NAME} = $dupfirstname . " ". $duplastname;
			}
            	}
           $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,28);
        $cert->printCAAARPLabel($userId,$userData);
    ######## let's do a quick check for a dupliate request
    ######## if there is a duplicate request, we'll substitute any data
    } else {
	    if ($userData->{PRINT_DATE})
	    {
        	##### we're checking against print date as there will never be a request for
	        ##### a duplicate unless the user has already printed
	
	        ##### now, get the last bit of information for this user.  Take all data entries
        	##### from the user cert duplicate data tables
		my $duplicateId = $API->getUserCertDuplicateId($userId);
        	my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
		my ($dupfirstname,$duplastname);
        	foreach my $dataKey(keys %{$userDupData->{DATA}})
	        {
        	    ###### ... and send these off to the printer
	            $userData->{$dataKey} = $userDupData->{DATA}->{$dataKey};
		    if ($dataKey eq 'FIRST_NAME') {
                    	$dupfirstname = $userDupData->{DATA}->{$dataKey};
                    }
                    if ($dataKey eq 'LAST_NAME') {
                        $duplastname = $userDupData->{DATA}->{$dataKey};
                    }
        	}
		if ($dupfirstname || $duplastname) {
                	$dupfirstname = ($dupfirstname) ? $dupfirstname : $userData->{FIRST_NAME};
                        $duplastname = ($duplastname) ? $duplastname : $userData->{LAST_NAME};
                        $userData->{NAME} = $dupfirstname . " ". $duplastname;
                }
	    }
	
	    ##### ok, let's load up the @args array w/ the params to send into the
	    ##### print function
	    $pId=$cert->printCertificate($userId, $userData, { PRINTER => 1 },$pId,$printerKey,0,28);
    	    if($pId && !$userData->{PRINT_DATE} && $userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'TX'){
            	$API->putCookie($userId, {'CERT_SENT_VIA_EMAIL'=>'1'});
            }
    	    return $pId;
     }
	return 1;
}


sub emailUser
{
    my $self = shift;
    my ($userId, $certNumber,$emailAddress) = @_;

    my $API =Printing::AARP->new;
    $API->{PRODUCT}='AARP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $global= Settings->new;
    $global->{PRODUCT}='AARP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

   
    my $userData=$API->getUserData($userId);
    my $pId=0;
    my $printerKey='CA';
    $userData->{CERTIFICATE_NUMBER} = $certNumber;
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert;
    if($userData->{UPSELLEMAIL}){
	    use Certificate::CertForStudent;
    	    $cert = Certificate::CertForStudent->new($userId,$API->{PRODUCT});
    }else{
    	eval("use Certificate::$certModule");
    	$cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    }
    $pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,28);

    return $pId;
 
}


sub printRefaxUser
{
    my $self = shift;
    my ($userId,$faxNumber,$attention,$certNumber) = @_;
    my $API =Printing::AARP->new;
    $API->{PRODUCT}='AARP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $global= Settings->new;
    $global->{PRODUCT}='AARP';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};

    ######## this function will be handled a little differently. We're going to connect and get the
    ######## course id for the user.  Based on the course id, we're going to send it to the
    ######## appropriate printing script

    my $userData = $API->getUserData($userId);
    $certNumber = ($certNumber)?$certNumber:$API->getNextCertificateNumber($userId);
    my $printerKey='CA';
    my $pId = 0;
    $userData->{CERTIFICATE_NUMBER}   = $certNumber;
    $userData->{FAX}=($faxNumber)?$faxNumber:$userData->{FAX};
    $attention=($attention)?$attention:' ';
    $userData->{ATTENTION}=$attention;
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    eval("use Certificate::$certModule");
    my $cert = ("Certificate::$certModule")->new($userId, $API->{PRODUCT});
    $pId=$cert->printCertificate($userId, $userData, { FAX => $faxNumber },$pId,$printerKey,0,28);
    return $pId;
}

sub downloadUser {
	my $API =Printing::AARP->new;
	$API->{PRODUCT}='AARP';
	$API->constructor;
	my $global= Settings->new;
	$global->{PRODUCT}='AARP';
	$global->{PRODUCT_CON}=$API->{PRODUCT_CON};
	$global->{CRM_CON}=$API->{CRM_CON};

	my $self = shift;
	my ($userId, $certNumber, $pId, $printerKey) = @_;

	$printerKey = ($printerKey) ? $printerKey : 'CA';
	$pId        = ($pId) ? $pId : 0;

	my $userData = $API->getUserData($userId,0,1);
	$userData->{CERTIFICATE_NUMBER}=$certNumber;
	my $courseId = ($userData->{COURSE_ID}) ? $userData->{COURSE_ID} : '';

	#$API->getDataFromProductSite('AARP', $courseId, $global->{PRODUCT}, $userId);
	#$userData = $API->getUserData($userId,0,1);

	my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
	my $cert;
	##For CA/NY no DND Delivery for AARP
	if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} ne 'CA' && $userData->{COURSE_STATE} ne 'NY'){
		#use Certificate::CertForStudent;
		#$cert = Certificate::CertForStudent->new;
    		eval("use Certificate::$certModule");
    		$cert = ("Certificate::$certModule")->new;
		$pId=$cert->printCertificate($userId, $userData, { STDOUT => 1 },$pId,$printerKey,0,28);
		return $pId;
	}
	return $pId;
}

sub dbUsrCerDownloadInfo {
	my $API =Printing::AARP->new;
	$API->{PRODUCT}='AARP';
	$API->constructor;
	my $global= Settings->new;
	$global->{PRODUCT}='AARP';
	$global->{PRODUCT_CON}=$API->{PRODUCT_CON};
	$global->{CRM_CON}=$API->{CRM_CON};
	my $self = shift;
	my ($userId, $fromPage) = @_;
	my $userData=$API->getUserData($userId);
	$API->dbPutUserCerDownloadInfo($userId, $userData->{COURSE_ID}, $fromPage);
}



#my $idsPrint = IDSPrinterAARP->new;
#print Dumper($idsPrint->printUser('2715','5001:2715','','',1));
#print Dumper($idsPrint->emailUser('1053','33001:1053'));

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
