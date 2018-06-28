#!/usr/bin/perl -w 

package Printing::AAADIP;

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

my $NO_PRINT_AAADIP_COURSE = { map { $_ => 1 } qw(4007) };
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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'AAADIP';
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

     my $sql        = $self->{PRODUCT_CON}->prepare("select delivery_id, definition from delivery");
        $sql->execute;

        while (my ($v1, $v2) = $sql->fetchrow)
        {
                $self->{DELIVERY}->{$v1} = $v2;
        }

        $sql        = $self->{PRODUCT_CON}->prepare("select state_id, definition from states ");
        $sql->execute;

        while (my ($v1, $v2) = $sql->fetchrow)
        {
                $self->{STATES}->{$v1} = $v2;
        }


    ##### let's get some settings

    return $self;

    ##### since we're dealing w/ DIP printing, we need to know what type of job we need
    ##### in this case, the texas and the california jobs will be mutually exlusive,
    ##### therefore, we need a list of texas printing courses
}

=head2 getCompleteUsers

getCompleteUsers returns a complete list of completed users who are ready to print. In the DIP class, getCompleteUsers will isolate / query the course based only on DIP courses.  CLASSROOM, FLEET, TEEN, and HOSTED_AFFILIATE courses will not be queried.  This indicates the reduction in the number of courses / users which will eventually have to be fully parsed and possibly eliminiated before we can print.

getCompleteUsers can constrain users with granularity down to the regulator id or return all users based on a state.  Users can also be returned based on delivery methods. 

The following constraints are supported:
STATE
COURSE_ID
COUNTY_ID
REGULATOR_ID
STC
DELIVERY ID

Examples:
## All TX completed users, independent of course id 
Printing::DIP->getCompleteUsers({ STATE => 'TX' });     

## All San Diego Users  
Printing::DIP->getCompleteUsers({ COUNTY_ID => 36 });

