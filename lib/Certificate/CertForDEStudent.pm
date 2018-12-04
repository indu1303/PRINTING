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
#!/usr/bin/perl -w 

package Certificate::CertForDEStudent;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use PDF::Reuse;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;

sub _generateCertificate
{
    my $self = shift;
    my ($userId, $userData,$printId,$productId,$rePrintData,$faxEmail) = @_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $layout = $self->getCourseCertificateLayout($userData->{COURSE_ID},$productId);
    my $LINESPACE       = 12;

    ##### Let's give a delivery flag

    my $yPos=725;
    my $yPS=350;
    ###### let's print the disclaimer on the right
    $self->{PDF}->setFont('HELVETICA', 6);
   
#$userData->{ADDRESS_1}='4301 ROAD 211';
#$userData->{ADDRESS_2}='';
#$userData->{CITY}='CORTEZ';
#$userData->{STATE}='CO';
#$userData->{DATE_OF_BIRTH}='01/20/1994';

 
    ###### print the signature
    my $address = $userData->{ADDRESS_1} ;
    if($userData->{ADDRESS_2}){
    	$address .= ', ' . $userData->{ADDRESS_2};
    }	
    my $userInformation .= ' ' . $userData->{CITY} . ', '. $userData->{STATE} . ' ' . $userData->{ZIP};

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 14);
    $self->{PDF}->writeLine( 310-$xDiff, 580 ,'The following person has completed');
    $self->{PDF}->writeLine( 310-$xDiff, 562 ,'Colorado Drivers Ed course that has');
    $self->{PDF}->writeLine( 310-$xDiff, 544 ,'been Approved by the Colorado DMV');
    $self->{PDF}->writeLine(150-$xDiff, 490, 'Student Name        :');
    $self->{PDF}->writeLine(150-$xDiff, 470, 'Address                  :');
    $self->{PDF}->writeLine(150-$xDiff, 430, 'Completion Date     :');
    $self->{PDF}->writeLine(150-$xDiff, 410, 'Student Id               :');
    $self->{PDF}->writeLine(150-$xDiff, 390, 'Date of Birth            :');
    $self->{PDF}->writeLine(150-$xDiff, 370, 'Certificate Number  :');
    $self->{PDF}->writeLine(300-$xDiff, 490, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $self->{PDF}->writeLine(300-$xDiff, 470, $address );
    $self->{PDF}->writeLine(300-$xDiff, 450, $userInformation);
    $self->{PDF}->writeLine(300-$xDiff, 430, $userData->{COMPLETION_DATE});
    $self->{PDF}->writeLine(300-$xDiff, 410, $userData->{USER_ID});
    $self->{PDF}->writeLine(300-$xDiff, 390, $userData->{DATE_OF_BIRTH});
    $self->{PDF}->writeLine(300-$xDiff, 370, $userData->{CERTIFICATE_NUMBER});
#    $self->{PDF}->writeLine(60-$xDiff, 526, $userInformation );
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('DE');
    $self->{PDF}->writeLine(60-$xDiff, 698, "DriversEd.com" );
    $self->_printCorporateAddress(60-$xDiff,686, $OFFICECA,'');
    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $countyId = $userData->{COUNTY_ID};
    my $courseId = $userData->{COURSE_ID};
    $userData->{COUNTY_DEF}=($userData->{COUNTY_DEF})?$userData->{COUNTY_DEF}:$userData->{REGULATOR_DEF};
    if($countyId && exists $self->{SETTINGS}->{CTSI_COUNTY}->{$countyId}){
	my $rankNo=(keys %$fields) +1;
	$fields->{$rankNo}=15;		
	$rankNo++;
	$fields->{$rankNo}=2;		
    }
    my $y = 390;
    $yPS = 567;
    my $xOffset = 185;
    my $courseData='';
    $self->{PDF}->setFont('HELVETICA', 14);
    my @variableData;


	$self->{PDF}->setFont('HELVETICABOLD', 18);
	$self->{PDF}->writeLine (100-$xDiff,60,"This Proof of Completion is for Student Records");
	$self->{PDF}->writeLine (150-$xDiff,40,"Only and NOT accepted at the DMV");
        if(!$printId && !$userData->{UPSELLEMAIL}){
                $printId=$self->MysqlDB::getNextId('contact_id');
        }

    ###### how about the course def
    return ($self->{PDF},$printId,'',$self->{PS});
}

sub constructor
{
	my $self = shift;
	my ($userId,$top,$bottom,$faxEmail)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/CertificateForDEStudent.jpg",
					0, 0, 612, 792,1275,1650);
	return $self;
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: dharmateja $

=item $Date: 2009-09-23 16:09:43 $

=item $Rev: 71 $

=cut

1;
