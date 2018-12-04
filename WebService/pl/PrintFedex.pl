#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSFedex')
    -> handle;

package IDSFedex;

use lib qw(/ids/tools/PRINTING/lib);
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common;

use strict;
no strict "refs";

sub new
{
    my $self = shift;
    my $class = ref($self) || $self;
    bless {} => $class;
}

################### FedEx functions
sub printNonUserFedexLabel
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$officeId, $printingType, $userId) = @_;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $printingState='';
    if($officeId && $officeId == 1){
	$printingState='CA';
    }else{
	$printingState='TX';
    }
    $printingType = ($printingType) ? $printingType : "CERTFEDX";
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$printingState,PRINTING_TYPE=>$printingType,USERID => $userId );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);
if (exists $resp->{TRACKINGNUMBER} && ($deliveryId eq '22' || $deliveryId eq '23' || $deliveryId eq '27')) {
	$resp->{TRACKINGNUMBER} = 'USPS'.$resp->{TRACKINGNUMBER};
}
    return $resp;
}


sub printFedexRegulatorTransaction
{
    my $self = shift;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;

    my ($REGULATORID, $DELTYPE, $CERTCOUNT, $OFFICEID, $AFFILIATE_ID) = @_;

        my $retval = $API->pRegulatorFedexPrint($REGULATORID, $DELTYPE, $CERTCOUNT,  $AFFILIATE_ID);

    return $retval;
}

sub printFedexUserLabel
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $userData=$API->getUserData($userId);
    my $segmentName='';
    if($userData->{SEGMENT_ID_MAP}){
	$segmentName=$userData->{SEGMENT_NAME_MAP}
    }

    my $retval = $API->printFedexLabel($userId,1,'',1,'','',$segmentName);

    return $retval;
}

sub printUSPSUserLabel
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printUSPSLabel($userId,1,'',1);

    return $retval;
}


sub reprintUSPSLabel
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->pReprintUSPSLabel($userId,$trackingNumber, $priority);

    return $retval;
}

sub refundUSPSLabel
{
    my $self = shift;
    my ($trackingNumber, $transactionId) = @_;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my $retval = $API->refundUSPSLabel($trackingNumber, $transactionId);
    return $retval;
}

sub reprintFedexLabel
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;
    
    my $retval = $API->pReprintFedexLabel($userId,$trackingNumber, $priority);

    return $retval;
}

sub printFedexUserLabelTeen
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

sub printNonUserFedexLabelTeen
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory, $userId, $officeId) = @_;
    use Printing::Teen;
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->{USERID}=$userId;
    $API->constructor;

    my $printingState='';
    if($officeId && $officeId == 1){
        $printingState='CA';
    }else{
        $printingState='TX';
    }

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$state,PRINTING_TYPE=>'CERTFEDX',USERID => $userId, PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}


sub printFedexUserLabelCLASSROOM
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::Classroom;
    my $API =Printing::Classroom->new;
    $API->{PRODUCT}='CLASSROOM';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub printFedexUserLabelCLASS
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::Class;
    my $API =Printing::Class->new;
    $API->{PRODUCT}='CLASS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}
 
 sub printFedexUserLabelMature
 {
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::Mature;
    my $API =Printing::Mature->new;
    $API->{PRODUCT}='MATURE';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
 }


################### FedEx functions
sub printDriverRecordFedexLabel
{
    my $self = shift;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$shippingId,$printerKey) = @_;
    if(!$printerKey){
	$printerKey='CA';
    }
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, ADDRESS_2 => $address_2, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory ,SHIPPINGID => $shippingId);
    my $resp = $API->pDriverRecordFedexLabelPrint(\%data,$printerKey);

    return $resp;
}

sub printDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;
  	     
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $uData	= $API->getUserData($userId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId,'',$uData);
  	 
    return $retval;
}

sub CLASSROOMprintDuplicateFedexUserLabel
{

    my $self = shift;
    my ($userId,$duplicateId) = @_;
  	     
    use Printing::Classroom;
    my $API =Printing::Classroom->new;
    $API->{PRODUCT}='CLASSROOM';
    $API->{USERID}=$userId;
    $API->constructor;

    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $uData	= $API->getUserData($userId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId,'',$uData);
  	 
    return $retval;
}

