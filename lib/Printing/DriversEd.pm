#!/usr/bin/perl -w 

package Printing::DriversEd;

use lib qw(/ids/tools/PRINTING/lib);
use Printing;
use MysqlDB;
use vars qw(@ISA);
@ISA = qw (Printing MysqlDB);

use strict;
use printerSite;
use Socket 'inet_ntoa';
use Sys::Hostname 'hostname';

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use XML::Simple;


use Data::Dumper;

my $VERSION = 0.5;

my $NO_PRINT_DRIVERSED_COURSE = {  C0000013=>1, C0000034=>1, C0000055=>1, C0000023_NM => 1, C0000067 => 1};
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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'DRIVERSED';
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

=head2 getCompleteUsers

=cut

sub getCompleteUsers
{
	my $self    = shift;
        #my ($constraints, $enrollmentCert)    = @_;
        my ($constraints, $certType)    = @_;
	if(!$constraints->{DELIVERY_MODE} || ($constraints->{DELIVERY_MODE} && $constraints->{DELIVERY_MODE} ne 'DWNLD')) {
		$constraints->{DELIVERY_MODE_NOT} = 'DWNLD';
	}
    	my $retval;
	my $courseId = ($constraints->{COURSE}) ? $constraints->{COURSE} : 0;
        my $stcConstraint = 'not in';
        my @eList;
        #### define the different constraints that are available
    	my $constraintList        = { 
                            COURSE_ID       => ' ui.product_id in (\'[COURSE_ID]\') ',
                            DELIVERY_ID     => ' ud.delivery_id in ([DELIVERY_ID]) ',
                            COURSE_REASON     => ' ui.course_reason in (\'[COURSE_REASON]\') ',
                            DELIVERY_MODE     => ' ui.delivery_mode in (\'[DELIVERY_MODE]\') ',
                            DELIVERY_MODE_NOT     => ' ui.delivery_mode not in (\'[DELIVERY_MODE_NOT]\') ',
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
=pod
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
=cut
        my $noPrintCourse = $self->{SETTINGS}->{NO_PRINT_COURSE}->{$self->{PRODUCT}};

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
select ui.de_cert_data_id,ui.user_id, product_id as course_id, ui.delivery_id,ref_id from user_info ui  where ui.completion_date is not null and ui.print_date is null [CONSTRAINT]
EOM
	if($certType && $certType eq 'PARTCERT' && ($courseId && $courseId eq 'C0000067')) {
		##OH Scenario
    	$sqlStmt     = <<"EOM";
select ui.de_cert_data_id,ui.user_id, ui.product_id as course_id, ui.delivery_id, ui.ref_id from user_info ui, user_cookie uc where ui.de_cert_data_id = uc.de_cert_data_id and ui.completion_date is not null and ui.print_date is null and uc.param='OHOT_ENROLLMENT_CERT_NUMBER' and uc.value is not null [CONSTRAINT]
EOM
	}
	if($certType && $certType eq 'PARTCERT' && ($courseId && $courseId eq 'C0000071')) {
		##TX Teen32 Scenarip
		$sqlStmt     = <<"EOM";
select ui.de_cert_data_id,ui.user_id, ui.product_id as course_id, ui.delivery_id, ui.ref_id from user_info ui, user_cookie uc where ui.de_cert_data_id = uc.de_cert_data_id and ui.completion_date is not null and ui.print_date is null and uc.param='CERTIFICATETYPE' and uc.value = 'PARTCERT' [CONSTRAINT]
EOM
	}
	my $schoolId =  $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{PARAMETERS}->{DEFAULT}->{SCHOOLID};
	my $courseIds=0;
	if(!$constraints->{COURSE_ID}){
		$courseIds =  $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{PARAMETERS}->{DEFAULT}->{COURSEID};
	}else{
		$courseIds=$constraints->{COURSE_ID};
	}
	my $certificateReason = '';
	if($constraints->{COURSE_REASON}) {
		$certificateReason = $constraints->{COURSE_REASON};
		#print "\n Requested with Reason :: $certificateReason  \n";
	}
	my $downloadCertificate = '';
	if($constraints->{DELIVERY_MODE} && $constraints->{DELIVERY_MODE} eq 'DWNLD') {
		$downloadCertificate = $constraints->{DELIVERY_MODE};
	}
	if($certType && $certType eq 'PARTCERT') {
		##For Tx Teen32, the data already posted
	} else {
    		$self->getDataFromDriversEdSite($schoolId,$courseIds, '', $certificateReason, $downloadCertificate);
	}

        $sqlStmt =~ s/\[CONSTRAINT\]/$constraint/;
	#print STDERR "\n->>>>>\n$sqlStmt;\n<<<<<<<<\n";
    	my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    	$sql->execute;

        while (my ($v0,$v1, $v2, $v3, $v4) = $sql->fetchrow)
        {
            $retval->{$v0}->{USER_ID}           = $v1;
            $retval->{$v0}->{COURSEID}          = $v2;
            $retval->{$v0}->{DELIVERYID}        = ($v3)?$v3:1;
            $retval->{$v0}->{REF_ID}        	=  $v4;
        }

    	####### return the users;
    	return $retval;
}


##for NV DIP Reporting
sub getNVStdentsForReporting {
	my $self = shift;
	my ($lastMonth) = $self->{PRODUCT_CON}->selectrow_array("select date_format(date_sub(now(),interval 1 Month),'%Y-%m')");
	my $sql = $self->{PRODUCT_CON}->prepare("select de_cert_data_id as user_id, first_name, last_name, address_1, address_2, city, state, zip, drivers_license, date_format(date_of_birth,'%m/%d/%Y') as date_of_birth, date_format(completion_date,'%m/%d/%Y') as completion_date from user_info where product_id = 'C0000018' and print_date is not null and date_format(completion_date,'%Y-%m') = ?");
	my %tmpHash;
	my ($userId, $firstName, $lastName, $address1, $address2, $city, $state, $zip, $dl, $dob, $completionDate);
	$sql->execute($lastMonth); 
	while(($userId, $firstName, $lastName, $address1, $address2, $city, $state, $zip, $dl, $dob, $completionDate) = $sql->fetchrow) {
		$tmpHash{$userId}->{FIRST_NAME} = ucfirst lc $firstName;
		$tmpHash{$userId}->{LAST_NAME} = ucfirst lc $lastName;
		$tmpHash{$userId}->{ADDRESS1} = $address1;
		$tmpHash{$userId}->{ADDRESS2} = $address2;
		$tmpHash{$userId}->{CITY} = $city;
		$tmpHash{$userId}->{STATE} = $state;
		$tmpHash{$userId}->{ZIP} = $zip;
		$tmpHash{$userId}->{DL} = $dl;
		$tmpHash{$userId}->{DOB} = $dob;
		$tmpHash{$userId}->{COMPLETION_DATE} = $completionDate;
		$tmpHash{$userId}->{TODAY_DATE} =  $self->{PRODUCT_CON}->selectrow_array("select date_format(now(),'%m/%d/%Y')");
		$tmpHash{$userId}->{MONTH_YEAR} = $self->{PRODUCT_CON}->selectrow_array("select date_format(now(),'%Y-%m')");

        	my $sqlCookie = $self->{PRODUCT_CON}->prepare("select param, value from user_cookie where de_cert_data_id = ?");
	        $sqlCookie->execute($userId);
        	while (my ($v1, $v2) = $sqlCookie->fetchrow) {
                	$tmpHash{$userId}->{$v1} = $v2;
	        }
	}
	$sql->finish;
	return \%tmpHash;
}

sub getCookie {
	my $self=shift;
	my($userId, $arrRef) = @_;
	my %tmpHash;
	if(!$userId) {
		return \%tmpHash;
	}
	my $sth = $self->{PRODUCT_CON}->prepare('SELECT VALUE FROM user_cookie WHERE DE_CERT_DATA_ID = ? AND PARAM = ?');
	for my $param(@$arrRef) {
		$sth->execute($userId, $param);
		my @valArr = $sth->fetchrow_array;
		$tmpHash{$param} = $valArr[0];
		$sth->finish;
	}
	return \%tmpHash;
}


sub putCookie {
	my $self=shift;
	my($userId, $hashRef) = @_;
	$userId =(defined  $userId) ? $userId : '';
	if(!$userId){
		return 0;
	}
	my $sth1 = $self->{PRODUCT_CON}->prepare('UPDATE user_cookie SET VALUE = ? WHERE DE_CERT_DATA_ID = ? AND PARAM = ?');
	my $sth2 = $self->{PRODUCT_CON}->prepare('INSERT IGNORE INTO user_cookie (DE_CERT_DATA_ID, PARAM, VALUE) VALUES (?, ?, ?)');
	for my $param(keys %$hashRef) {
		my $paramValue = $$hashRef{$param};
		if($paramValue && $paramValue eq '0001-01-01T00:00:00') { next; }
		my $status = $sth1->execute($$hashRef{$param}, $userId, $param);
		if(!defined $status || $status != 1) {
			$sth2->execute($userId, $param, $$hashRef{$param});
		}
	}
	$sth1->finish;
	$sth2->finish;
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
    	my ($de_cert_data_id) = @_;
	my ($cId,$c) = $self->{PRODUCT_CON}->selectrow_array('select product_id,certificate_number from user_info where de_cert_data_id = ?', {},$de_cert_data_id);
	if (my $courseAlias = $self->{SETTINGS}->getCertPoolCourseForDriversEd($cId))
        {

                my $c = $self->{PRODUCT_CON}->selectrow_array('select min(certificate_number) from certificate where course_id = ?',
                                                {},$courseAlias);

                if(defined $c && length $c)
                {
                    my $status = $self->{PRODUCT_CON}->do('delete from certificate where certificate_number = ? and course_id = ?', {},$c, $courseAlias);

                    if(defined $status && $status == 1)
                    {
                        if (exists $self->{SETTINGS}->{ORDERING_COURSE_ITEM_MAPS}{DE_TX_ADULT}{$cId})
                        {
                                $self->updateCertsStock($self->{SETTINGS}->{CERT_ORDERS_MAP}{'DE_TX_ADULT'});
                        } 
                        if (exists $self->{SETTINGS}->{ORDERING_COURSE_ITEM_MAPS}{DE_TX_DIP}{$cId})
                        {
                                $self->updateCertsStock($self->{SETTINGS}->{CERT_ORDERS_MAP}{'DE_TX_DIP'});
                        } 
                        return $c;
                    }
                }



    	}
	elsif ($cId eq 'C0000013')
        {
        	return "[TBA CO]";
    	}
	elsif ($cId eq 'C0000034')
        {
        	return "[TBA CA]";
        } elsif($cId eq 'C0000057') { 
		##NV DE Teen Certificate Printing
		return "C0000057:$de_cert_data_id";
	}
	elsif ($cId eq 'C0000055')
        {
        	return "[TBA CA MATURE]";
	}
	elsif ($cId eq 'C0000023_NM')
        {
        	return "[TBA NM DIP]";
	}elsif($cId eq 'C0000067') {
		my $certCookie = $self->getCookie($de_cert_data_id,['OHOT_COMPLETION_CERT_NUMBER','OHOT_ENROLLMENT_CERT_NUMBER']);
		if($certCookie->{OHOT_COMPLETION_CERT_NUMBER}) {
			##The users record for Completion Certificate
			return $certCookie->{OHOT_COMPLETION_CERT_NUMBER};
		} elsif($certCookie->{OHOT_ENROLLMENT_CERT_NUMBER}) {
			##The users record for Enrollment Certificate
			return $certCookie->{OHOT_ENROLLMENT_CERT_NUMBER};
		} else {
			##The very exceptional scenario(should not occur at any given point of time)
			return "C0000067:$de_cert_data_id";
		}
	} else {
		my ($courseIdValue, $stateString) = split(/\_/, $cId);
		return "$courseIdValue:$de_cert_data_id";
	}
        return undef;


    ##### call the base class's certificate number.  No reason to redeclare the rest of this function	
}


=head2 getUserData

=cut

sub getUserData
{
    my $self        = shift;
    my ($de_cert_data_id, $retval)    = @_;
    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
		SELECT UI.USER_ID,UI.REF_ID,UI.SCHOOL_ID,  UI.PRODUCT_ID as COURSE_ID,COURSE_NAME as COURSE_AGGREGATE_DESC,
                date_format(UI.COMPLETION_DATE,'%m/%d/%Y') AS COMPLETION_DATE,
                date_format(UI.PRINT_DATE,'%m/%d/%Y') AS PRINT_DATE, UI.CERTIFICATE_NUMBER,UI.ORI_CONTROL_NO as REPLACED_CERTIFICATE_NUMBER,
                UPPER(UI.FIRST_NAME) as FIRST_NAME, UPPER(UI.LAST_NAME) as LAST_NAME, UI.MI, UI.ADDRESS_1, UI.ADDRESS_2, 
		UI.SEX, UI.CITY, UI.STATE, UI.ZIP, UI.DELIVERY_ID,COURSE_NAME as SHORT_DESC,  UI.DELIVERY_MODE AS DELIVERY_DEF,
                date_format(UI.DATE_OF_BIRTH,'%m/%d/%Y') AS DATE_OF_BIRTH,UI.PHONE, UI.IS_DUPLICATE, UI.AIRBILL_NUMBER, 
		date_format(UI.PRINT_DATE,'%Y-%m-%dT%H:%m:%s') AS PRINT_DATE_SQL, UI.DRIVERS_LICENSE, UI.CITATION_NUMBER, UI.REGULATOR_DEF, DATE_FORMAT(UI.DUE_DATE, '%m/%d/%Y') AS DUE_DATE, PRODUCT_ID,
		UI.DPS_AUTH_NUMBER as LEARNERSPERMIT, UI.DPS_CONTROL_NUMBER as CONTROLNUMBER, INSTRUCTOR_ON_CERTIFICATE, DE_CERT_DATA_ID, PRINTING_REQUEST_ID, ORIGINAL_PRINTING_REQUEST_ID,
		UI.DPS_AUTH_NUMBER as DPS_AUTH_NUMBER, UI.COURSE_REASON, DATE_FORMAT(NOW(),'%m/%d/%Y') AS TODAY
                FROM user_info UI WHERE UI.DE_CERT_DATA_ID =?
EOM
    
    $sql->execute($de_cert_data_id);
    $retval=$sql->fetchrow_hashref;
    my ($courseState, $shortDesc, $segment) = $self->{PRODUCT_CON}->selectrow_array("SELECT STATE, SHORT_DESC, SEGMENT FROM course WHERE COURSE_ID = ?",{},$retval->{COURSE_ID});
    $retval->{COURSE_STATE}=$courseState;
    $retval->{COURSE_SEGMENT}=$segment;
    $retval->{COURSE_AGGREGATE_DESC} = $shortDesc;
    $retval->{SHORT_DESC} = $shortDesc;
    if(($retval->{COURSE_STATE} && exists $self->{SETTINGS}->{DRIVERSED_BTW_OFFERED_STATES}->{$retval->{COURSE_STATE}})){
	my $needBTW = $self->{PRODUCT_CON}->selectrow_array("SELECT NEEDBTW FROM user_info WHERE DE_CERT_DATA_ID = ?", {}, $de_cert_data_id);
	if($needBTW) {	$retval->{NEEDBTW} = $needBTW;	}

	my $paidBTW = $self->{PRODUCT_CON}->selectrow_array("SELECT PAIDBTW FROM user_info WHERE DE_CERT_DATA_ID = ?", {}, $de_cert_data_id);
	if($paidBTW) {	$retval->{PAIDBTW} = $paidBTW;	}
    } 
	if($retval->{CITATION_NUMBER}) {
		$retval->{CITATION}->{CITATION_NUMBER} = $retval->{CITATION_NUMBER};
	}
	if($retval->{DUE_DATE}) {
		$retval->{CITATION}->{DUE_DATE} = $retval->{DUE_DATE};
	}

	if($retval->{COURSE_ID} eq 'C0000020' && $retval->{IS_DUPLICATE} && lc $retval->{IS_DUPLICATE} eq 'yes') {
		##Get the duplicate data has and construct the data hash, for now only for TX DIP
		my $duplicateDataId = $self->{PRODUCT_CON}->selectrow_array("SELECT DE_CERT_DATA_ID FROM user_info WHERE PRINTING_REQUEST_ID = ?", {}, $retval->{ORIGINAL_PRINTING_REQUEST_ID});
		if($duplicateDataId) {
			my ($certNumber, $fName, $lName, $dob) = $self->{PRODUCT_CON}->selectrow_array("SELECT CERTIFICATE_NUMBER, FIRST_NAME, LAST_NAME, DATE_FORMAT(DATE_OF_BIRTH,'%m/%d/%Y') AS DATE_OF_BIRTH FROM user_info WHERE DE_CERT_DATA_ID = ?", {}, $duplicateDataId);
			$retval->{DATA}->{CERTIFICATE_REPLACE} = $certNumber;
			$retval->{DATA}->{CERTIFICATE_NUMBER} = $certNumber;
			$retval->{DATA}->{FIRST_NAME} = $fName;
			$retval->{DATA}->{LAST_NAME} = $lName;
			$retval->{DATA}->{DATE_OF_BIRTH} = $dob;
		}
	}
	if($retval->{COURSE_ID} eq 'C0000020' && !$retval->{PRINT_DATE}) {
		$retval->{CERTIFICATE_NUMBER} = '';
	}
	my $sqlCookie = $self->{PRODUCT_CON}->prepare("select param, value from user_cookie where de_cert_data_id = ?");
	$sqlCookie->execute($de_cert_data_id);
	while (my ($v1, $v2) = $sqlCookie->fetchrow) {
		$retval->{$v1} = $v2;
		if($retval->{COURSE_ID} eq 'C0000071') {
			if($v1 eq 'INCARCOMPLETIONDATE') {
				my $incarCompletionDate =  $self->{PRODUCT_CON}->selectrow_array("SELECT DATE_FORMAT(?,'%m/%d/%Y') AS INCAR_COMPLETION_DATE", {}, $v2);
				$retval->{'INCAR_COMPLETION_DATE'} = $incarCompletionDate;
			}
		}
		if($v1 eq 'LABORATORYCOMPLETIONDATE') {
			my $laboratoryCompletionDate =  $self->{PRODUCT_CON}->selectrow_array("SELECT DATE_FORMAT(?,'%m/%d/%Y') AS LABORATORYCOMPLETIONDATE", {}, $v2);
			$retval->{'LABORATORYCOMPLETIONDATE'} = $laboratoryCompletionDate;
			$retval->{'LABORATORYCOMPLETIONDATEFORMATTED'} = $self->{PRODUCT_CON}->selectrow_array("SELECT DATE_FORMAT(?,'%b %d, %Y')", {}, $v2);
		}
	}
	
	if($retval->{COURSE_ID} eq 'C0000067') {
		my $certCookie = $self->getCookie($de_cert_data_id,['OHOT_COMPLETION_CERT_NUMBER','OHOT_ENROLLMENT_CERT_NUMBER']);
		if($certCookie->{OHOT_COMPLETION_CERT_NUMBER}) {
			$retval->{OH_COMPLETION_USERS} = 1;
		} elsif($certCookie->{OHOT_ENROLLMENT_CERT_NUMBER}) {
			$retval->{OH_ENROLLMENTS_USERS} = 1;
		} 
	}
	return $retval;
}


=head2 getCourseDescription

=cut
##### Get the all coursse info by course Id#####
sub getCourseDescription {
    my $self = shift;
    my ($courseId) = @_;
    my $sql;
    my %tmp;
    $sql = $self->{PRODUCT_CON}->prepare("select course_id, short_desc from course  where course_id =?");
    $sql->execute($courseId);
    while(my ($key, $def) = $sql->fetchrow)
    {
    	$tmp{$key}->{DEFINITION} = $def;
    }
    return \%tmp;
}

sub isPrintableCourse
{
    ### ..slurp the class
    my $self    = shift;
    my ($courseId) = @_;
    if (exists $NO_PRINT_DRIVERSED_COURSE->{$courseId})
    {
        return 0;
    }
    return 1;
}


sub putUserPrintRecord {
    my $self    = shift;
    my ($de_cert_data_id, $certNumber, $type) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare('update user_info set print_date = sysdate(), certificate_number = ? where  de_cert_data_id = ?');
    $sth->execute($certNumber, $de_cert_data_id);
}



sub putUserAirbillNumber {
    my $self    = shift;
    my ($de_cert_data_id, $airbillNumber) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare('update user_info set airbill_number = ? where de_cert_data_id= ? ');
    $sth->execute($airbillNumber, $de_cert_data_id);
}

sub putUserRecord {
	my $self = shift;
	my ($ref, $refCookie) = @_;
	my $count = $self->{PRODUCT_CON}->selectrow_array("select count(1) from user_info where printing_request_id = ? and print_date is null",{},$ref->{PRINTING_REQUEST_ID});
	if(!$count){
		my $cnt2 =$self->{PRODUCT_CON}->selectrow_array("select count(1) from user_info where printing_request_id = ? and print_date is not null and product_id in('C0000013','C0000034','C0000055','C0000023_NM') and certificate_number like '[TBA%'",{},$ref->{PRINTING_REQUEST_ID});
		if(!$cnt2){
			my $count2=$self->{PRODUCT_CON}->selectrow_array("select count(1) from user_info where printing_request_id = ? and print_date is not null and certificate_number_updated is null",{},$ref->{PRINTING_REQUEST_ID});
			if(!$count2){

				my $sth =  $self->{PRODUCT_CON}->prepare("insert into user_info set user_id =? , ref_id=? , school_id =?, product_id =? , course_name =?, first_name =?, last_name =?, mi = ?, date_of_birth =str_to_date(?,'%m/%d/%Y'), sex =? , completion_date =? , is_duplicate =? , ori_control_no =?, delivery_id=?, delivery_mode =?, address_1=?, address_2 =?, city =?, state=?, zip=?, phone=?, needbtw=?, paidbtw=?, drivers_license = ?, citation_number=?, regulator_def=?, due_date=str_to_date(?,'%m/%d/%Y'), dps_auth_number = ?, dps_control_number = ?,printing_request_id = ?, original_printing_request_id = ?, course_reason = ?, certificate_number = ?, email = ?, date_created=now()");
			$sth->execute($ref->{USER_ID}, $ref->{REF_ID}, $ref->{SCHOOL_ID}, $ref->{PRODUCT_ID}, $ref->{COURSE_NAME}, $ref->{FIRST_NAME}, $ref->{LAST_NAME},$ref->{MI}, $ref->{DOB}, $ref->{SEX}, $ref->{COMPLETION_DATE}, $ref->{IS_DUPLICATE}, $ref->{ORI_CONTROL_NO}, $ref->{DELIVERY_ID}, $ref->{DELIVERY_MODE}, $ref->{ADDRESS_1}, $ref->{ADDRESS_2}, $ref->{CITY}, $ref->{STATE}, $ref->{ZIP}, $ref->{PHONE}, $ref->{NEEDBTW}, $ref->{PAIDBTW}, $ref->{DRIVERS_LICENSE}, $ref->{CITATION_NUMBER}, $ref->{REGULATOR_DEF}, $ref->{DUE_DATE}, $ref->{DPS_AUTH_NUMBER}, $ref->{DPS_CONTROL_NUMBER}, $ref->{PRINTING_REQUEST_ID}, $ref->{ORIGINAL_PRINTING_REQUEST_ID},$ref->{COURSE_REASON}, $ref->{CERTIFICATE_NUMBER}, $ref->{EMAIL});

				my $printingRequestId = $self->{PRODUCT_CON}->selectrow_array("SELECT LAST_INSERT_ID()"); ##This will get the last record id inserted
				##Now, the additional data at the user_cookie table
				foreach(keys %$refCookie) {
					my $param = uc $_;
					my $value = $refCookie->{$param};
					if($value) {
						$self->putCookie($printingRequestId, {$param => $value});
					}
				}

			}else{
				#my $de_cert_data_id=$self->{PRODUCT_CON}->selectrow_array("select de_cert_data_id from user_info where user_id =? and ref_id =? and print_date is not null and certificate_number_updated is null and certificate_number not like '[TBA%'",{},$ref->{USER_ID}, $ref->{REF_ID});
				my $de_cert_data_id=$self->{PRODUCT_CON}->selectrow_array("select de_cert_data_id from user_info where printing_request_id = ? and print_date is not null and certificate_number_updated is null and certificate_number not like '[TBA%'",{},$ref->{PRINTING_REQUEST_ID});
				if($de_cert_data_id){
                        		my $retValue=$self->updateDriveredData($de_cert_data_id);
				}
			}
		}
	}
}

sub printFedexLabel
{
        my $self = shift;
        my ($de_cert_data_id, $priority, $printerKey,$webService,$file,$trackingNumber) = @_;
        my %tmpHash;
        ###### let's get user's shipping data
        $printerKey=($printerKey)?$printerKey:'CA';
        my $shippingData = $self->getUserData($de_cert_data_id);
        my $courseState=$shippingData->{COURSE_STATE};
        $shippingData->{DESCRIPTION} = "CERT FOR - $de_cert_data_id";
	$shippingData->{NAME} = "$shippingData->{FIRST_NAME} $shippingData->{LAST_NAME}";
	$shippingData->{ADDRESS}=$shippingData->{ADDRESS_1};
	$shippingData->{ADDRESS2}=$shippingData->{ADDRESS_2};
	$shippingData->{PHONE}=$shippingData->{PHONE};
	if($shippingData->{COURSE_ID} && $shippingData->{COURSE_ID} eq 'C0000071' && $shippingData->{COURSE_REASON} eq 'OTHERDS') {
		$shippingData->{NAME} = $shippingData->{DSPROVIDER};
		$shippingData->{ADDRESS}=$shippingData->{DSADDRESS};
		$shippingData->{CITY}=$shippingData->{DSCITY};
		$shippingData->{STATE}=$shippingData->{DSSTATE};
		$shippingData->{ZIP}=$shippingData->{DSZIPCODE};
	}
        ###### create the fedex object, sending in the printer key
	#if($shippingData->{COURSE_ID} && $shippingData->{COURSE_ID} eq 'C0000020') {
	#	$self->{PRODUCT} = 'DRIVERSEDTX';
	#} else {
		$self->{PRODUCT} = 'DRIVERSED';
	#}
        my $fedexObj = Fedex->new($self->{PRODUCT});
        $fedexObj->{PRINTERS}=$self->{PRINTERS};
	if($shippingData->{COURSE_ID} && $shippingData->{COURSE_ID} eq 'C0000020') {
		$courseState = 'TT';
	}
	if($shippingData->{COURSE_ID} && $shippingData->{COURSE_ID} eq 'C0000071') {
		$courseState = '32';
	}
        $fedexObj->{PRINTING_STATE}=$courseState;
        $fedexObj->{PRINTING_TYPE}='CERTFEDX';
        $fedexObj->{PRINTER_KEY}=$printerKey;

        my $reply= $fedexObj->printLabel( $shippingData, (($priority) ? $priority : 1 ),'','',$file,$trackingNumber);
        my $fedex = "\nUSERID : $shippingData->{USER_ID}\n";

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
        {
                        $fedex .= "\t$_ : $$reply{$_}\n";
                        if(!$trackingNumber){
                                $self->putUserAirbillNumber($de_cert_data_id, $$reply{$_});
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

sub printUSPSLabel
{
        my $self = shift;
        my ($de_cert_data_id, $priority, $printerKey,$webService,$file,$trackingNumber) = @_;
        my %tmpHash;
        ###### let's get user's shipping data
        $printerKey=($printerKey)?$printerKey:'CA';
        my $shippingData = $self->getUserData($de_cert_data_id);
	my $courseState=$shippingData->{COURSE_STATE};
        $shippingData->{DESCRIPTION} = "CERT FOR - $de_cert_data_id";
        $shippingData->{NAME} = "$shippingData->{FIRST_NAME} $shippingData->{LAST_NAME}";
        $shippingData->{ADDRESS}=$shippingData->{ADDRESS_1};
        $shippingData->{ADDRESS2}=$shippingData->{ADDRESS_2};
        $shippingData->{PHONE}=$shippingData->{PHONE};
        if($shippingData->{COURSE_ID} && $shippingData->{COURSE_ID} eq 'C0000071' && $shippingData->{COURSE_REASON} eq 'OTHERDS') {
                $shippingData->{NAME} = $shippingData->{DSPROVIDER};
                $shippingData->{ADDRESS}=$shippingData->{DSADDRESS};
                $shippingData->{CITY}=$shippingData->{DSCITY};
                $shippingData->{STATE}=$shippingData->{DSSTATE};
                $shippingData->{ZIP}=$shippingData->{DSZIPCODE};
        }
	#if($shippingData->{COURSE_ID} && $shippingData->{COURSE_ID} eq 'C0000020') {
	#	$self->{PRODUCT} = 'DRIVERSEDTX';
	#} else {
		$self->{PRODUCT} = 'DRIVERSED';
	#}

        ###### create the fedex object, sending in the printer key
        my $fedexObj = Fedex->new($self->{PRODUCT});
        $fedexObj->{PRINTERS}=$self->{PRINTERS};
	if($shippingData->{COURSE_ID} && $shippingData->{COURSE_ID} eq 'C0000020') {
		$courseState = 'TT';
	}
	if($shippingData->{COURSE_ID} && $shippingData->{COURSE_ID} eq 'C0000071') {
		$courseState = '32';
	}
        $fedexObj->{PRINTING_STATE}=$courseState;
        $fedexObj->{PRINTING_TYPE}='CERTFEDX';
        $fedexObj->{PRINTER_KEY}=$printerKey;

        my $reply= $fedexObj->printUSPSLabel( $shippingData, (($priority) ? $priority : 1 ),'','',$file,$trackingNumber);
        my $fedex = "\nUSERID : $de_cert_data_id\n";

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
        {
                        $fedex .= "\t$_ : $$reply{$_}\n";
                        if(!$trackingNumber){
				$self->putUserAirbillNumber($de_cert_data_id, $$reply{$_});
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

sub getPermitCertsUsers {
	my $self = shift;
	my ($approved, $courseId) = @_;
	my $schoolId = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{PARAMETERS}->{DEFAULT}->{SCHOOLID};
	if($courseId) {
		if($courseId eq 'C0000071') {
			$self->getDataFromDriversEdSite($schoolId, $courseId, 'CPCC');
		} elsif($courseId eq 'C0000067') {
			$self->getDataFromDriversEdSite($schoolId, $courseId, 'PARTCERT');
		}
	}
	#my $retVal;
	#return $retVal;
	my %hashProcessCourse;
	$hashProcessCourse{COURSE} = $courseId;
	#$self->getDataFromDriversEdSite($schoolId, $courseId,'PARTCERT');
	return $self->getCompleteUsers(\%hashProcessCourse, 'PARTCERT');
}


sub getAffidavitUsers
{
        my $self    = shift;
	my ($courseId, $courseReason) = @_;
	my $cookieParam = "";
	my $whereQuery = " AND UI.DELIVERY_MODE NOT IN ('DWNLD') ";
	if($courseId && $courseId eq 'C0000013') {
		$cookieParam = 'CO_ATTENDANCESHEET_PRINTED';
	}

	##For TX Teen32, only for Download returned students for Affilidavits
	if($courseId && $courseId eq 'C0000071') {
		$whereQuery = " AND UI.DELIVERY_MODE IN ('DWNLD') ";
		$cookieParam = "TXTEEN_STUDENTLOG_PRINTED";
		if($courseReason) {
			$whereQuery .= " AND UI.COURSE_REASON = '$courseReason' ";
		}
	}

        ##### let's get the courses which will not print from this job
        ##### they will consist of:
        ##### now, generate the SQL statement
	my $sqlStmt     = <<"EOM";
SELECT UI.DE_CERT_DATA_ID, UI.USER_ID, PRODUCT_ID AS COURSE_ID FROM user_info UI WHERE UI.COMPLETION_DATE IS NOT NULL AND UI.PRINT_DATE IS NOT NULL  AND UI.PRODUCT_ID = ? $whereQuery AND NOT EXISTS (SELECT DE_CERT_DATA_ID FROM user_cookie UC WHERE UC.DE_CERT_DATA_ID = UI.DE_CERT_DATA_ID AND UC.PARAM = ?)
EOM
        my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
        $sql->execute($courseId, $cookieParam);
        my $retval;
        while (my ($v0, $v1, $v2) = $sql->fetchrow)
        {
            $retval->{$v0}->{USER_ID}           = $v1;
            $retval->{$v0}->{COURSEID}          = $v2;
        }

        ####### return the users;
        return $retval;
}


sub getDataFromDriversEdSite
{
	my $self = shift;
	my ($schoolId, $courseId, $certType, $certificateReason, $deliveryMode) = @_;
	my $addr = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));
	my $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{BETA} ;
	my $postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{BETA} ;
	if($addr && exists $self->{SETTINGS}->{USPS_ALLOWED_IPADDRESS}->{$addr}){
		$host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{PROD} ;
		$postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD} ;
	}
		$host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{PROD} ;
		$postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD} ;
	my $hashField = {
                        'a:UserID'              =>'',
                        'a:RefID'               =>'',
                        'a:CourseName'          =>'',
                        'a:FirstName'           =>'',
                        'a:LastName'            =>'',
                        'a:MI'                  =>'',
                        'a:DOB'                 =>'',
                        'a:Gender'              =>'',
                        'a:CompletionDate'      =>'',
                        'a:isDuplicate'         =>'',
                        'a:OriControlNumber'    =>'',
                        'a:DeliveryMode'        =>'',
                        'a:DeliveryAddress1'    =>'',
                        'a:DeliveryAddress2'    =>'',
                        'a:DeliveryCity'        =>'',
                        'a:DeliveryState'       =>'',
                        'a:DeliveryZip'         =>'',
                        'a:DeliveryPhoneNumber'    =>'',
                        'a:NeedBTW'    =>'',
                        'a:PaidBTW'    =>'',
                        'a:Drvlicense'    =>'',
                        'a:CaseNumber'    =>'',
                        'a:Court'    =>'',
                        'a:DueDate'    =>'',
			'a:ControlNumber_OK'    =>'',
			'a:DPSAuthNum'    =>'',
			'a:RoadRulesScore'    =>'',
			'a:RoadSignsScore'    =>'',
			'a:SurveyAns1_TS_PendingDuringEnroll'    =>'',
			'a:SurveyAns2_TS_CourtDismissingTicket'    =>'',
			'a:SurveyAns3_TS_CompletedForCredit'    =>'',
			'a:SurveyAns4_TS_ViolationCount'    =>'',
			'a:SurveyAvailable'    =>'',
			'a:InCarHour_OK'    =>'',
			'a:InClassHour_OK'    =>'',
			'a:IsDPSTestSkipped'    =>'',
			'a:IsTXDPSTestCompleted'    =>'',
			'a:NumOfInstructions'    =>'',
			'a:ReprintReason'    =>'',
			'a:TXDPSTestCompletionDate'    =>'',
			'a:tothrs_OK'    =>'',
			'a:FinalScore'    =>'',
			'a:CertificatePrintingRequestID'    =>'',
			'a:prevCertificatePrintingRequestID'    =>'',
			'a:EnrollDate'    =>'',
			'a:TotalDuration'    =>'',
			'a:OHOT_CompletionCert_Nbr'    =>'',
			'a:OHOT_Enrcert_Nbr'    =>'',
			'a:OHOT_Enrcert_ReadyDate'    =>'',
			'a:CertificateType'    =>'',
			'a:HasTXDPSTest'    =>'',

			'a:DSProvider'   =>'',
			'a:DSAddress'   =>'',
			'a:DSCity'   =>'',
			'a:DSState'  =>'',
			'a:DSZipcode'  =>'',
			'a:DSPhone'  =>'',
			'a:ParentFormFilled'  =>'',
			'a:ParentAddressLine1'  =>'',
			'a:ParentAddressLine2'  =>'',
			'a:ParentAddressCity'  =>'',
			'a:ParentAddressState'  =>'',
			'a:ParentAddressPostcode'  =>'',
			'a:ParentName,'  =>'',
			'a:ParentEmail'  =>'',
			'a:ParentDL'  =>'',
			'a:ParentPhoneNumber'  =>'',
			'a:ParentDLState'  =>'',
			'a:LearnersPermitNumber'  =>'',
			'a:CPCCControlNumber'  =>'',
			'a:CPCCPrintingRequestID'  =>'',
             };

	my $defaultSchoolId = 'DRVEDCA';
	if($self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{PARAMETERS}->{COURSEID_SCHOOLS}->{$courseId}) {
		$defaultSchoolId = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{PARAMETERS}->{COURSEID_SCHOOLS}->{$courseId};
	}
	my ($cId, $stateId);
	my $originalCourseId = $courseId;
	if($courseId =~ /\_/ig) {
		($cId, $stateId) = split(/\_/, $courseId);
		if($cId) {
			$courseId = $cId;
		}
	}

	#my $certTypeXML = "";
	##if($courseId && $courseId eq 'C0000067') {
	#	if($certType) {
	#		$certTypeXML = "<ns1:certificateType>$certType</ns1:certificateType>";
	#	} else {
	#		$certTypeXML = "<ns1:certificateType></ns1:certificateType>";
	#	}
	#}

	my $reason = ""; ## To understand the reason here
	#$certType='';
	my $certificateType = '<ns1:certificateType>CERT</ns1:certificateType>';
	if($courseId && $courseId eq 'C0000071') {
		if($certType && $certType eq 'CPCC') {
			$reason = "<ns1:reason>CPC</ns1:schoolID>";
			$certificateType = '<ns1:certificateType>PARTCERT</ns1:certificateType>';
		} else {
			$certificateType = '<ns1:certificateType>CERT</ns1:certificateType>';
			if($certificateReason) {
				$certificateType .= "<ns1:reason>$certificateReason</ns1:reason>";
			}else {
				##No Reason Given, exi the user
				#print "\nInvalid Reason\nExiting...\n"; exit;
			}
		}
	} elsif($courseId && $courseId eq 'C0000067') {
		if($certType) {
			$certificateType = "<ns1:certificateType>$certType</ns1:certificateType>";
		} else {
			$certificateType = "<ns1:certificateType></ns1:certificateType>";
		}
	}

	if($courseId && $courseId eq 'BTWTMINI03' && $certificateReason && $certificateReason eq 'INSURANCE') {
		$certificateType .= "<ns1:reason>$certificateReason</ns1:reason>";
	}

	if($deliveryMode && $deliveryMode eq 'DWNLD') {
		$certificateType .= "<ns1:deliveryType>DWNLD</ns1:deliveryType>";
	}

	#print "\nCertificate REason : $certificateReason || certificateType: $certificateType | ->$certType<-  \n";
	my $objUserAgent = LWP::UserAgent->new;
	my $request = <<DATA;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://tempuri.org/"><SOAP-ENV:Body><ns1:GetNotPrintedCertificates><ns1:schoolID>$defaultSchoolId</ns1:schoolID><ns1:productID>$courseId</ns1:productID>$certificateType</ns1:GetNotPrintedCertificates></SOAP-ENV:Body></SOAP-ENV:Envelope>
DATA
	my $soapActionUrl = "http://tempuri.org/IWaitingToBePrinted/GetNotPrintedCertificates";
	if($courseId && ($courseId eq 'C0000087')) {
		##IL Adult reporining changes
		my $todayDate = $self->{PRODUCT_CON}->selectrow_array("select date_sub(now(), interval 1 day)");
		my ($date, $time) = split(/\s+/, $todayDate);
		my $stateDate = $date."T00:00:00";
		my $endDate = $date."T23:59:59";
		$request = <<DATA;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://tempuri.org/"><SOAP-ENV:Body><ns1:GetUserCompletionReport><ns1:schoolID>$defaultSchoolId</ns1:schoolID><ns1:productID>$courseId</ns1:productID><ns1:start>$stateDate</ns1:start><ns1:finish>$endDate</ns1:finish></ns1:GetUserCompletionReport></SOAP-ENV:Body></SOAP-ENV:Envelope>
DATA
		$soapActionUrl = "http://tempuri.org/IWaitingToBePrinted/GetUserCompletionReport";
	}

	#print STDERR "\n\n\nRequest\n-----------------\n\n\n$request\n\n\n\n";
	my $contentlength = length($request);
	my $objHeader = HTTP::Headers->new(
                                Host => $host,
                                Content_Type => 'text/xml',
                                Content_Length => $contentlength,
                                SOAPAction => $soapActionUrl,
                                );
	my $objRequest = HTTP::Request->new("POST",$postURL,$objHeader,$request);
        my $objResponse = $objUserAgent->request($objRequest);
	#print STDERR Dumper($objResponse);
        if (!$objResponse->is_error)
        {
                my $content = $objResponse->content;
		$self->dbPutXMLData($schoolId, $originalCourseId,$content);
                my $xml = new XML::Simple;
                my $responseData = $xml->XMLin($content);
		#print Dumper($responseData);
		if(exists $responseData->{'s:Body'}{GetNotPrintedCertificatesResponse}{GetNotPrintedCertificatesResult}{'a:CertificateData'}){
	                my $responseDataArr=$responseData->{'s:Body'}{GetNotPrintedCertificatesResponse}{GetNotPrintedCertificatesResult}{'a:CertificateData'};
			my @arrData;
			if(ref($responseDataArr) eq 'HASH'){
				push @arrData, $responseDataArr;
			}else{
        	        	@arrData=@$responseDataArr;
			}
	                my $noOfRecords= @arrData;
        	        for (my $i=0;$i<$noOfRecords;$i++){
                	        my $dataHash=$arrData[$i];
                        	foreach my $field(keys %$dataHash){
                                	my $fieldData=$dataHash->{$field};
	                                if(ref($fieldData) eq "HASH"){
        	                                $arrData[$i]->{$field}='';
                	                }
                        	}

				my $ref; 
				my $refCookie;
				$ref->{USER_ID}=$arrData[$i]->{'a:UserID'};
				$ref->{REF_ID}=$arrData[$i]->{'a:RefID'};
				$ref->{SCHOOL_ID}=$schoolId;
				$ref->{PRODUCT_ID}=$originalCourseId;
				$ref->{COURSE_NAME}=$arrData[$i]->{'a:CourseName'};
				$ref->{FIRST_NAME}=$arrData[$i]->{'a:FirstName'};
				$ref->{LAST_NAME}=$arrData[$i]->{'a:LastName'};
				$ref->{MI}=$arrData[$i]->{'a:MI'};
				$ref->{DOB}=$arrData[$i]->{'a:DOB'};
				$ref->{SEX}=$arrData[$i]->{'a:Gender'};
				$ref->{COMPLETION_DATE}=$arrData[$i]->{'a:CompletionDate'};
				$ref->{COMPLETION_DATE} =~ s/T/ /g;
				$ref->{IS_DUPLICATE}=$arrData[$i]->{'a:isDuplicate'};
				if($ref->{IS_DUPLICATE} eq 'true'){
					$ref->{IS_DUPLICATE}='yes';	
				}else{
					$ref->{IS_DUPLICATE}='no';	
				}
				$ref->{ORI_CONTROL_NO}=$arrData[$i]->{'a:OriControlNumber'};
				$ref->{DELIVERY_MODE}=$arrData[$i]->{'a:DeliveryMode'};
				my $deliveryMode = $ref->{DELIVERY_MODE};
				my $deliveryId =1;
				if($deliveryMode && exists $self->{SETTINGS}->{DRIVERSED_DELIVERY_METHOD}->{$deliveryMode}){
					$deliveryId = $self->{SETTINGS}->{DRIVERSED_DELIVERY_METHOD}->{$deliveryMode};
				}
				$ref->{DELIVERY_ID}=$deliveryId;
				$ref->{ADDRESS_1}=$arrData[$i]->{'a:DeliveryAddress1'};
				$ref->{ADDRESS_2}=$arrData[$i]->{'a:DeliveryAddress2'};
				$ref->{CITY}=$arrData[$i]->{'a:DeliveryCity'};
				$ref->{STATE}=$arrData[$i]->{'a:DeliveryState'};
				$ref->{ZIP}=$arrData[$i]->{'a:DeliveryZip'};
				$ref->{PHONE}=$arrData[$i]->{'a:DeliveryPhoneNumber'};
				$ref->{NEEDBTW}=$arrData[$i]->{'a:NeedBTW'};
				$ref->{PAIDBTW}=$arrData[$i]->{'a:PaidBTW'};
				$ref->{DRIVERS_LICENSE}=$arrData[$i]->{'a:Drvlicense'};
				$ref->{CITATION_NUMBER}=$arrData[$i]->{'a:CaseNumber'};
				$ref->{REGULATOR_DEF}=$arrData[$i]->{'a:Court'};
				$ref->{DUE_DATE}=$arrData[$i]->{'a:DueDate'};
				$ref->{DPS_AUTH_NUMBER}=$arrData[$i]->{'a:DPSAuthNum'};
				$ref->{DPS_CONTROL_NUMBER}=$arrData[$i]->{'a:ControlNumber_OK'};
				$ref->{PRINTING_REQUEST_ID}=$arrData[$i]->{'a:CertificatePrintingRequestID'};
				$ref->{ORIGINAL_PRINTING_REQUEST_ID}=$arrData[$i]->{'a:prevCertificatePrintingRequestID'};##the original id, to identify duplicates
				$ref->{COURSE_REASON}=$certificateReason; ##Certificate Reason - For TX Teen32 Uses only
				$ref->{CERTIFICATE_NUMBER}=$arrData[$i]->{'a:CPCCControlNumber'};
				$ref->{EMAIL}=$arrData[$i]->{'a:Email'};

				$refCookie->{ROADRULESSCORE} = $arrData[$i]->{'a:RoadRulesScore'};
				$refCookie->{ROADSIGNSSCORE} = $arrData[$i]->{'a:RoadSignsScore'};
				$refCookie->{SURVEYANS1_TS_PENDINGDURINGENROLL} = $arrData[$i]->{'a:SurveyAns1_TS_PendingDuringEnroll'};
				$refCookie->{SURVEYANS2_TS_COURTDISMISSINGTICKET} = $arrData[$i]->{'a:SurveyAns2_TS_CourtDismissingTicket'};
				$refCookie->{SURVEYANS3_TS_COMPLETEDFORCREDIT} = $arrData[$i]->{'a:SurveyAns3_TS_CompletedForCredit'};
				$refCookie->{SURVEYANS4_TS_VIOLATIONCOUNT} = $arrData[$i]->{'a:SurveyAns4_TS_ViolationCount'};
				$refCookie->{SURVEYAVAILABLE} = $arrData[$i]->{'a:SurveyAvailable'};
				$refCookie->{INCARHOUR_OK} = $arrData[$i]->{'a:InCarHour_OK'};
				$refCookie->{INCLASSHOUR_OK} = $arrData[$i]->{'a:InClassHour_OK'};
				$refCookie->{ISDPSTESTSKIPPED} = $arrData[$i]->{'a:IsDPSTestSkipped'};
				$refCookie->{ISTXDPSTESTCOMPLETED} = $arrData[$i]->{'a:IsTXDPSTestCompleted'};
				$refCookie->{NUMOFINSTRUCTIONS} = $arrData[$i]->{'a:NumOfInstructions'};
				$refCookie->{REPRINTREASON} = $arrData[$i]->{'a:ReprintReason'};
				$refCookie->{TXDPSTESTCOMPLETIONDATE} = $arrData[$i]->{'a:TXDPSTestCompletionDate'};
				$refCookie->{TOTHRS_OK} = $arrData[$i]->{'a:tothrs_OK'};
				$refCookie->{FINALSCORE} = $arrData[$i]->{'a:FinalScore'};
				$refCookie->{ENROLLDATE} = $arrData[$i]->{'a:EnrollDate'};
				$refCookie->{TOTALDURATION} = $arrData[$i]->{'a:TotalDuration'};
				$refCookie->{OHOT_COMPLETION_CERT_NUMBER} = $arrData[$i]->{'a:OHOT_CompletionCert_Nbr'};
				$refCookie->{OHOT_ENROLLMENT_CERT_NUMBER} = $arrData[$i]->{'a:OHOT_Enrcert_Nbr'};
				$refCookie->{OHOT_ENROLLMENT_CERT_DATE} = $arrData[$i]->{'a:OHOT_Enrcert_ReadyDate'};
				$refCookie->{CERTIFICATETYPE} = $arrData[$i]->{'a:CertificateType'};
				$refCookie->{HASTXDPSTEST} = $arrData[$i]->{'a:HasTXDPSTest'};

				$refCookie->{DSPROVIDER} = $arrData[$i]->{'a:DSProvider'};
				$refCookie->{DSADDRESS} = $arrData[$i]->{'a:DSAddress'};
				$refCookie->{DSCITY} = $arrData[$i]->{'a:DSCity'};
				$refCookie->{DSSTATE} = $arrData[$i]->{'a:DSState'};
				$refCookie->{DSZIPCODE} = $arrData[$i]->{'a:DSZipcode'};
				$refCookie->{DSPHONE} = $arrData[$i]->{'a:DSPhone'};

				$refCookie->{PARENTFORMFILLED} = $arrData[$i]->{'a:ParentFormFilled'};
				$refCookie->{PARENTADDRESSLINE1} = $arrData[$i]->{'a:ParentAddressLine1'};
				$refCookie->{PARENTADdRESSLINE2} = $arrData[$i]->{'a:ParentAddressLine2'};
				$refCookie->{PARENTADDRESSCITY} =  $arrData[$i]->{'a:ParentAddressCity'};
				$refCookie->{PARENTADDRESSSTATE} = $arrData[$i]->{'a:ParentAddressState'};
				$refCookie->{PARENTADDRESSPOSTCODE} = $arrData[$i]->{'a:ParentAddressPostcode'};
				$refCookie->{PARENTNAME} = $arrData[$i]->{'a:ParentName'};
				$refCookie->{PARENTEMAIL} = $arrData[$i]->{'a:ParentEmail'};
				$refCookie->{PARENTDL} = $arrData[$i]->{'a:ParentDL'};
				$refCookie->{PARENTPHONENUMBER} = $arrData[$i]->{'a:ParentPhoneNumber'};
				$refCookie->{PARENTDLSTATE} = $arrData[$i]->{'a:ParentDLState'};
				$refCookie->{INCARCOMPLETIONDATE} = $arrData[$i]->{'a:BTWTCompletionDate'};
				$refCookie->{LEARNERSPERMITNUMBER} = $arrData[$i]->{'a:LearnersPermitNumber'};
				$refCookie->{CPCCPRINTINGREQUESTID} = $arrData[$i]->{'a:CPCCPrintingRequestID'};
				$refCookie->{SEVENBTWINSTRUCTION} = $arrData[$i]->{'a:SevenBTWInstruction'};
				$refCookie->{SEVENINCAROBSERVATION} = $arrData[$i]->{'a:SevenInCarObservation'};
				$refCookie->{LABORATORYCOMPLETIONDATE} = $arrData[$i]->{'a:LaboratoryCompletionDate'};
				$refCookie->{SCHOOLLICENSENUMBER} = $arrData[$i]->{'a:SchoolLicenseNumber'};
				$refCookie->{SIGNATUREOFCHIEFSCHOOLOFFICIAL} = $arrData[$i]->{'a:SignatureOfChiefSchoolOfficial'};
				$refCookie->{SCHOOLNAME} = $arrData[$i]->{'a:SchoolName'};
				$refCookie->{SCHOOLADDRESS} = $arrData[$i]->{'a:SchoolAddress'};
				$refCookie->{SCHOOLCITY} = $arrData[$i]->{'a:SchoolCity'};
				$refCookie->{SCHOOLSTATE} = $arrData[$i]->{'a:SchoolState'};
				$refCookie->{SCHOOLZIP} = $arrData[$i]->{'a:SchoolZip'};
				$refCookie->{PERMITCONFIRMATIONNUMBER} = $arrData[$i]->{'a:PermitConfirmationNumber'};

				$self->putUserRecord($ref, $refCookie);

			}
                }
		if(exists $responseData->{'s:Body'}{GetUserCompletionReportResponse}{GetUserCompletionReportResult}{'a:UserCompletionData'}) {
			my $responseDataArr = $responseData->{'s:Body'}{GetUserCompletionReportResponse}{GetUserCompletionReportResult}{'a:UserCompletionData'};
			my @arrData;
			if(ref($responseDataArr) eq 'HASH'){
				push @arrData, $responseDataArr;
			}else{
				@arrData=@$responseDataArr;
			}
			my $noOfRecords= @arrData;
			for (my $i=0;$i<$noOfRecords;$i++){
				my $dataHash=$arrData[$i];
				foreach my $field(keys %$dataHash){
					my $fieldData=$dataHash->{$field};
					if(ref($fieldData) eq "HASH"){
						$arrData[$i]->{$field}='';
					}
				}

				my $ref;
				my $refCookie;
				$ref->{USER_ID}= ($arrData[$i]->{'a:Email'}) ? $arrData[$i]->{'a:Email'} : ( ($arrData[$i]->{'a:UserName'}) ? $arrData[$i]->{'a:UserName'} : '');
				$ref->{SCHOOL_ID}=$defaultSchoolId;
				$ref->{PRODUCT_ID}=$originalCourseId;
				$ref->{FIRST_NAME}=$arrData[$i]->{'a:FirstName'};
				$ref->{LAST_NAME}=$arrData[$i]->{'a:LastName'};
				$ref->{MI}=$arrData[$i]->{'a:MiddleName'};
				$refCookie->{SUFFIX}=$arrData[$i]->{'a:Suffix'};
				$ref->{DOB}=$self->{PRODUCT_CON}->selectrow_array("select date_format(?,'%m/%d/%Y')", {}, $arrData[$i]->{'a:DOB'});
				$ref->{SEX}=$arrData[$i]->{'a:Sex'};
				$ref->{ADDRESS_1}=$arrData[$i]->{'a:Address1'};
				$ref->{ADDRESS_2}=$arrData[$i]->{'a:Address2'};
				$ref->{CITY}=$arrData[$i]->{'a:City'};
				$ref->{STATE}=$arrData[$i]->{'a:State'};
				$ref->{ZIP}=$arrData[$i]->{'a:Zip'};
				$ref->{COMPLETION_DATE}=$arrData[$i]->{'a:CourseCompletionDate'};
				$ref->{DUE_DATE}=$arrData[$i]->{'a:CourseDueDate'};
				$ref->{DRIVERS_LICENSE}=($arrData[$i]->{'a:Drvlicense'}) ? $arrData[$i]->{'a:Drvlicense'} : ( ($arrData[$i]->{'a:DLNumber'}) ? $arrData[$i]->{'a:DLNumber'} : '');
				$refCookie->{COUNTY}=$arrData[$i]->{'a:County'};
				$refCookie->{TESTRESULT}=$arrData[$i]->{'a:TestResult'};
				$refCookie->{INSTRUCTIONPERMITNUMBER}=$arrData[$i]->{'a:InstructionPermitNumber'};
				$refCookie->{DATE_CREATED} = $self->{PRODUCT_CON}->selectrow_array("select now()");
				$self->putUserRecord($ref, $refCookie);
			}

		}
        }
        else
        {
                my $content = $objResponse->error_as_HTML;
		$self->dbPutXMLData($schoolId, $originalCourseId,$content."\nXML Request:$request\nReason:$certificateReason");
#               print $objResponse->is_error;
#               my $sent = $objRequest->as_string;
#               print "$sent\n\n";
#               $error = $objResponse->error_as_HTML;
#               print "error=$error\n\n";
                #print "respond=$sent\n\n";
        }
}

sub dbPutXMLData{
	my $self = shift;
	my ($schoolId, $courseId,$content) = @_;
	my $sth=$self->{PRODUCT_CON}->prepare('insert into printing_xml_data (trans_date, school_id, product_id, xml_data) values (now(), ?, ?, ?)');
	$sth->execute($schoolId, $courseId,$content);
}

sub dbPutAdminComments {
	my $self = shift;
	my ($userId, $operation, $comment) = @_;
	my $sth=$self->{PRODUCT_CON}->prepare('insert into user_admin_comments (de_cert_data_id, support_operator, comment_date, comments) values (?, ?, now(), ?)');
	$sth->execute($userId, $operation, $comment);
}
	
sub updateDriveredData
{
	my $self = shift;
	my ($de_cert_data_id) = @_;
	my $addr = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));
	my $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{BETA} ;
	my $postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{BETA} ;
	if($addr && exists $self->{SETTINGS}->{USPS_ALLOWED_IPADDRESS}->{$addr}){
		$host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{PROD} ;
		$postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD} ;
	}
	my $userData = $self->getUserData($de_cert_data_id);
	my $userId = $userData->{USER_ID};
	my $refId = $userData->{REF_ID};
	my $courseId = $userData->{COURSE_ID};
	my $certificateNumber = $userData->{CERTIFICATE_NUMBER};
	if($courseId && $courseId eq 'BTWTMINI03_I') {
		$certificateNumber = '';
	}
	my $airbillNumber= $userData->{AIRBILL_NUMBER};
	my $printDate = $userData->{PRINT_DATE_SQL};
	my $objUserAgent = LWP::UserAgent->new;
	my $certTypeXML = "";
	if($courseId && $courseId eq 'C0000067') {
		my $certCookie = $self->getCookie($de_cert_data_id,['OHOT_COMPLETION_CERT_NUMBER','OHOT_ENROLLMENT_CERT_NUMBER']);
		if($certCookie->{OHOT_COMPLETION_CERT_NUMBER}) {
			$certTypeXML = "<ns1:certificateType></ns1:certificateType>";
		} elsif($certCookie->{OHOT_ENROLLMENT_CERT_NUMBER}) {
			$certTypeXML = "<ns1:certificateType>PARTCERT</ns1:certificateType>";
		}
	}

        if($courseId && $courseId eq 'C0000071') {
                my $certCookie = $self->getCookie($de_cert_data_id,['CERTIFICATETYPE']);
                if($certCookie->{CERTIFICATETYPE} && $certCookie->{CERTIFICATETYPE} eq 'PARTCERT') {
                        $certTypeXML = "<ns1:certificateType>PARTCERT</ns1:certificateType>";
                } else {
                        $certTypeXML = "<ns1:certificateType></ns1:certificateType>";
                }
        }

	my $request = <<DATA;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://tempuri.org/"><SOAP-ENV:Body><ns1:UpdateCertificateStatus><ns1:userID>$userId</ns1:userID><ns1:refID>$refId</ns1:refID><ns1:certificateNbr>$certificateNumber</ns1:certificateNbr><ns1:deliveryTrackingNbr>$airbillNumber</ns1:deliveryTrackingNbr>$certTypeXML</ns1:UpdateCertificateStatus></SOAP-ENV:Body></SOAP-ENV:Envelope>
DATA
	my $contentlength = length($request);
	my $objHeader = HTTP::Headers->new(
                                Host => $host,
                                Content_Type => 'text/xml',
                                Content_Length => $contentlength,
                                SOAPAction => 'http://tempuri.org/IWaitingToBePrinted/UpdateCertificateStatus'
                                );
	my $objRequest = HTTP::Request->new("POST",$postURL,$objHeader,$request);
        my $objResponse = $objUserAgent->request($objRequest);
        if (!$objResponse->is_error)
        {
                my $content = $objResponse->content;
                my $xml = new XML::Simple;
                my $responseData = $xml->XMLin($content);
                my $responseDataArr=$responseData->{'s:Body'}{UpdateCertificateStatusResponse}{'xmlns'};
		if($responseDataArr){
			my $sth1=$self->{PRODUCT_CON}->prepare("update user_info set certificate_number_updated=now() where de_cert_data_id =?");
			$sth1->execute($de_cert_data_id);
			if($airbillNumber){
				my $sth2=$self->{PRODUCT_CON}->prepare("update user_info set airbill_number_updated=now() where de_cert_data_id =?");
				$sth2->execute($de_cert_data_id);
			}
			my $sth3=$self->{PRODUCT_CON}->prepare('insert into user_admin_comments (de_cert_data_id, support_operator, comment_date, comments) values (?, ?, now(), ?)');
			$sth3->execute($de_cert_data_id, 'CERT_NUMBER_UPDATED',$content);
			return "$userId : $certificateNumber :Updated : SUCCESS\n\n";
		}else{
			my $sth3=$self->{PRODUCT_CON}->prepare('insert into user_admin_comments (de_cert_data_id, support_operator, comment_date, comments) values (?, ?, now(), ?)');
			$sth3->execute($de_cert_data_id, 'CERT_NUMBER_NOT_UPDATED_ERROR1',$content);
			return "$userId : $certificateNumber :not Updated : ERROR\n\n";
		}
        }
        else
        {
                my $content = $objResponse->content;
                my $xml = new XML::Simple;
                my $responseData = $xml->XMLin($content);
		my $responseDataArr=$responseData->{'s:Body'}{'s:Fault'}{detail}{string}{content};
		if($responseDataArr){
			my $sth1=$self->{PRODUCT_CON}->prepare("update user_info set certificate_number_updated=now() where de_cert_data_id =?");
			$sth1->execute($de_cert_data_id);
			if($airbillNumber){
				my $sth2=$self->{PRODUCT_CON}->prepare("update user_info set airbill_number_updated=now() where de_cert_data_id =?");
				$sth2->execute($de_cert_data_id);
			}
			my $sth3=$self->{PRODUCT_CON}->prepare('insert into user_admin_comments (de_cert_data_id, support_operator, comment_date, comments) values (?, ?, now(), ?)');
			$sth3->execute($de_cert_data_id, 'CERT_NUMBER_ALREADY_UPDATED',$content);
			return "$userId : $certificateNumber :Already Updated : $responseDataArr\n\n";
		}else{
                	my $error = $objResponse->error_as_HTML;
			my $sth3=$self->{PRODUCT_CON}->prepare('insert into user_admin_comments (de_cert_data_id, support_operator, comment_date, comments) values (?, ?, now(), ?)');
			$sth3->execute($de_cert_data_id, 'CERT_NUMBER_NOT_UPDATED_ERROR2',$content);
			return "$userId : $certificateNumber : Not Updated : ERROR\n\n"; 
		}
        }
}

