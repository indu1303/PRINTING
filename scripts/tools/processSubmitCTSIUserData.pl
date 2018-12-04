#!/usr/local/bin/perl -I /ids/tools/PRINTING/lib -I /ids/tools/PRINTING_REVAMP/lib 

use strict;
use HTTP::Request::Common qw(POST GET);
use LWP::UserAgent;
use MIME::Lite;
use Net::SSL;
use Symbol;
use printerSite;
use Settings;
use Accessory;
use Data::Dumper;
use Printing::DIP;
use Printing::AHST;
use Printing::HTS;
use Date::Manip;

my $userId = $ARGV[0];
my $providerId = $ARGV[1];
my $providerKey = $ARGV[2];
my $providerUrl = $ARGV[3];
my $productId = $ARGV[4];
my $API;
my $ctsiSubmitDate = &UnixDate('now', '%m/%d/%Y');
my $product = 'DIP';

if($productId == 12){
	$API = Printing::AHST->new;
	$API->{PRODUCT}='AHST';
	$API->constructor;
	$product = 'AHST';
}elsif($productId == 13){
	$API = Printing::HTS->new;
	$API->{PRODUCT}='HTS';
	$API->constructor;
	$product = 'HTS';
}elsif($productId == 25){
	$API = Printing::TakeHome->new;
	$API->{PRODUCT}='TAKEHOME';
	$API->constructor;
	$product = 'TAKEHOME';
}else{
	$API = Printing::DIP->new;
	$API->{PRODUCT}='DIP';
	$API->constructor;
}

if(!$providerId) {
	$providerId = 'IDS20161058';
}
if(!$providerKey) {
	$providerKey = '{2BLK5CO2TD-YLD5-RQP0-7RK8-E4L8FJGNMIH5GT}';
}
if(!$providerUrl) {
	$providerUrl = 'https://www.scmsgateway.com/prvgate/amxcertsgateway.asp';
}

my $productDetails = { 
			'AHST' => { 
					NAME => 'Affordable Home Study',
					URL  => 'support@affordablehomestudy.com',
				},
			'HTS' => { 
					NAME => 'Happy Traffic School',
					URL  => 'support@happytrafficschool.com',
				},
			};

my $MONTH_NUM   = { 'JAN' => '01', 'FEB' => '02', 'MAR' => '03', 'APR' => '04', 'MAY' => '05', 'JUN' => '06', 'JUL' => '07', 'AUG' => '08', 'SEP' => '09', 'OCT' => '10', 'NOV' => '11', 'DEC' => '12' };

