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

package FloridaCerts;

use lib qw(/ids/tools/PRINTING/lib);
#use Printing::DIP;
use MIME::Lite;
use Settings;
my $userId = $ARGV[0];

=pod

=head1 NAME

FloridaCerts

=head1 Synopsis

This module makes a connection with Florida's Web Service and returns a certificate number
based on the infomation sent to them.  The information is based on the user's information

At construction, the user's user id must be passed in so proper initializations and data manipulations 
may occur so it may be properly sent Florida

=head1 METHODS

=head2 new

=cut

sub new
{
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;

    my $self = {    ERROR => undef,
                    WEBSERVICENAME      => "idswebservice",
                    PASSWORD            => "Traffic3000",
                    FIELDS => { 
                                FIRST_NAME              => 16,
                                LAST_NAME               => 20,
                                SOCIAL_SECURITY_NUMBER  => 4,
                                TICKET_NUMBER           => 7,
                                ADDRESS_1               => 30,
                                ADDRESS_2               => 50,
                                CITY                    => 30,
                                EMAIL                   => 30,
                                ZIP                     => 5
                               },
                    @_,
            };
   $self->{SETTINGS} = Settings->new;
    ###### create the object 
    bless($self, $class);

    ##### ... and return
    return $self;
}




=pod

=head2 getError

Return the error code received from Florida

=cut

sub getError
{
    my $self = shift;

    return $self->{ERROR};
}



=pod

=head2 getErrorCode

Get the definition of the received error

=cut

sub getErrorCode
{
    my $self = shift;

    my ($error) = @_;

    if (! $error)
    {
        ###### there is no valid error code.  Florida might be down 
        return "An unknown error has occured.  Verify Florida's website is up and try again\n";
    }

    ##### ok, so a valid error code has been returned.  Define the different error codes 
    ##### and return the appropriate one
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
    $errorCode{999}   = "Florida System is down";

    ###### return the error code
    return $errorCode{$error};
}


###### these fields are the only fields that really need to be checked.  The other fields sent over are
###### either blank, predefined, or the data will be manipulated by the time it goes out.

###### define some values that are the defaults, like login information, etc
my $SCHOOLID            = 649;
my $COURSEID            = 263;
my $INSID               = 121;