sub updateDriveredAirbillData
{
	my $self = shift;
	my ($de_cert_data_id) = @_;
	my $addr = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));
	my $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{BETA} ;
	my $postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{BETA} ;
	if($addr && exists $self->{SETTINGS}->{USPS_ALLOWED_IPADDRESS}->{$addr}){
		$host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{PROD} ;
		$postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD} ;
	}
	my $userData = $self->getUserData($de_cert_data_id);
	my $userId = $userData->{USER_ID};
	my $refId = $userData->{REF_ID};
	my $certificateNumber = $userData->{CERTIFICATE_NUMBER};
	my $airbillNumber= $userData->{AIRBILL_NUMBER};
	my $printDate = $userData->{PRINT_DATE_SQL};

	my $courseId = $userData->{COURSE_ID};
	my $certTypeXML = '';
	if($courseId && $courseId eq 'C0000067') {
		my $certCookie = $self->getCookie($de_cert_data_id,['OHOT_COMPLETION_CERT_NUMBER','OHOT_ENROLLMENT_CERT_NUMBER']);
		if($certCookie->{OHOT_COMPLETION_CERT_NUMBER}) {
			$certTypeXML = "<ns1:certificateType></ns1:certificateType>";
		} elsif($certCookie->{OHOT_ENROLLMENT_CERT_NUMBER}) {
			$certTypeXML = "<ns1:certificateType>PARTCERT</ns1:certificateType>";
		}
	}
        if($courseId && $courseId eq 'C0000071') {
                my $certCookie = $self->getCookie($de_cert_data_id,['CERTIFICATETYPE']);
                if($certCookie->{CERTIFICATETYPE} && $certCookie->{CERTIFICATETYPE} eq 'PARTCERT') {
                        $certTypeXML = "<ns1:certificateType>PARTCERT</ns1:certificateType>";
                } else {
                        $certTypeXML = "<ns1:certificateType></ns1:certificateType>";
                }
        }

	my $objUserAgent = LWP::UserAgent->new;
	my $request = <<DATA;
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://tempuri.org/"><SOAP-ENV:Body><ns1:UpdateDeliveryTrackingNumber><ns1:userID>$userId</ns1:userID><ns1:refID>$refId</ns1:refID>$certTypeXML<ns1:deliveryTrackingNbr>$airbillNumber</ns1:deliveryTrackingNbr></ns1:UpdateDeliveryTrackingNumber></SOAP-ENV:Body></SOAP-ENV:Envelope>
DATA
	my $contentlength = length($request);
	my $objHeader = HTTP::Headers->new(
                                Host => $host,
                                Content_Type => 'text/xml',
                                Content_Length => $contentlength,
                                SOAPAction => 'http://tempuri.org/IWaitingToBePrinted/UpdateDeliveryTrackingNumber'
                                );
	my $objRequest = HTTP::Request->new("POST",$postURL,$objHeader,$request);
        my $objResponse = $objUserAgent->request($objRequest);
        if (!$objResponse->is_error)
        {
                my $content = $objResponse->content;
                my $xml = new XML::Simple;
                my $responseData = $xml->XMLin($content);
                my $responseDataArr=$responseData->{'s:Body'}{UpdateDeliveryTrackingNumberResponse}{'xmlns'};
		if($responseDataArr){
			my $sth2=$self->{PRODUCT_CON}->prepare("update user_info set airbill_number_updated=now() where de_cert_data_id =?");
			$sth2->execute($de_cert_data_id);

			my $sth3=$self->{PRODUCT_CON}->prepare('insert into user_admin_comments (de_cert_data_id, support_operator, comment_date, comments) values (?, ?, now(), ?)');
			$sth3->execute($de_cert_data_id, 'CERT_LABEL_UPDATED',$content);
			return "$userId : $certificateNumber :Updated : SUCCESS\n\n";
		}else{
			my $sth3=$self->{PRODUCT_CON}->prepare('insert into user_admin_comments (de_cert_data_id, support_operator, comment_date, comments) values (?, ?, now(), ?)');
			$sth3->execute($de_cert_data_id, 'CERT_LABEL_NOT_UPDATED_ERROR1',$content);

			return "$userId : $certificateNumber :not Updated : ERROR\n\n";
		}
        }
        else
        {
                my $error = $objResponse->error_as_HTML;
		my $sth3=$self->{PRODUCT_CON}->prepare('insert into user_admin_comments (de_cert_data_id, support_operator, comment_date, comments) values (?, ?, now(), ?)');
		$sth3->execute($de_cert_data_id, 'CERT_LABEL_NOT_UPDATED_ERROR2',$error);

		return "$userId : $certificateNumber : Not Updated : $error\n\n"; 
        }
}

