#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Copyright Idrivesafely.com, Inc. 2006
# All Rights Reserved.  Licensed Software.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF Idrivesafely.com, Inc.
# The copyright notice above does not evidence any actual or
# intended publication of such source code.
#
# PROPRIETARY INFORMATION, PROPERTY OF Idrivesafely.com, Inc.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#!/usr/bin/perl -w 

package Fedex;

use lib qw(/ids/tools/PRINTING/lib );

use strict;
use printerSite;
use Data::Dumper;
use Settings;
use Carp;
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::Simple;
use PDF::Reuse;
use Image::Info qw(image_info dim);
use Socket 'inet_ntoa';
use Sys::Hostname 'hostname';

my $VERSION = 0.5;

=pod

=head1 NAME

Fedex

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=cut

sub new
{
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;

    my ($product,$dps) = @_;
    my $self;
    #### make sure a product is defined
    $self->{SETTINGS} = Settings->new;
    $self->{PRODUCT} = $product;
    $self->{PRODUCT_ID} = $self->{SETTINGS}->{PRODUCT_ID}->{$product};
    unless ($self->{PRODUCT})
    {
        $self->{PRODUCT}    = 'DIP';
    }

    ###### let's make sure Fedex has been instantiated w/ an existing product.  
    ###### there's no reason for it to continue if the product is not good
    my $fedex = ($dps)?$self->{SETTINGS}->getFedex($dps):$self->{SETTINGS}->getFedex($self->{PRODUCT});
    my $usps = $self->{SETTINGS}->getUSPS($self->{PRODUCT});

    if (! $fedex)
    {
        croak "$self->{PRODUCT} is an unknown Fedex account\n";
    }
    if (! $usps)
    {
        croak "$self->{PRODUCT} is an unknown USPS account\n";
    }

    ###### get the account / meter number
    $self->{ACCOUNT}        = $fedex->{ACCOUNT};
    $self->{METER}          = $fedex->{METER};
    $self->{USERCREDENTIAL} = $fedex->{USERCREDENTIAL};
    $self->{PASSWORD}       = $fedex->{PASSWORD};

    $self->{USPSACCOUNT}    = $usps->{ACCOUNT};
    $self->{USPSREQUESTERID}    = $usps->{REQUESTERID};
    $self->{USPSPASSWORD}   = $usps->{PASSWORD};
    $self->{USPSTESTACCOUNT}= 'YES';


    my $addr = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));
    
    if($addr && exists $self->{SETTINGS}->{USPS_ALLOWED_IPADDRESS}->{$addr}){
    	$self->{USPSTESTACCOUNT}   = 'NO';
    }


    my $dbConnects = dbConnect();
    $self->{CRM_CONNECT}  = $dbConnects->{CRM_CON}; 
    ### declare the class 
    bless($self, $class);

    ### ... and return
    return $self;
}

=head2 printLabel

Generate and print a label for Fedex.  The return value will be either a tracking number, an error code, or a stop code

=cut

sub printLabel
{
    my $self = shift;

    my ($data, $priority,$affiliateId,$regulatorId,$file,$trackingNumber) = @_;
    my $retval;
    if($trackingNumber){
            $self->_printFedexLabel($trackingNumber, $priority, $data);
            $retval->{TRACKINGNUMBER} = $trackingNumber;
    }else{
    	my $transaction = $self->_genFullTransaction($data,$affiliateId,$regulatorId,$file);
	    my $reply = $self->_fedExComm($transaction);
	    for my $t(sort keys %$reply){
        	if ($t eq '3')
        	{
	            $retval->{ERROR} = $reply->{$t};
        	}
	        if ($t eq 'STOP')
        	{
	            $retval->{STOP} = $reply->{$t};
        	}
	        if ($t eq '29')
        	{
	            my $trackingNumber = $reply->{$t};
        	    $self->_convertLabel($trackingNumber);
	            if(!$file){
		            $self->_printFedexLabel($trackingNumber, $priority,$data);
	    	    }
	            $retval->{TRACKINGNUMBER} = $trackingNumber;
        	}
    	}
    }
    return $retval;
}

=head2 reprintLabel

Reprint an already printed label.  

=cut

sub reprintLabel
{
    my $self = shift;
	my ($trackingNumber, $priority) = @_;

    return $self->_printFedexLabel($trackingNumber, $priority);
}

##########################
#### Define some private members


