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
use lib qw(/ids/tools/PRINTING/lib);

package Printing;
use Fedex;
use Settings;
use strict;

use DBI;
use Symbol;
#use DBD::Oracle qw(:ora_types);
use DBD::mysql qw(:ora_types);
use IO::Socket;
use MIME::Lite;
use MIME::Base64;
use Data::Dumper;
my $VERSION = 0.5;

=head1 NAME

Printing

=head1 Synopsis

This module will be the base class for all printing systems.  All children will derive from this base class
(this class should never be instantiated)

=head1 METHODS

=head2 new

=cut

sub new
{
   
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self = {    CRM_CON =>   { DB => $printerSite::CRM_DATABASE, HOST=>$printerSite::CRM_DATABASE_HOST, USERNAME => $printerSite::CRM_DATABASE_USER, PASSWORD => $printerSite::CRM_DATABASE_PASSWORD },
                    @_,
               };
    
    bless($self, $class);
    return $self;
}


sub constructor
{
	####### get all of the delivery constants from the database
   my $self = shift;
}


=head2 getCompleteUsers

=cut

sub getCompleteUsers
{
	my $self = shift;

	###### pretty pointless right now as eventually this function will be overwritten.
	return 1;
}

=head2 getUserData

=cut

sub getUserData
{
        my $self = shift;

        my($userId)=@_;

        ###### pretty pointless right now as eventually this function will be overwritten.
        return 1;
}

=pod

=head2 getNextCertificateNumber

Most of the certificate numbers will follow this basic format:
course_id : user id   Each derived class may or may not redeclare this class to format
for it's particular site

=cut

=head2 getUserContact

=cut 
sub getUserContact
{
    my $self        = shift;
    my ($userId)    = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM");
select USER_ID,PHONE,EMAIL,sf_decrypt(ADDRESS_1) as ADDRESS_1,sf_decrypt(ADDRESS_2) as ADDRESS_2,sf_decrypt(CITY) as CITY,sf_decrypt(STATE) as STATE,sf_decrypt(ZIP) as ZIP,sf_decrypt(FIRST_NAME) as FIRST_NAME,sf_decrypt(LAST_NAME) as LAST_NAME,SEX,date_format(sf_decrypt(DATE_OF_BIRTH),'%m/%d/%Y') as DATE_OF_BIRTH,REGISTRATION_DATE from user_contact where user_id = ?
EOM
    $sql->execute($userId);
    my $retval = $sql->fetchrow_hashref;
    $sql->finish;

    return $retval;
}

sub getUserInfo{
    my $self=shift;
    my($userId) = @_;
    my $sth =  $self->{PRODUCT_CON}->prepare("select USER_ID,sf_decrypt(DRIVERS_LICENSE) as DRIVERS_LICENSE,LOGIN_DATE,COURSE_ID,REGULATOR_ID,TEST_INFO,COMPLETION_DATE,date_format(COMPLETION_DATE,'%m/%d/%Y') as COMPLETIONDATE, PRINT_DATE,PASSWORD,CERTIFICATE_NUMBER from user_info ui where ui.user_id = ?");
    $sth->execute($userId);
    my $tmpHash = $sth->fetchrow_hashref;
    $sth->finish;
    return $tmpHash;
}

       
sub getNextCertificateNumber
{
    ### ..slurp the class name
    my $self = shift;

    my ($userId, $courseId) = @_;
    if (! $courseId)
    {
        $courseId = $self->getUserCourseId($userId);
    }

    return ($courseId . ':' . $userId);
}

sub getCertificateCount {
    my $self=shift;
    my($cid) = @_;
    return  $self->{PRODUCT_CON}->selectrow_array('select count(*) from certificate where course_id = ?', {}, $cid);
}


#########################################################
##### add all of the accompany letter functionality
#########################################################

=head2 getAccompanyLetterUsers

Return a list of all users who need accompany letters. 
This is a base class and will be overwritten based on product

=cut

sub getAccompanyLetterUsers
{
    my $self = shift;
    
    ##### this class will be overwritten.  return nothing
    return;
}


=head2 putAccompanyLetterUsers

Add a user to the accompany letter queue

=cut

sub putAccompanyLetterUser
{
    my $self = shift;

    return ;
}


=head2 putAccompanyLetterUserPrint

Set the print date for a user's accompany letter

=cut

sub putAccompanyLetterUserPrint
{
    my $self = shift;
    return ;
}