sub getCOTeenStudentAttendanceRecord {
        my $self = shift;
        my ($de_cert_data_id, $userData) = @_;
        my $addr = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));
        my $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{BETA} ;
        my $postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{BETA} ;
        if($addr && exists $self->{SETTINGS}->{USPS_ALLOWED_IPADDRESS}->{$addr}){
                $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{PROD} ;
                $postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD} ;
        }
	my $API =Printing::DriversEd->new;
        $API->{PRODUCT}='DRIVERSED';
       	$API->constructor;
        $userData = $API->getUserData($de_cert_data_id);
        my $userId = $userData->{USER_ID};
        my $refId = $userData->{REF_ID};
        my $certificateNumber = $userData->{CERTIFICATE_NUMBER};
        my $airbillNumber= $userData->{AIRBILL_NUMBER};
        my $printDate = $userData->{PRINT_DATE_SQL};
	my $requestId = $userData->{PRINTING_REQUEST_ID};
	my $courseId = $userData->{COURSE_ID};
	my $startDate = $userData->{ENROLLDATE};
	my ($dt, $time) = split(/T/,$startDate);
	my ($Y,$M,$D) = split(/\-/, $dt);
	$startDate = "$M/$D/$Y";

	my $completionDate = $userData->{COMPLETION_DATE};
	my $finalScore  = $userData->{FINALSCORE};
	my $schoolId = 'DRVEDCA';
	my $success = 0;



	my $html = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\"><html xmlns=\"http://www.w3.org/1999/xhtml\"><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" /></head><body>";