sub _fedExComm
{
    ###### slurp the class name
    my $self = shift;
	my ($transaction) = @_;
	my %tmpHash;
	use SOAP::Lite;
	my $c= SOAP::Lite
	   -> proxy('http://localhost/phpservice/generateLabel.php')
           -> call('generateLabel',$transaction->{USERCREDENTIAL},$transaction->{PASSWORD},$transaction->{ACCOUNT},$transaction->{METER},$transaction->{CUSTOMERTRANSID},$transaction->{DELIVERY_ID},$transaction->{OFFICECONTACTPERSON},$transaction->{OFFICENAME},$transaction->{OFFICEADDRESS},$transaction->{OFFICECITY},$transaction->{OFFICESTATE},$transaction->{OFFICEZIP},$transaction->{OFFICEPHONE},$transaction->{NAME},$transaction->{ATTENTION},$transaction->{ADDRESS},$transaction->{ADDRESS2},$transaction->{CITY},$transaction->{STATE},$transaction->{ZIP},$transaction->{PHONE},$transaction->{DESCRIPTION},$transaction->{SIGNATURE})
          -> result;
	if($c =~ m/TRACKING_NUMBER:/g){
		$c =~ s/TRACKING_NUMBER://g;
		$tmpHash{29}=$c;
        }elsif($c =~ m/FEDEXERROR:/g){
		$c =~ s/FEDEXERROR://g;
		$tmpHash{3}=$c;
        }else{
   	    return 0;
        }
    return \%tmpHash;
} 

sub _getOfficeShippingTrans
{
    ####### this function will generate the office shipping address in the FedEx manner
    my $self = shift;

    ###### get the hardcoded value .....add a little more efficiency
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa($self->{PRODUCT});

    my $transaction = <<TRN;
4,"$OFFICECA->{NAME}"5,"$OFFICECA->{ADDRESS}"6,""7,"$OFFICECA->{CITY}"8,"$OFFICECA->{STATE}"9,"$OFFICECA->{ZIP}"32,""117,"US"183,"$OFFICECA->{PHONE}"
TRN

	return $transaction;
} 


