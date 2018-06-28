#!/usr/bin/perl -w 

package Printing::Classroom;

use lib qw(/ids/tools/PRINTING/lib);
use Printing;
use MysqlDB;
use vars qw(@ISA);
@ISA = qw (Printing MysqlDB);

use strict;
use printerSite;
use Data::Dumper;

my $VERSION = 0.5;

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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'DIP';
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
    my $sql        = $self->{PRODUCT_CON}->prepare("select SHORT_DEFINITION, definition from classroom_state ");
    $sql->execute;

    while (my ($v1, $v2) = $sql->fetchrow)
    {
                $self->{STATES}->{$v1} = $v2;
    }


    return $self;

    ##### since we're dealing w/ DIP printing, we need to know what type of job we need
    ##### in this case, the texas and the california jobs will be mutually exlusive,
    ##### therefore, we need a list of texas printing courses
}

=head2 getCompleteUsers

=cut

sub getCompleteUsers
{
	my $self    = shift;
        my ($constraints)    = @_;
    	my $retval;
        my $stcConstraint = 'not in';
        my @eList;
        #### define the different constraints that are available
    	my $constraintList        = { 
                            COURSE_ID       => ' CS.course_id in ([COURSE_ID]) ',
                                    };
        if ($constraints->{COURSE})
        {
		if($constraints->{COURSE} eq 'ALLCAPRINT'){
			delete $constraints->{COURSE};
		}else{
			$constraints->{COURSE_ID}=$constraints->{COURSE};
			delete $constraints->{COURSE};
		}
        }
       
        my $constraint = "";
        foreach my $cKey(keys %$constraints)
        {
            $constraint .= ' and' . $constraintList->{$cKey};
            $constraint =~ s/\[$cKey\]/$constraints->{$cKey}/g;
        }
        ##### let's get the courses which will not print from this job
        ##### they will consist of:
        ##### all hosted affiliate courses
        ##### all fleet courses
        ##### all classroom courses
        my $noCourses;

	my $noPrintCourse = $self->{SETTINGS}->{NO_PRINT_COURSE}->{$self->{PRODUCT}};
        my $noCourseList = join(',', (@eList,keys %$noPrintCourse));

        ##### now, generate the SQL statement
    	my $sqlStmt     = <<"EOM";
SELECT DISTINCT CS.STUDENT_ID AS USER_ID FROM classroom_students CS WHERE CS.PRINT_FLAG = 'N' AND CS.COURSE_COMPLETION_DATE IS NOT NULL AND PAYMENT_FLAG = 'Y' [CONSTRAINT]
EOM

        $sqlStmt =~ s/\[CONSTRAINT\]/$constraint/;
        $sqlStmt =~ s/\[STC\]/$stcConstraint/;
    	my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    	$sql->execute;

        while (my ($v1) = $sql->fetchrow)
        {
            $retval->{$v1}->{USER_ID}          = $v1;
        }

    	####### return the users;
    	return $retval;
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
    	my ($userId, $duplicate) = @_;
    	my $cId = $self->_getUserCourseId($userId);
#	my $c = $self->{PRODUCT_CON}->selectrow_array('select certificate_number from user_info where user_id = ?', {},$userId);

	if (my $courseAlias = $self->{SETTINGS}->getCertPoolCourse($cId))
	{
        ###### this certificate must be retrieved from the certificate pool. 

	 my $DB=$self->{SETTINGS}->{DBCONNECTION}->{DIP};
         my $DBH_DIP ||= DBI->connect("dbi:mysql:$DB->{DBNAME}:$DB->{HOST}", $DB->{USER}, $DB->{PASSWORD});
        if (! $DBH_DIP)         { print STDERR "Error Connecting to the database: $DB->{DBNAME} - $DBI::errstr\n"; return 0; } 
		my $c = $DBH_DIP->selectrow_array('select min(certificate_number) from certificate where course_id = ?',
                                                {},$courseAlias);
	    
        ##### we got a certificate number back from the table, but now can we legally delete this from the table?
        ##### if we can delete the certificate number from the table, then everything is great and we can return the 
        ##### certificate number
		if(defined $c && length $c)
		{
		    my $status = $DBH_DIP->do('delete from certificate where certificate_number = ? and course_id = ?', {},$c, $courseAlias);

		    if(defined $status && $status == 1){ return $c; }
		}

        ##### the certificate was not returned / something went wrong.  return undef
		return undef;
	}
    ##### call the base class's certificate number.  No reason to redeclare the rest of this function	
    $self->SUPER::getNextCertificateNumber($userId, $cId);
}


