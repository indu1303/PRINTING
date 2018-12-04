#!/usr/bin/perl -w 

package Printing::DIPDVD;

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

my $NO_PRINT_DIP_COURSE = { };
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
    my $product =($self->{PRODUCT})?$self->{PRODUCT}:'DIPDVD';
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
        #### define the different constraints that are available

        ##### now, generate the SQL statement
    	my $sqlStmt     = "exec Certificate_NYCertificate";
    	my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    	$sql->execute;
	my $retval;
        while (my ($v1, $v2, $v3, $v4, $v5, $v6, $v7, $v8, $v9, $v10, $v11, $v12, $v13, $v14, $v15, $v16, $v17, $v18, $v19, $v20, $v21) = $sql->fetchrow)
        {

            $retval->{$v5}->{USER_ID}           	= $v5;
            $retval->{$v5}->{COURSE_ID}          	='40005';
            $retval->{$v5}->{DELIVERY_ID}        	= ($v21)?$v21:1; 
            $retval->{$v5}->{USERDATA}->{DELIVERY_ID}   	= ($v21)?$v21:1; 
            $retval->{$v5}->{USERDATA}->{COMPLETION_DATE}   	= $v7;
            $retval->{$v5}->{USERDATA}->{DRIVERS_LICENSE}   	= $v6;
	    $retval->{$v5}->{USERDATA}->{FIRST_NAME}	=$v8;
	    $retval->{$v5}->{USERDATA}->{LAST_NAME}	=$v9;
	    $retval->{$v5}->{USERDATA}->{NAME}	=	"$v8 $v9";
	    $retval->{$v5}->{USERDATA}->{ADDRESS_1}	=$v10;
	    $retval->{$v5}->{USERDATA}->{CITY}		=$v11;
	    $retval->{$v5}->{USERDATA}->{STATE}		=$v12;
	    $retval->{$v5}->{USERDATA}->{COURSESTATE}	='NY';
	    $retval->{$v5}->{USERDATA}->{ZIP}		=$v13;
	    $retval->{$v5}->{USERDATA}->{PHONE}		=$v14;
	    $retval->{$v5}->{USERDATA}->{COURSE_ID}	='40005';
        }
    	####### return the users;
    	return $retval;
}



sub getUserData
{
        my $self    = shift;
        my ($userId)    = @_;
        my $sqlStmt     = "exec Certificate_NYCertificate $userId";
        my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
        $sql->execute;
        my $retval;
        while (my ($v1, $v2, $v3, $v4, $v5, $v6, $v7, $v8, $v9, $v10, $v11, $v12, $v13, $v14, $v15, $v16, $v17, $v18, $v19, $v20, $v21) = $sql->fetchrow)
        {

            $retval->{$v5}->{USER_ID}                   = $v5;
            $retval->{$v5}->{COURSE_ID}                 ='40005';
            $retval->{$v5}->{DELIVERY_ID}               = ($v21)?$v21:1;
            $retval->{$v5}->{USERDATA}->{DELIVERY_ID}           = ($v21)?$v21:1;
            $retval->{$v5}->{USERDATA}->{COMPLETION_DATE}       = $v7;
            $retval->{$v5}->{USERDATA}->{DRIVERS_LICENSE}       = $v6;
            $retval->{$v5}->{USERDATA}->{FIRST_NAME}    =$v8;
            $retval->{$v5}->{USERDATA}->{LAST_NAME}     =$v9;
            $retval->{$v5}->{USERDATA}->{NAME}  =       "$v8 $v9";
            $retval->{$v5}->{USERDATA}->{ADDRESS}       =$v10;
            $retval->{$v5}->{USERDATA}->{CITY}          =$v11;
            $retval->{$v5}->{USERDATA}->{STATE}         =$v12;
            $retval->{$v5}->{USERDATA}->{COURSESTATE}   ='NY';
            $retval->{$v5}->{USERDATA}->{ZIP}           =$v13;
            $retval->{$v5}->{USERDATA}->{PHONE}         =$v14;
            $retval->{$v5}->{USERDATA}->{COURSE_ID}     ='40005';
        }


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
  	my ($userId, $cId) = @_;
    	$self->SUPER::getNextCertificateNumber($userId, $cId);
}

=head2 putUserPrintRecord

=cut

sub putUserPrintRecord {
    my $self    = shift;
    my ($userId) = @_;
    my $sqlStmt     = "exec Certificate_NYUpdatePrinted $userId";
    my $sql     = $self->{PRODUCT_CON}->prepare($sqlStmt);
    $sql->execute;
    
}


=head2 printFedexLabel

=cut

sub printFedexLabel
{
        my $self = shift;
        my ($userId, $userData,$priority,$webService) = @_;
        my %tmpHash;
        ###### let's get user's shipping data
	my $printerKey='CA';
	my $trackingNumber='';
        my $shippingData = $userData;
	my $courseState=$userData->{COURSESTATE};
        $shippingData->{DESCRIPTION} = "CERT FOR - $userId";

        ###### create the fedex object, sending in the printer key
        my $fedexObj = Fedex->new($self->{PRODUCT});
	$fedexObj->{PRINTERS}=$self->{PRINTERS};
	$fedexObj->{PRINTING_STATE}=$courseState;
	$fedexObj->{PRINTING_TYPE}='CERTFEDX';
	$fedexObj->{PRINTER_KEY}=$printerKey;

        my $reply= $fedexObj->printLabel( $shippingData, (($priority) ? $priority : 1 ),'','','','');
        my $fedex = "\nUSERID : $userId\n";

        for(keys %$reply)
        {
                if($_ eq 'TRACKINGNUMBER')
        {
                        $fedex .= "\t$_ : $$reply{$_}\n";
			if(!$trackingNumber){
				$trackingNumber=$reply->{TRACKINGNUMBER};
	                        $self->putUserShipping($userId, $trackingNumber);
				##### Print The Data to Database;   
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
        	return ($fedex,$trackingNumber);
	}

}

=head2 putUserShipping

=cut

sub putUserShipping
{
    #### ..slurp the class
    my $self = shift;

    my ($userId, $trackingNumber) = @_;
    if ($trackingNumber)
    {
	my $sql = $self->{PRODUCT_CON}->prepare(qq{exec Certificate_NYUpdateTracking \@StudentID=$userId, \@TrackingNumber='$trackingNumber'});
    	$sql->execute;
    }
}

1;