sub _getPNGfile
{
    my $self = shift;
	my ($reply) = @_;

    #### get the file from FedEx.  Variable 29 corresponds to the tracking number from the reply 
    #### and 188 corresponds to the PNG label data buffer

    #### the file is brought over base64 encoded, so let's do a base 64 decode.
    my $trackingNumber = $reply->{29};		        
    open(PNG,">$printerSite::SITE_PNG_PATH/$trackingNumber.png") || die(print STDERR "error:  $_");

    my @data = split(//, $reply->{188});
    my $c = @data;
    my $output = "";
  
    ##### let's do conversions
    for (my $i=0; $i<$c; ++$i)
    {
        if ($data[$i] eq "%")
        {
                $output .= chr(hex($data[$i+1] . $data[$i+2])); 
                $i+=2;
        }
        else
        {
                $output .= $data[$i];
        }
    }

    print PNG $output;
    close PNG;
}



sub _convertLabel
{
    my $self = shift;
	my ($TRACKINGNUMBER) = @_;

    ##### let's do some image manipulation.  rotate it, append an image and rotate it again so it will be in a format
    ##### we can use with our sticky labels
    system("/usr/bin/convert -background white -rotate 270 $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.png $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg");
	system("/usr/bin/convert $printerSite::SITE_PNG_PATH/blank.jpg $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg +append $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg");
	system("/usr/bin/convert -rotate 90 $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg");
	system("/usr/bin/convert -background white -rotate 180 $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg");
        
	system("rm $printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.png");

    return 0;
}

sub _printFedexLabel
{
    my $self = shift;
	my ($TRACKINGNUMBER, $priority, $data) = @_;
	if(!defined $priority || ! $priority) 
    	{
		$priority = 1;
	}
        my $PRINTER = 'HP-PDF-HOU05';
	my $media='Tray6';
	$self->_convertPDF($TRACKINGNUMBER);
	my $st='XX';   ##########  Default state, we have mentioned as XX;
        $st=($self->{PRINTING_STATE})?$self->{PRINTING_STATE}:$st;
	my $printingType=($self->{PRINTING_TYPE})?$self->{PRINTING_TYPE}:'CERTFEDX';
	my $productId=($self->{PRODUCT})?$self->{SETTINGS}->{PRODUCT_ID}->{$self->{PRODUCT}}:1;	
	($PRINTER,$media)=Settings::getPrintingDetails($self, $productId, $st,$printingType);
	my $manualPrintingLableOffices = { 'CAPRINTER' => 'HP-PDF-OAK02', 'CATRAY' => 'Tray6', 'TXPRINTER' => 'HP-PDF-HOU06', 'TXTRAY' => 'Tray6', 'AARPTXPRINTER' => 'HP-PDF-HOU04', 'AARPTXTRAY' => 'Tray5', 'DRIVERSEDTXPRINTER' => 'HP-PDF-HOU02', 'DRIVERSEDTXTRAY' => 'Tray5' };

	if($data->{PRINTMANUALLABLE}) {
		if($data->{PRINTMANUALLABLE} eq 'CA') {
			$PRINTER = $manualPrintingLableOffices->{CAPRINTER};
			$media = $manualPrintingLableOffices->{CATRAY};
		} elsif($data->{PRINTMANUALLABLE} eq 'TX') {
			$PRINTER = $manualPrintingLableOffices->{TXPRINTER};
			$media = $manualPrintingLableOffices->{TXTRAY};
			if($data->{AARPUSER} && $data->{AARPUSER} eq '1') {
				$PRINTER = $manualPrintingLableOffices->{AARPTXPRINTER};
				$media = $manualPrintingLableOffices->{AARPTXTRAY};
			}
			if($data->{DRIVERSEDUSER} && $data->{DRIVERSEDUSER} eq '1') {
				$PRINTER = $manualPrintingLableOffices->{DRIVERSEDTXPRINTER};
				$media = $manualPrintingLableOffices->{DRIVERSEDTXTRAY};
			}
		}
	}

	if(!$PRINTER){
        	$PRINTER = 'HP-PDF-HOU05';
	}	
	if(!$media){
		$media='Tray6';
	}
print STDERR "FedEx : printer - $PRINTER | medi - $media  \n";
	if(-e "/tmp/$TRACKINGNUMBER.pdf"){
		system("lp -d $PRINTER -q $priority -o position=bottom-left -o page-left=50 -o page-top=20 -o media=$media /tmp/$TRACKINGNUMBER.pdf");
		system("rm /tmp/$TRACKINGNUMBER.pdf");
	
		## Reduce the count of Fedex Label if printed ##
		my $itemId = $self->{SETTINGS}->{CERT_ORDERS_MAP}->{FEDEX};
		my @Stock = $self->{CRM_CONNECT}->selectrow_array("SELECT CURRENT_STOCK,ITEMS_PER_PACKAGE FROM stock_items WHERE ITEM_ID = ?", {}, $itemId);
		my $currentStock = $Stock[0];
		my $Items = $Stock[1]; 
		my $temp=0;
		if ($currentStock && ($Items == 0))
                {
                        $currentStock-=1;
                        $self->{CRM_CONNECT}->do("UPDATE stock_items set CURRENT_STOCK = $currentStock WHERE ITEM_ID = $itemId");
		} else {
			$temp = ($currentStock * $Items) - 1;
			$currentStock = (($temp) / ($Items));
			$self->{CRM_CONNECT}->do("UPDATE stock_items set CURRENT_STOCK = $currentStock WHERE ITEM_ID = $itemId");
                }

	}
}

sub _convertPDF
{
    my $self = shift;
    my ($TRACKINGNUMBER) = @_;
    my $hidetoolbar = '';
    my $hidemenubar = '';
    my $hidewindowui = '';
    my $fitwindow = '';
    my $centerwindow = '';
    my $xwidth = '';
    my $yheigth = '';

    if(-e "$printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg"){
			prFile("/tmp/$TRACKINGNUMBER.pdf",$hidetoolbar,$hidemenubar,$hidewindowui,$fitwindow,$centerwindow,$xwidth,$yheigth);
                        my $file = "$printerSite::SITE_PNG_PATH/$TRACKINGNUMBER.jpg";
                        my $info = image_info($file);
                        my ($width, $height) = dim($info);   
                        my $intName = prJpeg("$file",$width, $height);
                        $width=.40*$width*.95;
                        $height=.40*$height*.95;
                        my $str = "q\n";
                        $str   .= "$width 0 0 $height 90 105 cm\n";
                        $str   .= "/$intName Do\n";
                        $str   .= "Q\n";
                        prAdd($str);

                        $file = "$printerSite::SITE_PNG_PATH/blank-disclaimer.jpg";
                        $info = image_info($file);
                        ($width, $height) = dim($info);
                        $intName = prJpeg("$file",$width, $height);
                        $width=.40*$width*.95;
                        $height=.40*$height*.95;
                        $str = "q\n";
                        $str   .= "$width 0 0 $height 90 325 cm\n";
                        $str   .= "/$intName Do\n";
                        $str   .= "Q\n";
                        prAdd($str);


                        $file = "$printerSite::SITE_PNG_PATH/disclaimer.jpg";
                        $info = image_info($file);
                        ($width, $height) = dim($info);
                        $intName = prJpeg("$file",$width, $height);
                        $width=.40*$width*.95;
                        $height=.40*$height*.95;
                        $str = "q\n";
                        $str   .= "$width 0 0 $height 30 325 cm\n";
                        $str   .= "/$intName Do\n";
                        $str   .= "Q\n";
                        prAdd($str);
			if(exists $self->{SETTINGS}->{LOGO_PRINT_PRODUCT}->{$self->{PRODUCT}}){
                        	my $logoFile = "$printerSite::SITE_TEMPLATES_PATH/printing/images/ids-logo-flip.jpg";
				if($self->{SETTINGS}->{LOGO_PRINT_PRODUCT}->{$self->{PRODUCT}} eq 'DE'){
					$logoFile = "$printerSite::SITE_TEMPLATES_PATH/printing/images/driversed-logo-flip.jpg";
				}elsif($self->{SETTINGS}->{LOGO_PRINT_PRODUCT}->{$self->{PRODUCT}} eq 'EDRIVING'){
					$logoFile = "$printerSite::SITE_TEMPLATES_PATH/printing/images/edriving-logo-flip.jpg";
				}
                        	my $info2 = image_info($logoFile);
	                        my ($width2, $height2) = dim($info2);   
        	                my $intName2 = prJpeg("$logoFile",$width2, $height2);
                	        my $str2 = "q\n";
				if($self->{SETTINGS}->{LOGO_PRINT_PRODUCT}->{$self->{PRODUCT}} eq 'DE'){
		                       	$str2   .= " ";
				}elsif($self->{SETTINGS}->{LOGO_PRINT_PRODUCT}->{$self->{PRODUCT}} eq 'EDRIVING'){
		                       	$str2   .= " ";
				}else{
		                       	$str2   .= " ";
				}
	                        $str2   .= "/$intName2 Do\n";
        	                $str2   .= "Q\n";
#                	        prAdd($str2);
			}                        	
                        prEnd();
    }
}

sub _genFullTransaction
{
    my $self = shift;
    my ($data,$affiliateId,$regulatorId,$file) = @_;
    my $prepend = ($affiliateId)?"$affiliateId:  ":'';
    my %sendData;
    my @sendData =();
    my $transaction = "";
    if(exists $self->{SETTINGS}->{DELIVERYMAP}->{$self->{PRODUCT}}->{$data->{DELIVERY_ID}}){
             $data->{DELIVERY_ID}=$self->{SETTINGS}->{DELIVERYMAP}->{$self->{PRODUCT}}->{$data->{DELIVERY_ID}};
     }
    my $serviceType = { 2 => 'STANDARD_OVERNIGHT', 7 => 'FEDEX_2_DAY', 11 => 'PRIORITY_OVERNIGHT', 51 => 'FEDEX_GROUND', 26 => 'FEDEX_EXPRESS_SAVER' };

    $sendData{USERCREDENTIAL}=$self->{USERCREDENTIAL};
    $sendData{PASSWORD}=$self->{PASSWORD};
    $sendData{ACCOUNT}=$self->{ACCOUNT};
    $sendData{METER}=$self->{METER};
    $sendData{CUSTOMERTRANSID}=$self->{PRODUCT} . time();
    $sendData{DELIVERY_ID}=$serviceType->{$data->{DELIVERY_ID}};
    my $OFFICECA;
    if($file){
	    if($file == 2) {
		## For DSMS Workbook order 
	    	$OFFICECA = $self->{SETTINGS}->getOfficeCa('',2);
	    } else {
	    	$OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
	    }
    }else{
	    $OFFICECA = ($self->{DPS})?$self->{SETTINGS}->getOfficeCa($self->{DPS}):$self->{SETTINGS}->getOfficeCa($self->{PRODUCT});
	    if(!($self->{PRODUCT} && exists $self->{SETTINGS}->{OFFICE_CA}->{$self->{PRODUCT}})){
		if(!($self->{PRINTING_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$self->{PRINTING_STATE}})){
			$OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);   ####### Set for Houston Offfice with product eq 'FDK'
		}
		if($self->{PRODUCT} && $self->{PRODUCT} eq 'TEEN' && $self->{PRINTING_STATE} && $self->{PRINTING_STATE} eq 'CO'){
                $OFFICECA = $self->{SETTINGS}->getOfficeCa($self->{PRODUCT});
                }
	    }else{
		
		if(!($self->{PRINTING_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$self->{PRINTING_STATE}})){
			if(exists $self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$self->{PRODUCT}}){
				$OFFICECA=$self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$self->{PRODUCT}};   ####### Set for Houston Offfice with product'
			}
		}
	    }
    }
    $sendData{OFFICENAME}=$OFFICECA->{NAME};
    $sendData{OFFICECONTACTPERSON}='';
    $sendData{OFFICEADDRESS}=$OFFICECA->{ADDRESS};
    $sendData{OFFICECITY}=$OFFICECA->{CITY};
    $sendData{OFFICESTATE}=$OFFICECA->{STATE};
    $sendData{OFFICEZIP}=$OFFICECA->{ZIP};
    $sendData{OFFICEPHONE}=$OFFICECA->{PHONE};
    $sendData{OFFICEADDRESS} = ($OFFICECA->{ADDRESS2}) ? $sendData{OFFICEADDRESS}." ".$OFFICECA->{ADDRESS2} : $sendData{OFFICEADDRESS};
    my $uName  = uc $data->{NAME};
    $sendData{NAME}=($uName)?$uName:' ';
    $sendData{ATTENTION}=($data->{ATTENTION})?$data->{ATTENTION}:' ';
    my $mainPrintVal = maximumLineWidth($data->{ADDRESS});
    $sendData{ADDRESS}=$mainPrintVal->{MAINLINE};
    if ($mainPrintVal->{REM})
    {
	$data->{ADDRESS_2}=($data->{ADDRESS_2})?$data->{ADDRESS_2}:'';
	$data->{ADDRESS_2}=$mainPrintVal->{REM} . ' ' . $data->{ADDRESS_2};
    }
    $sendData{ADDRESS2}=($data->{ADDRESS_2})?$data->{ADDRESS_2}:' ';
    $sendData{CITY}=$data->{CITY};
    $sendData{STATE}=$data->{STATE};
    $sendData{ZIP}=$data->{ZIP};
    $sendData{PHONE}=$data->{PHONE};
    $sendData{DESCRIPTION}=($data->{DESCRIPTION})?$data->{DESCRIPTION}:' ';
    $sendData{SIGNATURE}=$data->{SIGNATURE};
    return  \%sendData;

}