=head2 getUserContact

=cut

sub getUserContact
{
    my $self        = shift;
    my ($userId)    = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
select * from classroom_students  where student_id = ?
EOM

    $sql->execute($userId);
    my $retval = $sql->fetchrow_hashref;
    $sql->finish;

    return $retval;
}

=head2 getUserData

=cut

sub getUserData
{
    my $self        = shift;
    my ($userId, $retval)    = @_;

#    my $retval;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
SELECT CS.STUDENT_ID AS USER_ID, CS.DRIVING_LICENSE AS DRIVERS_LICENSE, CS.COURSE_ID, CS.PAYMENT_ORDER_ID, date_format(CS.COURSE_COMPLETION_DATE,'%m/%d/%Y') AS COMPLETION_DATE,date_format(CCP.PRINT_DATE,'%m/%d/%Y') AS PRINT_DATE, CCP.CERTIFICATE_NUMBER_ISSUED, CS.REGISTRATION_DATE AS LOGIN_DATE,UPPER(CS.FIRST_NAME) as FIRST_NAME, UPPER(CS.LAST_NAME) as LAST_NAME, CS.ADDRESS1 as ADDRESS_1, CS.ADDRESS2 as ADDRESS_2, CS.CITY, CS.STATE,CS.ZIP, CS.EMAIL,CS.COURT_ID AS REGULATOR_ID,R.DEFINITION AS REGULATOR_DEF,CT.COUNTY_ID,CT.DEFINITION AS COUNTY_DEF,CS.DELIVERY_ID,CC.STATE_ID AS COURSE_STATE,CC.COURSE_DESCRIPTION as COURSE_AGGREGATE_DESC,D.DELIVERY_DESCRIPTION AS DELIVERY_DEF,'' AS USER_SEND_TO_REGULATOR,'' AS CERT_PROCESSING_ID,'' AS CERT_1,'' AS CERT_2,'' AS CERT_3,'' AS STC_USER_ID, RCI.SEND_TO_REGULATOR,RCI.FAX AS REGULATOR_FAX,'' AS LOCK_DATE, date_format(CS.DATE_OF_BIRTH,'%m/%d/%Y') AS DATE_OF_BIRTH,CS.PHONE,CL.CLASSROOM_LOCATION_CODE AS LOCATION_ID,ID.INSTRUCTOR_CODE AS EDUCATOR_ID, CONCAT(ID.FIRST_NAME,' ',ID.LAST_NAME) AS INSTRUCTOR_NAME FROM (((((((((classroom_students CS left outer join regulator R on CS.COURT_ID=R.REGULATOR_ID) left outer join regulator_contact_info RCI on CS.COURT_ID=RCI.REGULATOR_CONTACT_ID) left outer join  regulator_county RC on CS.COURT_ID=RC.REGULATOR_ID) left outer join classroom_courses CC on CS.COURSE_ID=CC.COURSE_ID) left outer join regulator_course_selection RCS on CS.COURSE_ID=RCS.REGULATOR_ID) left outer join county CT on CS.COUNTY_ID=CT.COUNTY_ID) left outer join classroom_delivery D on  CS.DELIVERY_ID=D.DELIVERY_ID) left outer join classroom_certificate_printing CCP on CS.STUDENT_ID=CCP.STUDENT_ID) left outer join classroom_location CL on CS.CLASSROOM_LOCATION_ID = CL.CLASSROOM_LOCATION_ID) left outer join instructor_details ID on CS.INSTRUCTOR_ID=ID.INSTRUCTOR_ID WHERE CS.STUDENT_ID = ?
EOM
    
    $sql->execute($userId);
    $retval=$sql->fetchrow_hashref;
    my $courseState=$self->{PRODUCT_CON}->selectrow_array("select short_definition from classroom_state where state_id=?",{},$retval->{COURSE_STATE});
    $retval->{COURSE_STATE}=($courseState)?$courseState:$retval->{COURSE_STATE};

    return $retval;
}