sub putAdminComment{
    my $self = shift;
    my($userRef) = @_;
    my $sth = $self->{PRODUCT_CON}->prepare("insert into user_admin_comments (user_id, support_operator, comments, comment_date)
                                   values (?, ?, ?, sysdate())");
    $sth->execute($$userRef{USER_ID}, $$userRef{SUPPORT_OPERATOR}, $$userRef{COMMENTS});
}


sub pdbGetShippingRecord
{
    my $self = shift;
    my($shippingId, $trackingNumber) = @_;
    my $sth;

    if ($trackingNumber)
    {
        $sth = $self->{PRODUCT_CON}->prepare("select SHIPPING_ID, sf_decrypt(NAME) as NAME, sf_decrypt(ADDRESS) as ADDRESS, sf_decrypt(CITY) as CITY, sf_decrypt(STATE) as STATE, sf_decrypt(ZIP) as ZIP, PHONE, sf_decrypt(DESCRIPTION) as DESCRIPTION, DELIVERY_ID,
                                       sf_decrypt(ATTENTION) as ATTENTION, date_format(PRINT_DATE, '%d-%b-%Y %H:%i') as PRINT_DATE, PRINT_CATEGORY_ID,
                                       AIRBILL_NUMBER from shipping_address where airbill_number = ?");
        $sth->execute($trackingNumber);
    }
    else
    {
        $sth = $self->{PRODUCT_CON}->prepare("select SHIPPING_ID, sf_decrypt(NAME) as NAME, sf_decrypt(ADDRESS) as ADDRESS, sf_decrypt(CITY) as CITY, sf_decrypt(STATE) as STATE, sf_decrypt(ZIP) as ZIP, PHONE, sf_decrypt(DESCRIPTION) as DESCRIPTION, DELIVERY_ID,
                                       sf_decrypt(ATTENTION) as ATTENTION, date_format(PRINT_DATE, '%d-%b-%Y %H:%i') as PRINT_DATE, PRINT_CATEGORY_ID,
                                       AIRBILL_NUMBER from shipping_address where shipping_id = ?");
        $sth->execute($shippingId);
    }
    my $tmpHash = $sth->fetchrow_hashref;
    $sth->finish;
    return $tmpHash;
}

sub updatePrintDate
{
	my $self = shift;
        my ($userID, $certNum) = @_;

        my $sth;
        if(defined $certNum && $certNum) {
                $self->{PRODUCT_CON}->do('update user_info set print_date = sysdate(), certificate_number = ? where user_id = ?', {}, $certNum, $userID);
        } 
	else 
	{
                $self->{PRODUCT_CON}->do('update user_info set print_date = sysdate() where user_id = ?', {}, $userID);
        }
}


=head2 getAllHostedAffiliateCourses

return a list of all hosted affiliate courses and their vendor tags

=cut


sub getAllHostedAffiliateCourses
{
    my $self = shift;
    my $retval;

    ##### Have we already gotten a list of courses yet?  
    ##### If so, return them
    if ($self->{HOSTED_AFFILIATE_COURSES})
    {
        return $self->{HOSTED_AFFILIATE_COURSES};
    }

    ##### ASSERT:  The HOSTED_AFFILIATE_COURSES hash has not been filled in yet.  Let's query the 
    ##### database and fill in our object so every time we need the list we don't have to query the 
    ##### database and save some precious seconds
    my $sth = $self->{PRODUCT_CON}->prepare("select course_id, value from course_attribute where attribute='HOSTED_AFFILIATE'");
    $sth->execute;

    while (my ($courseId, $vendorTag) = $sth->fetchrow)
    {
        $self->{HOSTED_AFFILIATE_COURSES}->{$courseId} = $vendorTag;
    }

    ##### return the list
    return $self->{HOSTED_AFFILIATE_COURSES};
}


=head2 getAllFleetCourses

return a list of all fleet courses and their vendor tags

=cut


sub getAllFleetCourses
{
    my $self = shift;
    my $retval;

    ##### Have we already gotten a list of courses yet?  
    ##### If so, return them
    if ($self->{FLEET_COURSES})
    {
        return $self->{FLEET_COURSES};
    }

    ##### ASSERT:  The FLEET_COURSES hash has not been filled in yet.  Let's query the 
    ##### database and fill in our object so every time we need the list we don't have to query the 
    ##### database and save some precious seconds
    my $sth = $self->{PRODUCT_CON}->prepare("select course_id, state from course where state='FC'");
    $sth->execute;

    while (my ($courseId, $vendorTag) = $sth->fetchrow)
    {
        $self->{FLEET_COURSES}->{$courseId} = $vendorTag;
    }

    ##### return the list
    return $self->{FLEET_COURSES};
}

sub _getUserCourseId
{
    my $self = shift;
    my ($userId) = @_;

    return $self->{PRODUCT_CON}->selectrow_array("select course_id from user_info where user_id = ?",{}, $userId);
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


=head2 getAllClassroomCourses

return a list of all classroom courses and their vendor tags

=cut


sub getAllClassroomCourses
{
    my $self = shift;
    my $retval;

    ##### Have we already gotten a list of courses yet?  
    ##### If so, return them
    if ($self->{CLASSROOM_COURSES})
    {
        return $self->{CLASSROOM_COURSES};
    }

    ##### ASSERT:  The CLASSROOM_COURSES hash has not been filled in yet.  Let's query the 
    ##### database and fill in our object so every time we need the list we don't have to query the 
    ##### database and save some precious seconds
    my $sth = $self->{PRODUCT_CON}->prepare("select course_id, value from course_attribute where attribute='CLASSROOM'");
    $sth->execute;

    while (my ($courseId, $state) = $sth->fetchrow)
    {
        $self->{CLASSROOM_COURSES}->{$courseId} = $state;
    }

    ##### return the list
    return $self->{CLASSROOM_COURSES};
}


=head2 getUserShipping

=cut

sub getUserShipping
{
    my $self        = shift;
    my ($userId)    = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM"); 
SELECT SA.SHIPPING_ID, sf_decrypt(SA.NAME) as NAME, sf_decrypt(SA.ADDRESS) as ADDRESS, sf_decrypt(SA.ADDRESS_2) as ADDRESS_2, sf_decrypt(SA.CITY) as CITY, sf_decrypt(SA.STATE) as STATE, sf_decrypt(SA.ZIP) as ZIP, SA.PHONE, sf_decrypt(SA.DESCRIPTION) as DESCRIPTION, SA.DELIVERY_ID,sf_decrypt(SA.ATTENTION) as ATTENTION, SA.SIGNATURE, DATE_FORMAT(SA.PRINT_DATE, '%d-%b-%Y %H:%i') as PRINT_DATE, SA.PRINT_CATEGORY_ID, SA.AIRBILL_NUMBER FROM user_shipping US, shipping_address SA WHERE US.USER_ID = ? AND US.SHIPPING_ID = SA.SHIPPING_ID
EOM

    $sql->execute($userId);
    my $retval = $sql->fetchrow_hashref;
    $sql->finish;

    return $retval;
}

sub insertShippingAddress { ########################################################################################################
    my $self = shift;
    my ($DATA) = @_;
    my $shippingID = 0;

        if(!defined $$DATA{PRINTCATEGORYID} || !exists $$DATA{PRINTCATEGORYID}) {
                $$DATA{PRINTCATEGORYID} = 1;
        }
	my $userId = 0;
	if (defined $$DATA{USERID} && $$DATA{USERID}) {
		$userId = $$DATA{USERID};
	}
	$$DATA{DELIVERYID} = ($$DATA{DELIVERYID}) ? $$DATA{DELIVERYID} : $$DATA{DELIVERY_ID};
        $shippingID=$self->updateShippingAddress($shippingID,$$DATA{NAME},$$DATA{ADDRESS},'',$$DATA{CITY},$$DATA{STATE},$$DATA{ZIP},$$DATA{PHONE},$$DATA{DESCRIPTION},$$DATA{ATTENTION},'',$userId,$$DATA{DELIVERYID},$$DATA{SIGNATURE},$$DATA{PRINTCATEGORYID},$$DATA{OFFICEID},0);
        return $shippingID;
} ### end sub insertShippingAddress()

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

                $self->{PRODUCT_CON}->do("INSERT INTO shipping_address (SHIPPING_ID, NAME, ADDRESS, ADDRESS_2, CITY, STATE, ZIP, PHONE, DESCRIPTION, ATTENTION, ADDITIONAL_NOTES, SIGNATURE, DELIVERY_ID, PRINT_CATEGORY_ID, OFFICE_ID, TYPE)
                           VALUES (?, sf_encrypt(?), sf_encrypt(?), sf_encrypt(?), sf_encrypt(?), sf_encrypt(?), sf_encrypt(?), ?, sf_encrypt(?), sf_encrypt(?), ?, ?, ?, ?, ?, ?)",
                           {}, $NEWsHIPPING_ID, $NAME, $ADDRESS, $ADDRESS_2, $CITY, $STATE, $ZIP, $PHONE, $DESCRIPTION, $ATTENTION, $ADDITIONAL_NOTES, $SIGNATURE, $DELIVERY_ID, $PRINT_CATEGORY, $OFFICEID, $TYPE);

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
                   SET NAME = sf_encrypt(?), ADDRESS = sf_encrypt(?), ADDRESS_2 = sf_encrypt(?),CITY = sf_encrypt(?),STATE = sf_encrypt(?),
                           ZIP = sf_encrypt(?), PHONE = ?, DESCRIPTION = sf_encrypt(?), ATTENTION = sf_encrypt(?),
                           ADDITIONAL_NOTES = ?, SIGNATURE = ? WHERE SHIPPING_ID = ?", {}, $NAME, $ADDRESS, $ADDRESS_2, $CITY, $STATE, $ZIP, $PHONE, $DESCRIPTION, $ATTENTION, $ADDITIONAL_NOTES, $SIGNATURE, $SHIPPING_ID);
                }else{
                   $self->{PRODUCT_CON}->do("UPDATE shipping_address
                   SET NAME = sf_encrypt(?), ADDRESS = sf_encrypt(?), ADDRESS_2 = sf_encrypt(?),CITY = sf_encrypt(?),STATE = sf_decrypt(?),
                           ZIP = sf_decrypt(?), PHONE = ?, DESCRIPTION = sf_encrypt(?),ATTENTION = sf_encrypt(?),
                           ADDITIONAL_NOTES = ?,SIGNATURE = ?,DELIVERY_ID = ? WHERE SHIPPING_ID = ?",
                           {}, $NAME, $ADDRESS, $ADDRESS_2, $CITY, $STATE, $ZIP, $PHONE, $DESCRIPTION, $ATTENTION, $ADDITIONAL_NOTES, $SIGNATURE, $DELIVERY_ID, $SHIPPING_ID)
               }
         }
    return $SHIPPING_ID;
}

sub addSTCshippingRecord{ ########################################################################################################
        my $self=shift;
        my ($TRACKINGNUMBER, $USERIDS) = @_;

        my $SHIPPINGID=$self->{PRODUCT_CON}->selectrow_array("SELECT SHIPPING_ID  FROM shipping_address WHERE AIRBILL_NUMBER = ?", {}, $TRACKINGNUMBER);

        for my $userID(@$USERIDS) {
                my $count=$self->{PRODUCT_CON}->selectrow_array("SELECT COUNT(USER_ID) FROM user_shipping WHERE USER_ID = ?", {},$userID);
                if(! $count)
                {
                        $self->{PRODUCT_CON}->do("INSERT INTO user_shipping (USER_ID, SHIPPING_ID) VALUES (?, ?)", {},$userID, $SHIPPINGID);
                }
                else
                {
                        $self->{PRODUCT_CON}->do("UPDATE user_shipping SET SHIPPING_ID = ? WHERE USER_ID = ?", {}, $SHIPPINGID, $userID);
                }
        }
}


=head2 printFedexLabel

=cut

sub printFedexLabel
{
        my $self = shift;
        my ($userId, $priority, $printerKey,$webService,$file,$trackingNumber,$segmentName) = @_;
        my %tmpHash;
        ###### let's get user's shipping data
	$printerKey=($printerKey)?$printerKey:'CA';
	##https://driversed.atlassian.net/browse/IDS-268
	##User paid for premium delivery after the certificate is printed
	my $userCertCheck = $self->{PRODUCT_CON}->selectrow_array("SELECT COUNT(USER_ID) FROM user_cert_verification WHERE USER_ID = ?", {},$userId);
	my $userShippingCheck = $self->{PRODUCT_CON}->selectrow_array("SELECT COUNT(USER_ID) FROM user_shipping WHERE USER_ID = ?", {},$userId);
	if($userCertCheck && $userShippingCheck == 0) {
        	my $userContact = $self->getUserContact($userId);
		my $userCookie = $self->getCookie($userId,['SIGNATURE', 'ATTENTION', 'DELIVER_TO_NEW']);
		my %data;
		$data{NAME} = "$$userContact{FIRST_NAME} $$userContact{LAST_NAME}";
		$data{ADDRESS} = "$$userContact{ADDRESS_1} $$userContact{ADDRESS_2}";
		$data{CITY} = $$userContact{CITY};
		$data{STATE} = $$userContact{STATE};
		$data{ZIP} = $$userContact{ZIP};
		$data{PHONE} = $$userContact{PHONE};
		my $deliveryId = $self->{PRODUCT_CON}->selectrow_array("SELECT DELIVERY_ID FROM user_delivery WHERE USER_ID = ?", {}, $userId);
		my $uData=$self->getUserData($userId);
		if($uData->{UPSELLMAILFEDEXOVA}) { ##Jira: IDSUIUX-243
			if($self->{PRODUCT} eq 'DIP') {
			 	$deliveryId = 11;
			} elsif($self->{PRODUCT} eq 'TEEN') {
			 	$deliveryId = 4;
			}
		}
		$data{DELIVERY_ID} = $deliveryId;
		if(defined $userCookie->{SIGNATURE}){
			$data{SIGNATURE} = $userCookie->{SIGNATURE};
		}
		if(defined $userCookie->{ATTENTION}){
			$data{ATTENTION} = $userCookie->{ATTENTION};
		}
		$data{DESCRIPTION} = "CERT FOR - $data{NAME}";
		$data{USERID} = $userId;
		my $shippingId = $self->insertShippingAddress(\%data);
	}

        my $shippingData = $self->getUserShipping($userId);
	my $courseState=$self->getUserState($userId,'COURSE');
        $shippingData->{DESCRIPTION} = "CERT FOR - $userId";

        ###### create the fedex object, sending in the printer key
        my $segName=$self->{PRODUCT};
	if($segmentName){
		$segName=$segmentName;
	}
        my $fedexObj = Fedex->new($segName);
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

=head2 printFedexLabel

=cut

sub printUSPSLabel
{
        my $self = shift;
        my ($userId, $priority, $printerKey,$webService,$file,$trackingNumber) = @_;
        my %tmpHash;
        ###### let's get user's shipping data
        $printerKey=($printerKey)?$printerKey:'CA';
        my $shippingData = $self->getUserShipping($userId);
        my $courseState=$self->getUserState($userId,'COURSE');
        $shippingData->{DESCRIPTION} = "CERT FOR - $userId";

        ###### create the fedex object, sending in the printer key
        my $fedexObj = Fedex->new($self->{PRODUCT});
        $fedexObj->{PRINTERS}=$self->{PRINTERS};
        $fedexObj->{PRINTING_STATE}=$courseState;
        $fedexObj->{PRINTING_TYPE}='CERTFEDX';
        $fedexObj->{PRINTER_KEY}=$printerKey;

        my $reply= $fedexObj->printUSPSLabel( $shippingData, (($priority) ? $priority : 1 ),'','',$file,$trackingNumber);
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


sub pRegulatorFedexPrint
{
        my $self=shift;
        my ($regulatorId, $delType,$CERTCOUNT,$affiliateId) = @_;
        my $PRIORITY = 1;         my $certStr = ($CERTCOUNT - 1) ? "Certificate of Completion ($CERTCOUNT Certs)" : "Certificate of Completion (1 Cert)";
        my $data =$self->getRegulatorShippingAddress($regulatorId);
        $data->{DESCRIPTION}=$certStr;
        $data->{DELIVERY_ID}=$delType;
        my $fedexObj = Fedex->new($self->{PRODUCT});
	$fedexObj->{PRINTING_STATE}=$data->{STATE};
        $fedexObj->{PRINTING_TYPE}='CERTFEDX';
	$fedexObj->{PRINTERS}=$self->{PRINTERS};

        my $reply= $fedexObj->printLabel($data, $PRIORITY,$affiliateId);

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
                {
                        my $shippingId=$self->insertShippingAddress($data);
			$self->putUserShipping($shippingId, $reply);
                }
        }
        return \%$reply;
}

sub pNonUserFedexLabelPrint{ #########################################################################################################
        my $self=shift;
        my ($data,$dupl) = @_;
        my $PRIORITY = 1;
        my $printerKey=$data->{PRINTER_KEY};
        $printerKey=($printerKey)?$printerKey:'CA';
	if($data->{PRODUCT_ID} && $data->{PRODUCT_ID} eq 'DRIVERSED') {
		$self->{PRODUCT} = $data->{PRODUCT_ID};
	}
        my $fedexObj = Fedex->new($self->{PRODUCT});
	$fedexObj->{PRINTERS}=$self->{PRINTERS};
	$fedexObj->{PRINTER_KEY}=$printerKey;
	$fedexObj->{PRINTING_STATE}=($data->{PRINTING_STATE})?$data->{PRINTING_STATE}:$self->{PRINTING_STATE};
	$fedexObj->{PRINTING_TYPE}=($data->{PRINTING_TYPE})?$data->{PRINTING_TYPE}:$self->{PRINTING_TYPE};
	my $reply;
	if($data->{DELIVERY_ID} && ($data->{DELIVERY_ID} eq '22' || $data->{DELIVERY_ID} eq '23' || $data->{DELIVERY_ID} eq '27')){
        	$reply= $fedexObj->printUSPSLabel($data, $PRIORITY);
	}else{
        	$reply= $fedexObj->printLabel($data, $PRIORITY);
	}
        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER' && $self->{PRODUCT} ne 'DRIVERSED')
                {
			if($dupl eq 'DUPLICATE' || $dupl eq 'WORKBOOK' || $dupl eq 'DISK'){
				$self->putUserShipping($data->{SHIPPING_ID}, $reply);
			}else{
	                        my $shippingId=$self->insertShippingAddress($data);
				$self->putUserShipping($shippingId, $reply);
			}
                }
        }
        return \%$reply;
}
sub pReprintFedexLabel{ ############################################################################################################
        my $self=shift;
        my ($USERID, $TRACKINGNUMBER, $PRIORITY, $OFFICEID) = @_;

        if($USERID ne '0') {
                $TRACKINGNUMBER = $self->{PRODUCT_CON}->selectrow_array("select s.airbill_number from shipping_address s, user_shipping u where u.user_id = ? and s.shipping_id = u.shipping_id", {}, $USERID);
        }
	my $uData=$self->getUserData($USERID);
        if(defined $TRACKINGNUMBER && $TRACKINGNUMBER) {
                if(!defined $PRIORITY || !$PRIORITY) {
                        $PRIORITY = 1;
                }
                my $fedexObj = Fedex->new($self->{PRODUCT});
		$fedexObj->{PRINTERS}=$self->{PRINTERS};
		$fedexObj->{PRINTING_TYPE}='CERTFEDX';
		$fedexObj->{PRINTING_STATE}=$uData->{COURSE_STATE};
                my $reply= $fedexObj->reprintLabel($TRACKINGNUMBER, $PRIORITY);
                return 1;
        } else {
                return 0;
        }
} 

sub pReprintUSPSLabel{ ############################################################################################################
        my $self=shift;
        my ($USERID, $TRACKINGNUMBER, $PRIORITY, $OFFICEID) = @_;

        if($USERID ne '0') {
                $TRACKINGNUMBER = $self->{PRODUCT_CON}->selectrow_array("select s.airbill_number from shipping_address s, user_shipping u where u.user_id = ? and s.shipping_id = u.shipping_id", {}, $USERID);
        }
        my $uData=$self->getUserData($USERID);
        if(defined $TRACKINGNUMBER && $TRACKINGNUMBER) {
                if(!defined $PRIORITY || !$PRIORITY) {
                        $PRIORITY = 1;
                }
                my $fedexObj = Fedex->new($self->{PRODUCT});
                $fedexObj->{PRINTERS}=$self->{PRINTERS};
                $fedexObj->{PRINTING_TYPE}='CERTFEDX';
                $fedexObj->{PRINTING_STATE}=$uData->{COURSE_STATE};
                my $reply= $fedexObj->$self->_printUSPSMailLabel($TRACKINGNUMBER, $PRIORITY);
                return 1;
        } else {
                return 0;
        }
}

=head2 getUserCertDuplicateData

=cut
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
        $sth = $self->{PRODUCT_CON}->prepare("select param, sf_decrypt(value) from user_cert_duplicate_data where duplicate_id = ?");
        $sth->execute($duplicateId);

        while (my ($v1, $v2) = $sth->fetchrow)
        {
            $retval->{DATA}->{$v1} = uc($v2);
            if ($v1 eq 'REGULATOR_ID')
            {
                    $retval->{DATA}->{REGULATOR_DEF} = $self->getRegulatorDef($v2);
            }
	    if($v1 eq 'DELIVERY_ID' || $v1 eq 'SHIPPING_ID'){
		$retval->{$v1}=$v2;
	    }
	    if($v1 eq 'DATE_OF_BIRTH') {
		my ($d, $m, $y) = split(/\-/, $v2); 
		my $mm = $self->{SETTINGS}->{MONTH_NUM}->{uc $m};
		$retval->{DATA}->{DOBFORMATTED} = "$mm/$d/$y";
	    }
        }
    	$retval->{DATA}->{CERTIFICATE_NUMBER} = $retval->{CERTIFICATE_REPLACED};
    	if($retval->{DATA}->{LAST_DUPLICATE_ID}){
                my $lastDuplicateId=$retval->{DATA}->{LAST_DUPLICATE_ID};
                $duplicateId=$lastDuplicateId;
                while($lastDuplicateId){
                        $lastDuplicateId=$self->{PRODUCT_CON}->selectrow_array("select  sf_decrypt(value) from user_cert_duplicate_data where duplicate_id = ? and param = ?",{},$duplicateId,'LAST_DUPLICATE_ID');
                        if($lastDuplicateId){
                                $duplicateId=$lastDuplicateId;
                        }
                }
		$sth = $self->{PRODUCT_CON}->prepare("select param, sf_decrypt(value) from user_cert_duplicate_data where duplicate_id = ?");
	        $sth->execute($duplicateId);

        	while (my ($v1, $v2) = $sth->fetchrow)
        	{
		    unless ($v1 eq 'DUPLICATE_ID' || $v1 eq 'SHIPPING_ID' || $v1 eq 'DELIVERY_ID')
            	    { 
	            	$retval->{DATA}->{$v1} = uc($v2);
	        	    if ($v1 eq 'REGULATOR_ID')
        	    	   {
                	   	$retval->{DATA}->{REGULATOR_DEF} = $self->getRegulatorDef($v2);
            		   }
			   ##RT #15936, At Classroom REGULATOR_ID is String, not numerical value.
			   if($v1 eq 'REGULATOR_ID' && !$retval->{REGULATOR_DEF} && $v2 && int($v2) == 0) {
                	   	$retval->{DATA}->{REGULATOR_DEF} = $v2;
			   }
		    }
        	}

       } 

    }
    $retval->{REGULATOR_ID} = $userInfo->{REGULATOR_ID};
    $retval->{REGULATOR_DEF} = $self->getRegulatorDef($userInfo->{REGULATOR_ID});

    ####### now, one last set of checks.  let's check the table user_cert_duplicate table to see if this user
    ####### has requested anything before.  if he has, make sure all of the data he's submitted previously
    ####### is in the record so we're sure we're not pulling from user_info
    my $oldDupId = $self->{PRODUCT_CON}->selectrow_array('select max(duplicate_id) from user_cert_duplicate where print_date is not null and user_id = ? and duplicate_id < ?',{},$userId, $duplicateId);

    if ($oldDupId)
    {
        ##### ok, old data exists for him.  Get all of it from the duplicate table and place it in the return hash
        $sth = $self->{PRODUCT_CON}->prepare("select param, sf_decrypt(value) from user_cert_duplicate_data where duplicate_id = ?");
        $sth->execute($oldDupId);

        while (my ($v1, $v2) = $sth->fetchrow)
        {

            unless ($v1 eq 'DUPLICATE_ID' || $v1 eq 'SHIPPING_ID' || $v1 eq 'DELIVERY_ID')
            {
                $retval->{$v1} = uc($v2);
                if ($v1 eq 'REGULATOR_ID')
                {
                        $retval->{REGULATOR_DEF} = $self->getRegulatorDef($v2);
                }
		##RT #15936, At Classroom REGULATOR_ID is String, not numerical value.
		if($v1 eq 'REGULATOR_ID' && !$retval->{REGULATOR_DEF} && $v2 && int($v2) == 0) {
                        $retval->{REGULATOR_DEF} = $v2; 
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

=head2 getCertDuplicatePrint

=cut
sub getCertDuplicatePrint
{
    my $self=shift;
    my $retval;

    my $sth=$self->{PRODUCT_CON}->prepare("select user_id, duplicate_id from user_cert_duplicate where approved='Y' and certificate_number is null and print_date is null");

    $sth->execute;
    while (my ($v1,$v2) = $sth->fetchrow)
    {
        $retval->{$v2}->{USER_ID} =$v1;
    }

    return $retval;
}

=head2 getRegulatorDef

=cut
sub getRegulatorDef {
    my $self=shift;
    my($regulatorId) = @_;
    return $self->{PRODUCT_CON}->selectrow_array('select definition from regulator where regulator_id = ?', {}, $regulatorId);
}
=head2 getUserTestCenter

=cut


sub getRegulatorShippingAddress{
    my $self = shift;
    my ($REGULATORID) = @_;
    my (%tmpHash);

        my $sth = $self->{PRODUCT_CON}->prepare("SELECT C.REGULATOR_CONTACT_ID, R.DEFINITION, IFNULL(C.CONTACT_PERSON, ''),IFNULL(C.CONTACT_TITLE, ''), IFNULL(C.DELIVERY_ATTENTION, ''), C.PHONE,C.FAX,  C.ADDRESS, C.CITY,   C.STATE,   C.ZIP,  C.SEND_TO_REGULATOR  FROM regulator_contact_info C, regulator R WHERE C.REGULATOR_CONTACT_ID = R.REGULATOR_ID AND C.REGULATOR_CONTACT_ID = ?");
        $sth->execute($REGULATORID);
        while (my (@result) = $sth->fetchrow_array) {
                $tmpHash{REGULATOR_CONTACT_ID} = uc $result[0];
                $tmpHash{NAME} = uc $result[1];
                $tmpHash{CONTACT_PERSON} = uc $result[2];
                $tmpHash{CONTACT_TITLE} = uc $result[3];
                $tmpHash{DELIVERY_ATTENTION} = uc $result[4];
                $tmpHash{PHONE} = uc $result[5];
                $tmpHash{FAX} = uc $result[6];
                $tmpHash{ADDRESS} = uc $result[7];
                $tmpHash{CITY} = uc $result[8];
                $tmpHash{STATE} = uc $result[9];
                $tmpHash{ZIP} = uc $result[10];
                $tmpHash{SEND_TO_REGULATOR} = uc $result[11];
    }
    $sth->finish;
    return \%tmpHash;
}

=head2 putUserShipping

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

=head2 getPrinters

Return a list of the printers available for printing certificates

=cut

sub getPrinters
{
	#### since this is the base class, it's pretty worthless for now   :-)
	my $self = shift;

	my ($userId, $productId) = @_;
	if(!$userId && $self->{USERID}) {
		$userId = $self->{USERID};
	}
	if(!$productId && $self->{PRODUCT}) {
		$productId = $self->{PRODUCT};
	}
	
	##### Let's see if we already have this definition.  
	if (exists $self->{PRINTERS})
	{
		return $self->{PRINTERS};
	}

	##Check whether the user has a backup printer or not.
    	my $backupPrinterCheck = $self->{CRM_CON}->selectrow_array('select count(1) from backup_printing_users where user_id = ? and product = ?', {}, $userId, $productId);

	##### let's get the fields from the database
	my $sql = $self->{CRM_CON}->prepare("select * from printing_printers_info");
	$sql->execute;

	my @courseArray;
	while (my ($printerId, $printerName, $printerDesc, $printerIp, $tray, $backupPrinterId, $backup) = $sql->fetchrow)
	{
		if(($backup && $backupPrinterId) || $backupPrinterCheck) {
			($printerId, $printerName, $printerDesc, $printerIp, $tray) = $self->{CRM_CON}->selectrow_array("select printer_id, printer_name, printer_desc, printer_ip, tray from printing_printers_info where printer_id = ?",{},$backupPrinterId);
		}
		
		$self->{PRINTERS}->{$printerId}->{PRINTER_NAME} = $printerName;
		$self->{PRINTERS}->{$printerId}->{PRINTER_IP} 	 = $printerIp;
		$self->{PRINTERS}->{$printerId}->{TRAY} 	 = $tray;
	}
	$sql->finish;
	$sql = $self->{CRM_CON}->prepare("select * from printing_course_printers");
        $sql->execute;

        while (my ($state, $printingType, $printerId, $productId) = $sql->fetchrow)
        {
		my ($backupPrinterId, $backup) = $self->{CRM_CON}->selectrow_array("select backup_printer_id, backup from printing_printers_info where printer_id = ?", {}, $printerId);
		if(($backup && $backupPrinterId) ||$backupPrinterCheck ) {
			$printerId = $backupPrinterId;
		}
                $self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$state}->{$printingType}->{PRINTIERID} = $printerId;
        }
	
	####### NOW return the printers
	return $self->{PRINTERS};
}

=head2 getRegulatorContact

Get the regulator definition.  This definition will include delivery address and any circuit court / county code
information for Fla as needed

=cut

sub getRegulatorContact
{
    my $self = shift;
    my ($regulatorId) = @_;
    my $retval;

    ##### Have we already gotten the definition for this particular regulator?
    ##### If so, return it
    if ($self->{REGULATOR_DEFS}->{$regulatorId})
    {
        return $self->{REGULATOR_DEFS}->{$regulatorId};
    }

    my $sth = $self->{PRODUCT_CON}->prepare(<<"EOM");
select definition, phone, fax, address, city, state, zip, circuit_court, county_code from regulator r, 
regulator_contact_info ri, regulator_circuit_court rcc where r.regulator_id = ? and
r.regulator_id = ri.regulator_contact_id and r.regulator_id = rcc.regulator_id (+)
EOM
  
    $sth->execute($regulatorId);

    while (my ($v1, $v2, $v3, $v4, $v5, $v6, $v7, $v8, $v9) = $sth->fetchrow)
    {
        $self->{REGULATOR_DEFS}->{$regulatorId}->{DEFINITION}       = $v1;
        $self->{REGULATOR_DEFS}->{$regulatorId}->{PHONE}            = $v2;
        $self->{REGULATOR_DEFS}->{$regulatorId}->{FAX}              = $v3;
        $self->{REGULATOR_DEFS}->{$regulatorId}->{ADDRESS}          = $v4;
        $self->{REGULATOR_DEFS}->{$regulatorId}->{CITY}             = $v5;
        $self->{REGULATOR_DEFS}->{$regulatorId}->{STATE}            = $v6;
        $self->{REGULATOR_DEFS}->{$regulatorId}->{ZIP}              = $v7;
        $self->{REGULATOR_DEFS}->{$regulatorId}->{CIRCUIT_COURT}    = $v8;
        $self->{REGULATOR_DEFS}->{$regulatorId}->{COUNTY_CODE}      = $v9;
    }

    ##### return the list
    return $self->{REGULATOR_DEFS}->{$regulatorId};
}


#########################################################################
# deal w/ the class constructor / destructor
#########################################################################
sub _dbConnect
{
    my $self = shift;

    ###### set the home environment variable for oracle
    $ENV{ORACLE_HOME} = $printerSite::SITE_ORACLEHOME;
    my $DB = $self->{SETTINGS}->{DBCONNECTION}->{$self->{PRODUCT}};
    my $MYSQLDB = $self->{SETTINGS}->{DBCONNECTION}->{CRMDB};
    my $DBH;
    my $mysqlDBH;
    if($DB->{ORACLEDB}){    

    	$DBH ||= DBI->connect("dbi:Oracle:" . $DB->{DBNAME}, $DB->{USER}, $DB->{PASSWORD});
    	if (! $DBH)         { print STDERR "Error Connecting to the database: $DB->{DBNAME} - $DBI::errstr\n";	return 0; }

    }elsif(exists $DB->{STOREPROCEDUREDB} && $DB->{STOREPROCEDUREDB}){    
	$DBH ||= DBI->connect("dbi:ODBC:$DB->{DBNAME}","$DB->{USER}","$DB->{PASSWORD}");
    	if (! $DBH)         { print STDERR "Error Connecting to the database: $DB->{DBNAME} - $DBI::errstr\n";	return 0; }


    }else{
	$DBH = DBI->connect("dbi:mysql:$DB->{DBNAME}:$DB->{HOST}",
    						$DB->{USER},
						$DB->{PASSWORD});
    	if(!$DBH)	{ print STDERR "Error Connecting to the database: $DB->{DBNAME} - $DBI::errstr\n";	return 0; }
		
    }


    
####### ok, now let's connect to the mysql db for the CRM 
    	$mysqlDBH = DBI->connect("dbi:mysql:$MYSQLDB->{DBNAME}:$MYSQLDB->{HOST}",
    						$MYSQLDB->{USER},
						$MYSQLDB->{PASSWORD});
    if(!$mysqlDBH)	{ print STDERR "Error Connecting to the database: $MYSQLDB->{DBNAME} - $DBI::errstr\n";	return 0; }
    ###### ASSERT:  We connected to both databases.  Return the connections
    $mysqlDBH->do("SET SESSION wait_timeout = 50800");
    my $retval = { 'PRODUCT_CON' => $DBH, 'CRM_CON' => $mysqlDBH};

    return $retval;
}

####### call the class dtor.  All we're going to do is disconnect from the database
sub DESTROY
{
    my $self = shift;
    if($self->{PRODUCT_CON}){
	    $self->{PRODUCT_CON}->disconnect;
    }
    if($self->{CRM_CON}){
    	$self->{CRM_CON}->disconnect;
    }
}

####### define some functions that should not be accessible by anyone.  These are
####### private functions only accessable by the class.  There will be no perldocs
####### for these functions
sub getUserCourseId
{
    my $self = shift;
    my ($userId) = @_;

    return $self->{PRODUCT_CON}->selectrow_array("select course_id from user_info where user_id = ?",{}, $userId);
}

sub getUserCertDuplicateId
{
    	 my $self = shift;
         my ($userID) = @_;
         return $self->{PRODUCT_CON}->selectrow_array("select max(duplicate_id) from user_cert_duplicate where approved='Y' and user_id = ?",{},$userID);
}
sub getUserPermitDuplicateId
{
    	 my $self = shift;
         my ($userId,$duplicateId) = @_;
	 my $compDate=$self->{PRODUCT_CON}->selectrow_array("select completion_date from user_info where user_id=?",{},$userId);
	 if(!$compDate){
		return 0;
	 }else{
         	return $self->{PRODUCT_CON}->selectrow_array("select duplicate_id from user_cert_duplicate where duplicate_id=? and user_id=? and request_date<?",{},$userId,$duplicateId,$compDate);
	}
}
sub pDriverRecordFedexLabelPrint{ #########################################################################################################
        my $self=shift;
        my ($data,$printerKey) = @_;
        my $PRIORITY = 1;
	if(!$printerKey){$printerKey='CA';}
	if(!defined $$data{OFFICEID}) { $$data{OFFICEID} = 1;}
        my $fedexObj = Fedex->new($self->{PRODUCT},$self->{DPS});
        $fedexObj->{PRINTERS}=$self->{PRINTERS};
        $fedexObj->{DPS}=$self->{DPS};
	$fedexObj->{PRINTER_KEY}=$printerKey;
        my $reply= $fedexObj->generateLabel($data, $PRIORITY);

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
                {
                        $self->putUserShipping($data->{SHIPPINGID}, $reply);
                }
        }
        return \%$reply;
}
sub getCookie{
    my $self=shift;
    my($userId, $arrRef) = @_;
    my %tmpHash;
    my $sth = $self->{PRODUCT_CON}->prepare('SELECT VALUE FROM user_cookie WHERE USER_ID = ? AND PARAM = ?');
    for my $param(@$arrRef){
        $sth->execute($userId, $param);
        my @valArr = $sth->fetchrow_array;
        $tmpHash{$param} = $valArr[0];
        $sth->finish;
    }
    return \%tmpHash;
}

sub getUserShippingByShippingId
{
    my $self        = shift;
    my ($shippingId) = @_;

    my $sql         = $self->{PRODUCT_CON}->prepare(<<"EOM"); 
SELECT SA.SHIPPING_ID, sf_decrypt(SA.NAME) as NAME, sf_decrypt(SA.ADDRESS) as ADDRESS, sf_decrypt(SA.ADDRESS_2) as ADDRESS_2, sf_decrypt(SA.CITY) as CITY, sf_decrypt(SA.STATE) as STATE, sf_decrypt(SA.ZIP) as ZIP, SA.PHONE, sf_decrypt(SA.DESCRIPTION) as DESCRIPTION, SA.DELIVERY_ID,sf_decrypt(SA.ATTENTION) as ATTENTION, SA.SIGNATURE, DATE_FORMAT(SA.PRINT_DATE, '%d-%b-%Y %H:%i') as PRINT_DATE, SA.PRINT_CATEGORY_ID AS PRINTCATEGORYID, SA.AIRBILL_NUMBER FROM  shipping_address SA WHERE SA.SHIPPING_ID = ?
EOM
    $sql->execute($shippingId);
    my $retval = $sql->fetchrow_hashref;
    $sql->finish;

    return $retval;
}
 
sub pDuplicateFedexLabelPrint
{
    my $self = shift;
    my ($shippingId,$printerKey,$uData) = @_;
    if(!$printerKey){
	$printerKey='CA';
    }
    my $shipData = $self->getUserShippingByShippingId($shippingId); 
    $shipData->{PRINTER_KEY}=$printerKey;
    my $state=$uData->{COURSE_STATE};
    $self->{PRINTING_STATE}=$state;
    $self->{PRINTING_TYPE}='CERTFEDX';
    my $response = $self->pNonUserFedexLabelPrint($shipData,'DUPLICATE');
    return $response;
}

sub isPrintableCourse
{
	my $self = shift;
	return 1;
}

sub isXLSPrintableCourse
{
	my $self=shift;
	return 0;
}
sub getCompletionDays{
    my $self=shift;
    my($userID) =@_;
    return $self->{PRODUCT_CON}->selectrow_array("select to_days(now())-to_days(COMPLETION_DATE) from user_info where USER_ID=? and COMPLETION_DATE <= now() ",{},$userID);
}

sub pNonTXDriverRecordFedexLabelPrint{ #########################################################################################################
        my $self=shift;
        my ($data,$printerKey) = @_;
        my $PRIORITY = 1;
        if(!$printerKey){$printerKey='CA';}
        if(!defined $$data{OFFICEID}) { $$data{OFFICEID} = 1;}
        my $fedexObj = Fedex->new($self->{PRODUCT});
        $fedexObj->{PRINTERS}=$self->{PRINTERS};
        $fedexObj->{PRINTER_KEY}=$printerKey;
        my $reply= $fedexObj->printLabel($data, $PRIORITY);

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
                {
                        $self->putUserShipping($data->{SHIPPINGID}, $reply);
                }
        }
        return \%$reply;
}
sub pFedexLabelPrintForWorkbook{ #########################################################################################################
        my $self=shift;
        my ($data,$webService) = @_;
        my $PRIORITY = 1;
        my $printerKey=$data->{PRINTER_KEY};
        $printerKey=($printerKey)?$printerKey:'CA';
        my $fedexObj = Fedex->new($self->{PRODUCT});
	$fedexObj->{PRINTING_STATE}=$data->{COURSE_STATE};
	$fedexObj->{PRINTING_TYPE}=$data->{CERTFEDEX};
        $fedexObj->{PRINTERS}=$self->{PRINTERS};
        $fedexObj->{PRINTER_KEY}=$printerKey;
        my $reply= $fedexObj->printLabel($data, $PRIORITY);
	my $userId = $data->{USER_ID};
	my $fedex = "\nUSERID : $userId\n";
        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
                {
                        my $shippingId=$self->insertShippingAddress($data);
                        $self->putUserShipping($shippingId, $reply);
			$self->updateUserWorkbookProcess($userId,$shippingId);
                }else{
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
sub updateUserWorkbookProcess {
        my $self=shift;
        my ($userId,$shippingId) = @_;
        my $sql     = $self->{PRODUCT_CON}->prepare(<<"EOM");
update user_workbook_process set shipping_id=?, processed_date=sysdate(),process_status=? where user_id = ?
EOM
        $sql->execute($shippingId,'Processed',$userId);
}

sub updateCTSIUserCertNumber {
        my $self=shift;
        my ($userId,$certificateNumber) = @_;
        my $sql     = $self->{PRODUCT_CON}->prepare(<<"EOM");
UPDATE user_info SET CERTIFICATE_NUMBER  = ? WHERE USER_ID = ? 
EOM
        $sql->execute($certificateNumber,$userId);
}

sub printDPSFedexLabel
{
         my $self = shift;
         my ($userId,$priority, $printerKey,$webService) = @_;
         my %tmpHash;
         ###### let's get user's shipping data
         $printerKey=($printerKey)?$printerKey:'DR';
         my $uData=$self->getDPSInformation($userId);
         my $shippingId=$uData->{SHIPPING_ID};
         my $shippingData = $self->getUserShippingByShippingId($shippingId);
         $shippingData->{DESCRIPTION} = "DR FOR - $userId";
  	 
         ###### create the fedex object, sending in the printer key
         my $fedexObj = Fedex->new($self->{PRODUCT});
         $fedexObj->{PRINTERS}=$self->{PRINTERS};
         $fedexObj->{PRINTER_KEY}=$printerKey;
	 $fedexObj->{PRINTING_TYPE}='DRFEDEX';
	 $fedexObj->{PRINTING_STATE}=$uData->{DR_STATE};
  	 
         my $reply= $fedexObj->printLabel( $shippingData, (($priority) ? $priority : 1 ));
         my $fedex = "\nUSERID : $userId\n";
  	 
         for(keys %$reply)
         {
                 if($_ eq 'TRACKINGNUMBER')
	         {
  	               $fedex .= "\t$_ : $$reply{$_}\n";
  	               $self->putUserShipping($shippingData->{SHIPPING_ID}, $reply);
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

sub printDSMSWokbookLabel
{
         my $self = shift;
         my ($orderId,$priority, $printerKey,$webService) = @_;
         my %tmpHash;
         ###### let's get user's shipping data
         $printerKey=($printerKey)?$printerKey:'CA';
         my $uData=$self->getWorkbookOrderInfo($orderId);
         my $shippingId=$uData->{SHIPPING_ID};
         my $shippingData = $self->getUserShippingByShippingId($shippingId);

         ###### create the fedex object, sending in the printer key
         my $fedexObj = Fedex->new($self->{PRODUCT});
         $fedexObj->{PRINTERS}=$self->{PRINTERS};
         $fedexObj->{PRINTER_KEY}=$printerKey;
	 $fedexObj->{PRINTING_STATE}=$shippingData->{STATE};
	 $fedexObj->{PRINTING_TYPE}='WBFEDX'; #$shippingData->{WBFEDX};

         my $reply= $fedexObj->printLabel( $shippingData, (($priority) ? $priority : 1 ));
	 my $fedex = "\nORDERID : $orderId\n";

         for(keys %$reply)
         {
                 if($_ eq 'TRACKINGNUMBER')
                 {
                       $fedex .= "\t$_ : $$reply{$_}\n";
                       $self->putUserShipping($shippingData->{SHIPPING_ID}, $reply);
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

sub getUserState
{
    my $self        = shift;
    my ($userId,$types) = @_;
    my $sql;
    if($types && $types eq 'COURSE'){
	return $self->{PRODUCT_CON}->selectrow_array("select c.state from user_info ui,course c where ui.user_id=? and ui.course_id=c.course_id",{},$userId);
    }elsif($$types && $types eq 'DR'){
	return $self->{PRODUCT_CON}->selectrow_array("select dr_state from dps_information where user_id=?",{},$userId);

    }

}

sub getAllPrintersIP
{
        my $self = shift;
        my $sql = $self->{CRM_CON}->prepare("select distinct printer_ip from printing_printers_info");
        $sql->execute;

        my @ipArray;
        while (my ($printerIp, $tray) = $sql->fetchrow)
        {
		push @ipArray,$printerIp;
        }
        $sql->finish;

        return @ipArray;
}

sub updateCertsStock
{
        my $self = shift;
        my ($itemId) = @_;

        if ($itemId)
        {	
		my @Stock = $self->{CRM_CON}->selectrow_array("SELECT CURRENT_STOCK,ITEMS_PER_PACKAGE FROM stock_items WHERE ITEM_ID = ?", {}, $itemId);
                my $currentStock = $Stock[0];
                my $Items = $Stock[1];
                my $temp=0;
                if ($currentStock && ($Items == 0))
                {
                        $currentStock-=1;
                        $self->{CRM_CON}->do("UPDATE stock_items set CURRENT_STOCK = $currentStock WHERE ITEM_ID = $itemId");
                } else {
                        $temp = ($currentStock * $Items) - 1;
			if($Items){
	                        $currentStock = (($temp) / ($Items));		
        	                $self->{CRM_CON}->do("UPDATE stock_items set CURRENT_STOCK = $currentStock WHERE ITEM_ID = $itemId");
			}
                }

        }
}

sub getItemOrderDetails
{
        my $self = shift;
        my ($itemId, $orderId) = @_;
        return $self->{CRM_CON}->selectrow_hashref("SELECT DATE_FORMAT(O.ORDER_DATE, '%m-%d-%Y') AS ORDER_DATE,V.VENDOR_NAME, I.COST_PER_ITEM, 
						I.ITEM_ID,I.ITEM_NAME,I.PACKAGES_PER_BOX,I.ITEMS_PER_PACKAGE,I.REORDER_FREQUENCY_PERCENT,O.QUANTITY,
						O.ORDER_BY,I.ORDER_METHOD,I.MIN_STOCK,I.CURRENT_STOCK,O.TOTAL_COST, I.ORDER_TEMPLATE FROM stock_items I,
						stock_order_details O, stock_vendor_details V WHERE I.ITEM_ID = O.ITEM_ID AND O.ORDER_ID = $orderId AND 
						I.ITEM_ID =$itemId AND I.VENDOR_ID=V.VENDOR_ID");
}


sub dbInsertReportDetails
{
        my $self = shift;
        my ($ref) = @_;
        my $userId = (exists $ref->{USERID}) ? $ref->{USERID} : '';
        my $reportBy = (exists $ref->{REPORT_BY}) ? $ref->{REPORT_BY} : 'SYSTEM';
        my $productId = (exists $ref->{PRODUCTID}) ? $ref->{PRODUCTID} : '1';
        my $reportId = (exists $ref->{REPORTID}) ? $ref->{REPORTID} : '1';
        my $reportDate = (exists $ref->{REPORTDATE}) ? $ref->{REPORTDATE} : "";
        if ($userId)
        {
                ### Get User's Details required to insert into DB ###
                my ($dl, $compDate, $printDate, $login);
		if ($productId == 2 || $productId == 18)
		{
                	($dl, $compDate, $printDate) = $self->{PRODUCT_CON}->selectrow_array("SELECT EMAIL, COMPLETION_DATE, PRINT_DATE FROM user_info WHERE USER_ID = ?", {}, $userId);
		}
		else
		{
                	($dl, $compDate, $printDate, $login) = $self->{PRODUCT_CON}->selectrow_array("SELECT DRIVERS_LICENSE, COMPLETION_DATE, PRINT_DATE, LOGIN FROM user_info WHERE USER_ID = ?", {}, $userId);
		} 
                my ($fn, $ln) = $self->{PRODUCT_CON}->selectrow_array("SELECT FIRST_NAME, LAST_NAME FROM user_contact WHERE USER_ID = ?", {}, $userId);
                $fn = ($fn) ? $fn : "";
                $ln = ($ln) ? $ln : "";
                $dl = ($dl) ? $dl : "";
                $login = ($login) ? $login : "";

                ## finally gather all the data to be insert into  CRM db
                my $count = $self->{CRM_CON}->selectrow_array("SELECT COUNT(USER_ID) FROM report_details WHERE USER_ID=? AND REPORT_ID=? AND PRODUCT_ID=?", {}, $userId, $reportId, $productId);
                if ($count)
                {
			if ($reportDate)
			{
                        	my $usql = $self->{CRM_CON}->prepare("UPDATE report_details set FIRST_NAME=?, LAST_NAME=?, EMAIL=?, DRIVERS_LICENSE=?, COMPLETION_DATE=?, PRINT_DATE=?, REPORT_DATE=?, REPORT_BY=? WHERE REPORT_ID=? AND USER_ID=? AND PRODUCT_ID=?");
                        	$usql->execute($fn, $ln, $login, $dl, $compDate, $printDate, $reportDate, $reportBy, $reportId, $userId, $productId);
                        	$usql->finish;
			}
			else
			{
                        	my $sql = $self->{CRM_CON}->prepare("UPDATE report_details set FIRST_NAME=?, LAST_NAME=?, EMAIL=?, DRIVERS_LICENSE=?, COMPLETION_DATE=?, PRINT_DATE=?, REPORT_DATE=now(), REPORT_BY=? WHERE REPORT_ID=? AND USER_ID=? AND PRODUCT_ID=?");
                        	$sql->execute($fn, $ln, $login, $dl, $compDate, $printDate, $reportBy, $reportId, $userId, $productId);
                        	$sql->finish;
			}	
                }
                else
                {
                        if ($reportDate)
                        {
                                my $sth = $self->{CRM_CON}->prepare("INSERT INTO report_details(REPORT_ID, USER_ID, PRODUCT_ID, FIRST_NAME, LAST_NAME, EMAIL, DRIVERS_LICENSE, COMPLETION_DATE, PRINT_DATE, REPORT_DATE, REPORT_BY) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                                $sth->execute($reportId, $userId, $productId, $fn, $ln, $login, $dl, $compDate, $printDate, $reportDate, $reportBy);
                                $sth->finish;
                        }
                        else
                        {
                                my $sth = $self->{CRM_CON}->prepare("INSERT INTO report_details(REPORT_ID, USER_ID, PRODUCT_ID, FIRST_NAME, LAST_NAME, EMAIL, DRIVERS_LICENSE, COMPLETION_DATE, PRINT_DATE, REPORT_DATE, REPORT_BY) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, now(), ?)");
                                $sth->execute($reportId, $userId, $productId, $fn, $ln, $login, $dl, $compDate, $printDate, $reportBy);
                                $sth->finish;
                        }
                }
        }
}

sub dbSelectReportId
{
        my $self = shift;
	my ($ref) = @_;
        my $reportName = $ref->{REPORT_NAME};
        my $productId = $ref->{PRODUCT_ID};
        my $reportId = $self->{CRM_CON}->selectrow_array("SELECT CRON_ID FROM cron_list WHERE REPORT_NAME LIKE '$reportName%' AND PRODUCT_ID=$productId AND ACTIVE=1 limit 0, 1");
        if (!$reportId)
        {
                $reportId = '9999';
        }
        return $reportId;
}

sub pFedexLabelPrintForDisk
{
    my $self = shift;
    my ($shippingId,$printerKey) = @_;
    if(!$printerKey){
        $printerKey='CA';
    }
    my $shipData = $self->getUserShippingByShippingId($shippingId);
    $shipData->{PRINTER_KEY}=$printerKey;
    $self->{PRINTING_TYPE}='CERTFEDX';
    my $response = $self->pNonUserFedexLabelPrint($shipData,'DISK');
    return $response;
}

sub refundUSPSLabel
{
        my $self = shift;
        my ($trackingNumber,$transactionId) = @_;
        ###### let's get user's shipping data

        ###### create the fedex object, sending in the printer key
        my $fedexObj = Fedex->new($self->{PRODUCT});
	my $reply= $fedexObj->_uspsRefund($trackingNumber,$transactionId);
	return $reply;
}

sub dbSendMailMarketo {
	my $self = shift;
	my ($productId, $userId, $eventType, $orderId, $paymentAmoumt, $paymentFor, $emailShortDesc, $drUser, $shippingId) = @_;
	#print STDERR "\n_______________ USER HERE FOR MARKETO -- $productId, $userId, $eventType, $orderId, $paymentAmoumt, $paymentFor, $emailShortDesc, $drUser \n";
	if($productId != 1 && $productId != 2 && $productId != 18) {
		return 1;
	}
	my $MARKETO_API = {'MARKETO_API_URL' => 'marketo.idrivesafely.com', 'MARKETO_API_TIMEOUT' => '45'};
	use LWP::UserAgent;
	use HTTP::Headers;
	my $marketoAPIURL = $MARKETO_API->{MARKETO_API_URL};
	my $marketoAPITimeout = $MARKETO_API->{MARKETO_API_TIMEOUT};
	my $postURL = "http://$marketoAPIURL"."/marketo/getStudentsDataForMarketo/";
	my $product = 'DIP';
	if($productId == 2) {
		$product = 'TEEN';
	} elsif($productId == 18) {
		$product = 'ADULT';
	}
	my $xmlForDr = '';
	if($drUser && $drUser == 1) {
		$xmlForDr = "<drUser>1</drUser>";
	}
	my $isValidMarketoEmail = 0;
	$isValidMarketoEmail = $self->dbCheckEmailShortDescExist('MARKETO', $emailShortDesc, $userId);
	#print "\n__________________________ $isValidMarketoEmail \n";
	if($isValidMarketoEmail && $isValidMarketoEmail == 1){
		my $request = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><getStudentsDataForMarketo><userId>$userId</userId><productId>$product</productId><eventType>$eventType</eventType><orderId>$orderId</orderId><paymentAmount>$paymentAmoumt</paymentAmount><paymentFor>$paymentFor</paymentFor>$xmlForDr<shippingId>$shippingId</shippingId><eventSite>PRINTING</eventSite><emailShortDesc>$emailShortDesc</emailShortDesc></getStudentsDataForMarketo>";
		#print STDERR "\nRequest\n===============\n$request\n\n";
		my $objUserAgent = LWP::UserAgent->new;
		my $contentlength = length($request);
		my $objHeader = HTTP::Headers->new(
			Host => $marketoAPIURL,
			Content_Type => 'application/xml',
			Accept => 'application/json',
			Content_Length => $contentlength,
			SOAPAction => $postURL,
		);
		my $objRequest = HTTP::Request->new("POST",$postURL,$objHeader,$request);
		my $objResponse = $objUserAgent->request($objRequest);
		#print STDERR Dumper($objResponse);
		if (!$objResponse->is_error) {
			my $content = $objResponse->content;
			#print STDERR "\nSucccess : $content - \n";
			#print STDERR "\n Content ---  ->$content<--\n";
			#print STDERR "\n if ------------------------------------------- \n";
			#print STDERR Dumper($responseData);
			#use crmDB;
			$self->dbInsertMarketoData($userId, $request, $content);
		} else {
			my $content = $objResponse->error_as_HTML;
			$self->dbInsertMarketoData($userId, $request, $content);
		}
	}
}

sub dbCheckEmailShortDescExist {
	my $self = shift;
	my ($emailType, $shortDesc, $userId) = @_;
	my $count=0;
	my $query = "";
	if($userId) {
		my $userInfo = $self->getUserInfo($userId);
		my $segmentId = $self->dbGetCourseAttribute($userInfo->{COURSE_ID},'SEGMENT_ID');
		if($segmentId && $segmentId == 8) {
			##This user is from mature
			$query = " and product = 'MATURE' ";
		}
	}
	if($emailType eq 'MARKETO'){
		$count = $self->{PRODUCT_CON}->selectrow_array("SELECT COUNT(*) FROM marketo_email_master_data WHERE marketo = 1 and email_short = ? $query", {}, $shortDesc);
	}else{
		$count = $self->{PRODUCT_CON}->selectrow_array("SELECT COUNT(*) FROM marketo_email_master_data WHERE sendgrid = 1 and email_short = ? $query", {}, $shortDesc);
	}
	if($count){
		return 1;
	}else{
		return 0;
	}
}


sub dbInsertMarketoData {
	my $self = shift;
	my ($userId, $dataPosted, $responseReceived) = @_;
	my $sth=$self->{PRODUCT_CON}->prepare("INSERT INTO marketo_data_requests SET USER_ID = ?, PRODUCT_ID = ?, DATA_POSTED = ?, RESPONSE = ?, TRANSACTION_DATE = NOW()");
	$sth->execute($userId, 'DIP', $dataPosted, $responseReceived);
	$sth->finish;
}

sub dbGetCourseAttribute{
	my $self = shift;
	my($courseId, $attribute) = @_;
	my $retVal = 0;
	my $COUNT = 0;
	$attribute =~ s/\s+//g;
	$attribute= uc $attribute;

	$COUNT = $self->{PRODUCT_CON}->selectrow_array('SELECT COUNT(COURSE_ID)  FROM course_attribute WHERE COURSE_ID = ? AND ATTRIBUTE = ?', {}, $courseId, $attribute);
	if($COUNT == 1){
		$retVal = $self->{PRODUCT_CON}->selectrow_array("SELECT VALUE FROM course_attribute  WHERE COURSE_ID = ? AND ATTRIBUTE = ? ", {}, $courseId, $attribute);
	}elsif($COUNT == 0){
		$retVal = 0;
	}else{
		$retVal = -1;
	}
	return $retVal;
}

sub dbPutUserCerDownloadInfo{
         my $self=shift;
         my ($userId, $courseId, $fromPage) = @_;
         my ($delType, $printDays) = $self->{PRODUCT_CON}->selectrow_array('select dd.definition, DATEDIFF(NOW(), ui.print_date) as noOfDays from delivery dd, user_delivery ud, user_info ui where ud.delivery_id = dd.delivery_id and ud.user_id = ui.user_id and ui.user_id = ?',{},$userId);
        my $sth = '';
        if(!$fromPage){
                $fromPage = "My Account";
        }
        my $certMsg = "Email Delivery Downloaded from $fromPage";
	if($delType ne 'Email Delivery' && $printDays >= 30){
        	$sth = $self->{CRM_CON}->prepare("insert into user_download_cert_records (user_id, product_id, course_id, action, date) values (?, '28', ?, 'Delivery Download', NOW())");
        	$sth->execute($userId, $courseId);
	}elsif($delType eq 'Email Delivery'){
		$sth = $self->{CRM_CON}->prepare("insert into user_download_cert_records (user_id, product_id, course_id, action, date) values (?, '28', ?, ?, NOW())");
        	$sth->execute($userId, $courseId, $certMsg);
	}
 }






1;