sub CLASSprintDuplicateFedexUserLabel
{

    my $self = shift;
    my ($userId,$duplicateId) = @_;
  	     
    use Printing::Class;
    my $API =Printing::Class->new;
    $API->{PRODUCT}='CLASS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $uData	= $API->getUserData($userId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId,'',$uData);
  	 
    return $retval;
}

sub MATUREprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::Mature;
    my $matureAPI = Printing::Mature->new;
    $matureAPI->{PRODUCT}='MATURE';
    $matureAPI->{USERID}=$userId;
    $matureAPI->constructor;
    my $userDupData = $matureAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $uData	= $matureAPI->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $matureAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
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
    my $uData	= $teenAPI->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $teenAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}


sub printNonUserFedexLabelMATURE
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory, $userId) = @_;
    use Printing::Mature;
    my $API =Printing::Mature->new;
    $API->{PRODUCT}='MATURE';
    $API->{USERID}=$userId;
    $API->constructor;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$state,PRINTING_TYPE=>'CERTFEDX',USERID => $userId );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

################### FedEx functions
sub printNonTXDriverRecordFedexLabel
{
    my $self = shift;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$shippingId,$printerKey) = @_;
    if(!$printerKey){
        $printerKey='CA';
    }
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, ADDRESS_2 => $address_2, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory ,SHIPPINGID => $shippingId,PRINTING_TYPE=>'DRFEDX',PRINTING_STATE=>$state);
    my $resp = $API->pNonTXDriverRecordFedexLabelPrint(\%data,$printerKey);

    return $resp;
}

sub printFedexRegulatorTransactionAHST
{
    my $self = shift; 
    use Printing::AHST;
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->constructor;

    my ($REGULATORID, $DELTYPE, $CERTCOUNT, $OFFICEID, $AFFILIATE_ID) = @_;

        my $retval = $API->pRegulatorFedexPrint($REGULATORID, $DELTYPE, $CERTCOUNT,  $AFFILIATE_ID);
    
    return $retval;
}   
    
sub printFedexUserLabelAHST
{   
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::AHST;
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);
    
    return $retval;
}

sub reprintFedexLabelAHST
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::AHST;
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->pReprintFedexLabel($userId,$trackingNumber, $priority);

    return $retval;
}

sub printNonUserFedexLabelAHST
{
    my $self = shift;
    use Printing::AHST;
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>'CA',PRINTING_TYPE=>'CERTFEDX' );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub AHSTprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::AHST;
    my $tstgAPI = Printing::AHST->new;
    $tstgAPI->{PRODUCT}='AHST';
    $tstgAPI->constructor;
    my $userDupData = $tstgAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $uData	= $tstgAPI->getUserData($userId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $tstgAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printFedexRegulatorTransactionHTS
{
    my $self = shift;
    use Printing::HTS;
    my $API =Printing::HTS->new;
    $API->{PRODUCT}='HTS';
    $API->constructor;

    my ($REGULATORID, $DELTYPE, $CERTCOUNT, $OFFICEID, $AFFILIATE_ID) = @_;

        my $retval = $API->pRegulatorFedexPrint($REGULATORID, $DELTYPE, $CERTCOUNT,  $AFFILIATE_ID);

    return $retval;
}

sub printFedexUserLabelHTS
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::HTS;
    my $API =Printing::HTS->new;
    $API->{PRODUCT}='HTS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub reprintFedexLabelHTS
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::HTS;
    my $API =Printing::HTS->new;
    $API->{PRODUCT}='HTS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->pReprintFedexLabel($userId,$trackingNumber, $priority);

    return $retval;
}

