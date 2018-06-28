#!/usr/local/bin/perl -I/ids/tools/PRINTING/lib 

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
my $API = Printing::DIP->new;
$API->{PRODUCT}='DIP';
$API->constructor;

my $userId = $ARGV[0];
my $lg  = 'EN';

my $FLcounties = 
{
        'ALACHUA' => 11, 'BAKER' => 52, 'BAY' => 23, 
        'BRADFORD' => 45, 'BREVARD' => 19, 'BROWARD' => 10, 
        'CALHOUN' => 58, 'CHARLOTTE' => 53, 'CITRUS' => 47, 
        'CLAY' => 48, 'COLLIER' => 64, 'COLUMBIA' => 29, 
        'DADE' => 1, 'DESOTO' => 34, 'DIXIE' => 54, 
        'DUVAL' => 2, 'ESCAMBIA' => 9, 'FLAGLER' => 61, 
        'FRANKLIN' => 59, 'GADSDEN' => 21, 'GILCHRIST' => 55, 
        'GLADES' => 60, 'GULF' => 66, 'HAMILTON' => 56, 
        'HARDEE' => 30, 'HENDRY' => 49, 'HERNANDO' => 40, 
        'HIGHLANDS' => 27, 'HILLSBOROUGH' => 3, 'HOLMES' => 51, 
        'INDIAN RIVER' => 32, 'JACKSON' => 25, 'JEFFERSON' => 46, 
        'LAFAYETTE' => 62, 'LAKE' => 12, 'LEE' => 18, 
        'LEON' => 13, 'LEVY' => 39, 'LIBERTY' => 67, 
        'MADISON' => 35, 'MANATEE' => 15, 'MARION' => 14, 
        'MARTIN' => 42, 'MONROE' => 38, 'NASSAU' => 41, 
        'OKALOOSA' => 43, 'OKEECHOOBEE' => 57, 'ORANGE' => 7, 
        'OSCEOLA' => 26, 'PALM BEACH' => 6, 'PASCO' => 28, 
        'PINELLAS' => 4, 'POLK' => 5, 'PUTNAM' => 22, 
        'SANTA ROSA' => 33, 'SARASOTA' => 16, 'SEMINOLE' => 17, 
        'ST JOHNS' => 20, 'ST LUCIE' => 24, 'SUMTER' => 44,
        'SUWANNEE' => 31, 'TAYLOR' => 37, 'UNION' => 63, 
        'VOLUSIA' => 8, 'WAKULLA' => 65, 'WALTON' => 36, 
        'WASHINGTON' => 50, 'ST. LUCIE' => 24
};

my $MONTH_ALPHA   = { '01'=> 'JAN', '02'=>'FEB', '03' => 'MAR', '04' => 'APR', '05' => 'MAY', '06' => 'JUN',
                 '07' => 'JUL', '08' => 'AUG', '09' => 'SEP', '10' => 'OCT', '11' => 'NOV', '12' => 'DEC'};

my $courseId = $API->getUserCourseId($userId);

my $userContact = $API->getUserContact($userId);
my $userInfo = $API->getUserInfo($userId);
my $citationInfo = $API->getUserCitation($userId, 'COUNTY_YOU_RESIDE_IN');
my $citationSSN = $API->getUserCitation($userId, 'LAST_FOUR_DIGITS_OF_YOUR_SOCIAL_SECURITY_NUMBER_OR_YOUR_ALIEN_REGISTRATION');
my $del = $API->getUserDelivery($userId);
my $shippingAddress;

#### format the data to remove and apostrophes.
foreach my $k(keys %$userContact)
{
                $userContact->{$k} =~ s/\'//g;
}

