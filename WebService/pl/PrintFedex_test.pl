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
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

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
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub reprintFedexLabel
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::DIP;
    my $API =Printing::DIP->new;
    $API->{PRODUCT}='DIP';
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
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub printFedexRegulatorTransactionTSTG
{
    my $self = shift;
    use Printing::TSTG;
    my $API =Printing::TSTG->new;
    $API->{PRODUCT}='TSTG';
    $API->constructor;

    my ($REGULATORID, $DELTYPE, $CERTCOUNT, $OFFICEID, $AFFILIATE_ID) = @_;

        my $retval = $API->pRegulatorFedexPrint($REGULATORID, $DELTYPE, $CERTCOUNT,  $AFFILIATE_ID);

    return $retval;
}

sub printFedexUserLabelTSTG
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::TSTG;
    my $API =Printing::TSTG->new;
    $API->{PRODUCT}='TSTG';
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub reprintFedexLabelTSTG
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::TSTG;
    my $API =Printing::TSTG->new;
    $API->{PRODUCT}='TSTG';
    $API->constructor;
    
    my $retval = $API->pReprintFedexLabel($userId,$trackingNumber, $priority);

    return $retval;
}

sub printFedexRegulatorTransactionAZTS
{
    my $self = shift;
    use Printing::AZTS;
    my $API =Printing::AZTS->new;
    $API->{PRODUCT}='AZTS';
    $API->constructor;

    my ($REGULATORID, $DELTYPE, $CERTCOUNT, $OFFICEID, $AFFILIATE_ID) = @_;

        my $retval = $API->pRegulatorFedexPrint($REGULATORID, $DELTYPE, $CERTCOUNT,  $AFFILIATE_ID);

    return $retval;
}

sub printFedexUserLabelAZTS
{
    my $self = shift;
    my ($userId, $affiliate) = @_;
    use Printing::AZTS;
    my $API =Printing::AZTS->new;
    $API->{PRODUCT}='AZTS';
    $API->constructor;

    my $retval = $API->printFedexLabel($userId,1,'',1);

    return $retval;
}

sub reprintFedexLabelAZTS
{
    my $self = shift;
    my ($userId, $trackingNumber, $priority) = @_;
    use Printing::AZTS;
    my $API =Printing::AZTS->new;
    $API->{PRODUCT}='AZTS';
    $API->constructor;
    
    my $retval = $API->pReprintFedexLabel($userId,$trackingNumber, $priority);

    return $retval;
}

sub printNonUserFedexLabelTeen
{
    my $self = shift;
    use Printing::Teen;
    my $API =Printing::Teen->new;
    $API->{PRODUCT}='TEEN';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub printNonUserFedexLabelTSTG
{
    my $self = shift;
    use Printing::TSTG;
    my $API =Printing::TSTG->new;
    $API->{PRODUCT}='TSTG';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

sub printNonUserFedexLabelAZTS
{
    my $self = shift;
    use Printing::AZTS;
    my $API =Printing::AZTS->new;
    $API->{PRODUCT}='AZTS';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory );

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
    $API->{DPS}='DPS';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory,$shippingId,$printerKey) = @_;
    if(!$printerKey){
	$printerKey='CA';
    }
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
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
    $API->constructor;

    my $userDupData = $API->getUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $API->pDuplicateFedexLabelPrint($shippingId);
  	 
    return $retval;
}

sub MATUREprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::Mature;
    my $matureAPI = Printing::Mature->new;
    $matureAPI->{PRODUCT}='MATURE';
    $matureAPI->constructor;
    my $userDupData = $matureAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $matureAPI->pDuplicateFedexLabelPrint($shippingId);

    return $retval;
}

sub TEENprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;

    use Printing::Teen;
    my $teenAPI = Printing::Teen->new;
    $teenAPI->{PRODUCT}='TEEN';
    $teenAPI->constructor;
    my $userDupData = $teenAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $teenAPI->pDuplicateFedexLabelPrint($shippingId);

    return $retval;
}

sub TSTGprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;
  	 
    use Printing::TSTG;
    my $tstgAPI = Printing::TSTG->new;
    $tstgAPI->{PRODUCT}='TSTG';
    $tstgAPI->constructor;
    my $userDupData = $tstgAPI->getUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $tstgAPI->pDuplicateFedexLabelPrint($shippingId);	 

    return $retval;
}

sub AZTSprintDuplicateFedexUserLabel
{
    my $self = shift;
    my ($userId,$duplicateId) = @_;
    
    use Printing::AZTS;
    my $aztsAPI = Printing::AZTS->new;
    my $userDupData = $aztsAPI->AZTSpGetUserCertDuplicateData($userId,$duplicateId);
    my $shippingId = $userDupData->{SHIPPING_ID};
    my $retval = $aztsAPI->pDuplicateFedexLabelPrint($shippingId);  	 
    return $retval;
}

sub printNonUserFedexLabelMATURE
{
    my $self = shift;
    use Printing::Mature;
    my $API =Printing::Mature->new;
    $API->{PRODUCT}='MATURE';
    $API->constructor;
    my ($name, $attention, $address, $address_2, $city, $state, $zip, $phone, $description, $signature,
        $deliveryId, $printCategory) = @_;

    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my %data = ( NAME => $name, ATTENTION => $attention, ADDRESS => $address, CITY => $city,
                 STATE => $state, ZIP => $zip, PHONE => $phone, DESCRIPTION => $description,
                 SIGNATURE => $signature, DELIVERY_ID => $deliveryId, PRINTCATEGORYID => $printCategory );

    my $resp = $API->pNonUserFedexLabelPrint(\%data);

    return $resp;
}

my $test = IDSFedex->new;
#my $retval = $test->printFedexUserLabelCLASSROOM(7897986); 
my $retval = $test->printFedexUserLabel(9785593);
#my $retval = $test->reprintFedexLabel(0,790371706484,1);
print Dumper($retval);
