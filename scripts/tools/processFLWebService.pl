#!/usr/bin/perl -I /www/lib -I /www/libconf

use Printing;
use MIME::Lite;
use printerSite;
use teDB;
use teHtml;

dbConnect();

my $userId = $ARGV[0];

$ENV{ORACLE_HOME} = $Printing::ORACLEHOME;
$ENV{ORACLE_SID} = $Printing::ORACLESID;


####### add some error codes for this process.  In case any of these error codes are returned, 
####### send an email detailing the issue

my %errorCodes;
$errorCode{AF000} = "Could not insert Address";
$errorCode{CC000} = "School is out of cerfificates";
$errorCode{CC001} = "Could not update School Certificate Count";
$errorCode{CF000} = "Unique STUDENT Identifier Validation Failed needs SSN( last 4),alien number last 4 or non-alien number last 4";
$errorCode{CF010} = "No Valid unique Applicant Identifier Submitted";
$errorCode{CF020} = "Submitted SSN is not four numeric digits";
$errorCode{CF031} = "Driver's license number submitted is not a valid Florida driver's license number";
$errorCode{CF032} = "Submitted as a Florida DL Number, but not in Florida DL Format X999999999999";
$errorCode{CF030} = "Driver License and State of Record are required in combination together.  One is missing";
$errorCode{CF040} = "Last 4 digits of alien registration number must be numeric";
$errorCode{CF050} = "Last 4 digits of non-alien registration number must be numeric";
$errorCode{CL000} = "County Name is a required field for this reason attending code";
$errorCode{CO000} = "County name is invalid";
$errorCode{DB000} = "Generic Student insert error";
$errorCode{DV030} = "Student First name not sent";
$errorCode{DV040} = "Student Last name is missing";
$errorCode{DV050} = "Student Sex is required";
$errorCode{DV060} = "Case number not sent";
$errorCode{DV070} = "Drivers License Number of Student is required";
$errorCode{DV080} = "Citation Date of Student is required";
$errorCode{DV090} = "Citation County of Student is required";
$errorCode{DV100} = "Citation Number of Student is required";
$errorCode{DV110} = "Reason Attending of Student is required";
$errorCode{DV120} = "INVALID Address State Code of Applicant";
$errorCode{DV130} = "Valid Numeric Address ZIP Code of Applicant is required";
$errorCode{DV140} = "Valid Numeric Address Phone of Student is required";
$errorCode{SI000} = "SCHOOL INSTRUCTOR is a required field";
$errorCode{SI001} = "SCHOOL INSTRUCTOR could not be validated";
$errorCode{ST000} = "Student First Name Missing";
$errorCode{ST001} = "Student last Name Missing";
$errorCode{ST002} = "Student Sex field Missing";
$errorCode{ST003} = "Reason Attending is a required field";
$errorCode{ST004} = "Student Date of Birth Missing";
$errorCode{ST005} = "Reason Attending Validation Failed";
$errorCode{VC000} = "Could not verify Class.  Please check class dates and times for correct data format";
$errorCode{VC001} = "Invalid Reason code";
$errorCode{VI000} = "Could not Verify Instructor";
$errorCode{VS000} = "School Validation Failed";
$errorCode{VL000} = "Log in Failed";


###### these fields are the only fields that really need to be checked.  The other fields sent over are
###### either blank, predefined, or the data will be manipulated by the time it goes out.
my %fieldLength;
$fieldLength{FIRST_NAME} = 16;
$fieldLength{LAST_NAME} = 20;
$fieldLength{SOCIAL_SECURITY_NUMBER} = 4;
$fieldLength{TICKET_NUMBER} = 7;
$fieldLength{ADDRESS_1} = 30;
$fieldLength{ADDRESS_2} = 50;
$fieldLength{CITY} = 30;
$fieldLength{EMAIL} = 30;
$fieldLength{ZIP} = 5;

###### define some values that are the defaults, like login information, etc
my $SCHOOLID            = 649;
my $COURSEID            = 263;
my $INSID               = 121;
my $WEBSERVICENAME      = "idswebservice";
my $PASSWORD            = "Traffic3000";


###### get the user's information
my $userContact         = dbGetUserContact($userId);
my $userCitation        = dbGetUserCitation($userId);
my $userInfo            = dbGetUserInfo($userId);

#### modify completion date to be inline w/ the standards needed by Fla
#### first, get the appropriate data
my $completion_date     = $userInfo->{COMPLETION_DATE};
my @completionDateTime = split(/ /,$completion_date);