$html .= "<table width=\"100%\" border=\"0\" align=\"center\" cellpadding=\"0\" cellspacing=\"0\"><tr><td align=\"left\" valign=\"top\" width=\"66\"><img src=\"http://printer02.idrivesafely.com/.download/images/staple-coc.jpg\" width=\"66\" height=\"65\" alt=\"staple\" /></td><td align=\"left\" valign=\"top\">&nbsp;</td><td align=\"right\" width=\"350\" valign=\"top\"><img src=\"http://printer02.idrivesafely.com/.download/images/logo.png\" width=\"250\" alt=\"driversed\" /></td></tr><tr><td colspan=\"3\" align=\"center\" valign=\"top\"><Strong>Commercial Driving School Student Record for a 30 Hour Classroom Program</strong><br /><strong>Organization #9105</strong></td></tr><!-- Header End--><tr><td colspan=\"3\" align=\"left\" valign=\"top\">&nbsp;</td></tr><tr><td colspan=\"3\" align=\"left\" valign=\"top\"><table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr><td>";

        my $objUserAgent = LWP::UserAgent->new;
        my $request = <<DATA;
<?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://tempuri.org/"><SOAP-ENV:Body><ns1:GetAttendanceRecord><ns1:schoolID>$schoolId</ns1:schoolID><ns1:productID>$courseId</ns1:productID><ns1:CertificatePrintingRequestID>$requestId</ns1:CertificatePrintingRequestID></ns1:GetAttendanceRecord></SOAP-ENV:Body></SOAP-ENV:Envelope>
DATA
	#print STDERR "\n$request\n\n";
        my $contentlength = length($request);
        my $objHeader = HTTP::Headers->new(
                                Host => $host,
                                Content_Type => 'text/xml',
                                Content_Length => $contentlength,
                                SOAPAction => 'http://tempuri.org/IWaitingToBePrinted/GetAttendanceRecord'
                                );
        my $objRequest = HTTP::Request->new("POST",$postURL,$objHeader,$request);
        my $objResponse = $objUserAgent->request($objRequest);
	#print STDERR Dumper($objResponse);
        if (!$objResponse->is_error)
        {
                my $content = $objResponse->content;
		my $API =Printing::DriversEd->new;
	        $API->{PRODUCT}='DRIVERSED';
        	$API->constructor;
		$API->dbPutXMLData($schoolId, $courseId,$content);
                my $xml = new XML::Simple;
                my $responseData = $xml->XMLin($content);
		my $responseDataArr = $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:Modules'}{'a:Module_Info'};
		if(!ref($responseDataArr)) {

			##Store the resoponse data returned
			my $API =Printing::DriversEd->new;
		        $API->{PRODUCT}='DRIVERSED';
        		$API->constructor;
                	my $content = $objResponse->error_as_HTML;
			$API->dbPutXMLData($schoolId, $courseId,$content);

			##Something went wrong, need to alert the team
			$API->dbPutAdminComments($de_cert_data_id, 'CO_TEEN_ATTENDANCE_NOTGENERATED','Could not print the DE CO Teen student attendance record');
			use MIME::Lite;
			my $emailData = "Hi,<br><br>DriversEd CO Teen - Attendance Sheet not printed for Request Id: $requestId; User Id: $userId, at ". Settings::getDateTime() .".<br><br>Thank you,<br>I DRIVE SAFELY";
			my $msg = MIME::Lite->new(From => 'I Drive Safely <wecare@idrivesafely.com>',
				To => 'hamsa.palepu@edriving.com,rajesh@edriving.com,formeco.spencer@edriving.com,idcqa@ed-ventures-online.com',
				#To => 'rajesh@ed-ventures-online.com, rajesh2@ed-ventures-online.com',
				Subject => "DriversEd CO Teen - Attendance Sheet not printed for Request Id: $requestId, at " . Settings::getDateTime(),
				Type    => 'multipart/mixed');
			$msg->attach(Type => 'text/html', Data => $emailData);
			$msg->send;			
			#$msg->send('smtp','192.168.1.214');			
			return 1;
		} else {
		$success = 1;
		my $firstName =  $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:FirstName'};
		my $lastName =  $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:LastName'};
		my $dob =  $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DOB'};
		my $totalDuration =  $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:TotalDuration'};
		my $durationHrs = int($totalDuration/60);
		my $durationMin = $totalDuration%60;
		$totalDuration = "$durationHrs Hrs $durationMin Min";
		my $dataHash;

		$html .="<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr><td width=\"100\" align=\"left\" valign=\"bottom\">Student Name:</td><td width=\"305\" align=\"left\" valign=\"bottom\" >$firstName $lastName</td><td width=\"10\" align=\"left\" valign=\"bottom\" >&nbsp;</td><td width=\"100\" align=\"left\" valign=\"bottom\">Date of Birth:</td><td width=\"175\" align=\"left\" valign=\"bottom\" >$dob</td></tr><tr><td width=\"100\" align=\"left\" valign=\"bottom\">Start Date:</td><td width=\"305\" align=\"left\" valign=\"bottom\">$startDate</td><td width=\"10\" align=\"left\" valign=\"bottom\" >&nbsp;</td><td width=\"100\" align=\"left\" valign=\"bottom\">Completion Date:</td><td width=\"175\" align=\"left\" valign=\"bottom\" >$completionDate</td></tr><tr><td width=\"220\" align=\"left\" valign=\"bottom\">Total Hours(hours:minutes):</td><td width=\"246\" align=\"left\" valign=\"bottom\" > $totalDuration </td><td width=\"10\" align=\"left\" valign=\"bottom\" >&nbsp;</td><td width=\"95\" align=\"left\" valign=\"bottom\">Final Score:</td><td width=\"163\" align=\"left\" valign=\"bottom\" >$finalScore</td></tr></table></td></tr><tr><td height=\"15\"></td></tr></table></td></tr><tr><td colspan=\"3\" align=\"left\" valign=\"top\">&nbsp;</td></tr><tr><td colspan=\"3\" align=\"center\" valign=\"top\"><table width=\"100%\" border=\"1\" bordercolor=\"#000\" cellspacing=\"0\" cellpadding=\"0\"><tr><td width=\"50%\" height=\"50\" align=\"center\" valign=\"middle\">Module</td><td width=\"30%\" align=\"center\" valign=\"middle\" >Time Spent in Module HH:mm</td><td width=\"20%\" align=\"center\" valign=\"middle\" >Quiz Score </td></tr><tbody> ";
		my @arrData=@$responseDataArr;
		my $noOfRecords= @arrData;
		for (my $i=0;$i<$noOfRecords;$i++){
		        $dataHash=$arrData[$i];
		        foreach my $field(keys %$dataHash){
		                my $fieldData=$dataHash->{$field};
		                if(ref($fieldData) eq "HASH"){
		                        #$arrData[$i]->{$field}='';
		                }
		        }

		        my $moduleId = $arrData[$i]->{'a:ModuleID'};
		        my $moduleTitle = $arrData[$i]->{'a:ModuleTitle'};
        		my $moduleDuration = $arrData[$i]->{'a:ModuleDuration'};
		        my $testScores = $arrData[$i]->{'a:Scores'};
		        if(!$testScores->{'a:COOT_TestScore'}) {
        		}
		        my $hashSize = keys %$testScores;
			$html .="<tr><td height=\"30\" align=\"left\" valign=\"middle\">$moduleTitle</td>\n";
			my $mdurationHrs = int($moduleDuration/60);
			my $mdurationMin = $moduleDuration%60;
			$moduleDuration = "$mdurationHrs Hrs $mdurationMin Min";
			$html .="<td align=\"center\" valign=\"middle\" >$moduleDuration</td>\n";

			if(!$hashSize || $hashSize == 0) {
				$html .="<td align=\"center\" valign=\"middle\" >N/A</td>\n";
			}
			my($topic_id,$module_score,$topic_title);
		        if($hashSize >= 1) {
			          foreach my $key(keys %$testScores){
					my @tmp_arr = $testScores->{$key}; # Here We need to check the length
					my $length = $tmp_arr[0];
					if (ref($length) eq "HASH") {  # Here We need to check the length,Hash array comes only element
						$topic_id = $tmp_arr[0]->{'a:TopicId'};
						$module_score = $tmp_arr[0]->{'a:ModuleTestScore'};
						$topic_title = $tmp_arr[0]->{'a:TopicTitle'};
						$html .="<td align=\"center\" valign=\"middle\" >$module_score</td>\n";
					}else{
						my $k=1;
						$html .="<td align=\"left\" valign=\"top\"><table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr>\n";
						foreach my $key(@$length){ # Here We need to check the length,topicid and topic score
                    					$topic_id = $key->{'a:TopicId'};
							$module_score = $key->{'a:ModuleTestScore'};
							$topic_title = $key->{'a:TopicTitle'};
							my $hr = "";
							if($k==1) {
								$hr = "<hr>";
							}
							$html .="<td bordercolor=\"#999999\" align=\"center\">$module_score $hr </td>\n";
							$k++;
							$html .="</tr>";
               					}
						$html .="</table></td></tr>";
					}
          			}
        		}
		}
		}
	} else {
		my $API =Printing::DriversEd->new;
	        $API->{PRODUCT}='DRIVERSED';
        	$API->constructor;
                my $content = $objResponse->error_as_HTML;
		$API->dbPutXMLData($schoolId, $courseId,$content);
	}
	$html .="</table></td></tr></table><!--