if($userId) {
	my $ua = LWP::UserAgent->new();
	$ua->timeout(15);
	my $certificateCount = 1;
	my $caseNumber = $API->getUserCitation($userId,'CASE_NUMBER');
	my $userInfo =  $API->getUserInfo($userId);
	my $courtId = $API->getCTSICourtNumber($userInfo->{REGULATOR_ID});
	my $certificateDueDate = $API->getUserCitation($userId,'DUE_DATE');
	my @certificateDueDate = split(/\-/, $certificateDueDate);
	my $dueDate =  "$MONTH_NUM->{uc $certificateDueDate[1]}/$certificateDueDate[0]/$certificateDueDate[2]";
	my @completionDateArr = split(/\s+/, $userInfo->{COMPLETION_DATE});
	my @cDate = split(/\-/, $completionDateArr[0]);
	my $completionDate = "$cDate[1]/$cDate[2]/$cDate[0]";
	my $certificateNumber = $userInfo->{COURSE_ID}.":".$userId;
	my $userContact = $API->getUserContact($userId);
	my $defendantLastName = $userContact->{LAST_NAME};
	my $defendantFirstName =  $userContact->{FIRST_NAME};
	my $defendantDLnumber = $userInfo->{DRIVERS_LICENSE};
	my $defendantDLstate = 'CA';
	my $dob = $userContact->{DATE_OF_BIRTH};
	my $defendantAddress = $userContact->{ADDRESS_1};
	my $defendantCity = $userContact->{CITY};
	my $defendantState = $userContact->{STATE};
	my $defendantZip = $userContact->{ZIP};
	my $defendantPhone = $userContact->{PHONE};
	$defendantPhone =~ s/\-//g; $defendantPhone =~ s/\s+//g;
	$defendantPhone =~ s/\(//g; $defendantPhone =~ s/\)//g;
	$defendantPhone = substr($defendantPhone, length($defendantPhone)-10,length($defendantPhone));
	$defendantPhone = substr($defendantPhone,0,3)."-".substr($defendantPhone, 3,3)."-".substr($defendantPhone, 6, 10);
	my $defendantEmail = $userContact->{EMAIL};
	my $emailType = 1;
	my $popFlag = 1;
	if ($userInfo->{DRIVERS_LICENSE} =~ m/test/gi || $defendantEmail =~ m/test/gi || $defendantEmail =~ m/idrivesafely.com/gi || $defendantEmail =~ m/ed-ventures-online.com/gi || $defendantEmail =~ m/continueded.com/gi || ($defendantLastName =~ m/test/gi && $defendantFirstName =~ m/test/gi))
	{
		$providerUrl = 'https://www.scmsgateway.com/prvtbgate/tstcertsgateway.asp';
	}

	my $loginURL = "$providerUrl?providerid=$providerId&providerkey=$providerKey&certificatecount=$certificateCount&casenumber=$caseNumber&courtid=$courtId&certificateduedate=$dueDate&completiondate=$completionDate&certificatenumber=$certificateNumber&defendantlastname=$defendantLastName&defendantfirstname=$defendantFirstName&defendantdlnumber=$defendantDLnumber&defendantdlstate=$defendantDLstate&defendantdob=$dob&defendantaddress=$defendantAddress&defendantcity=$defendantCity&defendantstate=$defendantState&defendantzip=$defendantZip&defendantphone=$defendantPhone&defendantemail=$defendantEmail&emailtype=$emailType&popflag=$popFlag&studentid=$userId&programlength=8";
	$loginURL =~ s/#//g;
	#print STDERR "\nloginURL ----\n\n$loginURL \n\n\n";
	my $login_req = HTTP::Request->new( GET => $loginURL );
	my $loginPage = $API->getPage( $ua, $login_req );
	#print STDERR "\n$loginPage\n";
	my @dataArray = split(/ASP\.NET/, $loginPage);
	my $xmlString = $dataArray[1];
	$xmlString =~ s/[\r\n\t]//g;
	#print STDERR "\nXML String --\n\n->$xmlString<-\n\n";
        
	use XML::Smart;
        my $ref = new XML::Smart($xmlString);
        #print STDERR Dumper($ref);
        my $WST = time();
        $API->putCookie($userId, { CTSI_DATA_SUBMITTED => $WST });
        my $resultKey = $ref->{response}->{sequences}->{sequence}->{results}->{key};
        my $comments = '';
        if($resultKey eq 'RECEIVED') {
		##Received
		$API->putCookie($userId, { CTSI_SEND => $WST });
		$API->putCookie($userId, { CTSI_SEND_DATE => $ctsiSubmitDate });
		$API->updateCTSIUserCertNumber($userId, $certificateNumber);
		####Added For updating current stocks [CRM - ORDERING]
		my $CTSIItemId = 12;
		$API->updateCertsStock($CTSIItemId);
		####
	}
        my $warning = $ref->{response}->{sequences}->{sequence}->{results}->{warning}->{key};
        if($warning) {
                $warning .=" - ".$ref->{response}->{sequences}->{sequence}->{results}->{warning}->{message};
                $comments = $warning;
                $API->putCookie($userId, { CTSI_WARNING => $warning });
        }
        my $error = $ref->{response}->{sequences}->{sequence}->{results}->{error}->{key};
        if($error) {
                $error .=" - ".$ref->{response}->{sequences}->{sequence}->{results}->{error}->{message};
                $comments = $error;
                $API->putCookie($userId, { CTSI_ERROR => $error });
		sendErrorResponse($userId, $product);
        }
        my $status = $ref->{response}->{sequences}->{sequence}->{results}->{statusupdate}->{key};
        if($status) {
                $status .=" - ".$ref->{response}->{sequences}->{sequence}->{results}->{statusupdate}->{message};
                $comments = $status;
                $API->putCookie($userId, { CTSI_STATUS => $status });
        }
        my $idNumber = $ref->{response}->{sequences}->{sequence}->{idnumber};
        $API->deleteCookie($userId, ['CTSI_ID_NUMBER']);
        $API->putCookie($userId, { CTSI_ID_NUMBER => $idNumber });
	#print STDERR "$ref->{response}->{sequences}->{sequence}->{results}->{error}->{message}:$comments";
        print "$ref->{response}->{sequences}->{sequence}->{results}->{error}->{message}:$comments";
}

sub sendErrorResponse
{
	my ($userId, $product) = @_;
	my $userContact = $API->getUserContact($userId);
	my $userInfo = $API->getUserInfo($userId);
	my $courseId = $userInfo->{COURSE_ID};
	my $cookie = $API->getCookie($userId, ['CTSI_ERROR']);
	my $fn = $userContact->{FIRST_NAME};
	my $ln = $userContact->{LAST_NAME};
	my $productTitle = 'I DRIVE SAFELY'; 
	my $productUrl = 'wecare@idrivesafely.com';
	if(exists $productDetails->{$product}){
		$productTitle = $productDetails->{$product}{NAME}; 
		$productUrl = $productDetails->{$product}{URL};
	}
	my $courseDetails = $API->getCourseDescription($courseId);
	my $courseName = $courseDetails->{$courseId}{DEFINITION};

	my $message = <<HTML;
<p>Based on the information provided by <b>$fn</b>, we were unable to process the certificate.</p>
<table border="0" width="500" class="table_class">
	<tr>
		<td width="50">Product:</td>
		<td><b>$product</b></td>
	</tr>
	<tr>
		<td>Name:</td>
		<td><b>$fn $ln</b></td>
	</tr>
	<tr>
		<td>Userid:</td>
		<td><b>$userId</b></td>
	</tr>
</table>
<p>Error returned by SCMS : <b>$cookie->{CTSI_ERROR}</b></p>
HTML

	my $letter =<<LETTER;
<html>
<style type="text/css">
<!--
body {
	font-family: Arial, Helvetica, sans-serif;
	font-size:12px;
}
.table_class {
	font-family: Arial, Helvetica, sans-serif;
	font-size:12px;
}
h1.ids { color:#FF0000; font-size:16px; font-weight:bold;}
.titles { color:#3366CC; font-size:14px; font-weight:bold; }
-->
</style>
<title>CTSI Certificate Processing Status</title><body>
<h1 class="ids">$productTitle - $courseName</h1>
$message
<p style="height:15px;">&nbsp;</p>
<p>Best regards,</p>
<p><b>$productTitle</b></p>
</body>
</html>
LETTER

my $msg = MIME::Lite->new(
			  From => "$productTitle <$productUrl>",
			  To => 'supportmanagers@idrivesafely.com',
			  Cc => 'liz@idrivesafely.com,rebecca@idrivesafely.com',
			  Subject => "CTSI $product Certificate Processing Status ($userId)",
			  Type => 'multipart/mixed'
		  );
$msg->attach(Type => 'text/html',
             Data => "$letter"
	    );	  
$msg->send;
}