## All California Users 
Printing::DIP->getCompleteUsers({ COURSE_ID => 13 });

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
                            REGULATOR_ID    => ' ui.regulator_id in ([REGULATOR_ID]) ',
                            COURSE_ID       => ' ui.course_id in ([COURSE_ID]) ',
                            DELIVERY_ID     => ' ud.delivery_id in ([DELIVERY_ID]) ',
                                    };
        if ($constraints->{COURSE})
        {
		if($constraints->{COURSE} eq 'ALLCAPRINT'){
			my $texasCourses = $self->{SETTINGS}->{TEXASPRINTING}->{$self->{PRODUCT}};
	            	@eList = sort keys %$texasCourses;
			delete $constraints->{COURSE};
		}else{
			$constraints->{COURSE_ID}=$constraints->{COURSE};
			delete $constraints->{COURSE};
		}
        }
        if ($constraints->{STATE})
        {
            my @courseIds;
            my $sql     = $self->{PRODUCT_CON}->prepare("select course_id from course where state=? and course_id not in (select course_id from course_attribute where attribute = ?)");
            $sql->execute($constraints->{STATE},'HOSTED_AFFILIATE');
            while (my ($s) = $sql->fetchrow)
            {
                    push @courseIds, $s;
            }

            $constraints->{COURSE_ID} = ($constraints->{COURSE_ID}) ? 
                            ("$constraints->{COURSE_ID}," . join(',',@courseIds)) :
                            (join(',', @courseIds));

            delete $constraints->{STATE};
        }
       
        if ($constraints->{COUNTY_ID})
        {
            my @regulatorIds;
            my $sql     = $self->{PRODUCT_CON}->prepare("select regulator_id from regulator_county where county_id=?");
            $sql->execute($constraints->{COUNTY_ID});
            while (my ($s) = $sql->fetchrow)
            {
                push @regulatorIds, $s;
            }

            $constraints->{REGULATOR_ID} = ($constraints->{REGULATOR_ID}) ? 
                            ("$constraints->{REGULATOR_ID}," . join(',',@regulatorIds)) :
                            (join(',', @regulatorIds));

            delete $constraints->{COUNTY_ID};
        }

        if ($constraints->{STC})
        {
            $stcConstraint = 'in';
            delete $constraints->{STC};
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
select ui.user_id, ui.course_id, ui.regulator_id, drivers_license, date_format(ui.completion_date,'%m/%d/%Y'), 
delivery_id, date_format(ui.login_date,'%m/%d/%Y') from user_info ui left outer join user_delivery ud on ui.user_id=ud.user_id, user_course_payment ucp, user_cert_verification uc where ui.user_id = ucp.user_id  and ui.course_id not in ($noCourseList) and ui.user_id = uc.user_id and ui.completion_date is not null and ui.print_date is null and ucp.payment_date is not null [CONSTRAINT]
EOM

        $sqlStmt =~ s/\[CONSTRAINT\]/$constraint/;
        $sqlStmt =~ s/\[STC\]/$stcConstraint/;
    	my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    	$sql->execute;
        while (my ($v1, $v2, $v3, $v4, $v5, $v6, $v7) = $sql->fetchrow)
        {
	    my $lockoutUser = $self->{PRODUCT_CON}->selectrow_array('select user_id from user_lockout where user_id = ?', {},$v1);
	    if($lockoutUser) {
		next;
	    }

            $retval->{$v1}->{USER_ID}           = $v1;
            $retval->{$v1}->{COURSEID}          = $v2;
            $retval->{$v1}->{REGULATORID}       = $v3;
            $retval->{$v1}->{DRIVERS_LICENSE}   = $v4;
            $retval->{$v1}->{COMPLETION_DATE}   = $v5;
            $retval->{$v1}->{DELIVERYID}        = ($v6)?$v6:1; 
            $retval->{$v1}->{LOGIN_DATE}        = $v7;
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
	my $c = $self->{PRODUCT_CON}->selectrow_array('select certificate_number from user_info where user_id = ?', {},$userId);
    ##### call the base class's certificate number.  No reason to redeclare the rest of this function	
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
		SELECT UI.USER_ID, UI.DRIVERS_LICENSE, UI.COURSE_ID,
                date_format(UI.COMPLETION_DATE,'%m/%d/%Y') AS COMPLETION_DATE,
                date_format(UI.PRINT_DATE,'%m/%d/%Y') AS PRINT_DATE, UI.CERTIFICATE_NUMBER, UI.LOGIN_DATE,
                UPPER(UC.FIRST_NAME) as FIRST_NAME, UPPER(UC.LAST_NAME) as LAST_NAME, UC.ADDRESS_1, UC.ADDRESS_2, 
		UC.CITY, UC.STATE, UC.ZIP, UC.EMAIL,UC.SEX,
                UI.REGULATOR_ID,R.DEFINITION AS REGULATOR_DEF,CT.COUNTY_ID,CT.DEFINITION AS COUNTY_DEF,UD.DELIVERY_ID,
                C.STATE AS COURSE_STATE,C.SHORT_DESC,C.COURSE_LENGTH,D.DEFINITION AS DELIVERY_DEF,
                UD.SEND_TO_REGULATOR AS USER_SEND_TO_REGULATOR,RCI.SEND_TO_REGULATOR,RCI.FAX AS REGULATOR_FAX,
                CP.CERT_PROCESSING_ID, CERT_1,CERT_2,CERT_3, RCC.CIRCUIT_COURT,
                US.USER_ID AS STC_USER_ID,
                UL.LOCK_DATE,round(UI.PRINT_DATE) as CERT_PRINT_DATE,
                date_format(UC.DATE_OF_BIRTH,'%m/%d/%Y') AS DATE_OF_BIRTH,UC.PHONE, date_format(REGISTRATION_DATE,'%m/%d/%Y') as DATE_OF_REGISTRATION
                FROM
                (((((((((((((user_info UI left outer join regulator R on UI.REGULATOR_ID=R.REGULATOR_ID) left outer join regulator_contact_info RCI on UI.REGULATOR_ID=RCI.REGULATOR_CONTACT_ID) left outer join  user_contact UC  on UI.USER_ID=UC.USER_ID) left outer join  regulator_county RC on UI.REGULATOR_ID=RC.REGULATOR_ID) left outer join user_delivery UD on UI.USER_ID=UD.USER_ID) left outer join course C on UI.COURSE_ID=C.COURSE_ID) left outer join regulator_course_selection RCS on UI.REGULATOR_ID=RCS.REGULATOR_ID) left outer join regulator_circuit_court RCC on UI.REGULATOR_ID=RCC.REGULATOR_ID) left outer join user_lockout UL on UI.USER_ID=UL.USER_ID) left outer join user_stc US on UI.USER_ID=US.USER_ID) left outer join county CT on RC.COUNTY_ID=CT.COUNTY_ID) left outer join delivery D on  UD.DELIVERY_ID=D.DELIVERY_ID) left outer join certificate_processing CP on  RCS.CERT_PROCESSING_ID = CP.CERT_PROCESSING_Id) WHERE UI.USER_ID = ? AND UI.COURSE_ID=RCS.COURSE_ID
EOM
    
    $sql->execute($userId);
    $retval=$sql->fetchrow_hashref;

    ##### get the final score
    my $finalScore              = $self->{PRODUCT_CON}->selectrow_array('select max(score) from user_final_exam where user_id = ?', {},$userId);
    $retval->{FINAL_SCORE}      = $finalScore;

    ##### getCourse Aggregate Desc
    $retval->{COURSE_AGGREGATE_DESC} = $self->{PRODUCT_CON}->selectrow_array('select COURSE_AGGREGATE_DESCRIPTION from course_aggregate_desc cad,course c where cad.course_aggregate_id =c.course_aggregate_id and course_id=?',{},$retval->{COURSE_ID});
    
    ##### get third party data
 
    my $tpd                     = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='THIRD_PARTY_DATA'", {},$userId);
    if ($tpd)
    {
        $retval->{THIRD_PARTY_DATA}      = $tpd;
    }
    ##### get voice verified data
 
    my $voice                   = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='VOICE_VERIFICATION_STATUS'", {},$userId);
    if ($voice)
    {
        $retval->{VOICE_VERIFICATION_STATUS}      = $voice;
    }

    my $resident                  = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='RESIDENT_STATE'", {},$userId);
    if ($resident)
    {
        $retval->{RESIDENT_STATE}      = $resident;
    }
    my $coupon                  = $self->{PRODUCT_CON}->selectrow_array("select coupon from user_course_pricing where user_id =? ",{},$userId);
    if($coupon){
	$retval->{COUPON} = $coupon;
    } 
    my $CTSI_SCMS                   = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='CTSI_SCMS_USER'", {},$userId);
    if ($CTSI_SCMS)
    {
        $retval->{CTSI_SCMS_USER}      = $CTSI_SCMS;
    }
    my $NO_PRINT_CERT                  = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='NO_PRINT_CERT'", {},$userId);
    if ($NO_PRINT_CERT)
    {
        $retval->{NO_PRINT_CERT}      = $NO_PRINT_CERT;
    }
    my $AAA_INS_CALL                  = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='AAA_INSURANCE_CALL'", {},$userId);
    if ($AAA_INS_CALL)
    {
        $retval->{AAA_INS_CALL}      = ($AAA_INS_CALL eq 'YES')?'Y':'N';
    }
	
    ##### get user citation information
    $sql                    = $self->{PRODUCT_CON}->prepare(<<"EOM");
select param, value from user_citation where user_id = ?
EOM
    $sql->execute($userId);

    while (my ($v1, $v2, $v3) = $sql->fetchrow)
    {
        ###### we have both case and ticket numbers.  basically, ticket numbers are citation numbers
        ###### so we can technically be interchangable.  For field purposes, stick to CASE_NUMBER
        if ($v1 eq 'TICKET_NUMBER' || $v1 eq 'CASE_NUMBER')
        {
            $v1 = 'CITATION_NUMBER';
        }
	if ($v1 eq 'COURT_DATE')
        {
            $v1 = 'DUE_DATE';
        }

        $retval->{CITATION}->{$v1} = $v2;
    }

	($retval->{OFFICECA}->{NAME}, $retval->{OFFICECA}->{ADDRESS}, $retval->{OFFICECA}->{CITY}, $retval->{OFFICECA}->{STATE}, $retval->{OFFICECA}->{ZIP}, $retval->{OFFICECA}->{PHONE}) = $self->{PRODUCT_CON}->selectrow_array("select ACO.name,concat(ACO.address1,ACO.address2) as ADDRESS,ACO.city,ACO.state,ACO.zip,ACO.phone from affiliate_contact_info ACO,aaa_club AC,aaa_division AD,aaa_coupon_code ACC where ACC.aaa_division_id=AD.aaa_division_id and AD.aaa_id=AC.aaa_id and AC.affiliate_contact_info_id=ACO.affiliate_contact_info_id and ACC.coupon_code=?", {}, $coupon);
	
	if($coupon eq 'AAATVN' || $coupon eq 'AAATVM') {
		$retval->{AAA_TIDEWATER_CLUB} = 1;
	}
	
    ##### get user Upsell Data 
    return $retval;
}


=head2 putUserPrintRecord

=cut

sub putUserPrintRecord {
    my $self    = shift;
    my ($userId, $certNumber, $type, $duplicateId) = @_;
    my $deliveryId =  $self->{PRODUCT_CON}->selectrow_array('select delivery_id from user_delivery where user_id = ?', {}, $userId);
    if(!defined $deliveryId){
        $deliveryId = 1;
        $self->updateDelivery($userId, $deliveryId);
    }

    if($type eq 'PRINT')
    {
        my $sth =  $self->{PRODUCT_CON}->prepare('update user_info set print_date = sysdate(), certificate_number = ? where user_id = ?');        $sth->execute($certNumber, $userId);
    }
    elsif ($type eq 'DUPLICATE')
    {
        my $sth =  $self->{PRODUCT_CON}->prepare('update user_cert_duplicate set print_date = sysdate(), certificate_number = ? where user_id = ? and duplicate_id = ?') || die ("BAD MONKEY $DBI::errstr");
        $sth->execute($certNumber, $userId, $duplicateId) || die("NAUGHTY MONKEY $DBI::errstr");
    }
    else
    {
                my $sth =  $self->{PRODUCT_CON}->prepare('insert into orders_reprinted (user_id, delivery_id, print_date, certificate_number)
                                                                                   values (?, ?, sysdate(), ?)');
                $sth->execute($userId, $deliveryId, $certNumber);
    }
}
=head2 updateDelivery

=cut
sub updateDelivery { 
    my  $self= shift;
    my ($userId, $delId) = @_;

    if(!defined $delId){
                my $sth = $self->{PRODUCT_CON}->prepare("delete from user_delivery where user_id = ?");
                $sth->execute($userId);
    } else {
                my $sth = $self->{PRODUCT_CON}->prepare("update user_delivery set delivery_id = ? where user_id = ?");
                my $status = $sth->execute($delId, $userId);
                if(!defined $status || $status != 1){
                    $sth = $self->{PRODUCT_CON}->prepare("insert into user_delivery (user_id, delivery_id) values (?, ?)");
                    $sth->execute($userId, $delId);
                }
    }

    if(!defined $delId || ($delId != 2 && $delId != 7 && $delId != 11)){ $self->updateSTC($userId); }
}

=head2 updateSTC

=cut
sub updateSTC {
    my  $self= shift;
    my ($userId, $stc) = @_;

    my $sth =  $self->{PRODUCT_CON}->prepare("update user_delivery set send_to_regulator = ? where user_id = ?");
    if(defined $stc){
        $sth->execute($stc, $userId);
    } else {
        $sth->execute(undef, $userId);
    }
}

=head2 getCourseSelection

=cut

##### Get the all coursse info by state#####
sub getCourseSelection{
    my $self = shift;
    my ($state, $display) = @_;
    my $sql;
    if($state eq 'FK'){
	my $stateList = $self->{SETTINGS}->{FEDEXKINKOS}->{$self->{PRODUCT}}->{NONTX};
	my $states='';
	foreach(keys %$stateList){
        	$states .= "'".$_."'".",";
	}
	$states = substr($states,0,-1);
	$sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where cs.state in ($states) 
                                and cs.course_id  not in (select  course_id from course_attribute where attribute =?)");
        $sql->execute('HOSTED_AFFILIATE');
    }elsif(defined $display){
        $sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where
                              cs.state = ? and cs.display >= ? and cs.course_id  not in (select 
				course_id from course_attribute where attribute =?)");
        $sql->execute($state, $display,'HOSTED_AFFILIATE');
    } else {
        $sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where cs.state = ? 
				and cs.course_id  not in (select  course_id from course_attribute where attribute =?)");
        $sql->execute($state,'HOSTED_AFFILIATE');
    }

    my (%tmp, $key, $def,);

    while(($key, $def, $display) = $sql->fetchrow)
    {
                $tmp{$key}->{DEFINITION} = $def;
                $tmp{$key}->{SORT} = $display;
    }

    foreach my $ids(sort keys %tmp)
    {
        if (exists $self->{SETTINGS}->{COURSEAGGREGATESHELLMAP}->{$self->{PRODUCT}}->{$ids})
        {
            delete $tmp{$self->{SETTINGS}->{COURSEAGGREGATESHELLMAP}->{$self->{PRODUCT}}->{$ids}};
        }
    }

    $sql->finish;
    return \%tmp;
}


=head2 getCourseDescription

=cut
##### Get the all coursse info by course Id#####
sub getCourseDescription {
    my $self = shift;
    my ($courseId) = @_;
    my $sql;
    my %tmp;
               $sql = $self->{PRODUCT_CON}->prepare("select c.course_id, ca.course_aggregate_description from course c, course_aggregate_desc ca where c.course_id =? and c.course_aggregate_id = ca.course_aggregate_id and c.course_id not in (select course_id from course_attribute where attribute =?)");

		$sql->execute($courseId,'HOSTED_AFFILIATE');
	        	
    		while(my ($key, $def) = $sql->fetchrow)
    		{
                	$tmp{$key}->{DEFINITION} = $def;
    		}
		return \%tmp;
        }


=head2 getAccompanyLetterUsers 

=cut
#######Get All Accompany Lettwer

sub getAccompanyLetterUsers
{
    my $self=shift;
    my $sth = $self->{PRODUCT_CON}->prepare("select user_id from user_accompany_letter where print_date is null");
    $sth->execute();

    my %tmpHash;
    my $v1;
    while(($v1) = $sth->fetchrow){
       $tmpHash{$v1}=0;
    }
    $sth->finish;
    return \%tmpHash;
}


=head2 putAccompanyLetterUser 

=cut

### This is for, when STC Cert has been printed , we are going to insert a record in user_accompany_letter for printing the user_accompany_letter.
sub putAccompanyLetterUser {
    my $self=shift;
    my($userId) = @_;
    $self->{PRODUCT_CON}->do('insert into user_accompany_letter (user_id, print_date) values (?, null)', {}, $userId);
}


=head2 putAccompanyLetterUserPrint 

=cut

### When accompany Letter has been printer , we are updating the print date on user_accompany_letter table.
sub putAccompanyLetterUserPrint {
    my $self=shift;
    my($userId) = @_;
    my $status = $self->{PRODUCT_CON}->do('update user_accompany_letter set print_date = sysdate() where user_id = ?', {}, $userId);
    if(!defined $status || $status != 1){
        $self->{PRODUCT_CON}->do('insert into user_accompany_letter values (?, sysdate())', {}, $userId);
    }
}

=head2 getUserTestCenter 

=cut

sub getUserTestCenter {
    my $self=shift;
    my($userId) = @_;
    return $self->{PRODUCT_CON}->selectrow_array('select test_center_id from user_test_center where user_id = ?', {}, $userId);
}

=head2 getTestCenter 

=cut
sub getTestCenter {
    my $self=shift;
    my($testCenterId) = @_;

    keys my %tmpHash = 8;
    ($tmpHash{TEST_CENTER_ID}, $tmpHash{TEST_CENTER}, $tmpHash{ADDRESS}, $tmpHash{CITY}, $tmpHash{STATE}, $tmpHash{ZIP},
     $tmpHash{PHONE},$tmpHash{FAX}, $tmpHash{PASSWORD}, $tmpHash{TEST_OR_AUTH}, $tmpHash{HOLIDAY_SCHEDULE}, $tmpHash{HOURS_OF_OPERATION},
     $tmpHash{TEST_CENTER_TYPE}, $tmpHash{NOTIFY})
        = $self->{PRODUCT_CON}->selectrow_array('select tc.test_center_id, tc.test_center, tc.address, tc.city, tc.state, tc.zip, tc.phone,
                                 tc.fax,tc.password, tc.TEST_CENTER_TYPE, tci.holiday_schedule, tci.hours_of_operation,
                                 tci.test_center_type, tc.notify
                                 from test_center tc, test_center_info tci
                                 where tc.test_center_id = ?
                                                                 and tc.active = ?
                                 and tc.test_center_id = tci.test_center_id', {}, $testCenterId, 1);
    return \%tmpHash;
}

sub getDPSInformation {
    my $self=shift;
    my ($userId) = @_;
    my $sth = $self->{PRODUCT_CON}->prepare("select USER_ID,DRIVERS_LICENSE, FIRST_NAME, LAST_NAME, ADDRESS1,ADDRESS2,CITY, STATE, ZIP, PHONE, date_format(DPS_DATE,'%m/%d/%Y') as DPS_DATE,date_format(date_of_birth,'%m/%d/%Y')  as DATE_OF_BIRTH, FAX, ACTIVE, STATUS, FOLLOWUP, date_format(DATE_FAXED,'%m-%d-%Y') as DATE_FAXED, date_format(DATE_PROCESSED,'%d-%b-%Y') AS DATE_PROCESSED, DRIVER_RECORD_NUMBER,SIGNATURE,DELIVERY_ID,SHIPPING_ID from dps_information where user_id=?");
  	     $sth->execute($userId);
  	     my $tmpHash = $sth->fetchrow_hashref;
  	     $sth->finish;
  	     return $tmpHash;
}
sub getUserCitation{
    my $self=shift;
    my($userId, $param) = @_;
    if(defined $param){
                return  $self->{PRODUCT_CON}->selectrow_array('SELECT VALUE FROM user_citation WHERE USER_ID = ? AND PARAM = ?', {}, $userId, $param);
    } else {
                my $sth =  $self->{PRODUCT_CON}->prepare('SELECT PARAM, VALUE FROM user_citation WHERE USER_ID = ?');
                $sth->execute($userId);
                my(%tmpHash, $key, $v1);
                while(my @tmpArr = $sth->fetchrow_array){
                        $tmpHash{$tmpArr[0]} = $tmpArr[1];
                }
                $sth->finish;
                return \%tmpHash;
    }
}

sub getUserDelivery{
    my $self=shift;
    my($userId) = @_;
    my %tmp;
    ($tmp{DELIVERY_ID}, $tmp{SEND_TO_REGULATOR}, $tmp{DEFINITION}) =
        $self->{PRODUCT_CON}->selectrow_array('SELECT UD.DELIVERY_ID, UD.SEND_TO_REGULATOR, D.DEFINITION
                               from user_delivery UD, delivery D
                               where UD.USER_ID = ?
                               and UD.DELIVERY_ID = D.DELIVERY_ID', {}, $userId);
    return \%tmp;
}
sub deleteCookie{
    my $self=shift;
    my($userId, $arrRef) = @_;
    my %tmpHash;
    my $sth = $self->{PRODUCT_CON}->prepare('delete from user_cookie where user_id = ? and param = ?');
    for my $param(@$arrRef){
        $sth->execute($userId, $param);
    }
}

sub putCookie{
    my $self=shift;
    my($userId, $hashRef) = @_;
    my $sth1 = $self->{PRODUCT_CON}->prepare('update user_cookie set value = ? where user_id = ? and param = ?');
    my $sth2 = $self->{PRODUCT_CON}->prepare('insert into user_cookie (user_id, param, value) values (?, ?, ?)');
    for my $param(keys %$hashRef){
        my $status = $sth1->execute($$hashRef{$param}, $userId, $param);
        if(!defined $status || $status != 1){
            $sth2->execute($userId, $param, $$hashRef{$param});
        }
    }
}

sub getCompletionDate{
        my $self=shift;
        my ($userId) = @_;
        return $self->{PRODUCT_CON}->selectrow_array("select date_format(completion_date, '%d-%b-%Y %H:%i') from user_info
                                              where user_id = ?", {}, $userId);
}
=head2 isPrintableCourse

=cut

sub isPrintableCourse
{
    ### ..slurp the class
    my $self    = shift;
    my ($courseId) = @_;
    if (exists $NO_PRINT_AAADIP_COURSE->{$courseId})
    {
        return 0;
    }
    return 1;
}

sub getCTSICourtNumber {
        my $self=shift;
        my ($idsRegulatorId) = @_;
        my $sql = "SELECT CTSI_COUNTY_ID FROM cts_county_map WHERE IDS_REGULATOR_ID = ?";
        return $self->{PRODUCT_CON}->selectrow_array($sql,{},$idsRegulatorId);
} 

sub getPage {
        my $self=shift;
	my ($ua, $req) = @_;
	my $content;
        $content = $ua->request($req)->as_string;

        if ($content =~ /500 \(Internal Server Error\)/ ) {
                return undef;
        } else {
                return $content;
        }
}

sub getOKUsers
{
        my $self = shift;
	my ($constraints)    = @_;

        my $reportDate = $self->{PRODUCT_CON}->selectrow_array("select date_format(date_sub(now(), interval 1 day), '%Y-%m-%d') as reportdate");
        my $fromDate = $reportDate." 00:00:00";
        my $toDate = $reportDate." 23:59:59";
	my $courseId='';
	my $appendQuery = '';

	if ($constraints->{COURSE}){
		$courseId = $constraints->{COURSE};
	}else{
	        my $sql     = $self->{PRODUCT_CON}->prepare("select course_id from course where state = ? and course_id not in (select course_id from course_attribute where attribute = ?)");
        	$sql->execute('OK', 'HOSTED_AFFILIATE');
	        my @courseIds;
        	while (my ($s) = $sql->fetchrow)
	        {
        	        push @courseIds, $s;
	        }
        	$courseId = join(',', @courseIds);
		$appendQuery = "and regulator_id = $self->{SETTINGS}{OKLAHOMA_CITY_COURT}";
	}

        my $sql = $self->{PRODUCT_CON}->prepare(<<"EOM");
select user_id from user_info where completion_date between str_to_date('$fromDate', '%Y-%m-%d %H:%i:%s') and str_to_date('$toDate', '%Y-%m-%d %H:%i:%s') and course_id in ($courseId) $appendQuery
EOM
        my %tmpHash;
        my $v1;
        $sql->execute();
        while(($v1) = $sql->fetchrow)
        {
           $tmpHash{$v1}=0;
        }
        $sql->finish;
        return \%tmpHash;
}

1;
