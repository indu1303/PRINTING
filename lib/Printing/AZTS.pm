#!/usr/bin/perl -w 

package Printing::AZTS;

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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'AZTS';
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

    ##### get the list of hosted affiliate courses and other courses
    ##### which need to be segreated based on certificate type
   # $self->constructor;
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
            my $sql     = $self->{PRODUCT_CON}->prepare("select course_id from course where state=? and course_id in (select course_id from course_attribute where attribute = ? and value=?)");
            $sql->execute($constraints->{STATE},'HOSTED_AFFILIATE','AZTS');
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

        ##### now, generate the SQL statement
    	my $sqlStmt     = <<"EOM";
select ui.user_id, ui.course_id, ui.regulator_id, drivers_license, date_format(ui.completion_date,'%m/%d/%Y'), 
delivery_id, date_format(ui.login_date,'%m/%d/%Y') from user_info ui left outer join user_delivery ud on ui.user_id=ud.user_id, user_course_payment ucp, user_cert_verification uc where ui.user_id = ucp.user_id and ui.user_id = uc.user_id and ui.completion_date is not null and ui.print_date is null and ucp.payment_date is not null and ui.user_id not in (select user_id from user_lockout) and ui.course_id in (select course_id from course_attribute where attribute ='HOSTED_AFFILIATE' and value='AZTS') [CONSTRAINT]
EOM

        $sqlStmt =~ s/\[CONSTRAINT\]/$constraint/;
        $sqlStmt =~ s/\[STC\]/$stcConstraint/;
    	my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    	$sql->execute;

        while (my ($v1, $v2, $v3, $v4, $v5, $v6, $v7) = $sql->fetchrow)
        {
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
		UC.CITY, UC.STATE, UC.ZIP, UC.EMAIL,
                UI.REGULATOR_ID,R.DEFINITION AS REGULATOR_DEF,CT.COUNTY_ID,CT.DEFINITION AS COUNTY_DEF,UD.DELIVERY_ID,
                C.STATE AS COURSE_STATE,C.SHORT_DESC,C.COURSE_LENGTH,D.DEFINITION AS DELIVERY_DEF,
                UD.SEND_TO_REGULATOR AS USER_SEND_TO_REGULATOR,RCI.SEND_TO_REGULATOR,RCI.FAX AS REGULATOR_FAX,
                CP.CERT_PROCESSING_ID, CERT_1,CERT_2,CERT_3, RCC.CIRCUIT_COURT,
                US.USER_ID AS STC_USER_ID,
                UL.LOCK_DATE,
                date_format(UC.DATE_OF_BIRTH,'%m/%d/%Y') AS DATE_OF_BIRTH,UC.PHONE
                FROM
                (((((((((((((user_info UI left outer join regulator R on UI.REGULATOR_ID=R.REGULATOR_ID) left outer join regulator_contact_info RCI on UI.REGULATOR_ID=RCI.REGULATOR_CONTACT_ID) left outer join  user_contact UC  on UI.USER_ID=UC.USER_ID) left outer join  regulator_county RC on UI.REGULATOR_ID=RC.REGULATOR_ID) left outer join user_delivery UD on UI.USER_ID=UD.USER_ID) left outer join course C on UI.COURSE_ID=C.COURSE_ID) left outer join regulator_course_selection RCS on UI.REGULATOR_ID=RCS.REGULATOR_ID) left outer join regulator_circuit_court RCC on UI.REGULATOR_ID=RCC.REGULATOR_ID) left outer join user_lockout UL on UI.USER_ID=UL.USER_ID) left outer join user_stc US on UI.USER_ID=US.USER_ID) left outer join county CT on RC.COUNTY_ID=CT.COUNTY_ID) left outer join delivery D on  UD.DELIVERY_ID=D.DELIVERY_ID) left outer join certificate_processing CP on  RCS.CERT_PROCESSING_ID = CP.CERT_PROCESSING_Id)                 WHERE UI.USER_ID = ? AND UI.COURSE_ID=RCS.COURSE_ID
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

    return $retval;
}


=head2 getUserShipping

=cut

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
    if(defined $display){
        $sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where
                              cs.state = ? and cs.display >= ? and cs.course_id  in (select 
				course_id from course_attribute where attribute =? and value=?)");
        $sql->execute($state, $display,'HOSTED_AFFILIATE','AZTS');
    } else {
        $sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where cs.state = ? 
				and cs.course_id  in (select  course_id from course_attribute where attribute =? and value=?)");
        $sql->execute($state,'HOSTED_AFFILIATE','AZTS');
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
               $sql = $self->{PRODUCT_CON}->prepare("select c.course_id, ca.course_aggregate_description from course c, course_aggregate_desc ca where c.course_id =? and c.course_aggregate_id = ca.course_aggregate_id and c.course_id in (select course_id from course_attribute where attribute =? and value = ? )");

		$sql->execute($courseId,'HOSTED_AFFILIATE','AZTS');
	        	
    		while(my ($key, $def) = $sql->fetchrow)
    		{
                	$tmp{$key}->{DEFINITION} = $def;
    		}
		return \%tmp;
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

1;
