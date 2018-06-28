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
    my $userDupData = $matureAPI->MaturepGetUserCertDuplicateData($userId,$duplicateId);
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
    my $userDupData = $teenAPI->TeenpGetUserCertDuplicateData($userId,$duplicateId);
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
    my $userDupData = $tstgAPI->TSTGpGetUserCertDuplicateData($userId,$duplicateId);
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
#my $userList='8606366,7838851,8668043,8523766,8671235,8611266,8669429,8653329,8663815,8643242,8669464,8622053,8662506,8663395,8661246,8670059,8670626,8570106,8543485,8646693,8668260,8597749,8557674,8536051,8670752,8563645,8637733,8590140,8669149,8663304,8586381,8662387,8536443,8649094,8667112,8668393,8669268,8637880,8657242,8651677,8669303,8667371,8621325,8630201,8669793,8642234,8667280,8668806,8593297,8669576,8659839,8668302,8655758,8663339,8649297,8669562,8668771,8671634,8659195,8665670,8671172,8496970';
#my $userList='8714565,8646679,8714495,8724246,8722993,8626435,8716070,8723679,8630383,8710323,8723770,8723147,8717358,8722468,8721327,8598673,8717848,8718408,8693852,8724596,8725177,8724617,8722433,8722762,8721915,8647316,8699970,8723651,8724946,8402638,8721040,8725478,8706326,8716441,8454536,8714999,8674770,8725793,8724274,8704170,8634506,8724197,8725485,8724022,8709476,8588747,8714824,8699802,8725401,8724050,8725758,8715447,8724883,8549400,8702980,8699305,8725821,8679964,8726171,8650116,8725737,8633029,8724680,8723448,8725492,8721495,8724176,8725849,8676709,8725576,8712185,8725989,8726038,8724379,8692340,8726577,8719164,8700474,8726269,8725926,8370305,8725786,8726437,8706207,8707614,8725051,8723469,8718821,8701825,8724127,8689372,8722167,8726612,8716924,8726367,8720837,8725835,8725975,8712850,8718709,8712423,8719381,8686873,8726388,8706956,8544122,8712836,8504964,8492700,8719591,8489767,8535057,8710771,8727025,8646168,8715510,8725905,8554125,8724862,8618056,8724792,8727340,8666300,8691451,8725604,8669163,8704912,8723609,8713781,8623166,8726493,8724659,8720025,8728089,8728061,8727802,8727725,8721859,8719752,8727368,8480765,8579304,8723665,8645300,8725583,8688455,8704660,8357565,8726066,8506854,8682596,8726339,8727263,8727130,8667679,8642073,8640022,8714481,8635815,8718947,8534966,8726927,8691654,8670528,8723315,8724148,8727697,8494198,8715265,8716602,8611644,8728593,8728901,8726003,8728180,8726486,8670976,8724344,8728614,8681056,8724897,8723385,8720760,8729405,8724323,8727382,8726402';
my $userList='10359642,10423412,10551204,10500160';
my @allUsers=split(/,/,$userList);
foreach my $uId(@allUsers){
my $test = IDSFedex->new;
my $retval = $test->printFedexUserLabel($uId); 
#my $retval = $test->printFedexUserLabelTeen(1126815);
#my $retval = $test->reprintFedexLabel(0,790371706484,1);
print Dumper($retval);
print "\n $uId";
sleep 2;
print "\n";
}