sub printNonUserFedexLabelHTS
{
    my $self = shift;
    use Printing::HTS;
    my $API =Printing::HTS->new;
    $API->{PRODUCT}='HTS';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>'CA',PRINTING_TYPE=>'CERTFEDX' );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub HTSprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::HTS;
    my $tstgAPI = Printing::HTS->new;
    $tstgAPI->{PRODUCT}='HTS';
    $tstgAPI->{USERID}=$userId;
    $tstgAPI->constructor;
    my $userDupData = $tstgAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $uData	= $tstgAPI->getUserData($userId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $tstgAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printWorkbookUserFedexLabelAHST
{
    my $self = shift;
    use Printing::AHST;
    my $API =Printing::AHST->new;
    $API->{PRODUCT}='AHST';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$shippingId) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,SHIPPING_ID=>$shippingId,PRINTING_STATE=>'CA',PRINTING_TYPE=>'WBFEDX' );

    my $resp = $API->pNonUserFedexLabelPrint(\%data,'WORKBOOK');

    return $resp;
}

sub printWorkbookUserFedexLabelHTS
{
    my $self = shift;
    use Printing::HTS;
    my $API =Printing::HTS->new;
    $API->{PRODUCT}='HTS';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$shippingId) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,SHIPPING_ID=>$shippingId,PRINTING_STATE=>'CA',PRINTING_TYPE=>'WBFEDX' );

    my $resp = $API->pNonUserFedexLabelPrint(\%data,'WORKBOOK');

    return $resp;
}

################### FedEx functions
sub printDPSFedexLabel
{
	my $self = shift;
  	my ($userId,$printerKey) = @_;
  	use Printing::DIP;
  	my $API =Printing::DIP->new;
  	$API->{PRODUCT}='DIP';
    	$API->{USERID}=$userId;
  	$API->constructor;
  	if(!$printerKey){
  		$printerKey='TX';
        }
        ##### ok, let's load up the @args array w/ the params to send into the
        ##### print function
        my $retval = $API->printDPSFedexLabel($userId,1,$printerKey,1);
        return $retval;
}

sub printFedexUserLabelAdult
{
    my $self = shift;
    my ($userId) = @_;
    my $printerKey='AD';
    use Printing::Adult;
    my $API =Printing::Adult->new;
    $API->{PRODUCT}='ADULT';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,$printerKey,1);

    return $retval;
}
sub printNonUserFedexLabelAdult
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory, $userId, $officeId) = @_;
    use Printing::Adult;
    my $API =Printing::Adult->new;
    $API->{PRODUCT}='ADULT';
    $API->{USERID}=$userId;
    $API->constructor;

    my $printingState='';
    if($officeId && $officeId == 1){
        $printingState='CA';
    }else{
        $printingState='TX';
    }

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$state,PRINTING_TYPE=>'CERTFEDX',USERID => $userId, PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub AdultprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;
    my $printerKey='AD';
    use Printing::Adult;
    my $adultAPI = Printing::Adult->new;
    $adultAPI->{PRODUCT}='ADULT';
    $adultAPI->{USERID}=$userId;
    $adultAPI->constructor;
    my $userDupData = $adultAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $uData	= $adultAPI->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $adultAPI->pDuplicateFedexLabelPrint($shippingId,$printerKey,$uData);

    return $retval;
}

sub printFedexRegulatorTransactionAAADIP
{
    my $self = shift; 
    use Printing::AAADIP;
    my $API =Printing::AAADIP->new;
    $API->{PRODUCT}='AAADIP';
    $API->constructor;

    my ($REGULATORID, $DELTYPE, $CERTCOUNT, $OFFICEID, $AFFILIATE_ID) = @_;

        my $retval = $API->pRegulatorFedexPrint($REGULATORID, $DELTYPE, $CERTCOUNT,  $AFFILIATE_ID);
    
    return $retval;
}   
    
sub printFedexUserLabelAAADIP
{   
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::AAADIP;
    my $API =Printing::AAADIP->new;
    $API->{PRODUCT}='AAADIP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);
    
    return $retval;
}

sub reprintFedexLabelAAADIP
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::AAADIP;
    my $API =Printing::AAADIP->new;
    $API->{PRODUCT}='AAADIP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->pReprintFedexLabel($userId,$trackingNumber, $priority);

    return $retval;
}