=head2 getUserShipping

=cut

sub getUserShipping
{
    my $self        = shift;
    my ($userId)    = @_;
    
    my (%tmpHash);
    my $pos = 0;
    my $sth = $self->{PRODUCT_CON}->prepare("SELECT S.STUDENT_ID, CONCAT(S.FIRST_NAME,' ',S.LAST_NAME) AS NAME, S.ADDRESS1 , S.ADDRESS2, S.CITY, S.STATE, S.ZIP, S.PHONE, S.AIRBILL_PRINT_DATE, S.ATTENTION, S.DELIVERY_ID, S.SIGNATURE FROM classroom_students S WHERE S.STUDENT_ID=?");
    $sth->execute($userId);

    while (my (@result) = $sth->fetchrow_array) {
                $tmpHash{STUDENT_ID} = uc $result[0];
                $tmpHash{NAME} = uc $result[1];
                $tmpHash{ADDRESS} = uc $result[2];
                $tmpHash{ADDRESS_2} = uc $result[3];
                $tmpHash{CITY} = uc $result[4];
                $tmpHash{STATE} = uc $result[5];
                $tmpHash{ZIP} = uc $result[6];
                $tmpHash{PHONE} = uc $result[7];
                $tmpHash{PRINT_DATE} = uc $result[8];
                $tmpHash{DESCRIPTION} = '';
                $tmpHash{ATTENTION} = uc $result[9];
                $tmpHash{ADDITIONAL_NOTES} = '';
                $tmpHash{DELIVERY_ID} = uc $result[10];
                $tmpHash{SIGNATURE} = uc $result[11];
    }

        ##### let's format the user's phone number, make sure it's in a format FEDEX can understand
        ##### FEDEX requires the phone number be 10 characters, no more, no less, all numbers....no symbols or letters

        ##### remove anything but numbers
        $tmpHash{PHONE} =~ s/[^0-9]//g;
        if ($tmpHash{PHONE} =~ m/^1/)
        {
                #### remove any preceeding "1"'s
                $tmpHash{PHONE} =~ s/^1//;
        }

        ##### now, make sure the number is 10 chars long
        if (length($tmpHash{PHONE}) > 10)
        {
                $tmpHash{PHONE} = substr($tmpHash{PHONE},0,10);
        }
        elsif (length($tmpHash{PHONE}) < 10)
        {
                ##### after all the transformations, the number is too short.  Just include the
                ##### number of the office
                $tmpHash{PHONE} = "8587240040";
        }

    return \%tmpHash;

}

=head2 putUserPrintRecord

=cut

sub putUserPrintRecord{
        my $self    = shift;
        my ($studentId, $certNumber, $type, $duplicateId) = @_;
        my $deliveryId = $self->{PRODUCT_CON}->selectrow_array('select delivery_id from classroom_students where student_id = ?', {}, $studentId);
        if(!$deliveryId){
                $deliveryId=100;
                $self->updateDelivery($studentId,$deliveryId);
        }
        if($type eq 'PRINT')
        {
                my $studId = $self->{PRODUCT_CON}->selectrow_array("select student_id from classroom_certificate_printing where student_id = $studentId");
                if($studId){
                   my $sth = $self->{PRODUCT_CON}->prepare('update classroom_certificate_printing set print_date = now(), certificate_number_issued = ? where student_id = ?');
                   $sth->execute($certNumber, $studentId);
                   $sth->finish;
                } else{
                    my $printId = $self->{PRODUCT_CON}->selectrow_array("SELECT MAX(CERTIFICATE_PRINT_ID) FROM classroom_certificate_printing");
                    if($printId){
                                $printId++;
                    }else{
                        $printId=1;
                    }
                    my $sth = $self->{PRODUCT_CON}->prepare('insert into classroom_certificate_printing(CERTIFICATE_PRINT_ID,STUDENT_ID, PRINT_DATE,CERTIFICATE_NUMBER_ISSUED, STATUS) values (?, ?, now(), ?, ?)');
                    $sth->execute($printId,$studentId, $certNumber, 'Y');
                    $sth->finish;
                }
                $self->{PRODUCT_CON}->do("update classroom_students set print_flag='Y' where student_id = $studentId");
    }
    elsif ($type eq 'DUPLICATE')
    {
        my $sth = $self->{PRODUCT_CON}->prepare("update user_cert_duplicate set print_date = now(), certificate_number = ? where user_id = ? and duplicate_id = ?") || die ("BAD MONKEY $DBI::errstr");
        $sth->execute($certNumber, $studentId, $duplicateId) || die("NAUGHTY MONKEY $DBI::errstr");
    }

}
=head2 updateDelivery

