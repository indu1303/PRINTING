#!/usr/bin/perl -w 

package Printing::DSMSBTW;

use lib qw(/ids/tools/PRINTING/lib);
use Printing;
use MysqlDB;
use vars qw(@ISA);
@ISA = qw (Printing MysqlDB);

use strict;
use printerSite;
use Data::Dumper;
use MIME::Lite;


my $VERSION = 0.5;

my $NO_PRINT_BTW_STATES = { map { $_ => 1 } qw(CA) };

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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'DSMS';
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
    my $sql        = $self->{PRODUCT_CON}->prepare("SELECT STATE_ID, DEFINITION FROM states ");
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
	##For DSMS, the constraints may not be useful, will be included as and when they are required
    	my $constraintList        = { 
                            COURSE_ID       => ' CS.course_id in ([COURSE_ID]) ',
                            STATE           => ' CS.course_id in (select cc.course_id from courses cc where cc.ds_state = \'[STATE]\') ',
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
SELECT DISTINCT CS.STUDENT_ID AS USER_ID FROM tx_class_students CS, courses NY  WHERE NY.COURSE_ID = CS.COURSE_ID AND CS.COMPLETION_DATE IS NOT NULL AND CS.PRINT_DATE IS NULL AND NY.COURSE_TYPE_ID IN(2,3) [CONSTRAINT]
EOM

        $sqlStmt =~ s/\[CONSTRAINT\]/$constraint/;
        #$sqlStmt =~ s/\[STC\]/$stcConstraint/;
    	my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    	$sql->execute;

        while (my ($v1) = $sql->fetchrow)
        {

		#Allow this for CA State only, hard coded conditiona added for now
		my $dsStateId = $self->{PRODUCT_CON}->selectrow_array('select ds.ds_state_id from driving_school ds, tx_class_students ui where ui.ds_school_id = ds.ds_school_id and ui.student_id = ?', {},$v1);
		if($dsStateId ne 'CA') {
			next;
		}

            $retval->{$v1}->{USER_ID} = $v1;
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
	my $c = $self->{PRODUCT_CON}->selectrow_array('select certificate_number from tx_class_students where student_id = ?', {},$userId);
	my $courseTypeId = $self->{PRODUCT_CON}->selectrow_array('select course_type_id from courses where course_id = ?', {},$cId);

	if($courseTypeId eq '2' || $courseTypeId eq '3') {
		return "[TO BE ASSIGNED]";
	}
    	$c = $self->{PRODUCT_CON}->selectrow_array("select CERTIFICATE_NUMBER_ISSUED from classroom_certificate_printing where student_id=?",{},$userId);
	if(!$c){
		$self->{PRODUCT_CON}->do("UPDATE  certificate_no_seq SET id=LAST_INSERT_ID(id+1)");
		$c = $self->{PRODUCT_CON}->selectrow_array("SELECT LAST_INSERT_ID()");
	}
	return $c;
}


=head2 getUserContact

=cut

sub getUserContact
{
    my $self        = shift;
    my ($userId)    = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
select * from tx_class_students  where student_id = ?
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

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
SELECT CS.STUDENT_ID AS USER_ID, CS.DRIVERS_LICENSE AS DRIVERS_LICENSE, CS.COURSE_ID, DA.SCHOOL_CODE as DA_CODE, DA.LOGIN, date_format(CS.COMPLETION_DATE, '%m/%d/%Y') AS COMPLETION_DATE, date_format(CS.PRINT_DATE, '%m/%d/%Y') AS PRINT_DATE, CS.CERTIFICATE_NUMBER, UPPER(CS.FIRST_NAME) as FIRST_NAME, UPPER(CS.LAST_NAME) as LAST_NAME, CS.ADDRESS_1 as ADDRESS_1, CS.ADDRESS_2 as ADDRESS_2, CS.CITY, CS.STATE, CS.ZIP, CS.EMAIL, CC.DS_STATE AS COURSE_STATE, CC.DESCRIPTION as COURSE_AGGREGATE_DESC, '' AS CERT_PROCESSING_ID, '' AS CERT_1, '' AS CERT_2, '' AS CERT_3, '' AS STC_USER_ID, '' AS LOCK_DATE, date_format(CS.DATE_OF_BIRTH, '%m/%d/%Y') AS DATE_OF_BIRTH, CS.PHONE_1 AS PHONE, CL.LOCATION_CODE AS LOCATION_ID, ID.INSTRUCTOR_CODE AS EDUCATOR_ID, ID.INSTRUCTOR_CODE AS INSTRUCTOR_CODE, CONCAT(ID.FIRST_NAME,' ',ID.LAST_NAME) AS INSTRUCTOR_NAME, '' as DELIVERY_ID, '' as AIRBILL_NUMBER, NC.CLASS_ID, DA.DS_SCHOOL_ID AS DS_SCHOOL_ID, DA.SCHOOL_NAME AS DA_SCHOOL_NAME, DA.ADDRESS_1 AS DA_ADDRESS1, DA.ADDRESS_2 AS DA_ADDRESS2, DA.CITY AS DA_CITY, DA.STATE AS DA_STATE, DA.ZIP AS DA_ZIP, DA.PHONE_1 AS DA_PHONE1 FROM ((((tx_class_students CS left outer join courses CC on CS.COURSE_ID=CC.COURSE_ID)  left outer join class NC on CS.CLASS_ID = NC.CLASS_ID)  left outer join locations CL on NC.LOCATION_ID = CL.LOCATION_ID) left outer join driving_school_usr ID on CS.DS_SCHOOL_ID=ID.DS_SCHOOL_ID)  left outer join driving_school DA on CS.DS_SCHOOL_ID=DA.DS_SCHOOL_ID WHERE CS.STUDENT_ID = ?
EOM
    $sql->execute($userId);
    $retval=$sql->fetchrow_hashref;

    	##For instructor certificate
	my $maxSessionId = $self->{PRODUCT_CON}->selectrow_array("select max(appointment_session_id) from students_appointment where student_id = ? and status='COMPLETED'", {},$userId);
	##Get Instructor the max session, get his DL and signature data
	my $maxSessionIdAppointmentId = $self->{PRODUCT_CON}->selectrow_array("select appointment_id from students_appointment where student_id = ? and appointment_session_id = ?", {},$userId, $maxSessionId);
	my $instructorId = $self->{PRODUCT_CON}->selectrow_array("select instructor_id from incar_ds_appointments where appointment_id = ?", {},$maxSessionIdAppointmentId);
	my ($instructorDL, $instructorName, $instructorLicenseNumber) = $self->{PRODUCT_CON}->selectrow_array("select drivers_license,concat(first_name,' ', last_name), instructor_license_number from driving_school_usr where login_id = ?", {},$instructorId);
	if($instructorDL){
		$retval->{MAX_SESSION_INSTRUCTOR} = $instructorId;
		$retval->{MAX_SESSION_INSTRUCTOR_DL} = $instructorLicenseNumber;
		$retval->{MAX_SESSION_INSTRUCTOR_NAME} = $instructorName;
	}
	my $noOfHours = $self->{PRODUCT_CON}->selectrow_array("select btw_no_of_sessions * (btw_time/60) from courses where course_id = ?", {},$retval->{COURSE_ID});
	if($noOfHours) {
		$retval->{HOURS_COMPLETED} = int($noOfHours);
	}
	$retval->{SHORT_DESC} = $self->{PRODUCT_CON}->selectrow_array("select course_name from courses where course_id = ?", {}, $retval->{COURSE_ID});
	
    return $retval;
}


=head2 getUserShipping

=cut

sub getUserShippingOld
{
    my $self        = shift;
    my ($dsSchoolId)    = @_;
    
    my (%tmpHash);
    my $pos = 0;
    my $sth = $self->{PRODUCT_CON}->prepare("SELECT S.DS_SCHOOL_ID, CONCAT(S.OWNER_FIRST_NAME,' ',S.OWNER_LAST_NAME) AS NAME, S.ADDRESS_1 , S.ADDRESS_2, S.CITY, S.STATE, S.ZIP, S.PHONE_1 AS PHONE, S.SCHOOL_NAME FROM driving_school S where S.DS_SCHOOL_ID = ?");
    $sth->execute($dsSchoolId);

    while (my (@result) = $sth->fetchrow_array) {
                $tmpHash{DS_SCHOOL_ID} = uc $result[0];
                $tmpHash{NAME} = uc $result[1];
                $tmpHash{ADDRESS} = uc $result[2];
                $tmpHash{ADDRESS_2} = uc $result[3];
                $tmpHash{CITY} = uc $result[4];
                $tmpHash{STATE} = uc $result[5];
                $tmpHash{ZIP} = uc $result[6];
                $tmpHash{PHONE} = uc $result[7];
                $tmpHash{SCHOOL_NAME} = uc $result[8];
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

sub putUserPrintRecord {
        my $self    = shift;
        my ($studentId, $certNumber, $type, $duplicateId) = @_;
        my $classId = $self->{PRODUCT_CON}->selectrow_array('select class_id from tx_class_students where student_id = ?', {}, $studentId);
        #my $deliveryId = $self->{PRODUCT_CON}->selectrow_array('select delivery_id from ny_classroom where class_id = ?', {}, $classId);
        #if(!$deliveryId){
        #        $deliveryId=100;
        #        $self->updateDelivery($classId,$deliveryId);
        #}
        if($type eq 'PRINT')
        {
                   my $sth = $self->{PRODUCT_CON}->prepare('update tx_class_students set print_date = now(), certificate_number = ? where student_id = ?');
                   $sth->execute($certNumber, $studentId);
                   $sth->finish;
    	} elsif ($type eq 'DUPLICATE') {
		my $sth = $self->{PRODUCT_CON}->prepare("update user_cert_duplicate set print_date = now(), certificate_number = ? where user_id = ? and duplicate_id = ?") || die ("BAD MONKEY $DBI::errstr");
	        $sth->execute($certNumber, $studentId, $duplicateId) || die("NAUGHTY MONKEY $DBI::errstr");
	}
}
=head2 updateDelivery

=cut
sub updateDelivery { 
    my  $self= shift;
    my ($classId, $delId) = @_;

    if(!defined $delId){
               # my $sth = $self->{PRODUCT_CON}->prepare("delete from classroom_students where student_id = ?");
               # $sth->execute($userId);
    } else {
                my $sth = $self->{PRODUCT_CON}->prepare("update ny_classroom set delivery_id = ? where class_id = ?");
                my $status = $sth->execute($delId, $classId);
    }

}

=head2 printFedexLabel

=cut

sub printFedexLabel_not_required
{
	my $self = shift;
	my ($schoolId, $priority, $printerKey,$webService) = @_;
	my %tmpHash;
	my ($dsSchoolId, $classId) = split(/\:/, $schoolId);
	###### let's get user's shipping data
	my $shippingData = $self->getUserShipping($dsSchoolId);
	$shippingData->{DELIVERY_ID} = $self->getDeliveryId($classId);

	##Add DESC
	$shippingData->{DESCRIPTION} = "CERT FOR - $dsSchoolId";

	my $schoolInfo = $self->TCdbGetDrivingSchoolDetails($dsSchoolId);
	my $schoolName = $schoolInfo->{SCHOOL_NAME};

	$schoolName = substr($schoolName, 0, 25); ##DESC will accept 40 char max, next 10 for cert count
	my $certCount = $self->getNYClassStudentsCount($classId);
	$shippingData->{DESCRIPTION} = "FOR:$schoolName($certCount Certs)";


	###### create the fedex object, sending in the printer key
	use Fedex;
	my $fedexObj = Fedex->new($self->{PRODUCT});
	$fedexObj->{PRINTERS}=$self->{PRINTERS};
	$fedexObj->{PRINTING_TYPE}='CERTFEDX';
	$fedexObj->{PRINTING_STATE}=$shippingData->{STATE};
	
	my $reply= $fedexObj->printLabel( $shippingData, (($priority) ? $priority : 1 ));
        my $fedex = "\nSCHOOL : $dsSchoolId\n";

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
        {
                        $fedex .= "\t$_ : $$reply{$_}\n";
			$self->putUserShippingClass($classId, $reply);
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

=head2 putUserShippingClass

=cut

sub putUserShippingClass
{
    #### ..slurp the class
    my $self = shift;
   
    my ($classId, $trackingNumber) = @_;

    if ($trackingNumber->{TRACKINGNUMBER})
    {
        my $sql     = $self->{PRODUCT_CON}->prepare(<<"EOM");
update ny_classroom  set airbill_print_date=sysdate(), airbill_number=? where class_id = ?
EOM

        $sql->execute($trackingNumber->{TRACKINGNUMBER}, $classId);
    }
}


####### define some functions that should not be accessible by anyone.  These are 
####### private functions only accessable by the class.  There will be no perldocs 
####### for these functions
sub _getUserCourseId
{
    my $self = shift;
    my ($userId) = @_;

    return $self->{PRODUCT_CON}->selectrow_array("select course_id from tx_class_students where student_id = ?",{}, $userId);
}


####### the following functions may or may not remain.  I haven't decided this yet.  They may be exported
####### to their own class, but for now I'm going to keep them here.  Because their status is not known, 
####### no perldocs will be written
=pod
##This method not requied for DSMS
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
=cut

=head2 getRegulatorDef 

sub getRegulatorDef {
    my $self=shift;
    my($regulatorId) = @_;
    return $self->{PRODUCT_CON}->selectrow_array('select definition from regulator where regulator_id = ?', {}, $regulatorId);
}
=cut

sub getCertificateCount {
    my $self=shift;
    my($cid) = @_;
    my $DB=$self->{SETTINGS}->{DBCONNECTION}->{DIP};
    my $DBH_DIP ||= DBI->connect("dbi:mysql:$DB->{DBNAME}:$DB->{HOST}", $DB->{USER}, $DB->{PASSWORD});
    if (! $DBH_DIP)        { print STDERR "Error Connecting to the database: $DB->{DBNAME} - $DBI::errstr\n"; return 0; }

    return  $DBH_DIP->selectrow_array('select count(*) from certificate where course_id = ?', {}, $cid);
}

sub getUserInfo {
    my $self=shift;
    my($userId) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare('SELECT  CS.STUDENT_ID AS USER_ID,CS.DRIVERS_LICENSE as DRIVERS_LICENSE, CS.PRINT_DATE, CS.CERTIFICATE_NUMBER  as CERTIFICATE_NUMBER FROM tx_class_students CS where CS.STUDENT_ID = ?');
    $sth->execute($userId);
    my $tmpHash = $sth->fetchrow_hashref;
    $sth->finish;
    return $tmpHash;
}

sub getCourseDescription {
    my $self=shift;
    my($courseId) = @_;
    my %tmp;
    $tmp{$courseId}->{DEFINITION}=$self->{PRODUCT_CON}->selectrow_array('SELECT DESCRIPTION FROM courses WHERE COURSE_ID = ?',{},$courseId);
    return \%tmp;
}

sub getCompletionDays {
    my $self=shift;
    my($userID) =@_;
    return $self->{PRODUCT_CON}->selectrow_array("select to_days(now())-to_days(COMPLETION_DATE) from tx_class_students where STUDENT_ID=? and COMPLETION_DATE <= now() ",{},$userID);
}

sub getCourseSelection{
    my $self = shift;
    my ($state) = @_;
    my $sql;
    $sql = $self->{PRODUCT_CON}->prepare("select cc.course_id,cc.description from courses cc,states cs where cs.state_id=cc.ds_state and cs.state_id = ?");
    $sql->execute($state);
    my (%tmp, $key, $def,);
    while(($key, $def) = $sql->fetchrow)
    {
                $tmp{$key}->{DEFINITION} = $def;
    }
    return \%tmp;
}

=pod
sub getManagerEmail{

   my $self = shift;
   my ($daId) = @_;
   my $managerEmail = $self->{PRODUCT_CON}->selectrow_array("select EMAIL from idsmanager IM,idsmanager_deliveryagency_map IDM where IM.MANAGER_ID=IDM.MANAGER_ID and IDM.DA_ID=?",{},$daId);
   return $managerEmail;
}
=cut

=pod
sub putInvalidDlEmail{

   my $self = shift;
   my ($studentId) = @_;
   my $sth = $self->{PRODUCT_CON}->prepare('insert into classroom_students_cookie(STUDENT_ID, PARAM, VALUE) values (?,?,?)');
   $sth->execute($studentId,'EMAIL_SENT',1);
   $sth->finish;

}
=cut

sub getUserDriverLicense {
   my $self = shift;
   my ($studentId) = @_;
   my $drivingLicense =$self->{PRODUCT_CON}->selectrow_array('select drivers_license from tx_class_students where student_id=?',{},$studentId);
   return $drivingLicense;
}

=pod
sub getCookie{

  my $self = shift;
  my ($studentId,$param) = @_;
  my $value =$self->{PRODUCT_CON}->selectrow_array('select value from classroom_students_cookie where student_id=? and param=?',{},$studentId,$param);
  return $value;
}
=cut

sub getInstructorEmail {
   my $self = shift;
   my ($insId) = @_;
   my $email = $self->{PRODUCT_CON}->selectrow_array("select EMAIL from driving_school_usr where is_instructor='Y' and login_id = ?",{},$insId);
   return $email;
}

sub getClassStudents {
    my $self = shift;
    my ($classId) = @_;
    my $sql;
    $sql = $self->{PRODUCT_CON}->prepare("select student_id, concat(first_name,' ',last_name) as name from tx_class_students where class_id = ?");
    $sql->execute($classId);
    my (%tmp, $key, $def,);
    while(($key, $def) = $sql->fetchrow)
    {
                $tmp{$key}->{NAME} = $def;
    }
    return \%tmp;
}

sub getDeliveryId
{
    my $self = shift;
    my ($classId) = @_;

    return 1; #$self->{PRODUCT_CON}->selectrow_array("select delivery_id from ny_classroom where class_id = ?",{}, $classId);
}

=pod
sub getDeliveryId
{
    my $self = shift;
    my ($classId) = @_;

    return $self->{PRODUCT_CON}->selectrow_array("select delivery_id from ny_classroom where class_id = ?",{}, $classId);
}

sub getFedExPringingCheck {
    my $self = shift;
    my ($classId) = @_;

    my $trackingNumberCheck = $self->{PRODUCT_CON}->selectrow_array("select airbill_number from ny_classroom where class_id = ? and delivery_id = 101",{}, $classId);
    if(!$trackingNumberCheck) {
	return 1;
    } else {
	return 0;
    }

}

sub getAirbillPringingCheck {
    my $self = shift;
    my ($classId) = @_;

    my $check = $self->{PRODUCT_CON}->selectrow_array("select airbill_print_date from ny_classroom where class_id = ?",{}, $classId);
    if(!$check) {
        return 1;
    } else {
        return 0;
    }

}


sub putClassAirbillInfo
{
    #### ..slurp the class
    my $self = shift;

    my ($classId) = @_;
        my $sql     = $self->{PRODUCT_CON}->prepare(<<"EOM");
update ny_classroom  set airbill_print_date=sysdate() where class_id = ?
EOM

        $sql->execute($classId);
}



sub getCompleteWorkbookOrders{
    my $self = shift;
    my ($schoolId) = @_;
    my $sql;
    my $queryAppend = "";
    if($schoolId) {
	$queryAppend .= " and wod.ds_school_id = $schoolId";
    }
    $sql = $self->{PRODUCT_CON}->prepare("select wod.payment_order_id, wod.ds_school_id, wod.delivery_id, wod.shipping_id from workbook_order_data wod, shipping_address sa where wod.shipping_id = sa.shipping_id and sa.airbill_number is null and wod.payment_date is not null $queryAppend");
    $sql->execute();
    my (%tmp, $key, $dsSchoolId, $deliveryId, $shippingId);
    while(($key, $dsSchoolId, $deliveryId, $shippingId) = $sql->fetchrow)
    {
                $tmp{$key}->{DS_SCHOOL_ID} = $dsSchoolId;
                $tmp{$key}->{DELIVERY_ID} = $deliveryId;
                $tmp{$key}->{SHIPPING_ID} = $shippingId;
    }
    return \%tmp;
}

sub getWorkbookOrderInfo{
    my $self=shift;
    my($orderId) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare('SELECT DS_SCHOOL_ID, WORKBOOK_ID, PAYMENT_ID, PAYMENT_REF, ORDER_DATE, PAYMENT_DATE, PRICE, UNITS, DATE_CREATED, CC_TYPE, DELIVERY_ID, SHIPPING_ID FROM  workbook_order_data WHERE PAYMENT_ORDER_ID = ?');
    $sth->execute($orderId);
    my $tmpHash = $sth->fetchrow_hashref;
    $sth->finish;
    return $tmpHash;
}
=cut


sub putUserShipping
{
    #### ..slurp the class
    my $self = shift;

    my ($shippingId, $trackingNumber) = @_;
    if ($trackingNumber->{TRACKINGNUMBER})
    {
        my $sql     = $self->{PRODUCT_CON}->prepare(<<"EOM");
update shipping_address set print_date=sysdate(), airbill_number=?, type=0 where shipping_id = ?
EOM
        $sql->execute($trackingNumber->{TRACKINGNUMBER}, $shippingId);
    }
}

sub getUserShippingInfo{
    my $self=shift;
    my($orderId) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare('SELECT WOD.PAYMENT_ORDER_ID, WOD.DS_SCHOOL_ID, WOD.DELIVERY_ID, WOD.SHIPPING_ID, SA.AIRBILL_NUMBER FROM workbook_order_data WOD, shipping_address SA WHERE WOD.SHIPPING_ID = SA.SHIPPING_ID AND WOD.PAYMENT_ORDER_ID = ?');
    $sth->execute($orderId);
    my $tmpHash = $sth->fetchrow_hashref;
    $sth->finish;
    return $tmpHash;
}

=pod
sub getWorkBookOrdersForPrinting {
    my $self = shift;
    my $sql;
    $sql = $self->{PRODUCT_CON}->prepare("select distinct(wod.ds_school_id), count(*) from workbook_order_data wod,  shipping_address sa where wod.shipping_id = sa.shipping_id and sa.airbill_number is null group by wod.ds_school_id");
    $sql->execute();
    my (%tmp, $key, $count);
    while(($key, $count) = $sql->fetchrow)
    {
		$tmp{$key}->{COUNT} = $count;
		##For each school, get the number of labels to print on the day..
		#my $sql1 = "select wod.payment_order_id, wod.ds_school_id, wod.delivery_id, wod.shipping_id from workbook_order_data wod, shipping_address sa where wod.shipping_id = sa.shipping_id and sa.airbill_number is null and wod.payment_date is not null and wsd.ds_school_id = $key";
    }
   return \%tmp;
}

sub emailWorkBookOrder {
	my $self = shift;
	my ($dsSchoolId, $orderIdString,$noRecords) = @_;
        my $currDate = $self->{PRODUCT_CON}->selectrow_array("select date_format(now(), '%M %d, %Y')");
	my $emailMessage = "";
        my $msg = MIME::Lite->new(
                From    =>'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>',
                To      => 'nyworkbooks@idrivesafely.com',
                #To      => 'rajesh@ed-ventures-online.com',
                Subject => "Workbook Order Status: $currDate",
                Type    =>'multipart/mixed'
        );
	if($noRecords == 0) {
		$emailMessage = "No workbooks were ordered today.";
        	$msg->attach(Type => 'text/html', Data => "$emailMessage");
		$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f wecare@idrivesafely.com');
	} else {
	my $schoolInfo = $self->TCdbGetDrivingSchoolDetails($dsSchoolId);
	chop($orderIdString);
	my @orderIds = split(/\,/, $orderIdString);
	my $fileName = "cert_label_$dsSchoolId.pdf";
	my $filePath = "/ids/tools/PRINTING/PNG/DSMSWORKBOOKORDERS/$fileName";
	foreach my $paymentOrderId(@orderIds) {
		my $wbCcTrans = $self->BasicdbGetWorkbookCCTrans($paymentOrderId);
		my $ccNumber = $wbCcTrans->{CC_NUMBER};

		my $ccDigit = substr($ccNumber,0,1);
		$ccNumber = substr($ccNumber, length($ccNumber)-4, length($ccNumber));
		my $cardType = 'Credit Card';
		if($ccDigit == 3) { $cardType = 'American Express'; }
		elsif($ccDigit == 4) { $cardType = 'Visa'; }
		elsif($ccDigit == 5) { $cardType = 'Master Card'; }
		elsif($ccDigit == 6) { $cardType = 'Discover'; }
		my $orderData = $self->BasicdbGetWorkbookOrderData($paymentOrderId);
		my $shippingInfo = $self->getUserShippingInfo($paymentOrderId);

		$emailMessage .= "<table width=\"50%\" border=\"0\" cellspacing=\"0\" cellpadding=\"2\" style=\"color:#000; font-family:Arial, Helvetica, sans-serif; font-size:12px;\">
		  <tr>
		    <td colspan=\"2\" style=\"font-size:14px; font-weight:bold;\">Order #: $paymentOrderId<br />
		<hr size=\"1px\" noshade=\"noshade\" /></td>
		  </tr>
  		<tr>
		    <td width=\"25%\" align=\"left\" valign=\"middle\">Date/Time :</td>
		    <td align=\"left\" valign=\"middle\">$orderData->{PT_DATE} Eastern Time</td>
		  </tr>
		  <tr>
		    <td align=\"left\" valign=\"middle\"># of Workbooks:</td>
		    <td align=\"left\" valign=\"middle\">$orderData->{UNITS}</td>
  		</tr>
		  <tr>
		    <td align=\"left\" valign=\"middle\">Order Total:</td>
		    <td align=\"left\" valign=\"middle\">\$$orderData->{PRICE}</td>
		  </tr>
		  <tr>
		    <td align=\"left\" valign=\"middle\">Delivery Status </td>
		    <td align=\"left\" valign=\"middle\">In-transit</td>
		  </tr>
		  <tr>
		    <td align=\"left\" valign=\"middle\">FedEx Tracking #:</td>
		    <td align=\"left\" valign=\"middle\">$shippingInfo->{AIRBILL_NUMBER}</td>
		  </tr>
		</table>";

	}
	$emailMessage .= "<br>This is an automated message from the DSMS Basic system.<br><br>";
	$msg->attach(Type => 'text/html', Data => "$emailMessage");
        $msg->attach(Type     => ($fileName =~ /pdf/) ? 'application/pdf' : 'application/msword',
                Path     => $filePath,
                Filename => $fileName,
                Disposition => 'attachment'
        );
	$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f wecare@idrivesafely.com');
	#$msg->send('smtp','192.168.1.5');
	}
}

sub BasicdbGetWorkbookCCTrans {
	my $self = shift;
        my ($paymentOrderId) = @_;
	my $sth =  $self->{PRODUCT_CON}->prepare('SELECT WORKBOOK_ID, CC_NAME, CC_NUMBER, CC_EXP, CC_ZIP, CC_ADDRESS, CC_CITY, CC_STATE, CC_AMT, REF, RESULT_CODE FROM workbook_cc_trans WHERE PAYMENT_ORDER_ID = ?');
	$sth->execute($paymentOrderId);
	my $tmpHash = $sth->fetchrow_hashref;
	$sth->finish;
        return $tmpHash;
}
=cut

sub TCdbGetDrivingSchoolDetails {
	my $self = shift;
        my ($dsSchoolId) = @_;
        my $sql = "SELECT SCHOOL_NAME, LOCATION_CODE, COURSE_PROVIDER, SCHOOL_NUMBER, CLASSROOM_NUMBER, OWNER_FIRST_NAME, OWNER_LAST_NAME, CONTACT_NAME, ADDRESS_1, ADDRESS_2, CITY, STATE, ZIP, PHONE_1, PHONE_1_TYPE_ID, PHONE_2, PHONE_2_TYPE_ID, EMAIL, FAX, WEBSITE, TIME_ZONE_ID, DATE_CREATED, ACTIVE, FEE_FROM_RC_IDS, FEE_FROM_SCHOOL_RC, SCHOOL_CODE, DATE_FORMAT(EXPIRY_DATE,'%m/%d/%Y') as EXPIRY_DATE, RC_ID, AM_ID, ACTIVE, CLASS_CODE, LOGIN, PASSWORD, FEIN, SCHOOL_SETUPDOCS_EMAILED, DATE_FORMAT(DATE_CREATED,'%M %d, %Y') AS DATE_CREATED_FORMAT FROM driving_school WHERE DS_SCHOOL_ID = ?";
        my $sth =  $self->{PRODUCT_CON}->prepare($sql);
        $sth->execute($dsSchoolId);
        my $tmpHash = $sth->fetchrow_hashref;
        $sth->finish;
        return $tmpHash;
}

=pod
sub BasicdbGetWorkbookOrderData {
        my $self = shift;
        my ($paymentOrderId) = @_;
	my $newYorkTime = $self->getNYCurrentTime($paymentOrderId);
        my $sth =  $self->{PRODUCT_CON}->prepare("SELECT PAYMENT_ORDER_ID, WORKBOOK_ID, PAYMENT_ID, PAYMENT_REF, ORDER_DATE, DATE_FORMAT(PAYMENT_DATE, '%m/%d/%Y; %r PT') AS PAYMENT_DATE, PRICE, UNITS, DATE_CREATED, CC_TYPE, DELIVERY_ID, SHIPPING_ID, DATE_FORMAT('$newYorkTime', '%m/%d/%Y; %r') AS PT_DATE FROM workbook_order_data WHERE PAYMENT_ORDER_ID = ?");
        $sth->execute($paymentOrderId);
        my $tmpHash = $sth->fetchrow_hashref;
        $sth->finish;
        return $tmpHash;
}

sub getNYCurrentTime {
        my $self = shift;
        my ($paymentOrderId) = @_;
        my $paymentDate = $self->{PRODUCT_CON}->selectrow_array("SELECT PAYMENT_DATE FROM workbook_order_data WHERE PAYMENT_ORDER_ID = ?", {}, $paymentOrderId);
        my $newYorkTime = $self->{PRODUCT_CON}->selectrow_array("SELECT CONVERT_TZ('$paymentDate','-00:00','+03:00')");
        return $newYorkTime;
}

=cut

sub getInstructorCode {
    my $self=shift;
    my($studentId) = @_;	
    return $self->{PRODUCT_CON}->selectrow_array("select dsu.instructor_code from driving_school_usr dsu, tx_class_students cs where dsu.ds_school_id = cs.ds_school_id and cs.student_id = ?", {}, $studentId);

}

sub getUserCertDuplicateData_Not_required
{
    my $self=shift;
    my ($userId, $duplicateId, $printJob) = @_;

    my $retval;
    my $k;
    my $sth;
    if (! $duplicateId)
    {
        $sth=$self->{PRODUCT_CON}->prepare("select max(duplicate_id) from user_cert_duplicate where user_id = ? and APPROVED='Y' and print_date is not null and certificate_number is not null");

        $sth->execute($userId);
        ($duplicateId) = $sth->fetchrow();
    }
    ####### this is the user's first duplicate.  get it from user_info and user_contact
    my $userInfo = $self->getUserInfo($userId);
    foreach $k(keys %$userInfo)
    {
        $retval->{$k} = $userInfo->{$k};
    }



    if (! $printJob)
    {
        my $userContact = $self->getUserContactData($userId);
        foreach $k(keys %$userContact)
        {
            $retval->{DATA}->{$k} = uc($userContact->{$k});
        }
    }

    if ($duplicateId)
    {
        ###### ASSERT:  At this point, we should have the max duplicate id for this user.  Now, get all relevant data
        $sth = $self->{PRODUCT_CON}->prepare("select USER_ID,DUPLICATE_ID,REQUEST_DATE,REQUESTED_BY,APPROVAL_DATE,PRINT_DATE,APPROVED,APPROVED_BY,CERTIFICATE_NUMBER,CERTIFICATE_REPLACED,AFTERVOID_ID from user_cert_duplicate where duplicate_id = ?");
        $sth->execute($duplicateId);

        my ($row) = $sth->fetchrow_hashref;
        foreach $k(keys %$row)
        {
            $retval->{$k} = $row->{$k};
        }

        ##### Now, get the data entries from user_cert_duplicate_data
        $sth = $self->{PRODUCT_CON}->prepare("select param, value from user_cert_duplicate_data where duplicate_id = ?");
        $sth->execute($duplicateId);

        while (my ($v1, $v2) = $sth->fetchrow)
        {

            unless ($v1 eq 'DUPLICATE_ID' || $v1 eq 'SHIPPING_ID' || $v1 eq 'DELIVERY_ID')
            {
                $retval->{$v1} = uc($v2);
            }

            if ($retval->{$v1} eq $retval->{DATA}->{$v1})
            {
                delete $retval->{DATA}->{$v1};

            }
        }
    }
    return $retval;
}



sub getUserCertDuplicateData
{
    my $self=shift;
    my ($userId, $duplicateId, $printJob) = @_;
    my $retval;
    my $k;
    my $sth;
    if (! $duplicateId)
    {
        $sth=$self->{PRODUCT_CON}->prepare("select max(duplicate_id) from user_cert_duplicate where user_id = ? and certificate_number is not null");

        $sth->execute($userId);
        ($duplicateId) = $sth->fetchrow();
    }
	#####this is the user's first duplicate.  get it from user_info and user_contact
    my $userInfo = $self->getUserInfo($userId);
    foreach $k(keys %$userInfo)
    {
        $retval->{$k} = $userInfo->{$k};
    }



    if (! $printJob)
    {
        my $userContact = $self->getUserContact($userId);
        foreach $k(keys %$userContact)
        {
            $retval->{DATA}->{$k} = uc($userContact->{$k});
        }
    }
    if ($duplicateId)
    {
	####ASSERT:  At this point, we should have the max duplicate id for this user.  Now, get all relevant data
        $sth = $self->{PRODUCT_CON}->prepare("select USER_ID,DUPLICATE_ID,REQUEST_DATE,REQUESTED_BY,APPROVAL_DATE,PRINT_DATE,APPROVED,APPROVED_BY,CERTIFICATE_NUMBER,CERTIFICATE_REPLACED,AFTERVOID_ID from user_cert_duplicate where duplicate_id = ?");
        $sth->execute($duplicateId);

        my ($row) = $sth->fetchrow_hashref;
        foreach $k(keys %$row)
        {
            $retval->{$k} = $row->{$k};
        }

	####Now, get the data entries from user_cert_duplicate_data
        $sth = $self->{PRODUCT_CON}->prepare("select param, value from user_cert_duplicate_data where duplicate_id = ?");
        $sth->execute($duplicateId);

        while (my ($v1, $v2) = $sth->fetchrow)
        {
            $retval->{DATA}->{$v1} = uc($v2);
        }
    $retval->{DATA}->{CERTIFICATE_NUMBER} = $retval->{CERTIFICATE_REPLACED};
    }

	####now, one last set of checks.  let's check the table user_cert_duplicate table to see if this user
	####has requested anything before.  if he has, make sure all of the data he's submitted previously
	####is in the record so we're sure we're not pulling from user_info
    my $oldDupId = $self->{PRODUCT_CON}->selectrow_array('select max(duplicate_id) from user_cert_duplicate where print_date is not null and user_id = ? and duplicate_id < ?',{},$userId, $duplicateId);

    if ($oldDupId)
    {
	#####ok, old data exists for him.  Get all of it from the duplicate table and place it in the return hash
        $sth = $self->{PRODUCT_CON}->prepare("select param, value from user_cert_duplicate_data where duplicate_id = ?");
        $sth->execute($oldDupId);

        while (my ($v1, $v2) = $sth->fetchrow)
        {

            unless ($v1 eq 'DUPLICATE_ID')
            {
                $retval->{$v1} = uc($v2);
                if ($v1 eq 'REGULATOR_ID')
                {
                        $retval->{REGULATOR_DEF} = $self->getRegulatorDef($v2);
                }
            }

            if ($retval->{$v1} eq $retval->{DATA}->{$v1})
            {
                delete $retval->{DATA}->{$v1};

                if ($v1 eq 'REGULATOR_ID')
                {
                        delete $retval->{DATA}->{REGULATOR_DEF};
                }
            }
        }
    }

    return $retval;
}


sub getUserContactData
{
    my $self        = shift;
    my ($userId)    = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
select STUDENT_ID, DRIVERS_LICENSE, PHONE_1, EMAIL, ADDRESS_1, ADDRESS_2, CITY, STATE, ZIP, FIRST_NAME, LAST_NAME, SEX, date_format(DATE_OF_BIRTH,'%m/%d/%Y') as DATE_OF_BIRTH from tx_class_students where student_id = ?
EOM

    $sql->execute($userId);
    my $retval = $sql->fetchrow_hashref;
    $sql->finish;
    return $retval;
}

sub getNYClassStudentsCount {
    my $self=shift;
    my($classId) = @_;
    return $self->{PRODUCT_CON}->selectrow_array("select count(*) from tx_class_students where class_id = ? ",{},$classId);
}


sub TCdbGetInstructorDetails {
        my $self = shift;
        my ($insId) = @_;
	my $sql = "SELECT FIRST_NAME, LAST_NAME, ADDRESS_1, CITY, STATE, ZIP, INSTRUCTOR_CODE, DATE_FORMAT(START_DATE,'%M %d, %Y') AS START_DATE, DATE_FORMAT(EXPIRE_DATE,'%M %d, %Y') AS EXPIRE_DATE FROM driving_school_usr WHERE LOGIN_ID=?";
        my $sth =  $self->{PRODUCT_CON}->prepare($sql);
        $sth->execute($insId);
        my $tmpHash = $sth->fetchrow_hashref;
        $sth->finish;
        return $tmpHash;
}

sub isPrintableCourse {
	## ..slurp the class
	my $self    = shift;
	my ($courseId) = @_;
	my $courseTypeId = $self->{PRODUCT_CON}->selectrow_array('select course_type_id from courses where course_id = ?', {},$courseId);

	my $drivingSchoolState = $self->{PRODUCT_CON}->selectrow_array('select ds.ds_state_id from driving_school ds, courses c where ds.ds_school_id = c.ds_school_id and c.course_id = ?', {}, $courseId);

	my $noPrintStateCheck =  (exists $NO_PRINT_BTW_STATES->{$drivingSchoolState}) ? 1 : 0;

	if($courseTypeId eq '2' || $courseTypeId eq '3' && $noPrintStateCheck eq '1') { 
		##Ex: For CA, must land here
		return 0;
	}
	return 1;
}


sub getUserShipping
{
    my $self        = shift;
    my ($userId)    = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
SELECT SA.SHIPPING_ID, SA.NAME, SA.ADDRESS, SA.ADDRESS_2, SA.CITY, SA.STATE, SA.ZIP, SA.PHONE, SA.DESCRIPTION, SA.DELIVERY_ID,SA.ATTENTION, SA.SIGNATURE, DATE_FORMAT(SA.PRINT_DATE, '%d-%b-%Y %H:%i') as PRINT_DATE, SA.PRINT_CATEGORY_ID, SA.AIRBILL_NUMBER FROM user_shipping US, shipping_address SA WHERE US.USER_ID = ? AND US.SHIPPING_ID = SA.SHIPPING_ID
EOM

    $sql->execute($userId);
    my $retval = $sql->fetchrow_hashref;
    $sql->finish;

    return $retval;
}

sub printFedexLabel
{
        my $self = shift;
        my ($userId, $priority, $printerKey,$webService,$file,$trackingNumber) = @_;
        my %tmpHash;
        #### let's get user's shipping data
        $printerKey=($printerKey)?$printerKey:'CA';
        my $shippingData = $self->getUserShipping($userId);
        my $courseState=$self->getUserState($userId);
        $shippingData->{DESCRIPTION} = "BTW CERT FOR - $userId";

	#### create the fedex object, sending in the printer key
        my $fedexObj = Fedex->new($self->{PRODUCT});
        $fedexObj->{PRINTERS}=$self->{PRINTERS};
        $fedexObj->{PRINTING_STATE}=$courseState;
        $fedexObj->{PRINTING_TYPE}='CERTFEDX';
        $fedexObj->{PRINTER_KEY}=$printerKey;

        my $reply= $fedexObj->printLabel( $shippingData, (($priority) ? $priority : 1 ),'','',$file,$trackingNumber);
        my $fedex = "\nUSERID : $userId\n";

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
        {
                        $fedex .= "\t$_ : $$reply{$_}\n";
                        if(!$trackingNumber){
                                $self->putUserShipping($shippingData->{SHIPPING_ID}, $reply);
                        }
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

sub getUserState {
    my $self=shift;
    my($userId) = @_;
    return $self->{PRODUCT_CON}->selectrow_array("select ds.ds_state_id from driving_school ds, tx_class_students ui where ui.ds_school_id = ds.ds_school_id and ui.student_id = ?",{},$userId);
}


=pod


=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Printing/DIP.pm $

=item $Author: rajesh $

=item $Date: 2009/12/03 13:50:40 $

=item $Rev: 63 $

=cut
1;