sub printNonUserFedexLabelAAADIP
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory, $userId, $officeId) = @_;
    use Printing::AAADIP;
    my $API =Printing::AAADIP->new;
    $API->{PRODUCT}='AAADIP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $printingState='';
    if($officeId && $officeId == 1){
        $printingState='CA';
    }else{
        $printingState='TX';
    }

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,USERID => $userId, PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub AAADIPprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::AAADIP;
    my $tstgAPI = Printing::AAADIP->new;
    $tstgAPI->{PRODUCT}='AAADIP';
    $tstgAPI->{USERID}=$userId;
    $tstgAPI->constructor;
    my $userDupData = $tstgAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $tstgAPI->pDuplicateFedexLabelPrint($shippingId);

    return $retval;
}

sub printFedexUserLabelDIPDVD
{
    my $self = shift;
    my ($userId) = @_;
    use Printing::DIPDVD;
    my $API =Printing::DIPDVD->new;
    $API->{PRODUCT}='DIPDVD';
    $API->{USERID}=$userId;
    $API->constructor;
    my $userData=$API->getUserData($userId);
    my $uData=$userData->{$userId}->{USERDATA};
    my $retval = $API->printFedexLabel($userId,$uData,'',1);
    return $retval;
}

####### Fedex Functions for TAKEHOME  

sub printNonUserFedexLabelTAKEHOME
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$officeId, $printingType, $userId) = @_;
    use Printing::TakeHome;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;
    my $printingState='';
    if($officeId && $officeId == 1){
        $printingState='CA';
    }else{
        $printingState='TX';
    }
    $printingType = ($printingType) ? $printingType : "CERTFEDX";
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$printingState,PRINTING_TYPE=>$printingType,USERID => $userId, , PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub printNonUserFedexDiskLabelTHSS
{
    my $self = shift;
    use Printing::TakeHome;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$officeId, $printingType) = @_;
    my $printingState='';
    $printingState='TX';
    $printingType = ($printingType) ? $printingType : "DISKFEDEX";
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$printingState,PRINTING_TYPE=>$printingType );
    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}





sub printFedexRegulatorTransactionTAKEHOME
{
    my $self = shift;
    use Printing::TakeHome;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->constructor;

    my ($REGULATORID, $DELTYPE, $CERTCOUNT, $OFFICEID, $AFFILIATE_ID) = @_;

        my $retval = $API->pRegulatorFedexPrint($REGULATORID, $DELTYPE, $CERTCOUNT,  $AFFILIATE_ID);

    return $retval;
}

sub printFedexUserLabelTAKEHOME
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::TakeHome;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub reprintFedexLabelTAKEHOME
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::TakeHome;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->pReprintFedexLabel($userId,$trackingNumber, $priority);

    return $retval;
}

sub printDriverRecordFedexLabelTAKEHOME
{
    my $self = shift;
    use Printing::TakeHome;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$shippingId,$printerKey) = @_;
    if(!$printerKey){
        $printerKey='CA';
    }
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, ADDRESS_2 => $address_2, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory ,SHIPPINGID => $shippingId);
	
    my $resp = $API->pDriverRecordFedexLabelPrint(\%data,$printerKey);

    return $resp;
}

sub printDuplicateFedexUserLabelTAKEHOME
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::TakeHome;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->{USERID}=$userId;
    $API->constructor;

    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $API->getUserData($userId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printNonTXDriverRecordFedexLabelTAKEHOME
{
    my $self = shift;
    use Printing::TakeHome;
    my $API =Printing::TakeHome->new;
    $API->{PRODUCT}='TAKEHOME';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$shippingId,$printerKey) = @_;
    if(!$printerKey){
        $printerKey='CA';
    }
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, ADDRESS_2 => $address_2, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory ,SHIPPINGID => $shippingId,PRINTING_TYPE=>'DRFEDX',PRINTING_STATE=>$state);
    my $resp = $API->pNonTXDriverRecordFedexLabelPrint(\%data,$printerKey);

    return $resp;
}