=cut
sub updateDelivery { 
    my  $self= shift;
    my ($userId, $delId) = @_;

    if(!defined $delId){
                my $sth = $self->{PRODUCT_CON}->prepare("delete from classroom_students where student_id = ?");
                $sth->execute($userId);
    } else {
                my $sth = $self->{PRODUCT_CON}->prepare("update classroom_students set delivery_id = ? where student_id = ?");
                my $status = $sth->execute($delId, $userId);
    }

}

=head2 printFedexLabel

=cut

sub printFedexLabel
{
	my $self = shift;
	my ($userId, $priority, $printerKey,$webService) = @_;
	my %tmpHash;
	###### let's get user's shipping data
	my $shippingData = $self->getUserShipping($userId);
	#$shippingData->{DESCRIPTION} = "Teen Label - $userId";

	###### create the fedex object, sending in the printer key
	use Fedex;
	my $fedexObj = Fedex->new($self->{PRODUCT});
	$fedexObj->{PRINTERS}=$self->{PRINTERS};
        $fedexObj->{PRINTING_STATE}='TX';
        $fedexObj->{PRINTING_TYPE}='CERTFEDX';
        $fedexObj->{PRINTER_KEY}=$printerKey;
	
	my $reply= $fedexObj->printLabel( $shippingData, (($priority) ? $priority : 1 ));
        my $fedex = "\nUSERID : $userId\n";

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
        {
                        $fedex .= "\t$_ : $$reply{$_}\n";
			$self->putUserShipping($userId, $reply);
                }
        else
        {
                        $fedex .= "--------------------------------------------------------------------------\n";
                        $fedex .= "\t$_ : $$reply{$_}\n";
                }
        }
        if($webService){
                return \%$reply;
        }else{
                return $fedex;
        }


}

=head2 putUserShipping

=cut

sub putUserShipping
{
    #### ..slurp the class
    my $self = shift;
   
    my ($studentId, $trackingNumber) = @_;

    if ($trackingNumber->{TRACKINGNUMBER})
    {
        my $sql     = $self->{PRODUCT_CON}->prepare(<<"EOM");
update classroom_students  set airbill_print_date=sysdate(), airbill_number=? where student_id = ?
EOM

        $sql->execute($trackingNumber->{TRACKINGNUMBER}, $studentId);
    }
}


####### define some functions that should not be accessible by anyone.  These are 
####### private functions only accessable by the class.  There will be no perldocs 
####### for these functions
sub _getUserCourseId
{
    my $self = shift;
    my ($userId) = @_;

    return $self->{PRODUCT_CON}->selectrow_array("select course_id from classroom_students where student_id = ?",{}, $userId);
}