sub _prepUserData
{
    my $self = shift;
    my ($userId,$uData)=@_;
    ###### get the user's information
    my $userData            = $uData;
    my $userCitation        = $userData->{CITATION};
#### modify completion date to be inline w/ the standards needed by Fla
#### first, get the appropriate data
my $completion_date     = $userData->{COMPLETION_DATE};
my @completionDateTime = split(/ /,$completion_date);

#### now do the required operations...first on completion date
my @completionDate      = split(/-/,$completionDateTime[0]);
$completionDate         = $self->{SETTINGS}->{MONTH_NUM}->{uc $completionDate[1]} . $completionDate[0] . $completionDate[2];

#### now do the required operations...on the time
my @completionTime      = split(/:/,$completionDateTime[1]);
my $completionTime      = $completionTime[0] . $completionTime[1];
$completionTime      = '0007';
$userData->{COMPLETION_DATE}=$completionDate;
$userData->{COMPLETION_TIME}=$completionTime;
#### now do the required operations...for the date of birth
my @dob                                 = split(/\//,$userData->{DATE_OF_BIRTH});
$userData->{DATE_OF_BIRTH}           = $dob[0] . $dob[1] . $dob[2];


#### and take out any nonnumeric characters in the phone number
$userData->{PHONE}                   =~ s/[^0-9]//g;
if (length($userData->{PHONE}) != 10)
{
        $userData->{PHONE} = "8587240040";
}


my $dlState = ($userCitation->{DRIVERS_LICENSE_STATE}) ? $userCitation->{DRIVERS_LICENSE_STATE} : $userData->{STATE};
$userData->{DLSTATE}=$dlState;
$userCitation->{TICKET_NUMBER}=($userCitation->{CITATION_NUMBER})?$userCitation->{CITATION_NUMBER}:$userCitation->{TICKET_NUMBER};
$userCitation->{TICKET_NUMBER} =~ s/[^0-9a-zA-Z]//g;
$userData->{TICKET_NUMBER} =$userCitation->{TICKET_NUMBER};

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

$userData->{SOCIAL_SECURITY_NUMBER}=$userCitation->{SOCIAL_SECURITY_NUMBER};
##### get the county / regulator def 
my $countyDef           = "";
if ($userData->{COURSE_ID} == 2003 || $userData->{COURSE_ID} == 2013 || $userData->{COURSE_ID} == 2033)
{
        $countyDef = $userCitation->{COUNTY_YOU_RECEIVED_YOUR_CITATION_IN};
}
else
{
        if ($userData->{REGULATOR_ID} == 20069 || $userData->{REGULATOR_ID} == 20068 ||
                $userData->{REGULATOR_ID} == 20045 ||  $userData->{REGULATOR_ID} == 20070)
        {
                $countyDef = "ORANGE";
        }
        else
        {
                $countyDef = $userData->{REGULATOR_DEF}; 
        }
}

$userData->{COUNTY_DEF}=$countyDef;
##### finally, get the attendance reason:
my $attendanceReason = 'B1';

if ($userData->{COURSE_ID} == 2002 || $userData->{COURSE_ID} == 2012 || $userData->{COURSE_ID} == 2032)
{
    $attendanceReason = 'B3';
    $COURSEID = 7043;
    $INSID = 19395;

}
elsif ($userData->{COURSE_ID} == 2003 || $userData->{COURSE_ID} == 2013 || $userData->{COURSE_ID} == 2033)
{
    $attendanceReason = 'B2';
}

$userData->{ATTENDANCE_REASON}=$attendanceReason;
##### before we do anything else, check the lengths of the individual strings so we don't get
##### errors
my $fieldLength=$self->{FIELDS};
my %truncatedFields;
if (length $userData->{FIRST_NAME} > $fieldLength->{FIRST_NAME})
{
    $userData->{FIRST_NAME} = substr($userData->{FIRST_NAME},0,$fieldLength->{FIRST_NAME});
    $truncatedFields{FIRST_NAME} = $userData->{FIRST_NAME};
}
if (length $userData->{LAST_NAME} > $fieldLength->{LAST_NAME})
{
    $userData->{LAST_NAME} = substr($userData->{LAST_NAME},0,$fieldLength->{LAST_NAME});
    $truncatedFields{LAST_NAME} = $userData->{LAST_NAME};
}
if ($userData->{COURSE_ID} != 2002 && $userData->{COURSE_ID} != 2012 && $userData->{COURSE_ID} != 2032)
{
    if (length $userCitation->{TICKET_NUMBER} > $fieldLength->{TICKET_NUMBER})
    {
        $userCitation->{TICKET_NUMBER} = substr($userCitation->{TICKET_NUMBER},0,$fieldLength->{TICKET_NUMBER});
        $truncatedFields{TICKET_NUMBER} = $userCitation->{TICKET_NUMBER};
    }
}
else
{
    if (length $userCitation->{TICKET_NUMBER} == $fieldLength->{TICKET_NUMBER})
    {
        $userCitation->{TICKET_NUMBER} = 'CO' . $userCitation->{TICKET_NUMBER};
        $truncatedFields{TICKET_NUMBER} = $userCitation->{TICKET_NUMBER};
    }
}
$userData->{TICKET_NUMBER}=$userCitation->{TICKET_NUMBER};

if (length $userData->{ADDRESS_1} > $fieldLength->{ADDRESS_1})
{
    $userData->{ADDRESS_1} = substr($userData->{ADDRESS_1},0,$fieldLength->{ADDRESS_1});
    $truncatedFields{ADDRESS_1} = $userData->{ADDRESS_1};
}
if (length $userData->{ADDRESS_2} > $fieldLength->{ADDRESS_2})
{
    $userData->{ADDRESS_2} = substr($userData->{ADDRESS_2},0,$fieldLength->{ADDRESS_2});
    $truncatedFields{ADDRESS_2} = $userData->{ADDRESS_2};
}
if (length $userData->{CITY} > $fieldLength->{CITY})
{
    $userData->{CITY} = substr($userData->{CITY},0,$fieldLength->{CITY});
    $truncatedFields{CITY} = $userData->{CITY};
}
if (length $userData->{EMAIL} > $fieldLength->{EMAIL})
{
    $userData->{EMAIL} = substr($userData->{EMAIL},0,$fieldLength->{EMAIL});
    $truncatedFields{EMAIL} = $userData->{EMAIL};
}
if (length $userData->{ZIP} > $fieldLength->{ZIP})
{
    $userData->{ZIP} = substr($userData->{ZIP},0,$fieldLength->{ZIP});
    $truncatedFields{ZIP} = $userData->{ZIP};
}

###### finally, go through and make sure each of the different keys being sent over is not null
###### if it is, add a space just to send over a character
foreach my $key(sort keys %$userData)
{
    if (! $userData->{$key})     { $userData->{$key} = " "; }
}


####### Finally, let's make a check for the first character in the
####### drivers license......only if DLState is 'FL'
####### basically we can't have a leading zero
if ($dlState eq 'FL' && $userData->{DRIVERS_LICENSE} =~ m/^0/)
{
    ##### bad.....the leading 0 should be the letter O.  Change it
    $userData->{DRIVERS_LICENSE} =~ s/^0/O/;
}
return ($userData,\%truncatedFields);
}




sub _genTruncationEmail
{
    my $self = shift;
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

}


sub _genErrorEmail
{
	my $self=shift;
        my ($userId, $errorMsg, $errorCode) = @_;

	##Create followup
	my $api2=MysqlDB->new;
	$api2->createFollowUp($userId, $errorMsg, $errorCode,1);	
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

}

=pod

=head2 getCertificateNumber

Do the actual to Florida's Web Service and get the actual certificate number.  If a certificate number
has not been returned, set the error and output 0

=cut


sub getCertificateNumber
{
    my $self = shift;
    my ($user,$uData) = @_;
  
    ###### prepare the user data 
    my ($userData,$truncatedFields) = $self->_prepUserData($user,$uData); 

    ###### now to fill in and make the soap request.  Rather than ouline all of the fields here,
    ###### please refer to the file /ids/tools/HTDOCS/htdocs/wsPrimerComponent_1.wsdl for a 
    ###### list of all fields necessary to implement this functionality
   
my $WEBSERVICENAME      = "idswebservice";
my $PASSWORD            = "Traffic3000";

use SOAP::Lite;
my $ws_url ='https://services.flhsmv.gov/DriverSchoolWebService/wsPrimerComponentService.svc?wsdl';
my $ws_uri = 'http://wsPrimerComponentService';

my $soap = SOAP::Lite
-> uri( $ws_uri)
->on_action(sub{'http://wsPrimerComponentService/wsPrimerComponentPort/wsVerifyData';})
-> proxy($ws_url);

my $response = $soap->wsVerifyData(
SOAP::Data->new(name =>'mvUserid' ,value =>  "$self->{WEBSERVICENAME}"),
SOAP::Data->new(name =>'mvPassword' ,value =>  "$self->{PASSWORD}"),
SOAP::Data->new(name =>'mvSchoolid' ,value =>  "$SCHOOLID"),
SOAP::Data->new(name =>'mvClassDate' ,value =>  "$userData->{COMPLETION_DATE}"),
SOAP::Data->new(name =>'mvStartTime' ,value =>  "$userData->{COMPLETION_TIME}"),
SOAP::Data->new(name =>'mvSchoolIns' ,value =>  "$INSID"),
SOAP::Data->new(name =>'mvSchoolCourse' ,value =>  "$COURSEID"),
SOAP::Data->new(name =>'mvFirstName' ,value =>  "$userData->{FIRST_NAME}"),
SOAP::Data->new(name =>'mvMiddleName' ,value =>  ''),
SOAP::Data->new(name =>'mvLastName' ,value =>  "$userData->{LAST_NAME}"),
SOAP::Data->new(name =>'mvSuffix' ,value =>  ''),
SOAP::Data->new(name =>'mvDob' ,value =>  "$userData->{DATE_OF_BIRTH}"),
SOAP::Data->new(name =>'mvSex' ,value =>  "$userData->{SEX}"),
SOAP::Data->new(name =>'mvSocialSN' ,value =>  ''),
SOAP::Data->new(name =>'mvCitationDate' ,value =>  ''),
SOAP::Data->new(name =>'mvCitationCounty' ,value =>  $userData->{COUNTY_DEF}),
SOAP::Data->new(name =>'mvCitationNumber' ,value =>  $userData->{TICKET_NUMBER}),
SOAP::Data->new(name =>'mvReasonAttending' ,value =>  "$userData->{ATTENDANCE_REASON}"),
SOAP::Data->new(name =>'mvDriversLicense' ,value =>  "$userData->{DRIVERS_LICENSE}"),
SOAP::Data->new(name =>'mvdlStateOfRecordCode' ,value =>  "$userData->{DLSTATE}"),
SOAP::Data->new(name =>'mvAlienNumber' ,value =>  ''),
SOAP::Data->new(name =>'mvNonAlien' ,value =>  ''),
SOAP::Data->new(name =>'mvStreet' ,value =>  "$userData->{ADDRESS_1}"),
SOAP::Data->new(name =>'mvApartment' ,value =>  "$userData->{ADDRESS_2}"),
SOAP::Data->new(name =>'mvCity' ,value =>  "$userData->{CITY}"),
SOAP::Data->new(name =>'mvState' ,value => "$userData->{STATE}" ),
SOAP::Data->new(name =>'mvZipCode' ,value =>  "$userData->{ZIP}"),
SOAP::Data->new(name =>'mvZipPlus' ,value =>  ''),
SOAP::Data->new(name =>'mvPhone' ,value =>  "$userData->{PHONE}"),
SOAP::Data->new('mvEmail' ,value =>  "$userData->{EMAIL}"));

my $result=$response->result;

    if ($result && $result =~ /^[0-9]*$/)
    {
            ##### we got a valid certificate back print it
            return $result;

            if (keys %$truncatedFields)
            {
                $self->_genTruncationEmail($user, $truncatedFields);
            }
            exit;
    }

    ##### We got an error.  Send an error email and return 0 to the calling script
    $result =~ s/[^0-9a-zA-Z]//g;

    if ($result)
    {
        ##### we got a valid soap error.  Set the internal error to this error
        $self->{ERROR} = $result;
    }
    
    $self->_genErrorEmail($user, $errorCode{$result}, $result);
    return 0;
}

sub _genEmail
{
    my ($body, $title) = @_;

    use LWP::UserAgent;

    my $ua = LWP::UserAgent->new();
    $ua->timeout(15);

    my $response = $ua->get("$URL{DEFAULT}/email_template.html");
    my $content = $response->content;

    $content =~ s/\[!IDS::EMAIL_CONTENT!\]/$body/g;

    if (! $title) { $title = "IDRIVESAFELY Email"   }
    $content =~ s/\[!IDS::EMAIL_TITLE!\]/$title/g;

    return $content;
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/FloridaCerts.pm $

=item $Author: kumar $

=item $Date: 2009-05-13 11:56:01 $

=item $Rev: 55 $

=cut

1;
