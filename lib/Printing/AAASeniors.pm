#!/usr/bin/perl -w 

package Printing::AAASeniors;

use lib qw(/ids/tools/PRINTING/lib);
use Printing;
use MysqlDB;
use vars qw(@ISA);
@ISA = qw (Printing MysqlDB);

use strict;
use printerSite;
use Data::Dumper;

my $VERSION = 0.5;

my $NO_PRINT_AAA_SENIORS_COURSE = { map { $_ => 1 } qw(5002) };
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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'AAA_SENIORS';
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

   # $self->constructor;
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
        ##### let's get the courses which will not print from this job
        ##### they will consist of:
        ##### now, generate the SQL statement
    	my $sqlStmt     = <<"EOM";
select ui.user_id, course_id, delivery_id, drivers_license from user_info ui left outer join user_delivery ud on ui.user_id=ud.user_id, user_course_payment ucp,user_cert_verification uc where ui.user_id = ucp.user_id and ui.course_id not in ($noCourseList) and ui.user_id = uc.user_id and ui.completion_date is not null and ui.print_date is null and ucp.payment_date is not null and ui.user_id not in (select user_id from user_lockout) [CONSTRAINT]

EOM
        $sqlStmt =~ s/\[CONSTRAINT\]/$constraint/;
    	my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    	$sql->execute;
        while (my ($v1, $v2, $v3, $v4) = $sql->fetchrow)
        {
            $retval->{$v1}->{USER_ID}           = $v1;
            $retval->{$v1}->{COURSEID}          = $v2;
            $retval->{$v1}->{DELIVERYID}        = ($v3)?$v3:1;
            $retval->{$v1}->{DRIVERS_LICENSE}  	= $v4;
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
    	my ($userId, $duplicate,$permitExam) = @_;
    	my $cId = $self->_getUserCourseId($userId);
	my $c = $self->{PRODUCT_CON}->selectrow_array('select certificate_number from user_info where user_id = ?', {},$userId);
	if (!$self->isPrintableCourse($cId)) {
		###### We're going to assign it a certificate number later as needed because each
		###### CA cert has to be hand fed into the printer and hand assigned a cert number
		return "[TO BE ASSIGNED]";
	}
	return ($cId . ':' . $userId);
	exit;

	if($cId eq  '10006')
	{
        #### this is a florida course, we need to use their webservice to get a certificate number
        #### All of this is done from the FloridaTeenCerts object
	
        #### Before we do any new declarations to get a certificate number, let's make sure the user
        #### doesn't already have a certificate associated to him.  If he does, there is no reason
        #### to query Florida and get a new one. 
    		if ($c)
		{
            ##### just return the user's current certificate
		    return $c;
		}
       
        #### ASSERT:  The user does not have a certificate.  We will have to get one for him/her 
        #### call the florida certs object and go from there
	        use FloridaTeenCerts;
        	my $flaCert = FloridaTeenCerts->new;
                my $userData=$self->getUserData($userId);
                $userData->{CITATION}=$self->getUserCitation($userId);
		$userData->{COMPLETION_DATE}=$self->getCompletionDate($userId);
	        my $certNumber = $flaCert->getCertificateNumber($userId,$userData);
		if ($certNumber)
		{
			$self->updateCertsStock($self->{SETTINGS}->{CERT_ORDERS_MAP}{'FL_TEEN_TLSAE'});
		}
		return $certNumber;	
   	}
        elsif ($cId == 5001 || $cId == 5002 || $cId == 5003)
    	{
        ###### We're going to assign it a certificate number later as needed because each
        ###### CA cert has to be hand fed into the printer and hand assigned a cert number
        return "[TBA CA]";
    	}

	if ($cId == 11003)

	{

	return "[TBA GA]";

	}
	if ($cId == 44003)
	{
		my $loginDate = $self->{PRODUCT_CON}->selectrow_array('select login_date from user_info where user_id = ?', {},$userId);	
		if($loginDate){
           		$loginDate =~ s/(\-|\ |\:)//g;
	           	if($loginDate<20121001000000){
				return ($cId . ':' . $userId);
			}
           	}

		my ($permitUser,$printDate) = $self->{PRODUCT_CON}->selectrow_array('select user_id,print_date from user_permit_certificate where user_id = ?', {},$userId);	
		if($permitUser){
			if(!$printDate && !$permitExam){
				return undef;
			}else{
				my $dupUser=$self->{PRODUCT_CON}->selectrow_array('select certificate_number from user_cert_duplicate where user_id=? and print_date is not null order by duplicate_id desc limit 0,1',{},$userId);		
				if($dupUser){
					$c=$dupUser;
					return $c;
				}
    				if ($c && !$duplicate)
				{
				    return $c;
				}
			        if (my $courseAlias = $self->{SETTINGS}->getCertPoolCourseForTeen($cId))
        			{
			        ###### this certificate must be retrieved from the certificate pool.  
                			my $c = $self->{PRODUCT_CON}->selectrow_array('select min(certificate_number) from certificate where course_id = ?',
                                                {},$courseAlias);

			                ##### we got a certificate number back from the table, but now can we legally delete this from the table?
			                ##### if we can delete the certificate number from the table, then everything is great and we can return the 
			                ##### certificate number
			                if(defined $c && length $c)
                			{
			                    	my $status = $self->{PRODUCT_CON}->do('delete from certificate where certificate_number = ? and course_id = ?', {},$c, $courseAlias);

                    				if(defined $status && $status == 1){
				                        if (exists $self->{SETTINGS}->{ORDERING_COURSE_ITEM_MAPS}{TX_TEEN}{$cId})
                		        		{
		                		                $self->updateCertsStock($self->{SETTINGS}->{CERT_ORDERS_MAP}{'TX_TEEN'});
                        				}
				                        return $c;
                    				}
                			}else{
						return undef;
					}
				}else{
					return undef;
				}

			}
		}else{
    			if ($c)
			{
			    return $c;
			}
		}
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
select  USER_ID,PHONE,ADDRESS_1,ADDRESS_2,CITY,STATE,ZIP,FIRST_NAME,LAST_NAME,SEX,date_format(DATE_OF_BIRTH,'%m/%d/%Y') as DATE_OF_BIRTH,REGISTRATION_DATE from user_contact where user_id = ?
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
		SELECT UI.USER_ID, UI.LOGIN AS EMAIL, UI.DRIVERS_LICENSE, UI.COURSE_ID,
                date_format(UI.COMPLETION_DATE,'%m/%d/%Y') AS COMPLETION_DATE,date_format(UI.COMPLETION_DATE,'%Y%m%d') AS COMPLETION_DATE_FORMAT_YMD,date_format(UC.REGISTRATION_DATE,'%Y%m%d') AS REGISTRATION_DATE_FORMAT, 
                date_format(UI.PRINT_DATE,'%m/%d/%Y') AS PRINT_DATE, UI.CERTIFICATE_NUMBER, UI.LOGIN_DATE,
                UPPER(UC.FIRST_NAME) as FIRST_NAME, UPPER(UC.LAST_NAME) as LAST_NAME, UC.ADDRESS_1, UC.ADDRESS_2, 
		UC.CITY, UC.STATE, UC.ZIP, UC.SEX,
                UD.DELIVERY_ID,C.STATE AS COURSE_STATE,C.SHORT_DESC,C.COURSE_LENGTH,D.DEFINITION AS DELIVERY_DEF,
                date_format(UC.DATE_OF_BIRTH,'%m/%d/%Y') AS DATE_OF_BIRTH,UC.PHONE,
		date_format(UC.REGISTRATION_DATE,'%m/%d/%Y') as REGISTRATION_DATE
                FROM
                ((((user_info UI left outer join  user_contact UC  on UI.USER_ID=UC.USER_ID)  left outer join user_delivery UD on UI.USER_ID=UD.USER_ID) left outer join course C on UI.COURSE_ID=C.COURSE_ID) left outer join delivery D on  UD.DELIVERY_ID=D.DELIVERY_ID)  WHERE UI.USER_ID = ? 
EOM
    
    $sql->execute($userId);
    $retval=$sql->fetchrow_hashref;

    ##### get the final score
    my $finalScore              = $self->{PRODUCT_CON}->selectrow_array('select max(score) from user_final_exam where user_id = ?', {},$userId);
    $retval->{FINAL_SCORE}      = $finalScore;

    ##### getCourse Aggregate Desc
    $retval->{COURSE_AGGREGATE_DESC} = $self->{PRODUCT_CON}->selectrow_array('select COURSE_AGGREGATE_DESCRIPTION from course_aggregate_desc cad,course c where cad.course_aggregate_id =c.course_aggregate_id and course_id=?',{},$retval->{COURSE_ID});
    $sql = $self->{PRODUCT_CON}->prepare(<<"EOM");
select param, value from user_cookie where user_id = ?
EOM
    $sql->execute($userId);

    ##Get Course State, for WA, pass the STATE_LICENSE No: 147
    my $courseState =  $self->{PRODUCT_CON}->selectrow_array('select c.state from course c, user_info ui where ui.course_id = c.course_id and ui.user_id = ?', {}, $userId);
    if($courseState && $courseState eq 'WA') {
	$retval->{STATE_LICENSE} = '147';
    }
	
    while (my ($v1, $v2) = $sql->fetchrow)
    {
        ###### we have both case and ticket numbers.  basically, ticket numbers are citation numbers
        ###### so we can technically be interchangable.  For field purposes, stick to CASE_NUMBER
        if ($v1 eq 'CONTROLNUMBER')
        {
		$retval->{CONTROLNUMBER}  = $v2;
        }
        if ($v1 eq 'LEARNERSPERMIT')
        {
		$retval->{LEARNERSPERMIT}  = $v2;
        }
        if ($v1 eq 'TO_BE_CHARGE_INSTALLMENT_AMOUNT')
        {
		$retval->{TO_BE_CHARGE_INSTALLMENT_AMOUNT}  = $v2;
	}
    }
    ##### get user Upsell Data 
    my $upsellDownload = $self->{PRODUCT_CON}->selectrow_array("select count(user_id) from user_custom_payment where user_id = ? and payment_service_id = ? and payment_date is not null",{},$userId, $self->{SETTINGS}{UPSELLTYPES}{DOWNLOAD});
    my $upsellEmail = $self->{PRODUCT_CON}->selectrow_array("select count(user_id) from user_custom_payment where user_id = ? and payment_service_id = ? and payment_date is not null",{},$userId, $self->{SETTINGS}{UPSELLTYPES}{EMAIL});
    my $upsellMail = $self->{PRODUCT_CON}->selectrow_array("select count(user_id) from user_custom_payment where user_id = ? and payment_service_id = ? and payment_date is not null",{},$userId, $self->{SETTINGS}{UPSELLTYPES}{MAIL});
    my $coupon = $self->{PRODUCT_CON}->selectrow_array("select coupon from user_course_pricing where user_id = ?",{},$userId);
    $$retval{UPSELLDOWNLOAD}=($upsellDownload)?1:0;
    $$retval{UPSELLEMAIL}=($upsellEmail)?1:0;
    $$retval{UPSELLMAIL}=($upsellMail)?1:0;
    if($$retval{COMPLETION_DATE_FORMAT_YMD} && $$retval{COMPLETION_DATE_FORMAT_YMD}>='20131002'){
    	if($retval->{COURSE_STATE} && $retval->{COURSE_STATE} eq 'PA'){
		my $allAffiliateId=$self->{SETTINGS}->{TEEN_PA_COURSE_PRINT_AFFILIATE_EXCLUDE};
		my @allCouponsArr;
		if($coupon){
			if($allAffiliateId){	
    				my $sql1         = $self->{PRODUCT_CON}->prepare(<<"EOM");
SELECT COUPON_CODE FROM affiliate_coupon WHERE AFFILIATE_ID in ($allAffiliateId) 		
EOM
		    		$sql1->execute();
				my $allCoupons='';
				while(my ($key) = $sql1->fetchrow){
					push @allCouponsArr, "'".$key."'";
				}
				if(@allCouponsArr){
					$allCoupons=join(',',@allCouponsArr) ;
					my $couponExists=$self->{PRODUCT_CON}->selectrow_array("select count(1) from user_course_pricing where user_id=? and coupon in ($allCoupons)",{},$userId);
					if(!$couponExists || $couponExists eq  '0'){
						$couponExists=$self->{PRODUCT_CON}->selectrow_array("select count(1) from user_coupons  where user_id=? and coupon in ($allCoupons)",{},$userId);
						if(!$couponExists || $couponExists eq  '0'){
							$retval->{PA_CERT_CAN_PRINT}=1;
						}
					}
				}
			}
		}else{
			$retval->{PA_CERT_CAN_PRINT}=1;
		}		
    	}
    }
	##CT Mature, if the user is CT user and registered with AAA Southern New England club code coupon, need to print different certificate
	if($courseState && ($courseState eq 'CT' || $courseState eq 'VA') ) {
		my $couponCode = $self->{PRODUCT_CON}->selectrow_array("select coupon from user_course_pricing where user_id = ?", {}, $userId);
		##Check whether the coupon for AAA Southern New England or not
		if($couponCode) {
			my $aaaId = $self->{PRODUCT_CON}->selectrow_array("select ad.aaa_id from aaa_division ad, aaa_coupon_code ac where ad.aaa_division_id = ac.aaa_division_id and ac.coupon_code=?", {}, $couponCode);
			if($aaaId && $aaaId == 42) {
				##Club 240 certificates will use “Fran Mayko” signature AAA to provide electronic signature).	
				$retval->{CT_240_CLUB} = 1;
			}
			##For Mid-Atlantic(212)
			if($aaaId && $aaaId == 1 && $courseState eq 'VA') {
				$retval->{VA_MIDATLANTIC_CLUB} = 1;
				$retval->{CLINIC_CODE} = 'M5004';
			}
			##For VA Tidewater(258), the club id at db must be 43
			if($aaaId && $aaaId == 43 && $courseState eq 'VA') {
				$retval->{VA_TIDEWATER_CLUB} = 1;
				$retval->{CLINIC_CODE} = 'M5003';
			}
			if($courseState eq 'VA' && (!$aaaId || ( $aaaId && $aaaId ne '43') ) ) {
				##User registered with SYCS/CRM, for VA, other than AAA Tidewater Club
				##By Default, the user is: Mid-Atlantic(212)
				$retval->{VA_MIDATLANTIC_CLUB} = 1;
				$retval->{CLINIC_CODE} = 'M5004';
			}
		} elsif($courseState eq 'VA' && !$couponCode) {
			##VA User, no coupon, the user is: Mid-Atlantic(212)
			$retval->{VA_MIDATLANTIC_CLUB} = 1;
			$retval->{CLINIC_CODE} = 'M5004';
		}
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

=head2 isPrintableCourse

=cut

sub isPrintableCourse
{
    ### ..slurp the class
    my $self    = shift;
    my ($courseId) = @_;
    if (exists $NO_PRINT_AAA_SENIORS_COURSE->{$courseId})
    {
        return 0;
    }
    return 1;
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


####### define some functions that should not be accessible by anyone.  These are 
####### private functions only accessable by the class.  There will be no perldocs 
####### for these functions
sub _getUserCourseId
{
    my $self = shift;
    my ($userId) = @_;

    return $self->{PRODUCT_CON}->selectrow_array("select course_id from user_info where user_id = ?",{}, $userId);
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
        $sql = $self->{PRODUCT_CON}->prepare("select cs.course_id, cs.short_desc, cs.display from course cs where cs.state = ? ");
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
        $sth = $self->{PRODUCT_CON}->prepare("select param, value from user_cert_duplicate_data where duplicate_id = ?");
        $sth->execute($duplicateId);

        while (my ($v1, $v2) = $sth->fetchrow)
        {
            $retval->{DATA}->{$v1} = uc($v2);
        }
    $retval->{DATA}->{CERTIFICATE_NUMBER} = $retval->{CERTIFICATE_REPLACED};
    }

    ####### now, one last set of checks.  let's check the table user_cert_duplicate table to see if this user
    ####### has requested anything before.  if he has, make sure all of the data he's submitted previously
    ####### is in the record so we're sure we're not pulling from user_info
    my $oldDupId = $self->{PRODUCT_CON}->selectrow_array('select max(duplicate_id) from user_cert_duplicate where print_date is not null and user_id = ? and duplicate_id < ?',{},$userId, $duplicateId);

    if ($oldDupId)
    {
        ##### ok, old data exists for him.  Get all of it from the duplicate table and place it in the return hash
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

sub getUserInfo{
    my $self=shift;
    my($userId) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare("select  USER_ID,LOGIN AS EMAIL,LOGIN_DATE,COURSE_ID,TEST_INFO,date_format(COMPLETION_DATE,'%m/%d/%Y') as COMPLETION_DATE,date_format(PRINT_DATE,'%m/%d/%Y') as PRINT_DATE,PASSWORD,CERTIFICATE_NUMBER from user_info ui where ui.user_id = ?");
    $sth->execute($userId);
    my $tmpHash = $sth->fetchrow_hashref;
    $sth->finish;
    return $tmpHash;
}

sub getUserAffidavitData
{
    my $self        = shift;
    my ($userId, $retval)    = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
                SELECT UI.USER_ID, UI.LOGIN AS EMAIL, UI.COURSE_ID,
                date_format(UI.COMPLETION_DATE,'%m/%d/%Y') AS COMPLETION_DATE,
                date_format(UI.PRINT_DATE,'%m/%d/%Y') AS PRINT_DATE, UI.CERTIFICATE_NUMBER, UI.LOGIN_DATE,
                UC.FIRST_NAME, UC.LAST_NAME, UC.ADDRESS_1, UC.ADDRESS_2, UC.CITY, UC.STATE, UC.ZIP,
                date_format(UC.DATE_OF_BIRTH,'%b %d, %Y') AS DATE_OF_BIRTH,UC.PHONE,
		DATE_FORMAT(UC.REGISTRATION_DATE, '%b %d, %Y') AS REGISTRATION_DATE
                FROM user_info UI , user_contact UC where  UI.USER_ID=UC.USER_ID and  UI.USER_ID = ? 
EOM

    $sql->execute($userId);
    $retval=$sql->fetchrow_hashref;
    return $retval;
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

=head2 getCompleteUsers

=cut

sub getAffidavitUsers
{
        my $self    = shift;
        ##### let's get the courses which will not print from this job
        ##### they will consist of:
        ##### now, generate the SQL statement
        my $sqlStmt     = <<"EOM";
SELECT UI.USER_ID  FROM user_info UI, user_contact UC, user_course_payment UCP WHERE UI.USER_ID = UC.USER_ID AND UI.USER_ID=UCP.USER_ID  AND UCP.PAYMENT_DATE IS NOT NULL AND UI.COURSE_ID = 6001 AND UI.USER_ID  AND UI.USER_ID  NOT IN (select distinct ui.user_id from user_cookie uk, user_info ui where ui.user_id = uk.user_id and ui.course_id = 6001 and uk.param='CO_AFFIDAVIT_PRINTED') 

EOM
        my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
        $sql->execute;
	my $retval;
        while (my ($v1) = $sql->fetchrow)
        {
            $retval->{$v1}->{USER_ID}           = $v1;
            $retval->{$v1}->{COURSEID}          = 6001;
            $retval->{$v1}->{DELIVERYID}        = 1;
        }

        ####### return the users;
        return $retval;
}

=head2 getCompleteUsers

=cut

sub getPermitCertsUsers
{
        my $self    = shift;
        my $sqlStmt     = <<"EOM";
SELECT UI.USER_ID,UI.COURSE_ID,date_format(UPC.SECTION_COMPLETE_DATE,'%m/%d/%Y') as SECTION_COMPLETE_DATE  FROM user_info UI, user_course_payment UCP, user_permit_certificate UPC WHERE UI.USER_ID=UCP.USER_ID AND UI.USER_ID=UPC.USER_ID AND UCP.PAYMENT_DATE IS NOT NULL AND UPC.PRINT_DATE IS NULL 

EOM
        my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
        $sql->execute;
        my $retval;
        while (my ($v1,$v2,$v3) = $sql->fetchrow)
        {
            $retval->{$v1}->{USER_ID}           = $v1;
            $retval->{$v1}->{COURSE_ID}         = $v2;
            $retval->{$v1}->{SECTION_COMPLETE_DATE}         = $v3;
            $retval->{$v1}->{DELIVERY_ID}       = 1;
	    my $PERMIT_DELIVERY                   = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='iPERMIT_DELIVERY_ID'", {},$v1);
	    if ($PERMIT_DELIVERY)
	    {
            	$retval->{$v1}->{DELIVERY_ID}        = $PERMIT_DELIVERY;
	    }
	    my $SHIPPING_ID                         = $self->{PRODUCT_CON}->selectrow_array("select value from user_cookie where user_id = ? and param='iPERMIT_SHIPPING_ID'", {},$v1);
	    if ($SHIPPING_ID)
	    {
            	$retval->{$v1}->{SHIPPING_ID}        = $SHIPPING_ID;
	    }
        }
        return $retval;
}


sub updateShippingAddress {
    my $self = shift;
    my ($SHIPPING_ID,$NAME,$ADDRESS,$ADDRESS_2,$CITY,$STATE,$ZIP,$PHONE,$DESCRIPTION,$ATTENTION,$ADDITIONAL_NOTES,$USER_ID,$DELIVERY_ID,$SIGNATURE,$PRINT_CATEGORY,$OFFICEID,$TYPE) = @_;
    my $COUNT = 0;
    my $NEWsHIPPING_ID;
    if(!$DELIVERY_ID){$DELIVERY_ID=0;}
    if(!$SIGNATURE){$SIGNATURE=1;}
    if(!$PRINT_CATEGORY){$PRINT_CATEGORY=1;}
    if(!$OFFICEID){$OFFICEID=1;}
    $TYPE=0;
         $COUNT=$self->{PRODUCT_CON}->selectrow_array("SELECT COUNT(*) FROM shipping_address WHERE SHIPPING_ID = ?", {}, $SHIPPING_ID);
         if($COUNT == 0 || $SHIPPING_ID == 0 || !$SHIPPING_ID){
         $self->{PRODUCT_CON}->do('UPDATE shippingid_seq SET id=LAST_INSERT_ID(id+1)');
         $NEWsHIPPING_ID=$self->{PRODUCT_CON}->selectrow_array("select LAST_INSERT_ID()");

                if($DELIVERY_ID == 0 || !$DELIVERY_ID){
                   $DELIVERY_ID = 7;
                }

                $self->{PRODUCT_CON}->do("INSERT INTO shipping_address (SHIPPING_ID, NAME, ADDRESS, ADDRESS_2, CITY, STATE, ZIP, PHONE, DESCRIPTION, ATTENTION, ADDITIONAL_NOTES, SIGNATURE, DELIVERY_ID, PRINT_CATEGORY_ID, TYPE)
                           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                           {}, $NEWsHIPPING_ID, $NAME, $ADDRESS, $ADDRESS_2, $CITY, $STATE, $ZIP, $PHONE, $DESCRIPTION, $ATTENTION, $ADDITIONAL_NOTES, $SIGNATURE, $DELIVERY_ID, $PRINT_CATEGORY,  $TYPE);

                if($USER_ID != 0){
			$SHIPPING_ID = $NEWsHIPPING_ID;
                         $COUNT=$self->{PRODUCT_CON}->selectrow_array("SELECT COUNT(*) FROM user_shipping WHERE USER_ID = ?", {}, $USER_ID);
                         if($COUNT == 0){
                                $self->{PRODUCT_CON}->do("INSERT INTO user_shipping SELECT ?, ? FROM DUAL", {}, $USER_ID, $SHIPPING_ID);
                         }else{
                                $self->{PRODUCT_CON}->do("UPDATE user_shipping SET SHIPPING_ID = ? WHERE USER_ID = ?", {}, $SHIPPING_ID, $USER_ID);
                         }
                }
                $SHIPPING_ID = $NEWsHIPPING_ID;
         }elsif($COUNT == 1){
                if($DELIVERY_ID = 0 || !$DELIVERY_ID){
                   $self->{PRODUCT_CON}->do("UPDATE shipping_address
                   SET NAME = ?, ADDRESS = ?, ADDRESS_2 = ?,CITY = ?,STATE = ?,
                           ZIP = ?, PHONE = ?, DESCRIPTION = ?, ATTENTION = ?,
                           ADDITIONAL_NOTES = ?, SIGNATURE = ? WHERE SHIPPING_ID = ?", {}, $NAME, $ADDRESS, $ADDRESS_2, $CITY, $STATE, $ZIP, $PHONE, $DESCRIPTION, $ATTENTION, $ADDITIONAL_NOTES, $SIGNATURE, $SHIPPING_ID);
                }else{
                   $self->{PRODUCT_CON}->do("UPDATE shipping_address
                   SET NAME = ?, ADDRESS = ?, ADDRESS_2 = ?,CITY = ?,STATE = ?,
                           ZIP = ?, PHONE = ?, DESCRIPTION = ?,ATTENTION = ?,
                           ADDITIONAL_NOTES = ?,SIGNATURE = ?,DELIVERY_ID = ? WHERE SHIPPING_ID = ?",
                           {}, $NAME, $ADDRESS, $ADDRESS_2, $CITY, $STATE, $ZIP, $PHONE, $DESCRIPTION, $ATTENTION, $ADDITIONAL_NOTES, $SIGNATURE, $DELIVERY_ID, $SHIPPING_ID)
               }
         }
    return $SHIPPING_ID;
}

sub getUserCitation{
    my $self=shift;
    my($userId, $param) = @_;
    if(defined $param){
                return  $self->{PRODUCT_CON}->selectrow_array('SELECT VALUE FROM user_citation WHERE USER_ID = ? AND PARAM = ?',
{}, $userId, $param);
    } else {
                my $sth =  $self->{PRODUCT_CON}->prepare('SELECT PARAM,VALUE FROM user_citation WHERE USER_ID = ?');
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
    ($tmp{DELIVERY_ID}, $tmp{DEFINITION}) =
        $self->{PRODUCT_CON}->selectrow_array('SELECT UD.DELIVERY_ID, D.DEFINITION   from user_delivery UD, delivery D
                               where UD.USER_ID = ?
                               and UD.DELIVERY_ID = D.DELIVERY_ID', {},
$userId);
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

sub getCompletionDate
{
        my $self=shift;
        my ($userId) = @_;
        return $self->{PRODUCT_CON}->selectrow_array("select date_format(completion_date, '%d-%b-%Y %H:%i') from user_info where user_id = ?", {}, $userId);
}

=head2 putUserPrintPermitCertRecord

=cut

sub putUserPrintPermitCertRecord {
    my $self    = shift;
    my ($userId,$certNumber) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare('update user_permit_certificate set print_date = sysdate() where user_id = ?');        $sth->execute($userId);
    my $sth2 =  $self->{PRODUCT_CON}->prepare('update user_info set certificate_number=? where user_id = ?');        $sth2->execute($certNumber,$userId);
}
sub getPermitCertRecord {
    my $self    = shift;
    my ($userId) = @_;
    return $self->{PRODUCT_CON}->selectrow_array("select date_format(print_date, '%d-%b-%Y'),date_format(section_complete_date, '%m/%d/%Y') from user_permit_certificate where user_id = ?", {}, $userId);
}
	
1;