#### now do the required operations...first on completion date
my @completionDate      = split(/-/,$completionDateTime[0]);
$completionDate         = $teGL::MONTH_NUM->{$completionDate[1]} . $completionDate[0] . $completionDate[2];

#### now do the required operations...on the time
my @completionTime      = split(/:/,$completionDateTime[1]);
my $completionTime      = $completionTime[0]. $completionTime[1];
$completionTime      = '0007';
#### now do the required operations...for the date of birth
my @dob                                 = split(/-/,$userContact->{DATE_OF_BIRTH});
$userContact->{DATE_OF_BIRTH}           = $teGL::MONTH_NUM->{$dob[1]} . $dob[0] . $dob[2];


#### and take out any nonnumeric characters in the phone number
$userContact->{PHONE}                   =~ s/[^0-9]//g;
if (length($userContact->{PHONE}) != 10)
{
        $userContact->{PHONE} = "8587240040";
}


my $dlState = ($userCitation->{DRIVERS_LICENSE_STATE}) ? $userCitation->{DRIVERS_LICENSE_STATE} : $userContact->{STATE};

$userCitation->{TICKET_NUMBER} =~ s/[^0-9a-zA-Z]//g;


$userCitation->{SOCIAL_SECURITY_NUMBER} =~ s/[^0-9]//g;
if ($userCitation->{SOCIAL_SECURITY_NUMBER})
{
    ####### let's make sure we got the last four chars of the SSN.....
    ####### let's pad the SSN in case it's not nine characters......
    my $ssn = $userCitation->{SOCIAL_SECURITY_NUMBER};

    if (length($ssn < 9))        {        $ssn = '0' x (9 - length($ssn)) . $ssn;    }

    ##### ok, we're assured we have at least nine chars.....now get the final four digits
    $userCitation->{SOCIAL_SECURITY_NUMBER} = substr($ssn, length($ssn)-4, 4);
}


##### get the county / regulator def 
my $countyDef           = "";
if ($userInfo->{COURSE_ID} == 2003 || $userInfo->{COURSE_ID} == 2013 || $userInfo->{COURSE_ID} == 2033)
{
        $countyDef = $userCitation->{COUNTY_YOU_RECEIVED_YOUR_CITATION_IN};
}
else
{
        if ($userInfo->{REGULATOR_ID} == 20069 || $userInfo->{REGULATOR_ID} == 20068 ||
                $userInfo->{REGULATOR_ID} == 20045 ||  $userInfo->{REGULATOR_ID} == 20070)
        {
                $countyDef = "ORANGE";
        }
        else
        {
                $countyDef = dbGetRegulatorDef($userInfo->{REGULATOR_ID}); 
        }
}

if($countyDef && lc($countyDef) eq 'miami-dade') {
	$countyDef = 'Dade';
}

##### finally, get the attendance reason:
my $attendanceReason = 'B1';

if ($userInfo->{COURSE_ID} == 2002 || $userInfo->{COURSE_ID} == 2012 || $userInfo->{COURSE_ID} == 2032) 
{
    $attendanceReason = 'B3';
    $COURSEID = 7043;
    $INSID = 19395;

}
elsif ($userInfo->{COURSE_ID} == 2003 || $userInfo->{COURSE_ID} == 2013 || $userInfo->{COURSE_ID} == 2033)
{
    $attendanceReason = 'B2';
}


##### before we do anything else, check the lengths of the individual strings so we don't get
##### errors
my %truncatedFields;
if (length $userContact->{FIRST_NAME} > $fieldLength{FIRST_NAME})
{
    $userContact->{FIRST_NAME} = substr($userContact->{FIRST_NAME},0,$fieldLength{FIRST_NAME});
    $truncatedFields{FIRST_NAME} = $userContact->{FIRST_NAME};
}
if (length $userContact->{LAST_NAME} > $fieldLength{LAST_NAME})
{
    $userContact->{LAST_NAME} = substr($userContact->{LAST_NAME},0,$fieldLength{LAST_NAME});
    $truncatedFields{LAST_NAME} = $userContact->{LAST_NAME};
}

if ($userInfo->{COURSE_ID} != 2002 && $userInfo->{COURSE_ID} != 2012 && $userInfo->{COURSE_ID} != 2032)
{
    if (length $userCitation->{TICKET_NUMBER} > $fieldLength{TICKET_NUMBER})
    {
        $userCitation->{TICKET_NUMBER} = substr($userCitation->{TICKET_NUMBER},0,$fieldLength{TICKET_NUMBER});
        $truncatedFields{TICKET_NUMBER} = $userCitation->{TICKET_NUMBER};
    }
}
else
{
    if (length $userCitation->{TICKET_NUMBER} == $fieldLength{TICKET_NUMBER})
    {
        $userCitation->{TICKET_NUMBER} = 'CO' . $userCitation->{TICKET_NUMBER};
        $truncatedFields{TICKET_NUMBER} = $userCitation->{TICKET_NUMBER};
    }
}

