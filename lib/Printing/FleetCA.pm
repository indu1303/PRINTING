#!/usr/bin/perl -w 

package Printing::FleetCA;

use lib qw(/ids/tools/PRINTING/lib);
use Printing;
use MysqlDB;
use vars qw(@ISA);
@ISA = qw (Printing MysqlDB);

use strict;
use printerSite;
use Data::Dumper;

my $VERSION = 0.5;
my $NO_PRINT_FLEET_COURSE = { map { $_ => 1 } 55009 };

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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'FLEET_CA';
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
            my $sql     = $self->{PRODUCT_CON}->prepare("select course_id from course where state=? ");
            $sql->execute($constraints->{STATE});
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
delivery_id, date_format(ui.login_date,'%m/%d/%Y') from user_info ui left outer join user_delivery ud on ui.user_id=ud.user_id, user_course_payment ucp, user_cert_verification uc where ui.user_id = ucp.user_id and ui.user_id = uc.user_id and ui.completion_date is not null and ui.print_date is null and ucp.payment_date is not null [CONSTRAINT]
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




=head2 getUserData

=cut

##aabbcc
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
                UI.REGULATOR_ID,R.DEFINITION AS REGULATOR_DEF,'' as COUNTY_ID  ,'' AS COUNTY_DEF,'1' as DELIVERY_ID,
                C.STATE AS COURSE_STATE,C.SHORT_DESC,C.COURSE_LENGTH,'Regular' as DELIVERY_DEF,
                '' as USER_SEND_TO_REGULATOR,RCI.SEND_TO_REGULATOR,RCI.FAX AS REGULATOR_FAX,
                '' as CERT_PROCESSING_ID, '' as CERT_1,'' as CERT_2,'' as CERT_3, '' as CIRCUIT_COURT,
                US.USER_ID AS STC_USER_ID,
                UL.LOCK_DATE,
                date_format(UC.DATE_OF_BIRTH,'%m/%d/%Y') AS DATE_OF_BIRTH,UC.PHONE
                FROM
                (((((((user_info UI left outer join regulator R on UI.REGULATOR_ID=R.REGULATOR_ID) left outer join regulator_contact_info RCI on UI.REGULATOR_ID=RCI.REGULATOR_CONTACT_ID) left outer join  user_contact UC  on UI.USER_ID=UC.USER_ID)  left outer join course C on UI.COURSE_ID=C.COURSE_ID) left outer join regulator_course_selection RCS on UI.REGULATOR_ID=RCS.REGULATOR_ID)  left outer join user_lockout UL on UI.USER_ID=UL.USER_ID) left outer join user_stc US on UI.USER_ID=US.USER_ID)
                WHERE UI.USER_ID = ? AND UI.COURSE_ID=RCS.COURSE_ID
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


        my ($fleet_account_id,$fleet_sponsor, $fleet_account_manager_email)=$self->{PRODUCT_CON}->selectrow_array("select AD.ACCOUNT_ID,AD.ACCOUNT_NAME, AD.EMAIL AS ACCOUNT_MANAGER_EMAIL from user_info UI,account_data AD,trainee_data TCD where UI.USER_ID=TCD.USER_ID AND TCD.ACCOUNT_ID=AD.ACCOUNT_ID and UI.USER_ID=?",{},$userId);
        $retval->{ACCOUNT_ID}=$fleet_account_id;
        $retval->{ACCOUNT_NAME}=$fleet_sponsor;
        $retval->{ACCOUNT_MANAGER_EMAIL}=$fleet_account_manager_email;
	

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
                              cs.state = ? and cs.display >= ? ");
        $sql->execute($state, $display);
    } else {
        $sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where cs.state = ?");
        $sql->execute($state);
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
               $sql = $self->{PRODUCT_CON}->prepare("select c.course_id, ca.course_aggregate_description from course c, course_aggregate_desc ca where c.course_id =? and c.course_aggregate_id = ca.course_aggregate_id");

		$sql->execute($courseId);
	        	
    		while(my ($key, $def) = $sql->fetchrow)
    		{
                	$tmp{$key}->{DEFINITION} = $def;
    		}
		return \%tmp;
        }
=head2 isPrintableCourse

=cut

sub isPrintableCourse
{
    ### ..slurp the class
    my $self    = shift;
    my ($courseId) = @_; 
    if (exists $NO_PRINT_FLEET_COURSE->{$courseId})
    {
        return 0;
    }
    return 1;
} 

sub getAccountData
{
	my $self=shift;
	my ($accountId) = @_;
	my $retval;
        my ($fleet_account_id,$fleet_sponsor,$fleet_first_name,$fleet_last_name,$fleet_address1,$fleet_address2,$fleet_city,$fleet_state,$fleet_zip,$fleet_send_certificates,$fax,$email)=$self->{PRODUCT_CON}->selectrow_array("select AD.ACCOUNT_ID,AD.ACCOUNT_NAME,AD.FIRST_NAME,AD.LAST_NAME,AD.ADDRESS1,AD.ADDRESS2,AD.CITY,AD.STATE,AD.ZIP,AD.SEND_CERTIFICATES,FAX,EMAIL from account_data AD where AD.ACCOUNT_ID =?",{},$accountId);
        $retval->{ACCOUNT_ID}=$fleet_account_id;
        $retval->{NAME}=$fleet_sponsor;
        $retval->{FIRST_NAME}=$fleet_first_name;
        $retval->{LAST_NAME}=$fleet_last_name;
        $retval->{ADDRESS_1}=$fleet_address1;
        $retval->{ADDRESS_2}=$fleet_address2;
        $retval->{CITY}=$fleet_city;
        $retval->{STATE}=$fleet_state;
        $retval->{ZIP}=$fleet_zip;
        $retval->{ACCOUNT_SEND_CERTIFICATES}=$fleet_send_certificates;
        $retval->{FAX}=$fax;
        $retval->{EMAIL}=$email;
	return $retval;
}


sub getAccountDataByUserId {
	my $self=shift;
        my ($userId,$accountId) = @_;
	my ($retval,$fleet_send_certificates,$deliveryId);
	my $preRegData = $self->{PRODUCT_CON}->selectrow_array("select user_id from pre_registration_trainee_data where user_id=?",{},$userId);
	if($preRegData){
		($fleet_send_certificates,$deliveryId)=$self->{PRODUCT_CON}->selectrow_array("select fws.send_certificates,fws.delivery_id from pre_registration_trainee_data prtd,trainee_data td, fleet_work_states fws where prtd.user_id=?  and prtd.work_state=fws.state and fws.account_id=td.account_id and td.user_id= prtd.user_id",{},$userId);
	}else{
		($fleet_send_certificates,$deliveryId)=$self->{PRODUCT_CON}->selectrow_array("select fws.send_certificates,fws.delivery_id from account_data ad, fleet_work_states fws where ad.account_id=? and ad.state=fws.state and fws.account_id=ad.account_id",{},$accountId);
	}
	$retval->{ACCOUNT_SEND_CERTIFICATES}=$fleet_send_certificates;
	$retval->{DELIVERY_ID}=12; #$deliveryId;
	return $retval;
}


1;