sub DESTROY
{
    #### um...yeah, pretty worthless @ this point  :-)
    my $self = shift;
    if ($self->{CRM_CONNECT})
    {
        $self->{CRM_CONNECT}->disconnect;
    }

}

sub pFedexPrint
{
	my $self=shift;
        my ($userId,$data, $priority) = @_;
        my $PRIORITY = 1;
	my $fedex = "\nUSERID : $userId\n";
        my $reply = $self->printLabel($data, $PRIORITY);

        for(keys %$reply)
    	{
                if($_ eq 'TRACKINGNUMBER')
        {
                        $fedex .= "\t$_ : $$reply{$_}\n";
                }
        else
        {
                        $fedex .= "--------------------------------------------------------------------------\n";
                        $fedex .= "\t$_ : $$reply{$_}\n";
                }
        }

        return $fedex;
}



sub generateLabel
{
    my $self = shift;

    my ($data, $priority,$affiliateId,$regulatorId) = @_;
    my $retval;
    my $transaction = $self->_genFullTransaction($data,$affiliateId,$regulatorId);
    my $reply = $self->_fedExComm($transaction);
    for my $t(sort keys %$reply)
    {
        if ($t eq '3')
        {
            $retval->{ERROR} = $reply->{$t};
        }
        if ($t eq 'STOP')
        {
            $retval->{STOP} = $reply->{$t};
        }
        if ($t eq '29')
        {
            my $trackingNumber = $reply->{$t};
            $self->_convertLabel($trackingNumber);
            $retval->{TRACKINGNUMBER} = $trackingNumber;
        }
    }

    return $retval;
}