my $LastName = $$userContact{LAST_NAME};
my $FirstName = $$userContact{FIRST_NAME};
my $Birthdate = $$userContact{DATE_OF_BIRTH};
my @DOB=split(/\//,$Birthdate);
$Birthdate=$DOB[1] .' '. $MONTH_ALPHA->{$DOB[0]} .' '. $DOB[2];
my $Gender = $$userContact{SEX};
my $County = $$FLcounties{$citationInfo};
my $DateRegistered = $$userContact{REGISTRATION_DATE};
my @DATEOFREG=split(/ /,$DateRegistered);
$DateRegistered=$DATEOFREG[0];
my @NEWDATEOFREG=split(/-/,$DateRegistered);
$DateRegistered=$NEWDATEOFREG[2] .'-'. $MONTH_ALPHA->{$NEWDATEOFREG[1]} .'-'. $NEWDATEOFREG[0];
my $CoursecompletedDate = $$userInfo{COMPLETION_DATE};

my $DeliveryMethod = '';
my $SchoolCode = 'IDS';
my $Add1 = $$userContact{ADDRESS_1};
$Add1 .= (defined $$userContact{ADDRESS_2} && $$userContact{ADDRESS_2}) ? ' '.$$userContact{ADDRESS_2}: '';
my $PhoneNumber = $$userContact{PHONE};
my $City = $$userContact{CITY};
my $State = $$userContact{STATE};
my $Zip = $$userContact{ZIP};
my $StudentID = $userId;

if($$del{DELIVERY_ID} eq '2' || $del->{DELIVERY_ID} eq '11') 
{
	$shippingAddress = $API->getUserShipping($userId);
	if(keys %$shippingAddress) 
        {
                foreach my $k(keys %$shippingAddress)
                {
                        $shippingAddress->{$k} =~ s/\'//g;
                }
                
		$Add1 = $$shippingAddress{ADDRESS};
		$PhoneNumber = $$shippingAddress{PHONE};
		$City = $$shippingAddress{CITY};
		$State = $$shippingAddress{STATE};
		$Zip = $$shippingAddress{ZIP};
	}

	$DeliveryMethod = 'Overnight';
} 
else 
{
	$DeliveryMethod = 'US Mail';
}
my $ua = LWP::UserAgent->new;
my $req = POST "http://www.firsttimedriverclass.com/schools/reportcompleted.asp", [ LastName => $LastName, FirstName => $FirstName, Birthdate => $Birthdate, Gender => $Gender, County  => $County, DateRegistered => $DateRegistered, CoursecompletedDate => $CoursecompletedDate, DeliveryMethod => $DeliveryMethod, SchoolCode => $SchoolCode, Add1 => $Add1, PhoneNumber => $PhoneNumber, City => $City, State => $State, Zip => $Zip, StudentID => $StudentID, SSNUM => $citationSSN ];
my $content = $ua->request($req)->as_string;
######
## prepare a timestamp for this user to write into the log
my @ltime = localtime(time());
$ltime[4]++;
$ltime[5] += 1900;
$ltime[1] = ($ltime[1] >= 10) ? $ltime[1] : '0' . $ltime[1];
my $printTime = "$ltime[4]/$ltime[3]/$ltime[5] $ltime[2]:$ltime[1]";




##### set up the contact information for this person in a readable manner
my $contactInfo = <<CONTACT;
$FirstName $LastName<br />
$Add1<br />
$City, $State  $Zip
$PhoneNumber<br />
CONTACT


##### prepare an email to send verifying the user was sent
##### Prepare the header
my $header = <<HEADER;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="content-type" content="text/html;charset=ISO-8859-1">
	<title>Course Sign-Up Confirmation</title>
	<link href="$idsSite::SITE_PROD_URL/newsite/scripts/main.css" type="text/css" rel="stylesheet">
</head>

<body leftmargin="0" marginheight="0" marginwidth="0" topmargin="0">
<div align="left">
<table width="500" border="0" cellspacing="0" cellpadding="0">
<tr height="79">
	<td width="500" height="79"><img src="$idsSite::SITE_PROD_URL/newsite/images/comp/headline_02.gif" alt="" border="0"></td>
</tr>
<tr>
        <td height=50><b>The following user was rereported to ASI on $printTime</b></td>
</tr>
</table>

<table border=0 cellpadding=0 cellspacing=0 width=700>
HEADER


my $doc = <<HTML;
        
        <tr>
                <td width='5'>&nbsp;</td>
                <td valign='top' width='130'><b>Student Id:</b></td>
                <td>$StudentID<br /></td>
        </tr>

        <tr>
                <td colspan='3'>&nbsp;</td>
        </tr>
        <tr>
                <td width='5'>&nbsp;</td>
                <td valign='top' width='130'><b>Gender:</b></td>
                <td>$Gender<br /></td>
        </tr>

        
        <tr>
                <td colspan='3'>&nbsp;</td>
        </tr>
        <tr>
                <td width='5'>&nbsp;</td>
                <td valign='top' width='130'><b>User Information:</b></td>
                <td>$contactInfo<br /></td>
        </tr>

        <tr>
                <td colspan='3'>&nbsp;</td>
        </tr>
        <tr>
                <td width='5'>&nbsp;</td>
                <td valign='top' width='130'><b>Delivery Type:</b></td>
                <td>$DeliveryMethod<br /></td>
        </tr>

        <tr>
                <td colspan='3'>&nbsp;</td>
        </tr>
        <tr>
                <td width='5'>&nbsp;</td>
                <td valign='top' width='130'><b>County:</b></td>
                <td>$County<br /></td>
        </tr>
        
        <tr>
                <td colspan='3'>&nbsp;</td>
        </tr>
        <tr>
                <td width='5'>&nbsp;</td>
                <td valign='top' width='130'><b>Date Registered:</b></td>
                <td>$DateRegistered<br /></td>
        </tr>
        
        <tr>
                <td colspan='3'>&nbsp;</td>
        </tr>
        <tr>
                <td width='5'>&nbsp;</td>
                <td valign='top' width='130'><b>Course Completed Date:</b></td>
                <td>$CoursecompletedDate<br /></td>
        </tr>
        <tr>
                <td colspan='3'>&nbsp;</td>
        </tr>
        <tr>
                <td width='5'>&nbsp;</td>
                <td valign='top' width='130'><b>Last four digits of the SSN:</b></td>
                <td>$citationSSN<br /></td>
        </tr>
</table>
</body>
</html>
HTML


#### send out the email
#### prepare the email and send
my $msg = MIME::Lite->new(From => 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>',
                        To => 'supportmanagers@idrivesafely.com', Subject => "Posted to ASI for $LastName, $FirstName",
                                                Type => 'multipart/mixed');

$msg->attach(Type => 'text/html', Data => $header.$doc);
$msg->send;


##### put a cookie in this account so we can verify when the user has been both reported and received
$API->deleteCookie($userId, ['ASI_RECEIVED']);
$API->putCookie($userId, { ASI_SENT => $printTime });


#### the student has been sent.  Redirect the operator back to the main admin page
