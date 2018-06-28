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

package Affidavit::TeenAffidavit;

use strict;
use lib qw(/ids/tools/PRINTING/lib);
use Affidavit;
use Certificate::PDF;
use Data::Dumper;
use HTML::Template;

use vars qw(@ISA);
@ISA=qw(Affidavit);


sub _generateCOAffidavitForPrint
{
    my $self = shift;
    my ($userId, $userData,$printId) = @_;
    my @variableData;
    my $arrCtr=0;

    $self->{PDF}->setFont('HELVETICABOLD',9);
    my $yPos = 550;
    my $xPos = 60;
    $self->{PDF}->writeLine( $xPos, $yPos, uc $userData->{FIRST_NAME}." ".uc $userData->{LAST_NAME});

    $yPos = 535;
    $xPos = 60;
    $self->{PDF}->writeLine( $xPos, $yPos, uc $userData->{ADDRESS_1}." ".uc $userData->{ADDRESS_2});

    $yPos = 520;
    $xPos = 60;
    $self->{PDF}->writeLine( $xPos, $yPos, uc $userData->{CITY}." ".uc $userData->{STATE}.", ".$userData->{ZIP});

	# 2nd Part
    $yPos = 285;
    $xPos = 65;
    $self->{PDF}->writeLine( $xPos, $yPos, uc $userData->{FIRST_NAME});

    $yPos = 285;
    $xPos = 163;
    $self->{PDF}->writeLine( $xPos, $yPos, '');

    $yPos = 285;
    $xPos = 262;
    $self->{PDF}->writeLine( $xPos, $yPos, uc $userData->{LAST_NAME});

    $yPos = 285;
    $xPos = 460;
    my $dob = $userData->{DATE_OF_BIRTH};
    $self->{PDF}->writeLine( $xPos, $yPos, $dob);
    $variableData[$arrCtr++]="DATE OF BIRTH: $dob";

    $yPos = 240;
    $xPos = 210;
    my $registrationDate = $userData->{REGISTRATION_DATE};
    $self->{PDF}->writeLine( $xPos, $yPos,$registrationDate);
    $variableData[$arrCtr++]="REGISTRATION DATE: $registrationDate";

    $yPos = 210;
    $xPos = 210;
    $self->{PDF}->writeLine( $xPos, $yPos, 'Idrivesafely.com(9114)');

    my $title = "AFFIDAVIT OF ENROLLMENT IN A DRIVER EDUCATION COURSE";
    $yPos = 750;
    $xPos = 160;
    $self->{PDF}->writeLine( $xPos, $yPos, $title);
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
    	$printId=$self->MysqlDB::getNextId('contact_id');
    }
    my $variableDataStr=join '~',@variableData;
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);

    return ($self->{PDF},$printId);
}

sub _generateCOAffidavit {
    my $self = shift;
    my ($userId, $userData) = @_;
    $self->{PDF}->setFont('HELVETICABOLD',9);
    my $yPos = 690;
    my $xPos = 40;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{FIRST_NAME});

    $yPos = 690;
    $xPos = 153;
    $self->{PDF}->writeLine( $xPos, $yPos, '');

    $yPos = 690;
    $xPos = 260;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{LAST_NAME});

    $yPos = 690;
    $xPos = 480;
    my $dob = $userData->{DATE_OF_BIRTH};
    $self->{PDF}->writeLine( $xPos, $yPos, $dob);

    $yPos = 640;
    $xPos = 210;
    my $registrationDate = $userData->{REGISTRATION_DATE};
    $self->{PDF}->writeLine( $xPos, $yPos,$registrationDate);

    $yPos = 615;
    $xPos = 210;
    $self->{PDF}->writeLine( $xPos, $yPos, 'Idrivesafely.com');

    $yPos = 592;
    $xPos = 475;
    $self->{PDF}->writeLine( $xPos, $yPos, 'X');
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/sig.jpg",
                                210, 540, 105, 35,1050,305);
    return ($self->{PDF},1);

}



sub constructor
{
	my $self = shift;
	my ($userId,$template)=@_;
	###### let's create our certificate pdf object
	my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/$template";
        $self->{PDF} = Certificate::PDF->new($userId);
        my $full=1;
                ###### get the appropriate templates
        if(-e $top){
	       $self->{PDF}->setTemplate($top,'',$full);
        }
	return $self;

}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: kumar $

=item $Date: 2007/07/24 08:36:39 $

=item $Rev: 71 $

=cut

1;