sub maximumLineWidth
{
    my ($line) = @_;

    ###### maximum character length for the court row is 25 characters.  anymore
    ###### and we're going to split the line
    my $mainLine = "";
    my $rem = "";

    if (length($line) > 32)
    {
        my @regNameArray = split(/ /, $line);
        my $regField = 0;

        while (length($mainLine) <= 32)
        {
            my $tmp = $mainLine . $regNameArray[$regField] . " ";
            if (length($tmp) <= 32)
            {
                $mainLine .= $regNameArray[$regField] . " ";
                ++$regField;
            }
            else
            {
                last;
            }
        }
        while ($regField < @regNameArray)
        {
            $rem .= $regNameArray[$regField] . " ";
            ++$regField;
        }
    }
    else
    {
        $mainLine = $line;
    }


    my $retval = { MAINLINE => $mainLine, REM => $rem };
    return $retval;
}

sub dbConnect
{
    my $self = shift;

    ###### set the home environment variable for oracle
    my $API = Settings->new; 
    my $MYSQLDB = $API->{DBCONNECTION}->{CRMDB};
    my $mysqlDBH;
    $mysqlDBH = DBI->connect("dbi:mysql:$MYSQLDB->{DBNAME}:$MYSQLDB->{HOST}",
    						$MYSQLDB->{USER},
						$MYSQLDB->{PASSWORD});
    if(!$mysqlDBH)	{ print STDERR "Error Connecting to the database: $MYSQLDB->{DBNAME} - \n";	return 0; }
    ###### ASSERT:  We connected to both databases.  Return the connections
    my $retval = { 'CRM_CON' => $mysqlDBH };

    return $retval;
}


