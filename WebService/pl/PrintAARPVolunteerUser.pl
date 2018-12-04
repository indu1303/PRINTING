#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrinterAARPVolunteer')
    -> handle;

package IDSPrinterAARPVolunteer;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::AARPVolunteer;
use Certificate::PDF;
use Certificate::AARPVolunteerCertificate;
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

sub emailUser
{
    my $API =Printing::AARPVolunteer->new;
    $API->{PRODUCT}='AARP_VOLUNTEER';
    $API->constructor;
    my $global= Settings->new;
    $global->{PRODUCT}='AARP_VOLUNTEER';
    $global->{PRODUCT_CON}=$API->{PRODUCT_CON};
    $global->{CRM_CON}=$API->{CRM_CON};
    my $self = shift;
    my ($userId, $emailAddress,$courseId,$certFor) = @_;

   
    my $userData=$API->getUserData($userId);
    $userData->{CERTFOR}=$certFor;
    my $pId=0;
    my $printerKey='CA';
    $userData->{CERTIFICATE_NUMBER} = $API->getNextCertificateNumber($userId,$courseId);
    $userData->{COURSE_ID}=($courseId)?$courseId:$userData->{COURSE_ID};
    $userData->{EMAIL}=($emailAddress)?$emailAddress:$userData->{EMAIL};
    my $subUserCourseInfo=$API->getUserSubCourseCompletionInfo($userId,$courseId);
    $userData->{COMPLETION_DATE}=($subUserCourseInfo)?$subUserCourseInfo:$userData->{COMPLETION_DATE};
    my $certModule = $global->getCertificateModule($global->{PRODUCT},$userData->{COURSE_ID});
    my $cert = Certificate::AARPVolunteerCertificate->new;
    $pId=$cert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },$pId,$printerKey,0,34);

    if($pId){
    	$API->putUserPrintRecord($userId,$userData->{CERTIFICATE_NUMBER},'SUBCOURSEPRINT',$courseId);
        	if($certFor && $certFor eq 'A'){
                	$API->putUserPrintRecord($userId,$userData->{CERTIFICATE_NUMBER},'PRINT',$courseId);
                }
    }


    return $pId;
 
}


#my $idsPrint = IDSPrinterAARPVolunteer->new;
#print Dumper($idsPrint->emailUser('1','hari@ed-ventures-online.com','1001','O'));

######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