if (length $userContact->{ADDRESS_1} > $fieldLength{ADDRESS_1})
{
    $userContact->{ADDRESS_1} = substr($userContact->{ADDRESS_1},0,$fieldLength{ADDRESS_1});
    $truncatedFields{ADDRESS_1} = $userContact->{ADDRESS_1};
}
if (length $userContact->{ADDRESS_2} > $fieldLength{ADDRESS_2})
{
    $userContact->{ADDRESS_2} = substr($userContact->{ADDRESS_2},0,$fieldLength{APARTMENT});
    $truncatedFields{ADDRESS_2} = $userContact->{ADDRESS_2};
}
if (length $userContact->{CITY} > $fieldLength{CITY})
{
    $userContact->{CITY} = substr($userContact->{CITY},0,$fieldLength{CITY});
    $truncatedFields{CITY} = $userContact->{CITY};
}
if (length $userContact->{EMAIL} > $fieldLength{EMAIL})
{
    $userContact->{EMAIL} = substr($userContact->{EMAIL},0,$fieldLength{EMAIL});
    $truncatedFields{EMAIL} = $userContact->{EMAIL};
}
if (length $userContact->{ZIP} > $fieldLength{ZIP})
{
    $userContact->{ZIP} = substr($userContact->{ZIP},0,$fieldLength{ZIP});
    $truncatedFields{ZIP} = $userContact->{ZIP};
}


###### finally, go through and make sure each of the different keys being sent over is not null
###### if it is, add a space just to send over a character
foreach my $key(sort keys %$userContact)
{
    if (! $userContact->{$key})     { $userContact->{$key} = " "; }
}

foreach my $key(sort keys %$userInfo)
{
    if (! $userInfo->{$key})     { $userInfo->{$key} = " "; }
}

foreach my $key(sort keys %$userCitation)
{
    if (! $userCitation->{$key})     { $userCitation->{$key} = " "; }
}


####### Finally, let's make a check for the first character in the
####### drivers license......only if DLState is 'FL'
####### basically we can't have a leading zero
if ($dlState eq 'FL' && $userInfo->{DRIVERS_LICENSE} =~ m/^0/)
{
    ##### bad.....the leading 0 should be the letter O.  Change it
    $userInfo->{DRIVERS_LICENSE} =~ s/^0/O/;
}

dbDisconnect;

###### now to fill in and make the soap request.  Rather than ouline all of the fields here,
###### please refer to the file /ids/tools/HTDOCS/htdocs/wsPrimerComponent_1.wsdl for a 
###### list of all fields necessary to implement this functionality
use SOAP::Lite;
my $ws_url ='https://services.flhsmv.gov/DriverSchoolWebService/wsPrimerComponentService.svc?wsdl';
my $ws_uri = 'http://wsPrimerComponentService';

my $soap = SOAP::Lite
-> uri( $ws_uri)
->on_action(sub{'http://wsPrimerComponentService/wsPrimerComponentPort/wsVerifyData';})
-> proxy($ws_url);