sub printUSPSLabel
{
    my $self = shift;

    my ($data, $priority,$affiliateId,$regulatorId,$file,$trackingNumber) = @_;
    my $retval;
    if($trackingNumber){
            $self->_printUSPSMailLabel($trackingNumber, $priority);
            $retval->{TRACKINGNUMBER} = $trackingNumber;
    }else{
        my $transaction = $self->_genFullTransaction($data,$affiliateId,$regulatorId,$file);
	if($data->{DELIVERY_ID}  &&  $data->{DELIVERY_ID} eq '27'){
		$transaction->{DELIVERY_DEF}='<MailpieceShape>LargeFlatRateBox</MailpieceShape>';
	}
	if($data->{DELIVERY_ID}){
		$transaction->{DELIVERY_ID}=$data->{DELIVERY_ID};
	}
            my $reply = $self->_uspsComm($transaction);
            for my $t(sort keys %$reply){
                if ($t eq '3')
                {
                    $retval->{ERROR} = $reply->{$t};
                }
                if ($t eq '29')
                {
                    my $trackingNumber = $reply->{$t};
                    if(!$file){
                            $self->_printUSPSMailLabel($trackingNumber, $priority);
                    }
                    $retval->{TRACKINGNUMBER} = $trackingNumber;
                }
        }
    }
    return $retval;
}