sub printDPSFedexLabelTAKEHOME
{
        my $self = shift;
        my ($userId,$printerKey) = @_;
        use Printing::TakeHome;
        my $API =Printing::TakeHome->new;
        $API->{PRODUCT}='TAKEHOME';
    	$API->{USERID}=$userId;
        $API->constructor;
        if(!$printerKey){
                $printerKey='TX';
        }
        ##### ok, let's load up the @args array w/ the params to send into the
        ##### print function
        my $retval = $API->printDPSFedexLabel($userId,1,$printerKey,1);
        return $retval;
}

sub printFedexLabelForDiskTAKEHOME
{
        my $self = shift;
        my ($userId) = @_;

        use Printing::TakeHome;
        my $API =Printing::TakeHome->new;
        $API->{PRODUCT}='TAKEHOME';
    	$API->{USERID}=$userId;
        $API->constructor;
        my $shippingId = $API->getUserDiskShippingId($userId);
	my $shipData = $API->getUserShippingByShippingId($shippingId);
	$shipData->{FIRST_NAME}=$shipData->{NAME};
	$shipData->{ADDRESS_1}=$shipData->{ADDRESS};
	$shipData->{ADDRESS_2}=$shipData->{ADDRESS_2};
	if($shipData->{DELIVERY_ID}  eq '1'){
		 use Certificate::Oklahoma;
		 my $cert = Certificate::Oklahoma->new;
		 $cert->printRegularLabel($userId, $shipData);
		 my $retval={REGULARMAIL=>1}; 
		 return $retval;
	}else{
        	my $retval = $API->pFedexLabelPrintForDisk($shippingId);
	        return $retval;
	}
}

sub printFedexUserLabelSellerServer
{
    my $self = shift;
    my ($userId) = @_;
    use Printing::SellerServer;
    my $API =Printing::SellerServer->new;
    $API->{PRODUCT}='SS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub printNonUserFedexLabelSellerServer
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory, $userId, $officeId) = @_;
    use Printing::SellerServer;
    my $API =Printing::SellerServer->new;
    $API->{PRODUCT}='SS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $printingState='';
    if($officeId && $officeId == 1){
        $printingState='CA';
    }else{
        $printingState='TX';
    }
    
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$state,PRINTING_TYPE=>'CERTFEDX',USERID => $userId, PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub printDuplicateFedexUserLabelSellerServer
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::SellerServer;
    my $teenAPI = Printing::SellerServer->new;
    $teenAPI->{PRODUCT}='SS';
    $teenAPI->{USERID}=$userId;
    $teenAPI->constructor;
    my $userDupData = $teenAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $teenAPI->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $teenAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printFedexLabelForDiskSS
{
        my $self = shift;
        my ($userId) = @_;

        use Printing::SellerServer;
        my $API =Printing::SellerServer->new;
        $API->{PRODUCT}='SS';
        $API->{USERID}=$userId;
        $API->constructor;
        my $shippingId = $API->getUserDiskShippingId($userId);
        my $shipData = $API->getUserShippingByShippingId($shippingId);
        $shipData->{FIRST_NAME}=$shipData->{NAME};
        $shipData->{ADDRESS_1}=$shipData->{ADDRESS};
        $shipData->{ADDRESS_2}=$shipData->{ADDRESS_2};
        $shipData->{COURSE_STATE}=$shipData->{STATE};
        if($shipData->{DELIVERY_ID}  eq '1' || $shipData->{DELIVERY_ID}  eq '25' ){
                 use Certificate::Oklahoma;
                 my $cert = Certificate::Oklahoma->new;
                 $cert->printRegularLabel($userId, $shipData);
                 my $retval={REGULARMAIL=>1};
                 return $retval;
        }else{
                my $retval = $API->pFedexLabelPrintForDisk($shippingId);
                return $retval;
        }
}