<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"> <tr> <td height=\"15\"></td> </tr> <tr> <td colspan=\"3\" align=\"center\" valign=\"top\"><font size=\"2\">283 4th Street, Suite 301 &bull; Oakland CA 94607<img src=\"http://printer02.idrivesafely.com/.download/images/mobile-icon.jpg\" hspace=\"5\" border=\"0\" alt=\"mobile\" />&nbsp;510.433.060 <img src=\"http://printer02.idrivesafely.com/.download/images/fax-icon.jpg\" hspace=\"5\" border=\"0\" alt=\"fax\" />&nbsp;510.433.0230 <img src=\"http://printer02.idrivesafely.com/.download/images/mail-icon.jpg\" hspace=\"5\" alt=\"mail\" />info\@DriversEd.com</font></td> </tr> <tr> <td height=\"5\"></td> </tr><tr> <td colspan=\"3\" align=\"center\" valign=\"top\"><font size=\"2\"><img border=\"0\" src=\"http://printer02.idrivesafely.com/.download/images/fb-icon.jpg\"> DriversEd &nbsp; &nbsp; <img src=\"http://printer02.idrivesafely.com/.download/images/tw-icon.jpg\"/> DriversEd.com</font></td></tr></table>--></body></html>";

	if($success) {
		my $API =Printing::DriversEd->new;
	        $API->{PRODUCT}='DRIVERSED';
        	$API->constructor;
		$API->dbPutAdminComments($de_cert_data_id, 'CO_TEEN_ATTENDANCE','Printed the DE CO Teen student attendance record');
		##Insert cookie, that the attendance record has been printed
		$API->putCookie($de_cert_data_id, { "CO_ATTENDANCESHEET_PRINTED" => time()});
		##Ready with the attenance html to pdf conversion
		my $fileName = "$de_cert_data_id-".time();
		my $htmlFileName = "/tmp/$fileName.html";
		open (OUT,">$htmlFileName");
		print OUT $html;
		close OUT;

		##HTML Done, convert to PDF
		my $pdfCoverFileName = "/tmp/$fileName.pdf";
		my $cmd = <<CMD;
/usr/bin/htmldoc -f $pdfCoverFileName --size letter --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 $htmlFileName
CMD

		$ENV{TMPDIR}='/tmp/';
		$ENV{HTMLDOC_NOCGI}=1;
		system($cmd);
		unlink($htmlFileName); ##Delete the html file
		return $pdfCoverFileName;
	} else {
		##Store the resoponse data returned
		my $API =Printing::DriversEd->new;
		$API->{PRODUCT}='DRIVERSED';
		$API->constructor;
		my $content = $objResponse->error_as_HTML;
		$API->dbPutXMLData($schoolId, $courseId,$content);

		$API->dbPutAdminComments($de_cert_data_id, 'CO_TEEN_ATTENDANCE_NOTGENERATED','Could not print the DE CO Teen student attendance record');
		use MIME::Lite;
		my $emailData = "Hi,<br><br>DriversEd CO Teen - Attendance Sheet not printed for Request Id: $requestId; User Id: $userId, at ". Settings::getDateTime() .".<br><br>Thank you,<br>I DRIVE SAFELY";
		my $msg = MIME::Lite->new(From => 'I Drive Safely <wecare@idrivesafely.com>',
			To => 'hamsa.palepu@edriving.com,rajesh@edriving.com,formeco.spencer@edriving.com,idcqa@ed-ventures-online.com',
			#To => 'rajesh@ed-ventures-online.com, rajesh2@ed-ventures-online.com',
			Subject => "DriversEd CO Teen - Attendance Sheet not printed for Request Id: $requestId, at " . Settings::getDateTime(),
			Type    => 'multipart/mixed');
		$msg->attach(Type => 'text/html', Data => $emailData);
		$msg->send;			
		#$msg->send('smtp','192.168.1.214');			
		return 1;
	}
}

