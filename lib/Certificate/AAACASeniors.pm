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

package Certificate::AAACASeniors;

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
    my $xDiff=30;
    my $yDiff=-188;
    ###### as we do w/ all things, let's start at the top.  Print the header	
    ###### now, print the user's name and address
    if($userData->{COURSE_ID} == 5002){
	    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/tick90.jpg",
                                242-$xDiff, 226-$yDiff, 13, 16,27,32);
    }
    #if($userData->{COURSE_ID} == 400005){
    #		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/tick90.jpg",
    #                            242-$xDiff, 348-$yDiff, 13, 16,27,32);
    #}
    
    $self->{PDF}->setFont('HELVETICABOLD', 10);
    $self->{PDF}->writeLine( 280-$xDiff, 80-$yDiff, $userData->{DRIVERS_LICENSE} ,90);
    $self->{PDF}->writeLine( 280-$xDiff, 270-$yDiff, $userData->{COMPLETION_DATE} ,90);
    $self->{PDF}->writeLine( 280-$xDiff, 451-$yDiff, 'M0135' ,90);
    $self->{PDF}->writeLine( 304-$xDiff, 80-$yDiff, "$userData->{FIRST_NAME} $userData->{LAST_NAME}" ,90);
    my $address=$userData->{ADDRESS_1};
    if($userData->{ADDRESS_2}){
	$address .= ", $userData->{ADDRESS_2}";
    }
    $self->{PDF}->writeLine( 304-$xDiff, 260-$yDiff, $address ,90);
    $self->{PDF}->writeLine( 304-$xDiff, 451-$yDiff, $userData->{CITY} ,90);
    $self->{PDF}->writeLine( 328-$xDiff, 80-$yDiff, 'AAA Mature Safe Driver Program',90);
    $self->{PDF}->writeLine( 328-$xDiff, 260-$yDiff, '3333 Fairview Road, MS A193,',90);
    $self->{PDF}->writeLine( 328-$xDiff, 451-$yDiff, 'Costa Mesa,CA',90);

    $self->{PDF}->writeLine( 350-$xDiff, 451-$yDiff, Settings::getDate,90);
    $self->{PDF}->writeLine( 350-$xDiff, 125-$yDiff, 'AAA Mature Safe Driver Program',90);
    $self->{PDF}->writeLine( 403-$xDiff, 80-$yDiff, 'Ronald Salamanca',90);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/aaasalamancasig1.jpg",
                                383-$xDiff, 391-$yDiff, 35, 105,305,1050);
    
    my @variableData;
    my $variableDataStr=join '~',@variableData;
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
        $printId=$self->MysqlDB::getNextId('contact_id');
    }
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);

    return ($self->{PDF},$printId);
}

sub printAAACASeniorsLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/AAA_SENIORS_CA_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    $self->{PDF}->setTemplate($top,$bottom,$full);
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    my $OFFICECA_AAA = $self->{SETTINGS}->getOfficeCa('AAA_SENIORS');
    $self->_printCorporateAddress(21 , 665, $OFFICECA_AAA,'roadwisedriver.aaa.com');

    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $yPos -=11;
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
    my $st='CA';   
    my $productId=38; 
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
    if(!$printer){
        $printer = 'HP-PDF-MANUAL';
    }
    if(!$media){
            $media='Tray2';
    }

                my $outputFile = "/tmp/LABEL$userId.pdf";
		#print STDERR "\n Label: $outputFile \n";
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
        return $self;
}

1;
