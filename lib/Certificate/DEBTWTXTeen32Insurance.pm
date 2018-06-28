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

package Certificate::DEBTWTXTeen32Insurance;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use MysqlDB;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;

sub printCertificate {
    my $self = shift;
    my ($userId,$userData,$outputType,$printId,$printerKey,$accompanyLetter,$productId,$rePrintData)=@_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $yDiff=0;
    my $outputFile = "/tmp/$userId.pdf";
    $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
    #$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/DE_Insurance_Cert.jpg",
    #                            0, 300, 595, 396,934,604);
    my $template = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/DEBTWTXTeen32Insurance.pdf";
    $self->{PDF}->setTemplate($template,'','1');

    $self->{PDF}->setFont('HELVETICA', 10);

    $self->{PDF}->writeLine(110, 717, $userData->{LEARNERSPERMITNUMBER});
    $self->{PDF}->writeLine(93, 705, $userData->{REPLACED_CERTIFICATE_NUMBER});##Or, the OriControlNumber

    $self->{PDF}->writeLine(532, 679, $userData->{SCHOOLLICENSENUMBER});

    my $studentName = "$userData->{FIRST_NAME} $userData->{LAST_NAME}";
    $self->{PDF}->writeLine(220, 584, $studentName);

    my $totalDuration = ($userData->{SEVENBTWINSTRUCTION}) ? $userData->{SEVENBTWINSTRUCTION} : '0';
    $self->{PDF}->writeLine(438, 557, $totalDuration);

    my $laboratoryCompletionDate = $userData->{LABORATORYCOMPLETIONDATEFORMATTED};
    $self->{PDF}->writeLine(298, 530, $laboratoryCompletionDate);

    my $schoolAddress = "$userData->{SCHOOLADDRESS} $userData->{SCHOOLCITY}, $userData->{SCHOOLSTATE} $userData->{SCHOOLZIP}";
    if(!$userData->{SCHOOLADDRESS}) {
	##Doesn't happen, but to handle the exception
	my $OFFICECA = $self->{SETTINGS}->getOfficeCa('DRIVERSEDTX');
	$schoolAddress = "$OFFICECA->{ADDRESS} $OFFICECA->{CITY}, $OFFICECA->{STATE} $OFFICECA->{ZIP}";
    	$self->{PDF}->writeLine(400, 530, $OFFICECA->{ADDRESS});
    	$self->{PDF}->writeLine(400, 514, "$OFFICECA->{CITY}, $OFFICECA->{STATE} $OFFICECA->{ZIP}");
    } else {
    	$self->{PDF}->writeLine(400, 530, $userData->{SCHOOLADDRESS});
    	$self->{PDF}->writeLine(400, 514, "$userData->{SCHOOLCITY}, $userData->{SCHOOLSTATE} $userData->{SCHOOLZIP}");
    }

    ##Print Michael Black Signature
    my $schoolOfficial = $userData->{SIGNATUREOFCHIEFSCHOOLOFFICIAL};
    $self->{PDF}->getCertificate;

    ###### print the certificate number
    my $variableDataStr='';
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
    	$printId=$self->MysqlDB::getNextId('contact_id');
    }
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);

    my $st='TX';   ##########  Default state, we have mentioned as XX;
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    my ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'INSURANCECERT');
    if(!$printer){
    	$printer='HP-PDF-HOU02';
	$media='Tray4';
    }
    my $ph;
    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media $outputFile");
    close $ph;
    if(-e $outputFile){
	unlink $outputFile;
    }

    if($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq '1'){
	$self->printRegularLabel($userId, $userData);
    }
    return $printId;
}

sub printRegularLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    #my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/ADULT_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    #$self->{PDF}->setTemplate($top,$bottom,$full);
    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('DRIVERSEDTX');
    }
    my $xDiff='';
    $self->_printCorporateAddress2(55-$xDiff,725, $OFFICECA,'DriversEd.com');    
    
    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 55, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 55, $yPos, $userData->{ADDRESS_1} );
    $yPos -=11;
    if($userData->{ADDRESS_2}){
    	$self->{PDF}->writeLine( 55, $yPos, $userData->{ADDRESS_2} );
	$yPos -=11;
    }
    $self->{PDF}->writeLine( 55, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}");
    $self->{PDF}->getCertificate;
    my $printer = 0;
    my $media = 0;
    my $st='XX';   ##########  Default state, we have mentioned as XX;
    my $productId=41;  ##### This is for Driversed 
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
    if(!$printer){
                $printer = 'HP-PDF-HOU02';
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

1;