sub getTXTeen32HourLogOld {
        my $self = shift;
        my ($de_cert_data_id, $userData) = @_;
        my $addr = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));
        my $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{BETA} ;
        my $postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{BETA} ;
        if($addr && exists $self->{SETTINGS}->{USPS_ALLOWED_IPADDRESS}->{$addr}){
                $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{PROD} ;
                $postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD} ;
        }
        my $API =Printing::DriversEd->new;
        $API->{PRODUCT}='DRIVERSED';
        $API->constructor;
        $userData = $API->getUserData($de_cert_data_id);
        my $finalScore  = $userData->{FINALSCORE};
        my $requestId = $userData->{PRINTING_REQUEST_ID};
        my $firstName = $userData->{FIRST_NAME};
        my $lastName = $userData->{LAST_NAME};
        my $courseId = $userData->{COURSE_ID};
        my $schoolId = 'DRVEDCA';
        my $today = $userData->{TODAY};
        my $success = 0;
        my $html = "<table border=\"0\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" align=\"center\"><tbody><tr><td colspan=\"2\" align=\"left\" valign=\"top\" width=\"66\"><p><strong>Class Room Log</strong></p><p><strong>Student Name: </strong>$firstName $lastName </p></td><td align=\"right\" valign=\"top\" width=\"350\"><img src=\"http://printer02.idrivesafely.com/.download/images/logo.png\" alt=\"driversed\" width=\"250\" /></td></tr><tr><td colspan=\"3\" align=\"right\" valign=\"top\">4201 FM 1960 West, Ste. 100, Houston, TX 77068</td></tr><tr><td colspan=\"3\" align=\"center\" valign=\"top\"><table border=\"0\" width=\"100%\"><tbody><tr><td width=\"60%\"valign=\"top\"><strong>Unit Name</strong></td><td colspan=\"2\" width=\"20%\"><strong>Test Results&nbsp;</strong><br>Passed/Failed</td></tr>";
        my $objUserAgent = LWP::UserAgent->new;
        my $request = <<DATA;
