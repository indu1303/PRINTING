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
package Certificate::COTeen;
    
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
    my ($userId, $userData,$printId,$productId,$rePrintData,$faxEmail) = @_;
    my @variableData;
    $self->{PDF}->setFont('HELVETICABOLD',10);

    my $xPos = 210;
#   my $yPos = 100;
    my $yPos = 200;
    $self->{PDF}->writeLine( 249, 680, uc $userData->{FIRST_NAME}.'  '. uc $userData->{LAST_NAME} , 270, '');

    my $dob = $userData->{DATE_OF_BIRTH};
    my @dobArr = split /\//, $dob;
    $xPos = 210;
    $yPos = 580;
    $self->{PDF}->writeLine( 242, 400, $dobArr[0], 270, '');
    $yPos = 610;
    $self->{PDF}->writeLine( 242, 355, $dobArr[1], 270, '');
    $yPos = 645;
    $self->{PDF}->writeLine( 242, 330, $dobArr[2], 270, '');

    $xPos = 235;
    $yPos = 200;
    $self->{PDF}->setFont('HELVETICABOLD',10);
    my $address= $userData->{ADDRESS_1};
    if($userData->{ADDRESS_2}){
	$address .= ", $userData->{ADDRESS_2}";
    }
    $self->{PDF}->writeLine( 220, 720, $address, 270, '');
$self->{PDF}->setFont('HELVETICABOLD',10);
    $yPos = 500;
    $self->{PDF}->writeLine( 220, 505, $userData->{CITY}, 270, '');
$self->{PDF}->setFont('HELVETICABOLD',10);
    $yPos = 640;
$self->{PDF}->setFont('HELVETICABOLD',10);
    $self->{PDF}->writeLine( 220, 360, $userData->{ZIP}, 270, '');
$self->{PDF}->setFont('HELVETICABOLD',10);
    $xPos = 280;
    $yPos = 250;
    my $completionDate = $userData->{COMPLETION_DATE};
    $completionDate=~ s/\// \/ /g;
    $self->{PDF}->writeLine( 172, 690,$completionDate, 270, '');
$self->{PDF}->setFont('HELVETICABOLD',10);
    $xPos = 310;
    $yPos = 200;
    $self->{PDF}->writeLine( 142, 700, 'I Drive Safely', 270, '');
$self->{PDF}->setFont('HELVETICABOLD',10);
    $xPos = 310;
    $yPos = 580;
    $self->{PDF}->writeLine( 142, 360, '9114', 270, '');
    $xPos = 340;
    $yPos = 200;
#    $self->{PDF}->writeLine( 80, 700, 'Kami Mason', 270, '');
    $xPos = 340;
    $yPos = 580;
#    $self->{PDF}->writeLine( 80, 360, '9114H', 270, '');

    $variableData[0]="COMPLETION DATE:$completionDate";
    my $variableDataStr=join '~',@variableData;
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
        $printId=$self->MysqlDB::getNextId('contact_id');
    }
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    return ($self->{PDF},$printId);
}

sub constructor
{
	my $self = shift;
	my ($userId,$template)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
	return $self;

}

sub printCOTeenLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/CO_TEEN_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    my $xDiff='';
    $self->{PDF}->setTemplate($top,$bottom,$full);
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'CO'){
    	$OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    $self->_printCorporateAddress(21-$xDiff,662, $OFFICECA,'teen.idrivesafely.com');

    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
	 if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'CO'){
	       if($userData->{DATE_OF_BIRTH}){
	    	$self->{PDF}->writeLine(452, $yPos, "DOB : $userData->{DATE_OF_BIRTH}" );
	
	       }
	}
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS_1} );
	 if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'CO'){
	     if($userData->{COMPLETION_DATE}){
	    	$self->{PDF}->writeLine( 452, $yPos, "Completion Date : $userData->{COMPLETION_DATE}" );
	      }
	}
    $yPos -=11;
    if($userData->{ADDRESS_2}){
    	$self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS_2} );
	$yPos -=11;
    }
    $self->{PDF}->writeLine( 21, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}");
    $self->{PDF}->getCertificate;

    my $printer = 0;
    my $media = 0;
    my $st='CO';   ##########  Default state, we have mentioned as XX;
    my $productId=2;  ##### This is for Mature
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
    if(!$printer){
        $printer = 'HP-PDF2-MANUAL';
    }
    if(!$media){
            $media='Tray2';
    }
    my $outputFile = "/tmp/LABEL$userId.pdf";
    ######## send the label to the printer
	
    my $ph;
    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
    close $ph;
    if(-e $outputFile){
   	unlink $outputFile;
    }
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: hari $

=item $Date: 2007/06/06 14:03:22 $

=item $Rev: 71 $

=cut

1;