sub _uspsComm
{

    ###### slurp the class name
	my $self = shift;
	my ($transaction) = @_;
	my $uspsTracking = '';
	if($transaction->{DELIVERY_ID} && $transaction->{DELIVERY_ID} eq '24') {
		$uspsTracking = 'USPSTracking="ON"';
	}
	$transaction->{OFFICEPHONE} =~ s/-| |\(|\)//gi;
        my %tmpHash;
	my $objUserAgent = LWP::UserAgent->new;
	my $request = <<XML; 
<?xml version="1.0" encoding="utf-8"?>
<LabelRequest Test="$self->{USPSTESTACCOUNT}" LabelType="Default" LabelSize="4X6"
ImageFormat="Jpeg">
<RequesterID>$self->{USPSREQUESTERID}</RequesterID>
<AccountID>$self->{USPSACCOUNT}</AccountID>
<PassPhrase>$self->{USPSPASSWORD}</PassPhrase>
<MailClass>Priority</MailClass>
$transaction->{DELIVERY_DEF}
<MailpieceShape>FlatRateEnvelope</MailpieceShape>
<DateAdvance>0</DateAdvance>
<WeightOz>1</WeightOz>
<Stealth>TRUE</Stealth>
<Services InsuredMail="OFF" SignatureConfirmation="OFF" $uspsTracking />
<Value>0</Value>
<Description>Label for $transaction->{USERID}</Description>
<PartnerCustomerID></PartnerCustomerID>
<PartnerTransactionID>$self->{PRODUCT}$self->{USERID}</PartnerTransactionID>
<ToName>$transaction->{NAME}</ToName>
<ToTitle>$transaction->{ATTENTION}</ToTitle>
<ToCompany></ToCompany>
<ToAddress1>$transaction->{ADDRESS}</ToAddress1>
<ToAddress2>$transaction->{ADDRESS2}</ToAddress2>
<ToCity>$transaction->{CITY}</ToCity>
<ToState>$transaction->{STATE}</ToState>
<ToPostalCode>$transaction->{ZIP}</ToPostalCode>
<ToPhone>$transaction->{PHONE}</ToPhone>
<FromName></FromName>
<FromCompany>$transaction->{OFFICENAME}</FromCompany>
<ReturnAddress1>$transaction->{OFFICEADDRESS}</ReturnAddress1>
<FromCity>$transaction->{OFFICECITY}</FromCity>
<FromState>$transaction->{OFFICESTATE}</FromState>
<FromPostalCode>$transaction->{OFFICEZIP}</FromPostalCode>
<FromZIP4></FromZIP4>
<FromPhone>$transaction->{OFFICEPHONE}</FromPhone>
</LabelRequest>
XML
        $request = "labelRequestXML=$request";
	my $contentlength = length($request);
	my $objHeader = HTTP::Headers->new(
                                Host => 'www.envmgr.com',
                                Content_Type => 'application/x-www-form-urlencoded',
                                Content_Length => $contentlength
                                );
        my $objRequest = HTTP::Request->new("POST","https://labelserver.endicia.com/LabelService/EwsLabelService.asmx/GetPostageLabelXML",$objHeader,$request);
        my $objResponse = $objUserAgent->request($objRequest);
	if (!$objResponse->is_error)
        {
		my $content = $objResponse->content;
                my $xml = new XML::Simple;
                my $data = $xml->XMLin($content);
		my $data1=$data->{Base64LabelImage};
		my $trackingNumber=$data->{TrackingNumber};
		my $transactionId=$data->{TransactionID};
		my $amount=$data->{FinalPostage};
		if($trackingNumber){
	                $tmpHash{29}=$trackingNumber;
        	        my $decoded= MIME::Base64::decode_base64($data1);
			if(!-d "$printerSite::SITE_PNG_PATH/USPS"){
				mkdir "$printerSite::SITE_PNG_PATH/USPS";
			}
                	open my $fh, ">$printerSite::SITE_PNG_PATH/USPS/$trackingNumber.jpg" or die $!;
	                binmode $fh;
        	        print $fh $decoded;
                	close $fh;
			$self->{CRM_CONNECT}->do("insert into usps_mail_transaction (print_date,product_id,tracking_number,print_transaction_id,amount) values (now(),'$self->{PRODUCT_ID}','$trackingNumber','$transactionId','$amount')");
		}else{
			$tmpHash{3}= $data->{ErrorMessage};
		}

	}else{
                $tmpHash{3}= $objResponse->error_as_HTML;

	}
    return \%tmpHash;
}


sub _uspsRefund
{
    ###### slurp the class name
        my $self = shift;
        my ($trackingNumber,$transactionId) = @_;
        my %tmpHash;
        my $objUserAgent = LWP::UserAgent->new;
	my $WST=time();
	my $ua = LWP::UserAgent->new(env_proxy => 1, keep_alive => 1, timeout => 40);
	my $url='https://www.envmgr.com/LabelService/EwsLabelService.asmx?op=GetRefund';
	if($self->{USPSTESTACCOUNT} && $self->{USPSTESTACCOUNT} eq 'NO'){
		$url='https://labelserver.endicia.com/LabelService/EwsLabelService.asmx?op=GetRefund';
	}
	my $req = HTTP::Request->new(POST => $url);
	my $xmlData = <<XML;
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetRefund xmlns="www.envmgr.com/LabelService">
      <RefundRequest>
        <RequesterID>$self->{USPSREQUESTERID}</RequesterID>
        <RequestID>$WST</RequestID>
        <CertifiedIntermediary>
          <AccountID>$self->{USPSACCOUNT}</AccountID>
          <PassPhrase>$self->{USPSPASSWORD}</PassPhrase>
          <Token></Token>
        </CertifiedIntermediary>
        <PicNumbers>
          <PicNumber>$trackingNumber</PicNumber>
        </PicNumbers>
        <TransactionIds>
          <TransactionId>$transactionId</TransactionId>
        </TransactionIds>
        <PieceNumbers>
          <PieceNumber>1</PieceNumber>
        </PieceNumbers>
      </RefundRequest>
    </GetRefund>
  </soap:Body>
</soap:Envelope>
XML
	my $length = length($xmlData);
	$req->content($xmlData);
	$req->header('Content-length' => $length,'Content-Type'=> 'text/xml', charset=>'utf-8');
	my $res =  $ua->request($req);
	my $content = $res->content;
                my $xml = new XML::Simple;
                my $data = $xml->XMLin($content);
                my $data1=$data->{'soap:Body'}{GetRefundResponse}{RefundResponse}{Refund};
		if(ref($data1) eq 'ARRAY'){
	                return "$data->{'soap:Body'}{GetRefundResponse}{RefundResponse}{Refund}[0]->{RefundStatusMessage}";

		}else{
	                return "$data->{'soap:Body'}{GetRefundResponse}{RefundResponse}{Refund}{RefundStatus}";
                }

}


