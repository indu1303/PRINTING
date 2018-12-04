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

package Certificate::AAACATeen;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;

sub _generateCertificate
{
    my $self = shift;
    my ($userId, $userData,$printId,$productId) = @_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=-15;
    my $yDiff=130;
    ###### as we do w/ all things, let's start at the top.  Print the header	
    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICABOLD', 10);
    $self->{PDF}->writeLine( 138-$xDiff, 517+$yDiff, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $self->{PDF}->writeLine( 367-$xDiff, 517+$yDiff, $userData->{DATE_OF_BIRTH} );


    $self->{PDF}->writeLine( 138-$xDiff, 472+$yDiff, 'Auto Club Driving School');
    $self->{PDF}->writeLine( 373-$xDiff, 472+$yDiff, '3839');
    $self->{PDF}->writeLine( 138-$xDiff, 494+$yDiff, $userData->{COMPLETION_DATE});


    $self->{PDF}->writeLine( 128-$xDiff, 449+$yDiff, '3333 Fairview Road, Costa Mesa, CA 92626');
    $self->{PDF}->writeLine( 360-$xDiff, 448+$yDiff, '855  220 4858');

    $self->{PDF}->writeLine( 138-$xDiff, 425+$yDiff, 'Ronald J. Salamanca');
    $self->{PDF}->writeLine( 373-$xDiff, 423+$yDiff, 'I3839045');

    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/aaasalamancasig.jpg",
                                145-$xDiff, 302+$yDiff, 250, 35,250,35);
    $self->{PDF}->writeLine( 373-$xDiff, 315+$yDiff, Settings::getDate);

    ###### print the certificate number
    $printId=1;

    return ($self->{PDF},$printId);

}

sub printCATeenLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $full=1;
    my $bottom='';
    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 10);
    $self->{PDF}->writeLine( 21, 676, 'AAA HOW TO DRIVE ONLINE');
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $yPos -=11;
    my $xDiff='';
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    $self->_printCorporateAddress(21-$xDiff, 662, $OFFICECA,'howtodriveonline.aaa.com');

    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS_1} );
    $yPos -=11;
    if($userData->{ADDRESS_2}){
    	$self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS_2} );
	$yPos -=11;
    }
    $self->{PDF}->writeLine( 21, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}");
    $self->{PDF}->getCertificate;

    my $printer = 0;
    my $media = 0;
    my $st='CA';   ##########  Default state, we have mentioned as XX;
    my $productId=2;  ##### This is for Teen
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
    if(!$printer){
        $printer = 'HP-PDF-MANUAL';
    }
    if(!$media){
            $media='Tray2';
    }
		my $outputFile = "/tmp/LABEL$userId.pdf";
		######## send the certificate to the printer
	
                my $ph;
                open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
                close $ph;
	        if(-e $outputFile){
         	      	unlink $outputFile;
                }

}

sub constructor
{
	my $self = shift;
	my ($userId,$top,$bottom,$faxEmail)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
	$top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
	$bottom = ($bottom)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$bottom":'';
	my $full=(!$bottom)?1:0;

    ###### get the appropriate templates
	 if($top || $bottom){
         	$self->{PDF}->setTemplate($top,$bottom,$full);
	 }
	 return $self;

}

1;