####### the following functions may or may not remain.  I haven't decided this yet.  They may be exported
####### to their own class, but for now I'm going to keep them here.  Because their status is not known, 
####### no perldocs will be written
sub getRegulatorInfo
{
    my $self        = shift;
    my ($regulatorId)    = @_;

    if (! $self->{REGULATORS}->{$regulatorId})
    {
        my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
SELECT r.DEFINITION as REGULATOR_DEF, rc.county_id as COUNTY_ID, c.DEFINITION as COUNTY_DEF FROM 
REGULATOR r, REGULATOR_COUNTY rc, COUNTY c WHERE r.regulator_id = ? AND r.regulator_id = rc.regulator_id(+) 
AND rc.county_id = c.county_id(+)
EOM

        $sql->execute($regulatorId);
        my $row = $sql->fetchrow_hashref;

        $self->{REGULATORS}->{$regulatorId}->{REGULATOR_DEF} = $row->{REGULATOR_DEF};
        $self->{REGULATORS}->{$regulatorId}->{COUNTY_ID} = $row->{COUNTY_ID};
        $self->{REGULATORS}->{$regulatorId}->{COUNTY_DEF} = $row->{COUNTY_DEF};
        $sql->finish;
    }

    return $self->{REGULATORS}->{$regulatorId};
}

=head2 getRegulatorDef 

=cut
sub getRegulatorDef {
    my $self=shift;
    my($regulatorId) = @_;
    return $self->{PRODUCT_CON}->selectrow_array('select definition from regulator where regulator_id = ?', {}, $regulatorId);
}

sub getCertificateCount {
    my $self=shift;
    my($cid) = @_;
    my $DB=$self->{SETTINGS}->{DBCONNECTION}->{DIP};
    my $DBH_DIP ||= DBI->connect("dbi:mysql:$DB->{DBNAME}:$DB->{HOST}", $DB->{USER}, $DB->{PASSWORD});
    if (! $DBH_DIP)        { print STDERR "Error Connecting to the database: $DB->{DBNAME} - $DBI::errstr\n"; return 0; }

    return  $DBH_DIP->selectrow_array('select count(*) from certificate where course_id = ?', {}, $cid);
}

sub getUserInfo{
    my $self=shift;
    my($userId) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare('SELECT  CS.STUDENT_ID AS USER_ID,CS.DRIVING_LICENSE as DRIVERS_LICENSE,CS.REGISTRATION_DATE AS LOGIN_DATE,CS.COURSE_ID,CS.COURT_ID AS REGULATOR_ID,CS.COURSE_COMPLETION_DATE,CCP.PRINT_DATE,CCP.CERTIFICATE_NUMBER_ISSUED as CERTIFICATE_NUMBER FROM classroom_students CS,classroom_certificate_printing CCP WHERE CS.STUDENT_ID = CCP.STUDENT_ID AND CS.STUDENT_ID = ?');
    $sth->execute($userId);
    my $tmpHash = $sth->fetchrow_hashref;
    $sth->finish;
    return $tmpHash;
}

sub getCourseDescription {
    my $self=shift;
    my($courseId) = @_;
    my %tmp;
    $tmp{$courseId}->{DEFINITION}=$self->{PRODUCT_CON}->selectrow_array('SELECT COURSE_DESCRIPTION FROM classroom_courses WHERE COURSE_ID = ?',{},$courseId);
    return \%tmp;
}

sub getCompletionDays{
    my $self=shift;
    my($userID) =@_;
    return $self->{PRODUCT_CON}->selectrow_array("select to_days(now())-to_days(COURSE_COMPLETION_DATE) from classroom_students where STUDENT_ID=? and COURSE_COMPLETION_DATE <= now() ",{},$userID);
}

sub getCourseSelection{
    my $self = shift;
    my ($state) = @_;
    my $sql;
    $sql = $self->{PRODUCT_CON}->prepare("select cc.course_id,cc.course_description from classroom_courses cc,classroom_state cs where cs.state_id=cc.state_id and cs.short_definition=?");
    $sql->execute($state);
    my (%tmp, $key, $def,);
    while(($key, $def) = $sql->fetchrow)
    {
                $tmp{$key}->{DEFINITION} = $def;
    }
    return \%tmp;
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Printing/DIP.pm $

=item $Author: venu $

=item $Date: 2007/12/14 13:44:33 $

=item $Rev: 63 $

=cut
1;
