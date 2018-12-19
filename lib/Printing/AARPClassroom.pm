#!/usr/bin/perl -w 

package Printing::AARPClassroom;

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

my $NO_PRINT_AARP_COURSE = { map { $_ => 1 } qw(5001 5002 5003) };
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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'AARP_CLASSROOM';
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

        my $constraintList        = {
                            COURSE_ID       => ' ui.course_id in ([COURSE_ID]) ',
                            DELIVERY_ID     => ' ud.delivery_id in ([DELIVERY_ID]) ',
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
        if ($constraints->{STATE})
        {
            my @courseIds;
            my $sql     = $self->{PRODUCT_CON}->prepare("select course_id from course where state=?");
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
        my $noPrintCourse = $self->{SETTINGS}->{NO_PRINT_COURSE}->{$self->{PRODUCT}};
        my $noCourseList = join(',', (@eList,keys %$noPrintCourse));
	if(!$noCourseList){
		$noCourseList=0;
	}

        my $constraint = "";
        foreach my $cKey(keys %$constraints)
        {
            $constraint .= ' and' . $constraintList->{$cKey};
            $constraint =~ s/\[$cKey\]/$constraints->{$cKey}/g;
        }
	#select ui.user_id, ui.course_id, delivery_id from user_info ui left outer join user_delivery ud on ui.user_id=ud.user_id, user_course_payment ucp,user_cert_verification uc,course c where ui.user_id = ucp.user_id and ui.course_id not in ($noCourseList) and ui.user_id = uc.user_id and ui.completion_date is not null and ui.print_date is null and ucp.payment_date is not null and ui.user_id not in (select user_id from user_lockout) and ui.course_id=c.course_id [CONSTRAINT]
	#(1)modifield: select ui.user_id, ui.course_id, delivery_id from user_info ui left outer join user_delivery ud on ui.user_id=ud.user_id, user_course_payment ucp,course c where ui.user_id = ucp.user_id and ui.course_id not in ($noCourseList) and ui.completion_date is not null and ui.print_date is null and ucp.payment_date is not null and ui.user_id not in (select user_id from user_lockout) and ui.course_id=c.course_id [CONSTRAINT]
        my $sqlStmt     = <<"EOM";
		select ui.user_id, ui.course_id from user_info ui where ui.completion_date is not null and ui.print_date is null
EOM
        $sqlStmt =~ s/\[CONSTRAINT\]/$constraint/;
    	my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    	$sql->execute;
        while (my ($v1, $v2, $v3) = $sql->fetchrow)
        {
	    my $lockoutUser = $self->{PRODUCT_CON}->selectrow_array('select user_id from user_lockout where user_id = ?', {},$v1);
	    if($lockoutUser) {
		next;
	    }

            $retval->{$v1}->{USER_ID}           = $v1;
            $retval->{$v1}->{COURSEID}          = $v2;
            $retval->{$v1}->{DELIVERYID}        = ($v3)?$v3:1; 
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
	if (!$self->isPrintableCourse($cId))
        {
        ###### We're going to assign it a certificate number later as needed because each
        ###### CA cert has to be hand fed into the printer and hand assigned a cert number
        return "[TO BE ASSIGNED]";
        } else {
		if ($c)
		{
        	   ##### just return the user's current certificate
		    return $c;
		}
		
		if (my $courseAlias = $self->{SETTINGS}->getCertPoolCourseForUSI($cId))
		{
			
                	my $certNumber = $self->{PRODUCT_CON}->selectrow_array('select min(certificate_number) from certificate where course_id = ?',
	                                                {},$courseAlias);
	
        	        if(defined $certNumber && length $certNumber)
                	{
	                    my $status = $self->{PRODUCT_CON}->do('delete from certificate where certificate_number = ? and course_id = ?', {},$certNumber, $courseAlias);
				return $certNumber;
			}
			return '';
      		} 
		    ##### call the base class's certificate number.  No reason to redeclare the rest of this function	
	        #$self->SUPER::getNextCertificateNumber($userId, $cId);
		$self->{PRODUCT_CON}->do('UPDATE certificate_number_seq SET id=LAST_INSERT_ID(id+1)');
		my $newCertNumber = $self->{PRODUCT_CON}->selectrow_array("select LAST_INSERT_ID()");
		return "N0$newCertNumber";
	}
}


=head2 getUserData

=cut

sub getUserData
{
    my $self        = shift;
    my ($userId, $retval)    = @_;

#    my $retval;
    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
		SELECT UI.USER_ID, sf_decrypt(UI.DRIVERS_LICENSE) as DRIVERS_LICENSE, UI.COURSE_ID,
                date_format(UI.COMPLETION_DATE,'%m/%d/%Y') AS COMPLETION_DATE,
                date_format(UI.PRINT_DATE,'%m/%d/%Y') AS PRINT_DATE, UI.CERTIFICATE_NUMBER, 
                date_format(date_sub(UI.PRINT_DATE,interval -2 year),'%m/%d/%Y') as EXPIRATION_DATE, date_format(date_sub(NOW(),interval -2 year),'%m/%d/%Y') as EXPIRATION_DATE2,
                UPPER(sf_decrypt(UI.FIRST_NAME)) as FIRST_NAME, UPPER(sf_decrypt(UI.LAST_NAME)) as LAST_NAME, sf_decrypt(UI.ADDRESS1) as ADDRESS_1, sf_decrypt(UI.ADDRESS2) as ADDRESS_2, 
                sf_decrypt(UI.CITY) as CITY, sf_decrypt(UI.STATE) as STATE, sf_decrypt(UI.ZIP) as ZIP, UI.EMAIL,UI.SEX,
                UD.DELIVERY_ID,
                C.STATE AS COURSE_STATE,C.SHORT_DESC,D.DEFINITION AS DELIVERY_DEF,
                UL.LOCK_DATE,round(UI.PRINT_DATE) as CERT_PRINT_DATE,
                date_format(sf_decrypt(UI.DATE_OF_BIRTH),'%m/%d/%Y') AS DATE_OF_BIRTH,UI.PHONE, UI.INSTRUCTOR_NAME AS INSTRUCTOR_NAME
                FROM
                ((((user_info UI left outer join user_delivery UD on UI.USER_ID=UD.USER_ID) left outer join course C on UI.COURSE_ID=C.COURSE_ID)  left outer join user_lockout UL on UI.USER_ID=UL.USER_ID) left outer join delivery D on  UD.DELIVERY_ID=D.DELIVERY_ID)  WHERE UI.USER_ID = ? 
EOM
    $sql->execute($userId);
    $retval=$sql->fetchrow_hashref;

    if (!$retval->{EMAIL}) {
        $retval->{EMAIL} = $retval->{LOGIN};
    }

    ##### get the final score
    #my $finalScore              = $self->{PRODUCT_CON}->selectrow_array('select max(score) from user_final_exam where user_id = ?', {},$userId);
    #$retval->{FINAL_SCORE}      = $finalScore;

    ##### getCourse Aggregate Desc
    #$retval->{COURSE_AGGREGATE_DESC} = $self->{PRODUCT_CON}->selectrow_array('select COURSE_AGGREGATE_DESCRIPTION from course_aggregate_desc cad,course c where cad.course_aggregate_id =c.course_aggregate_id and course_id=?',{},$retval->{COURSE_ID});
    
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
    #my $coupon                  = $self->{PRODUCT_CON}->selectrow_array("select coupon from user_course_pricing where user_id =? ",{},$userId);
    #if($coupon){
#	$retval->{COUPON} = $coupon;
#    } 
    my $CERT_SENT_VIA_EMAIL                   = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='CERT_SENT_VIA_EMAIL'", {},$userId);
    if ($CERT_SENT_VIA_EMAIL)
    {
        $retval->{CERT_SENT_VIA_EMAIL}      = $CERT_SENT_VIA_EMAIL;
    }
    my $NO_PRINT_CERT                  = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='NO_PRINT_CERT'", {},$userId);
    if ($NO_PRINT_CERT)
    {
        $retval->{NO_PRINT_CERT}      = $NO_PRINT_CERT;
    }
    #my $AARPMEMBERCODE = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='AARPMEMBERCODE'", {},$userId);
    my $AARPMEMBERCODE = $self->{PRODUCT_CON}->selectrow_array("select member_id from user_info where user_id = ?", {},$userId);
	if ($AARPMEMBERCODE) {
		$retval->{AARPMEMBERCODE} = $AARPMEMBERCODE;
	}

    $retval->{NAME} = $retval->{FIRST_NAME} . " ". $retval->{LAST_NAME};
    if ($retval->{SEX} eq 'F') {
	$retval->{SEX} = 'Female';
    } else {
	$retval->{SEX} = 'Male';
    }	
    ##### get user citation information
    #$sql                    = $self->{PRODUCT_CON}->prepare(<<"EOM");
#select param, value from user_citation where user_id = ?
#EOM
    #$sql->execute($userId);
#
    #while (my ($v1, $v2, $v3) = $sql->fetchrow)
    #{
        ####### we have both case and ticket numbers.  basically, ticket numbers are citation numbers
        ####### so we can technically be interchangable.  For field purposes, stick to CASE_NUMBER
        #if ($v1 eq 'TICKET_NUMBER' || $v1 eq 'CASE_NUMBER')
        #{
            #$v1 = 'CITATION_NUMBER';
        #}
	#if ($v1 eq 'COURT_DATE')
        #{
            #$v1 = 'DUE_DATE';
        #}

        #$retval->{CITATION}->{$v1} = $v2;
    #}
    ##### get user Upsell Data 
    my $upsellEmail = $self->{PRODUCT_CON}->selectrow_array("select count(user_id) from user_custom_payment where user_id = ? and payment_service_id = ? and payment_date is not null",{},$userId, $self->{SETTINGS}{UPSELLTYPES}{EMAIL});
    my $upsellMail = $self->{PRODUCT_CON}->selectrow_array("select count(user_id) from user_custom_payment where user_id = ? and payment_service_id = ? and payment_date is not null",{},$userId, $self->{SETTINGS}{UPSELLTYPES}{MAIL});
    $$retval{UPSELLEMAIL}=($upsellEmail)?1:0;
    $$retval{UPSELLMAIL}=($upsellMail)?1:0;
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
        my $sth =  $self->{PRODUCT_CON}->prepare('update user_info set print_date = sysdate(), issue_date = sysdate(), certificate_number = ? where user_id = ?');        
	$sth->execute($certNumber, $userId);
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

    #if(!defined $delId || ($delId != 5 && $delId != 4 && $delId != 6)){ $self->updateSTC($userId); }
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
	$sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where cs.state in ($states)");
        $sql->execute();
    }elsif(defined $display){
        $sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where
                              cs.state = ? and cs.display >= ?");
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


sub getUserCitation{
    my $self=shift;
    my($userId, $param) = @_;
    if(defined $param){
                return  $self->{PRODUCT_CON}->selectrow_array('SELECT sf_decrypt(VALUE) as VALUE FROM user_citation WHERE USER_ID = ? AND PARAM = ?', {}, $userId, $param);
    } else {
                my $sth =  $self->{PRODUCT_CON}->prepare('SELECT PARAM, sf_decrypt(VALUE) as VALUE FROM user_citation WHERE USER_ID = ?');
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
    if (exists $NO_PRINT_AARP_COURSE->{$courseId})
    {
        return 0;
    }
    return 1;
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

sub getUserCertDuplicateData
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
        my $userContact = $self->getUserContact($userId);
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
        $sth = $self->{PRODUCT_CON}->prepare("select param, sf_decrypt(value) as value from user_cert_duplicate_data where duplicate_id = ?");
        $sth->execute($duplicateId);

        while (my ($v1, $v2) = $sth->fetchrow)
        {
            $retval->{DATA}->{$v1} = uc($v2);
            if ($v1 eq 'REGULATOR_ID')
            {
                    $retval->{DATA}->{REGULATOR_DEF} = ''; #$self->getRegulatorDef($v2);
            }
            if($v1 eq 'DELIVERY_ID' || $v1 eq 'SHIPPING_ID'){
                $retval->{$v1}=$v2;
            }
	    if($v1 eq 'DATE_OF_BIRTH') {
		my @dob = split(/\-/, $v2);
		$retval->{DATA}->{DATE_OF_BIRTH}="$dob[1]/$dob[0]/$dob[2]";
	    }
        }
        $retval->{DATA}->{CERTIFICATE_NUMBER} = $retval->{CERTIFICATE_REPLACED};
        if($retval->{DATA}->{LAST_DUPLICATE_ID}){
                my $lastDuplicateId=$retval->{DATA}->{LAST_DUPLICATE_ID};
                $duplicateId=$lastDuplicateId;
                while($lastDuplicateId){
                        $lastDuplicateId=$self->{PRODUCT_CON}->selectrow_array("select  sf_decrypt(value) as value from user_cert_duplicate_data where duplicate_id = ? and param = ?",{},$duplicateId,'LAST_DUPLICATE_ID');
                        if($lastDuplicateId){
                                $duplicateId=$lastDuplicateId;
                        }
                }
                $sth = $self->{PRODUCT_CON}->prepare("select param, sf_decrypt(value) as value from user_cert_duplicate_data where duplicate_id = ?");
                $sth->execute($duplicateId);

                while (my ($v1, $v2) = $sth->fetchrow)
                {
                    unless ($v1 eq 'DUPLICATE_ID' || $v1 eq 'SHIPPING_ID' || $v1 eq 'DELIVERY_ID')
                    {
                        $retval->{DATA}->{$v1} = uc($v2);
                            if ($v1 eq 'REGULATOR_ID')
                           {
                                $retval->{DATA}->{REGULATOR_DEF}  = ''; #$self->getRegulatorDef($v2);
                           }
                    }
                }

       }

    }
    $retval->{REGULATOR_ID} = $userInfo->{REGULATOR_ID};
    $retval->{REGULATOR_DEF} = ''; #$self->getRegulatorDef($userInfo->{REGULATOR_ID});

    ####### now, one last set of checks.  let's check the table user_cert_duplicate table to see if this user
    ####### has requested anything before.  if he has, make sure all of the data he's submitted previously
    ####### is in the record so we're sure we're not pulling from user_info
    my $oldDupId = $self->{PRODUCT_CON}->selectrow_array('select max(duplicate_id) from user_cert_duplicate where print_date is not null and user_id = ? and duplicate_id < ?',{},$userId, $duplicateId);

    if ($oldDupId)
    {
        ##### ok, old data exists for him.  Get all of it from the duplicate table and place it in the return hash
        $sth = $self->{PRODUCT_CON}->prepare("select param, sf_decrypt(value) as value from user_cert_duplicate_data where duplicate_id = ?");
        $sth->execute($oldDupId);

        while (my ($v1, $v2) = $sth->fetchrow)
        {

            unless ($v1 eq 'DUPLICATE_ID' || $v1 eq 'SHIPPING_ID' || $v1 eq 'DELIVERY_ID')
            {
                $retval->{$v1} = uc($v2);
                if ($v1 eq 'REGULATOR_ID')
                {
                        $retval->{REGULATOR_DEF} = ''; #$self->getRegulatorDef($v2);
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

sub getUserInfo{
    my $self=shift;
    my($userId) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare('SELECT USER_ID,sf_decrypt(DRIVERS_LICENSE) as DRIVERS_LICENSE,COURSE_ID,COMPLETION_DATE,PRINT_DATE,CERTIFICATE_NUMBER from user_info ui where ui.user_id = ?');
    $sth->execute($userId);
    my $tmpHash = $sth->fetchrow_hashref;
    $sth->finish;
    return $tmpHash;
}

sub getUserContact
{
    my $self        = shift;
    my ($userId)    = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
SELECT USER_ID,PHONE,EMAIL,sf_decrypt(ADDRESS1) as ADDRESS1,sf_decrypt(ADDRESS2) as ADDRESS2,sf_decrypt(CITY) as CITY,sf_decrypt(STATE) as STATE,sf_decrypt(ZIP) as ZIP,sf_decrypt(FIRST_NAME) as FIRST_NAME,sf_decrypt(LAST_NAME) as LAST_NAME,SEX,DATE_FORMAT(sf_decrypt(DATE_OF_BIRTH),'%m/%d/%Y') AS DATE_OF_BIRTH FROM user_info WHERE USER_ID = ?
EOM

    $sql->execute($userId);
    my $retval = $sql->fetchrow_hashref;
    $sql->finish;

    return $retval;
}


1;