<?xml version="1.0" encoding="UTF-8"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://tempuri.org/"><SOAP-ENV:Body><ns1:GetAttendanceRecord><ns1:schoolID>DRVEDCA</ns1:schoolID><ns1:productID>$courseId</ns1:productID><ns1:CertificatePrintingRequestID>$requestId</ns1:CertificatePrintingRequestID></ns1:GetAttendanceRecord></SOAP-ENV:Body></SOAP-ENV:Envelope>
DATA
        my $contentlength = length($request);
        my $objHeader = HTTP::Headers->new(
                Host => $host,
                Content_Type => 'text/xml',
                Content_Length => $contentlength,
                SOAPAction => 'http://tempuri.org/IWaitingToBePrinted/GetAttendanceRecord'
        );
        my $objRequest = HTTP::Request->new("POST",$postURL,$objHeader,$request);
        my $objResponse = $objUserAgent->request($objRequest);
        #print STDERR Dumper($objResponse);
        if (!$objResponse->is_error) {
                my $content = $objResponse->content;
                my $API =Printing::DriversEd->new;
                $API->{PRODUCT}='DRIVERSED';
                $API->constructor;
                $API->dbPutXMLData($schoolId, $courseId,$content);
                my $xml = new XML::Simple;
                my $responseData = $xml->XMLin($content);
                my $responseDataArr= $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:Modules'}{'a:Module_Info'};
                my @arrData=@$responseDataArr;
                my $noOfRecords= @arrData;
                my $dataHash;
                for (my $i=0;$i<$noOfRecords;$i++){
                        $dataHash=$arrData[$i];
                        foreach my $field(keys %$dataHash){
                                my $fieldData=$dataHash->{$field};
                                if(ref($fieldData) eq "HASH"){
                                        #$arrData[$i]->{$field}='';
                                }
                        }
                        my $moduleId = $arrData[$i]->{'a:ModuleID'};
                        my $moduleTitle = $arrData[$i]->{'a:ModuleTitle'};
                        my $moduleDuration = $arrData[$i]->{'a:ModuleDuration'};
                        #my $moduleScore = $arrData[$i]->{'a:Scores'}->{'i:nil'};
                        #print Dumper($moduleScore);
                        #my $finalScore = $arrData[$i]->{'a:FinalScore'};
                        #print "\nModule Id: $moduleId | $moduleTitle | $moduleDuration | moduleScore | $finalScore";
			my $module_score;
			my $testScores = $arrData[$i]->{'a:Scores'};
			my $hashSize = keys %$testScores;
			foreach my $key(keys %$testScores){
				my @tmp_arr = $testScores->{$key}; # Here We need to check the length
				my $length = $tmp_arr[0];
				if (ref($length) eq "HASH") {  
					$module_score = $tmp_arr[0]->{'a:ModuleTestScore'};
				}else{
					my $k=1;
					foreach my $key(@$length){ 
						$module_score = $key->{'a:ModuleTestScore'};
						$k++;
					}
				}
			}

                        my $testResult = 'P';
                        if($moduleTitle =~ /Final Exam/ig) {
                                $success = 1;
                                $testResult = $finalScore;
				if(!$testResult) {
					$testResult = $module_score;
				}
                        }
                        $html .= "<tr><td>$moduleTitle </td><td>$testResult &nbsp; &nbsp; &nbsp;&nbsp;</td><td></td></tr>";
                }
        } else {
                my $API =Printing::DriversEd->new;
                $API->{PRODUCT}='DRIVERSED';
                $API->constructor;
                my $content = $objResponse->error_as_HTML;
                $API->dbPutXMLData($schoolId, $courseId,$content);
        }
        $html .="<tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr><tr><td><strong>Instructor Name: Julio Esparza</strong></td><td>&nbsp;</td><td>&nbsp;</td></tr><tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr><tr><td><strong>Instructor Signature:</strong></td><td>&nbsp;</td><td>&nbsp;</td></tr><tr><td><img src=\"http://printer02.idrivesafely.com/.download/DE/TX/julionew.jpg\" alt=\"driversed\" width=\"120\" height=\"35\"/></td><td>&nbsp;</td><td>&nbsp;</td></tr><tr><td>____________________________________________</td><td>&nbsp;</td><td><strong>Date:</strong></td></tr><tr><td>&nbsp;</td><td>&nbsp;</td><td>$today</td></tr></tbody></table></td></tr></tbody></table>";

        if($success) {
                my $API =Printing::DriversEd->new;
                $API->{PRODUCT}='DRIVERSED';
                $API->constructor;
                $API->dbPutAdminComments($de_cert_data_id, 'TEEN32_STUDENT_LOG_PRINTED','Printed the DE TX Teen32 Student Log');

                ##Ready with the attenance html to pdf conversion
                my $fileName = "$de_cert_data_id-".time();
                $fileName = "$de_cert_data_id"; ##----------------------------------------------------------------------- to delete this line before updating for QA
                my $htmlFileName = "/tmp/$fileName.html";
                open (OUT,">$htmlFileName");
                print OUT $html;
                close OUT;

                ##HTML Done, convert to PDF
                my $pdfCoverFileName = "/tmp/$fileName.pdf";
                my $cmd = <<CMD;
/usr/bin/htmldoc -f $pdfCoverFileName --size letter --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 $htmlFileName
CMD

                $ENV{TMPDIR}='/tmp/';
                $ENV{HTMLDOC_NOCGI}=1;
                system($cmd);
                unlink($htmlFileName); ##Delete the html file
                return $pdfCoverFileName;
        } else {
                return 0;
        }
}

sub getFormattedDate {
	my $self = shift;
	my ($dateType, $date) = @_;
	if(!$date) {
		$date = "now()";
	} else {
		$date = "'$date'";
	}
	##DATE- TYPES
	##1 = DD Mon YYYY; EX: 03 Nov 2016
	##2 = YYYY-MM-DD HH:MM:SS; Ex: 2016-11-03 15:09:01
	##3 = MON, DD YYY; EX: May 17, 2017
	my $sql = '';
	if($dateType) {
		if($dateType == '1') {
			$sql = "select date_format($date,'%d %b %Y')";
		} elsif($dateType == '2') {
			$sql = "select date_format($date,'%Y-%m-%d %H:%i:%s')";
		} elsif($dateType == '3') {
			$sql = "select date_format($date,'%b %d, %Y')";
		}
	} else {
		return;
	}
	if($sql) {
		my $formattedDate = $self->{PRODUCT_CON}->selectrow_array($sql);
		return $formattedDate;
	} else {
		return;
	}
}