my $response = $soap->wsVerifyData(
SOAP::Data->new(name =>'mvUserid' ,value =>  "$WEBSERVICENAME"),
SOAP::Data->new(name =>'mvPassword' ,value =>  "$PASSWORD"),
SOAP::Data->new(name =>'mvSchoolid' ,value =>  "$SCHOOLID"),
SOAP::Data->new(name =>'mvClassDate' ,value =>  "$completionDate"),
SOAP::Data->new(name =>'mvStartTime' ,value =>  "$completionTime"),
SOAP::Data->new(name =>'mvSchoolIns' ,value =>  "$INSID"),
SOAP::Data->new(name =>'mvSchoolCourse' ,value =>  "$COURSEID"),
SOAP::Data->new(name =>'mvFirstName' ,value =>  "$userContact->{FIRST_NAME}"),
SOAP::Data->new(name =>'mvMiddleName' ,value =>  ''),
SOAP::Data->new(name =>'mvLastName' ,value =>  "$userContact->{LAST_NAME}"),
SOAP::Data->new(name =>'mvSuffix' ,value =>  ''),
SOAP::Data->new(name =>'mvDob' ,value =>  "$userContact->{DATE_OF_BIRTH}"),
SOAP::Data->new(name =>'mvSex' ,value =>  "$userContact->{SEX}"),
SOAP::Data->new(name =>'mvSocialSN' ,value =>  ''),
SOAP::Data->new(name =>'mvCitationDate' ,value =>  ''),
SOAP::Data->new(name =>'mvCitationCounty' ,value =>  $countyDef),
SOAP::Data->new(name =>'mvCitationNumber' ,value =>  $userCitation->{TICKET_NUMBER}),
SOAP::Data->new(name =>'mvReasonAttending' ,value =>  "$attendanceReason"),
SOAP::Data->new(name =>'mvDriversLicense' ,value =>  "$userInfo->{DRIVERS_LICENSE}"),
SOAP::Data->new(name =>'mvdlStateOfRecordCode' ,value =>  "$dlState"),
SOAP::Data->new(name =>'mvAlienNumber' ,value =>  ''),
SOAP::Data->new(name =>'mvNonAlien' ,value =>  ''),
SOAP::Data->new(name =>'mvStreet' ,value =>  "$userContact->{ADDRESS_1}"),
SOAP::Data->new(name =>'mvApartment' ,value =>  "$userContact->{ADDRESS_2}"),
SOAP::Data->new(name =>'mvCity' ,value =>  "$userContact->{CITY}"),
SOAP::Data->new(name =>'mvState' ,value => "$userContact->{STATE}" ),
SOAP::Data->new(name =>'mvZipCode' ,value =>  "$userContact->{ZIP}"),
SOAP::Data->new(name =>'mvZipPlus' ,value =>  ''),
SOAP::Data->new(name =>'mvPhone' ,value =>  "$userContact->{PHONE}"),
SOAP::Data->new('mvEmail' ,value =>  "$userContact->{EMAIL}"));

my $result=$response->result;

if ($result && $result =~ /^[0-9]*$/)
{
        ##### we got a valid certificate back print it
        print $result;

        if (keys %truncatedFields)
        {
            wGenerateTruncationEmail($userId, \%truncatedFields);
        }
        exit;
}
elsif ($result =~ /\:/g)
{
        ##### We got an error.  Send an error email and return 0 to the calling script
        $soap =~ s/[^0-9a-zA-Z]//g;
        wGenerateErrorEmail($userId, $errorCode{$result});
        print "0";
        exit;
}
else
{
        ##### We didn't get an error message from the server but we didn't get an error code
        ##### print out an error and return 0;
        wGenerateErrorEmail($userId, "An unknown error has occured - $result");
        print "0";
        exit;
}


sub wGenerateTruncationEmail
{
        my ($userId, $truncationList) = @_;
        my $imgSrc = $printerSite::SITE_PROD_IMAGE_URL;
     
        my $fields = "";
        
        foreach my $fieldName(keys %$truncationList)
        {
            $fields .= "<tr><td><b>$fieldName</b></td><td>$truncationList->{$fieldName}</td></tr>\n";
        }
       
        
my $letter =<<LETTER;
            <br/><font size="2" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular"><b>The following user had the following fields truncated:</b><br></font>
            <font size="2" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular"><br>
                <table border="0" cellpadding="0" cellspacing="0" width="100%">
                $fields
                </table>
            </font>
LETTER

        my $emailText = teGenEmail($letter);

        my $email = MIME::Lite->new(From => 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>',
                                    To => 'supportmanager@idrivesafely.com',
                                    Subject => "Florida Web Service Truncation:  UserId:  $userId",
                                    Type => 'multipart/related'
                                    );

        $email->attach(Type => 'text/html',
                       Data => "$emailText"
                       );

        $email->send;
}





sub wGenerateErrorEmail
{
        my ($userId, $errorMsg) = @_;
        my $imgSrc = $printerSite::SITE_PROD_IMAGE_URL;
        
my $letter =<<LETTER;
            <font size="2" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular">The following user generated a Florida error while processing his certificate online:<br></font>
            <font size="2" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular"><br></font>
            <font size="2" face="Arial,Helvetica,Geneva,Swiss,SunSans-Regular"><br>
                <b>User ID:</b>  $userId<br>
                <b>Error Message:</b>  $errorMsg</br></br>
                </b>Please investigate the above error and reprint the student's certificate.<br>
            </font>
LETTER

        my $emailText = teGenEmail($letter);

        my $email = MIME::Lite->new(From => 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>',
                                    To => 'supportmanager@idrivesafely.com',
                                    Subject => "Florida Web Service Error:  UserId:  $userId",
                                    Type => 'multipart/related'
                                    );

        $email->attach(Type => 'text/html',
                       Data => "$emailText"
                       );

        $email->send;
}