sub printFedexUserLabelAARP
{
    my $self = shift;
    my ($userId) = @_;
    use Printing::AARP;
    my $API =Printing::AARP->new;
    $API->{PRODUCT}='AARP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub printNonUserFedexLabelAARP
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory, $userId, $officeId) = @_;
    use Printing::AARP;
    my $API =Printing::AARP->new;
    $API->{PRODUCT}='AARP';
    $API->{USERID}=$userId;
    $API->constructor;

    my $printingState='';
    if($officeId && $officeId == 1){
	$printingState='CA';
    }else{
	$printingState='TX';
    }

    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$state,PRINTING_TYPE=>'CERTFEDX',USERID => $userId, PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub printDuplicateFedexUserLabelAARP
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::AARP;
    my $API = Printing::AARP->new;
    $API->{PRODUCT}='AARP';
    $API->{USERID}=$userId;
    $API->constructor;
    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $API->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printRegulerLabelForDiskTHSS
{
        my $self = shift;
        my ($userId) = @_;

        use Printing::TakeHome;
        my $API =Printing::TakeHome->new;
        $API->{PRODUCT}='TAKEHOME';
    	$API->{USERID}=$userId;
        $API->constructor;
        my $shippingId = $API->getUserDiskShippingId($userId);
        my $shipData = $API->getUserShippingByShippingId($shippingId);
        $shipData->{FIRST_NAME}=$shipData->{NAME};
        $shipData->{ADDRESS_1}=$shipData->{ADDRESS};
        $shipData->{ADDRESS_2}=$shipData->{ADDRESS_2};
        $shipData->{COURSE_STATE}=$shipData->{STATE};
        use Certificate::SellerServerTABC;
        my $cert = Certificate::SellerServerTABC->new;
        $cert->printRegularLabelForDISK($userId, $shipData);
        my $retval={REGULARMAIL=>1};
        return $retval;
}
sub printFedexUserLabelUsiOnline
{
    my $self = shift;
    my ($userId) = @_;
    use Printing::USIOnline;
    my $API =Printing::USIOnline->new;
    $API->{PRODUCT}='USI_ONINE';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub printDuplicateFedexUserLabelUsiOnline
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::USIOnline;
    my $API =Printing::USIOnline->new;
    $API->{PRODUCT}='USI_ONLINE';
    $API->{USERID}=$userId;
    $API->constructor;

    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $API->getUserData($userId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub DSMSBTWprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::DSMSBTW;
    my $DSMSAPI = Printing::DSMSBTW->new;
    $DSMSAPI->{PRODUCT}='DSMS';
    $DSMSAPI->{USERID}=$userId;
    $DSMSAPI->constructor;
    my $userDupData = $DSMSAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $DSMSAPI->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $DSMSAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printFedexUserLabelAAATeen
{
    my $self = shift;
    my ($userId) = @_;
    use Printing::AAATeen;
    my $API =Printing::AAATeen->new;
    $API->{PRODUCT}='AAATEEN';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub printNonUserFedexLabelAAATeen
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory, $userId) = @_;
    use Printing::AAATeen;
    my $API =Printing::AAATeen->new;
    $API->{PRODUCT}='AAATEEN';
    $API->{USERID}=$userId;
    $API->constructor;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$state,PRINTING_TYPE=>'CERTFEDX',USERID => $userId );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub AAATEENprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::AAATeen;
    my $teenAPI = Printing::AAATeen->new;
    $teenAPI->{PRODUCT}='AAATEEN';
    $teenAPI->{USERID}=$userId;
    $teenAPI->constructor;
    my $userDupData = $teenAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $teenAPI->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $teenAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printFedexUserLabelAAASenior {
    my $self = shift;
    my ($userId) = @_;
    use Printing::AAASeniors;
    my $API =Printing::AAASeniors->new;
    $API->{PRODUCT}='AAA_SENIORS';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub printDuplicateFedexUserLabelAAASenior {
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::AAASeniors;
    my $AAASeniorAPI = Printing::AAASeniors->new;
    $AAASeniorAPI->{PRODUCT}='AAA_SENIORS';
    $AAASeniorAPI->{USERID}=$userId;
    $AAASeniorAPI->constructor;
    my $userDupData = $AAASeniorAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $AAASeniorAPI->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $AAASeniorAPI->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}

sub printFedexUserLabelDriversEd
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::DriversEd;
    my $API =Printing::DriversEd->new;
    $API->{PRODUCT}='DRIVERSED';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);
    $API->updateDriveredAirbillData($userId);

    return $retval;
}