sub _printUSPSMailLabel
{
    my $self = shift;
        my ($TRACKINGNUMBER, $priority) = @_;
        if(!defined $priority || ! $priority)
        {
                $priority = 1;
        }
        my $PRINTER = 'HP-PDF-HOU05';
        my $media='Tray6';
	system("/usr/bin/convert -background white -rotate 90 $printerSite::SITE_PNG_PATH/USPS/$TRACKINGNUMBER.jpg $printerSite::SITE_PNG_PATH/USPS/$TRACKINGNUMBER.jpg");
        $self->_convertUSPSPDF($TRACKINGNUMBER);
        my $st='XX';   ##########  Default state, we have mentioned as XX;
        $st=($self->{PRINTING_STATE})?$self->{PRINTING_STATE}:$st;
        my $printingType=($self->{PRINTING_TYPE})?$self->{PRINTING_TYPE}:'CERTFEDX';
        my $productId=($self->{PRODUCT})?$self->{SETTINGS}->{PRODUCT_ID}->{$self->{PRODUCT}}:1;
        ($PRINTER,$media)=Settings::getPrintingDetails($self, $productId, $st,$printingType);
        if(!$PRINTER){
                $PRINTER = 'HP-PDF-HOU05';
        }
        if(!$media){
                $media='Tray6';
        }
	print STDERR "USPS : printer - $PRINTER | medi - $media  \n";
        if(-e "/tmp/$TRACKINGNUMBER.pdf"){
                system("lp -d $PRINTER -q $priority -o position=bottom-left -o page-left=50 -o page-top=20 -o media=$media /tmp/$TRACKINGNUMBER.pdf");
                system("rm /tmp/$TRACKINGNUMBER.pdf");

                ## Reduce the count of Fedex Label if printed ##
                my $itemId = $self->{SETTINGS}->{CERT_ORDERS_MAP}->{USPS};
                my @Stock = $self->{CRM_CONNECT}->selectrow_array("SELECT CURRENT_STOCK,ITEMS_PER_PACKAGE FROM stock_items WHERE ITEM_ID = ?", {}, $itemId);
                my $currentStock = $Stock[0];
                my $Items = $Stock[1];
                my $temp=0;
                if ($currentStock && ($Items == 0))
                {
                        $currentStock-=1;
                        $self->{CRM_CONNECT}->do("UPDATE stock_items set CURRENT_STOCK = $currentStock WHERE ITEM_ID = $itemId");
                } else {
                        $temp = ($currentStock * $Items) - 1;
			if(!$Items){
				$temp=0;
				$Items=1;
			}
                        $currentStock = (($temp) / ($Items));
                        $self->{CRM_CONNECT}->do("UPDATE stock_items set CURRENT_STOCK = $currentStock WHERE ITEM_ID = $itemId");
                }

        }
}

sub _convertUSPSPDF
{
    my $self = shift;
    my ($TRACKINGNUMBER) = @_;
    my $hidetoolbar = '';
    my $hidemenubar = '';
    my $hidewindowui = '';
    my $fitwindow = '';
    my $centerwindow = '';
    my $xwidth = '';
    my $yheigth = '';

    if(-e "$printerSite::SITE_PNG_PATH/USPS/$TRACKINGNUMBER.jpg"){
	    prFile("/tmp/$TRACKINGNUMBER.pdf",$hidetoolbar,$hidemenubar,$hidewindowui,$fitwindow,$centerwindow,$xwidth,$yheigth);
            my $file = "$printerSite::SITE_PNG_PATH/USPS/$TRACKINGNUMBER.jpg";
            my $info = image_info($file);
            my ($width, $height) = dim($info);
            my $intName = prJpeg("$file",$width, $height);
            $width=72*$width/300;
            $height=72*$height/300;
            my $str = "q\n";
            $str   .= "$width 0 0 $height 80 440 cm\n";
            $str   .= "/$intName Do\n";
            $str   .= "Q\n";
            prAdd($str);
            prEnd();
    }
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Fedex.pm $

=item $Author: sudheerb $

=item $Date: 2009-11-18 11:18:12 $

=item $Rev: 62 $

=cut

1;
