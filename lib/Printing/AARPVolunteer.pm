#!/usr/bin/perl -w 

package Printing::AARPVolunteer;

use lib qw(/ids/tools/PRINTING/lib);
use Printing;
use MysqlDB;
use vars qw(@ISA);
@ISA = qw (Printing MysqlDB);

use strict;
use printerSite;
use Settings;
use Data::Dumper;

my $VERSION = 0.5;

my $NO_PRINT_AARP_COURSE = { map { $_ => 1 } qw() };
=pod

=head1 NAME

DIP

=head1 DESCRIPTION

This class encapulates all of the DIP database calls in an OOP manner.  This class will provide
methods to return all users and update DIP users as necessary

=head1 METHODS


=head2 constructor

This function should be overridden for each class.  This will initialize the constants necessary for
each subclass.

=cut

sub constructor
{
    my $self = shift;
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'AARP_VOLUNTEER';
    $self->{SETTINGS} = Settings->new;
    
    my $dbConnects = $self->_dbConnect();
    if (! $dbConnects)
    {
        die();
    }

    ####### ASSERT:  The db connections were successful.  Assign
    $self->{PRODUCT_CON}     = $dbConnects->{PRODUCT_CON};
    $self->{CRM_CON}      = $dbConnects->{CRM_CON};
    my $userId =($self->{USERID})?$self->{USERID}:undef;


    ##### let's do some class initialization
    $self->getPrinters($userId, $product);

    return $self;

    ##### since we're dealing w/ DIP printing, we need to know what type of job we need
    ##### in this case, the texas and the california jobs will be mutually exlusive,
    ##### therefore, we need a list of texas printing courses
}


=head2 getNextCertificateNumber

getNextCertificateNumber will return a valid certificate number for a particular user.  Based on the course id, this function will return a certificate number in the format required by the court (if the court exists)

Texas:          query the table CERTIFICATE
Florida:        use FloridaCerts module to return a certificate number
Los Angeles:    Append IDS's TVS number and append a sequence to it

return the default case:  UserId:CourseId

=cut

sub getNextCertificateNumber
{
	my $self = shift;
    	my ($userId, $cId) = @_;
        $self->SUPER::getNextCertificateNumber($userId, $cId);
}


=head2 getUserData

=cut

sub getUserData
{
    my $self        = shift;
    my ($userId, $retval)    = @_;

#    my $retval;
    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
		SELECT UI.USER_ID, UI.VOLUNTEER_ID,UI.DRIVERS_LICENSE, UI.COURSE_ID,
                date_format(UI.COMPLETION_DATE,'%m/%d/%Y') AS COMPLETION_DATE,
                date_format(UI.PRINT_DATE,'%m/%d/%Y') AS PRINT_DATE, UI.CERTIFICATE_NUMBER, UI.LOGIN_DATE, 
		date_format(date_sub(UI.PRINT_DATE,interval -2 year),'%m/%d/%Y') as EXPIRATION_DATE, date_format(date_sub(NOW(),interval -2 year),'%m/%d/%Y') as EXPIRATION_DATE2,
                UPPER(UC.FIRST_NAME) as FIRST_NAME, UPPER(UC.LAST_NAME) as LAST_NAME, UC.ADDRESS_1, UC.ADDRESS_2, 
		UC.CITY, UC.STATE, UC.ZIP, UC.EMAIL,
                date_format(UC.DATE_OF_BIRTH,'%m/%d/%Y') AS DATE_OF_BIRTH,UC.PHONE, date_format(REGISTRATION_DATE,'%m/%d/%Y') as DATE_OF_REGISTRATION,
		UI.LOGIN AS LOGIN
                FROM
                (((user_info UI left outer join  user_contact UC  on UI.USER_ID=UC.USER_ID) left outer join course C on UI.COURSE_ID=C.COURSE_ID)  left outer join user_lockout UL on UI.USER_ID=UL.USER_ID)  WHERE UI.USER_ID = ?
EOM
    $sql->execute($userId);
    $retval=$sql->fetchrow_hashref;

    if (!$retval->{EMAIL}) {
        $retval->{EMAIL} = $retval->{LOGIN};
    }

    ##### get the final score
    return $retval;
}


=head2 putUserPrintRecord

=cut

sub putUserPrintRecord {
    my $self    = shift;
    my ($userId, $certNumber, $type, $courseId) = @_;

    if($type eq 'PRINT')
    {
        my $cnt = $self->{PRODUCT_CON}->selectrow_array("select count(1) from user_info where user_id = ? and print_date is null and completion_date is not null",{},$userId);
        if($cnt>0){
                my $sth =  $self->{PRODUCT_CON}->prepare('update user_info set print_date = sysdate(), certificate_number = ? where user_id = ?');
                $sth->execute($certNumber, $userId);
        }
    }
    if($type eq 'SUBCOURSEPRINT')
    {
        my $cnt = $self->{PRODUCT_CON}->selectrow_array("select count(1) from user_course_info where user_id = ? and course_id =? and print_date is null and completion_date is not null",{},$userId,$courseId);

        if($cnt>0){
                my $sth =  $self->{PRODUCT_CON}->prepare('update user_course_info set print_date = sysdate(), certificate_number = ? where user_id = ? and course_id=?');
                $sth->execute($certNumber, $userId, $courseId);
        }
    }
}


sub getUserSubCourseCompletionInfo {
	my $self=shift;
	my($userId,$courseId) = @_;
	my $completionDate=  $self->{PRODUCT_CON}->selectrow_array("select date_format(completion_date,'%m/%d/%Y') as CompletionDate from user_course_info where user_id = ? and course_id=?", {}, $userId,$courseId);
	return $completionDate;
}

1;