sub printUSPSUserLabelDriversEd
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::DriversEd;
    my $API =Printing::DriversEd->new;
    $API->{PRODUCT}='DRIVERSED';
    $API->{USERID}=$userId;
    $API->constructor;

    my $retval = $API->printUSPSLabel($userId,1,'',1);
    $API->updateDriveredAirbillData($userId);

    return $retval;
}

sub printNonUserFedexLabelDriversEdNotNeeded
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$officeId, $printingType, $userId, $officeId) = @_;
    use Printing::DriversEd;
    my $API =Printing::DriversEd->new;
    $API->{PRODUCT}='DRIVERSED';
    $API->{USERID}=$userId;
    $API->constructor;

    my $printingState='';
    if($officeId && $officeId == 1){
        $printingState='CA';
    }else{       
        $printingState='TX';
    }

    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$printingState,PRINTING_TYPE=>'CERTFEDX',USERID => $userId, PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}


sub printNonUserFedexLabelEDriving
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$officeId, $printingType, $userId) = @_;
    use Printing::EDriving;
    my $API =Printing::EDriving->new;
    $API->{PRODUCT}='EDRIVING';
    $API->constructor;
    $API->{USERID}=$userId;

    my $printingState='';
    if($officeId && $officeId == 1){
        $printingState='CA';
    }else{
        $printingState='TX';
    }

    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$printingState,PRINTING_TYPE=>'CERTFEDX',USERID => $userId, PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub printNonUserFedexLabelDriversEd
{
    my $self = shift;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$officeId, $printingType, $userId) = @_;
    use Printing::DriversEd;
    my $API =Printing::DriversEd->new;
    $API->{PRODUCT}='DRIVERSED';
    $API->{USERID}=$userId;
    $API->constructor;
    my $printingState='';
    if($officeId && $officeId == 1){
        $printingState='CA';
    }else{
        $printingState='TX';
    }
    $printingType = ($printingType) ? $printingType : "CERTFEDX";
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory,PRINTING_STATE=>$printingState,PRINTING_TYPE=>$printingType,USERID => $userId, PRODUCT_ID => 'DRIVERSED', PRINTMANUALLABLE => $printingState, );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);
if (exists $resp->{TRACKINGNUMBER} && ($deliveryId eq '22' || $deliveryId eq '23' || $deliveryId eq '27')) {
        $resp->{TRACKINGNUMBER} = 'USPS'.$resp->{TRACKINGNUMBER};
}
    return $resp;
}

sub printDuplicateFedexUserLabelAARPCLASSROOM
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::AARPClassroom;
    my $API = Printing::AARPClassroom->new;
    $API->{PRODUCT}='AARP_CLASSROOM';
    $API->{USERID}=$userId;
    $API->constructor;
    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $uData   = $API->getUserData($userId);
    my $shippingId = $userDupData->{DATA}->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId,'',$uData);

    return $retval;
}



#my $test = IDSFedex->new;
#my $retval = $test->printNonUserFedexLabel('$name', '$attention', '$address', '$address_2', '$city', 'CA', '92078', '1234567890', '$description', 0,7, 1, 12345); 
#my $retval = $test->printNonUserFedexLabelEDriving('$name', '$attention', '$address', '$address_2', '$city', 'CA', '92078', '1234567890', '$description', 0,7, 1, 12345); 
#my $retval = $test->printNonUserFedexLabelDriversEd('$name', '$attention', '$address', '$address_2', '$city', 'CA', '92078', '1234567890', '$description', 0,7, 1, 12345); 
#my $retval = $test->printFedexUserLabelCLASSROOM(7897986); 
#my $retval = $test->printFedexUserLabelTeen(1126815);
#my $retval = $test->printFedexUserLabelAdult(3642376);
#my $retval = $test->reprintFedexLabel(0,790371706484,1);
#my $retval = $test->printFedexUserLabelAAASenior(505593);
#my $retval = $test->printDuplicateFedexUserLabelAARPCLASSROOM(7380889,162506);
#print Dumper($retval);