sub getTXTeen32HourLog {
	my $self = shift;
	my ($de_cert_data_id, $userData) = @_;
	my $addr = inet_ntoa(scalar gethostbyname(hostname() || 'localhost'));
	my $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{BETA} ;
	my $postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{BETA} ;
	if($addr && exists $self->{SETTINGS}->{USPS_ALLOWED_IPADDRESS}->{$addr}){
		$host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{HOST}->{PROD} ;
		$postURL = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD} ;
	}
	my $API =Printing::DriversEd->new;
	$API->{PRODUCT}='DRIVERSED';
	$API->constructor;
	$userData = $API->getUserData($de_cert_data_id);
	my $finalScore = $userData->{FINALSCORE};
	my $requestId = $userData->{PRINTING_REQUEST_ID};
	my $firstName = $userData->{FIRST_NAME};
	my $lastName = $userData->{LAST_NAME};
	my $courseId = $userData->{COURSE_ID};
	my $schoolId = 'DRVEDCA';
	my $today = $userData->{TODAY};
	my $success = 0;
	my $timeEarnedHash = { 1 => '1:01:35', 2 => '1:00:46', 3 => '1:02:01', 4 => '1:02:24', 5 => '1:00:31', 6 => '1:02:22', 7 => '1:00:05', 8 => '1:03:16', 9 => '1:02:35', 10 => '1:02:35', 11 => '1:02:01', 12 => '1:01:00', 13 => '0:59:37', 14 => '1:00:56', 15 => '1:00:44', 16 => '1:01:21', 17 => '1:00:20', 18 => '1:02:08', 19 => '0:56:59', 20 => '0:57:18', 21 => '1:00:05', 22 => '1:03:08', 23 => '0:58:11', 24 => '1:02:57', 25 => '1:08:26', 26 => '0:55:29', 27 => '1:08:19', 28 => '1:01:54', 29 => '1:00:46', 30 => '1:01:33', 31 => '1:03:51', 32 => '0:50:00' };
	my $toDay = $API->getFormattedDate(1);
	my $objUserAgent = LWP::UserAgent->new;
	my $request = <<DATA;
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://tempuri.org/"><SOAP-ENV:Body><ns1:GetAttendanceRecord><ns1:schoolID>DRVEDCA</ns1:schoolID><ns1:productID>$courseId</ns1:productID><ns1:CertificatePrintingRequestID>$requestId</ns1:CertificatePrintingRequestID></ns1:GetAttendanceRecord></SOAP-ENV:Body></SOAP-ENV:Envelope>
DATA
	#print STDERR "\nRequest\n-------------------\n$request\n";
	my $contentlength = length($request);
	my $html = "<table width=\"100%\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n<tr>\n<td><table width=\"50%\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\">\n<tr>\n<td><table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">\n<tr>\n<td><strong>DriversEd.com</strong><br />\nSchool#:C2548<br />\n6069 Weber Road, Corpus Christi, TX 78413<br />\n(877) 382-1924 | www.DriversEd.com </td>\n</tr>\n</table>\n</td>\n</tr>\n<tr>\n<td>&nbsp;</td>\n</tr>\n<tr>\n<td><table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">\n<tr>\n<td><strong>INDIVIDUAL STUDENT RECORD(ISR)</strong><br />\n(TEXAS TEA TEEN DRIVER EDUCATION ONLINE COURSE)<br />\n<br />\nISR GENERATED ON: $toDay<br />\nCOURSE VERSION: #4</td>\n</tr>\n</table>\n</td>\n</tr>\n";

	my $objHeader = HTTP::Headers->new(
		Host => $host,
		Content_Type => 'text/xml',
		Content_Length => $contentlength,
		SOAPAction => 'http://tempuri.org/IWaitingToBePrinted/GetAttendanceRecord'
	);
	my $objRequest = HTTP::Request->new("POST",$postURL,$objHeader,$request);
	my $objResponse = $objUserAgent->request($objRequest);
	#print STDERR Dumper($objResponse);
	if (!$objResponse->is_error) {
		my $content = $objResponse->content;
		my $API =Printing::DriversEd->new;
		$API->{PRODUCT}='DRIVERSED';
		$API->constructor;
		$API->dbPutXMLData($schoolId, $courseId,$content);
		my $xml = new XML::Simple;
		my $responseData = $xml->XMLin($content);
		#print Dumper($responseData);
		my $firstName =  $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:FirstName'};
		my $lastName =  $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:LastName'};
		my $dob =  $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DOB'};
		my $totalDuration =  $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:TotalDuration'};
		my $durationHrs = int($totalDuration/60);
		my $durationMin = $totalDuration%60;
		$totalDuration = "$durationHrs Hrs $durationMin Min";
		my $averageTimePerGrade = $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:TotalDuration'}/32;
		my $avgHrs = int($averageTimePerGrade/60);
		my $avgMin = $averageTimePerGrade%60;
		$averageTimePerGrade = "$avgHrs Hrs $avgMin Min";

		my $courseStartDate = $API->getFormattedDate(1, $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:EnrollDate'});
		my $courseEndDate  = $API->getFormattedDate(1, $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:CompletionDate'});
		my $permitCertPrintDate  = $API->getFormattedDate(1, $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:TX_CPCCPrintedDate'});
		my $COCPrintDate = $API->getFormattedDate(1, $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:TX_COCPrintedDate'});

		my $deliveryAddress1 = $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DeliveryAddress1'};
		my $deliveryAddress2;
		if($responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DeliveryAddress2'}) {
			$deliveryAddress2 = $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DeliveryAddress2'};
			if(ref($deliveryAddress2) eq 'HASH') {
				$deliveryAddress2 = '';
			}
		}
		my $deliveryCity = $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DeliveryCity'};
		my $deliveryState = $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DeliveryState'};
		my $deliveryZip = $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DeliveryZip'};
		my $deliveryPhone = $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:DeliveryPhoneNumber'};

		$html .="<tr>\n<td>&nbsp;</td>\n</tr>\n<tr>\n<td><table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">\n<tr>\n<td><strong>STUDENT:</strong>\n<label>$firstName $lastName</label></td>\n</tr>\n<tr>\n<td><strong>DOB:</strong>\n<label>$dob</label></td>\n</tr>\n<tr>\n<td><strong>ADDRESS:</strong>\n<label>$deliveryAddress1 $deliveryAddress2</label></td>\n</tr>\n<tr>\n<td><strong>CITY/STATE/ZIP:</strong>\n<label>$deliveryCity $deliveryState, $deliveryZip</label></td>\n</tr>\n<tr>\n<td><strong>PHONE:</strong>\n<label>$deliveryPhone</label></td>\n</tr>\n</table></td>\n</tr>\n<tr>\n<td>&nbsp;</td>\n</tr>\n<tr>\n<td><table width=\"100%\" border=\"0\"cellspacing=\"0\" cellpadding=\"0\">\n<tr>\n<td>ASSIGNED CLASS<br />\nSTART DATE: $courseStartDate<br />\nEND DATE: $courseEndDate<br />\n6-HOUR CERTIFICATE: $permitCertPrintDate<br />\n32-HOUR CERTIFICATE: $COCPrintDate</td>\n<tr>\n</table>\n</td>\n</tr>\n<tr>\n<td>&nbsp;</td>\n</tr>\n</table></td>\n</tr>\n<tr>\n<td><table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">\n<tr>\n<td>COURSE CONTENT (INSTRUCTION)</td>\n</tr>\n<tr><td>&nbsp;</td><tr>\n<tr>\n<td><table width=\"100%\" border=\"1\" cellspacing=\"0\" cellpadding=\"0\">\n<thead>\n<tr>\n<th align=\"left\" valign=\"middle\">Unit #</th>\n<th align=\"left\" valign=\"middle\">Date Completed</th>\n<th align=\"left\" valign=\"middle\">Time Spent<br>(minutes)</th>\n<th align=\"left\" valign=\"middle\">Assessment Grade</th>\n<th align=\"left\" valign=\"middle\">Make-up Date</th>\n<th align=\"left\" valign=\"middle\">Instructor Initials ST-DETTA-FULL</th>\n</tr>\n</thead>\n<tbody>";

		my $responseDataArr= $responseData->{'s:Body'}{GetAttendanceRecordResponse}{GetAttendanceRecordResult}{'a:Modules'}{'a:Module_Info'};
		#print Dumper($responseDataArr);
		my @arrData=@$responseDataArr;
		my $noOfRecords = @arrData;	
		my $counter = 0;
		my $dataHash;
		my $topicHtml = '';
		my $totalModuleScore = 0;
		for (my $i=0;$i<$noOfRecords;$i++){
			$dataHash=$arrData[$i];
			$counter++;
			foreach my $field(keys %$dataHash){
				my $fieldData=$dataHash->{$field};
				if(ref($fieldData) eq "HASH"){
					#$arrData[$i]->{$field}='';
				}
			}
			$success = 1;
			my $moduleId = $arrData[$i]->{'a:ModuleID'};
			my $moduleTitle = $arrData[$i]->{'a:ModuleTitle'};
			my $moduleDuration = $arrData[$i]->{'a:ModuleDuration'};
			my $moduleDurationHours = int($moduleDuration/60);
			$moduleDurationHours = (length($moduleDurationHours) eq '1') ? "0$moduleDurationHours" : $moduleDurationHours;
			my $moduleDurationMin = $moduleDuration%60;
			$moduleDurationMin = (length($moduleDurationMin) eq '1') ? "0$moduleDurationMin" : $moduleDurationMin;
			my $moduleDurationFormatted = "$moduleDurationHours:$moduleDurationMin:00";

			my $moduleEndDate = $API->getFormattedDate(2,$arrData[$i]->{'a:ModuleEndDate'});
			my @moduleEndDateArr = split(/\s+/, $moduleEndDate);
			my ($moduleEndYear, $moduleEndMon, $moduleEndDay) = split(/\-/, $moduleEndDateArr[0]);
			my $makeUpDate = "$moduleEndMon/$moduleEndDay/$moduleEndYear";
			my $moduleScore = $arrData[$i]->{'a:Scores'}->{'i:nil'};

			#my $finalScore = '88%';
			#my $testResult = 'P';
			#if($moduleTitle =~ /Final Exam/ig) {
				#$testResult = $finalScore;
			#}
			my $testScores = $arrData[$i]->{'a:Scores'};
			my $hashSize = keys %$testScores;
			my($topic_id,$module_score,$topic_title);
				if($hashSize >= 1) {
					foreach my $key(keys %$testScores){
						my @tmp_arr = $testScores->{$key};	
						my $length = $tmp_arr[0];
						if (ref($length) eq "HASH") {
							$topic_id = $tmp_arr[0]->{'a:TopicId'}{'i:nil'};
							$module_score = $tmp_arr[0]->{'a:ModuleTestScore'};
							$topic_title = $tmp_arr[0]->{'a:TopicTitle'}{'i:nil'};
							$totalModuleScore +=$module_score;
						}
					}
				}
				my $averageGradePerModule = sprintf('%.2f',($totalModuleScore/32));;
				$html .="<tr><td height=\"30\" valign=\"middle\">$counter</td><td valign=\"middle\">$moduleEndDate</td><td valign=\"middle\">$moduleDurationFormatted</td><td valign=\"middle\">$module_score/100</td><td valign=\"middle\">$makeUpDate</td><td valign=\"middle\">&nbsp;<img src=\"http://printer02.idrivesafely.com/.download/DE/TX/instructors/je-small.jpg\" height=\"30\" width=\"80\"></td></tr>\n";
				if($counter == 32) { $html .="</tbody></table></td></tr>\n";}
				my $topicInfo = $arrData[$i]->{'a:TopicInfo'};
				my $topicInfoHashSize = keys %$topicInfo;
				my $timeEarned = $timeEarnedHash->{$counter};
				$topicHtml .= "<tr>\n<td height=\"30\" align=\"left\" valign=\"top\">$moduleTitle</td>\n<td align=\"left\" valign=\"top\">$timeEarned</td>"; 
				my $moduleChapters = '';
				if($topicInfoHashSize >= 1) {
					foreach my $key(keys %$topicInfo) {
						my @tmp_arr = $topicInfo->{$key};
						my $length = $tmp_arr[0];
						if (ref($length) eq "HASH") {
							##Nothing to do
						} else {
							my $k=1;
							foreach my $key(@$length){
								$topic_id = $key->{'a:TopicId'}{'i:nil'};
								$topic_title = $key->{'a:TopicTitle'};
								#$moduleChapters .= "$topic_title<br>";
								$moduleChapters .= "$topic_title, ";
								$k++;
							}
						}
					}
				}
				$topicHtml .= "<td align=\"left\" valign=\"top\">$moduleChapters</td>\n</tr>";
				#if($i eq '0') { last; }

				if($counter==32) {
					##After the first table TOC is printed
					$html .= "<tr><td>&nbsp;</td></tr>\n<tr>\n<td><strong>Total Hours of Phase 1 Earned: $totalDuration </strong></td>\n</tr>\n<tr>\n<td><strong>Average Completion Grade Earned: $averageGradePerModule%</strong></td>\n</tr>\n<tr>\n<td><strong>Start Date: $courseStartDate<strong></td>\n</tr>\n<tr>\n<td><strong>End Date: $courseEndDate</strong></td>\n</tr>\n</table></td>\n</tr>\n<tr>\n<td>&nbsp;</td>\n</tr>\n<tr>\n<td><table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">\n<tr>\n<td><strong>Signature of Student:</strong><br />\nHereby my signature, I certify that the information I have completed on this record are true and correct to my knowledge.</td>\n</tr>\n<tr><td>&nbsp;</td></tr>\n<tr>\n<td><table width=\"100%\" border=\"1\" cellspacing=\"0\" cellpadding=\"0\">\n<thead>\n<tr>\n<th align=\"left\">Lic#</th>\n<th align=\"left\">Certified</th>\n<th align=\"left\">Printed Name of Instructor</th>\n<th align=\"left\">Instructor Signature</th>\n<th align=\"left\">Initials</th>\n</tr>\n</thead>\n";
					$html .="<tbody>\n<tr>\n<td height=\"30\" align=\"left\" valign=\"middle\">4433</td>\n<td align=\"left\" valign=\"middle\">DET</td>\n<td align=\"left\" valign=\"middle\">Julio Esparza</td>\n<td align=\"left\" valign=\"middle\">&nbsp;<img src=\"http://printer02.idrivesafely.com/.download/DE/TX/instructors/je-big.jpg\" height=\"50\" width=\"170\"></td>\n<td align=\"left\"valign=\"middle\">&nbsp;<img src=\"http://printer02.idrivesafely.com/.download/DE/TX/instructors/je-small.jpg\" height=\"30\" width=\"80\"></td>\n</tr></tbody>\n</table>\n</td></tr>\n</table></td>\n</tr>\n<tr>\n<td>&nbsp;</td>\n</tr>\n<tr>\n<td><table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">\n<tr>\n<td><strong>Teacher of Record</strong><br />By my signature, I certify that I am responsible for all classroom Instruction RECORDED ON THIS FORM and TAUGHT by the TA-Full Instructors on this document, Further, I am responsible for the issuance of the completion certificates for this student, and the maintenance of the DE-964 form and all records surrounding this course, in compliance with law and rule in the state of Texas.</td>\n</tr>\n<tr><td>&nbsp;</td></tr>\n<tr>\n<td><table width=\"100%\" border=\"1\" cellspacing=\"0\" cellpadding=\"0\">\n<thead>\n<tr>\n<th align=\"left\">Lic#</th>\n<th align=\"left\">Certified</th>\n<th align=\"left\">Printed Name of Instructor</th>\n<th align=\"left\">Instructor Signature</th>\n<th align=\"left\">Initials</th>\n</tr>\n</thead>\n<tbody>\n<tr>\n<td height=\"30\" align=\"left\" valign=\"middle\">6541</td>\n<td align=\"left\" valign=\"middle\">ST-DET</td>\n<td align=\"left\"valign=\"middle\">Michael Black</td>\n<td align=\"left\" valign=\"middle\">&nbsp; <img src=\"http://printer02.idrivesafely.com/.download/DE/TX/instructors/mb-big.jpg\" height=\"50\" width=\"170\"> </td>\n<td align=\"left\" valign=\"middle\">&nbsp;<img src=\"http://printer02.idrivesafely.com/.download/DE/TX/instructors/mb-small.jpg\" height=\"30\" width=\"80\"></td>\n</tr></tbody>\n</table>\n</td></tr>\n<tr><td>&nbsp;</td></tr>\n<tr>\n<td><b>Texas Driver Education Program of Organized Instruction</b><br><br><table width=\"100%\"border=\"1\" cellspacing=\"0\" cellpadding=\"0\">\n<thead>\n<tr>\n<th align=\"left\">Texas Teen Driver Education Online Course</th>\n<th align=\"left\">Unit Time</th>\n<th align=\"left\">POI Instruction(Topics)</th>\n</tr>\n</thead>\n<tbody>\n";
					$html .= $topicHtml
				}
		}
		$html .="</td></tr>\n</table>\n</td>\n</tr>\n<tr>\n<td>&nbsp;</td>\n</tr>\n</table>\n";
	} else {
		my $API =Printing::DriversEd->new;
		$API->{PRODUCT}='DRIVERSED';
		$API->constructor;
		my $content = $objResponse->error_as_HTML;
		$API->dbPutXMLData($schoolId, $courseId,$content);
	}

	if($success) {
		my $API =Printing::DriversEd->new;
		$API->{PRODUCT}='DRIVERSED';
		$API->constructor;
		$API->dbPutAdminComments($de_cert_data_id, 'TEEN32_STUDENT_LOG_PRINTED','Printed the DE TX Teen32 Student Log');
		$API->putCookie($de_cert_data_id, { "TXTEEN_STUDENTLOG_PRINTED" => time()});

		##Ready with the attenance html to pdf conversion
		my $fileName = "$de_cert_data_id-".time();
		my $htmlFileName = "/tmp/$fileName.html";
		open (OUT,">$htmlFileName");
		print OUT $html;
		close OUT;

		##HTML Done, convert to PDF
		my $pdfCoverFileName = "/tmp/$fileName.pdf";
		my $cmd = <<CMD;
/usr/bin/htmldoc -f $pdfCoverFileName --size letter --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 $htmlFileName
CMD
		$ENV{TMPDIR}='/tmp/';
		$ENV{HTMLDOC_NOCGI}=1;
		system($cmd);
		unlink($htmlFileName); ##Delete the html file
		return $pdfCoverFileName;
	} else {
		return 0;
	}
}

1;
