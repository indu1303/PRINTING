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

package Certificate::TXAdult;

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
    my ($userId, $userData,$printId,$productId,$reprintData) = @_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $yDiff=0;
    $self->{PDF}->setFont('HELVETICA', 11);
    $self->{PDF}->writeLine( 503-$xDiff, 358-$yDiff, $userData->{CERTIFICATE_NUMBER});
    $self->{PDF}->writeLine( 503-$xDiff, 758-$yDiff, $userData->{CERTIFICATE_NUMBER});
    $self->{PDF}->writeLine( 26-$xDiff,  758-$yDiff, 'DPS COPY');
    $self->{PDF}->writeLine( 26-$xDiff, 358-$yDiff, 'STUDENT COPY');
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    ###### as we do w/ all things, let's start at the top.  Print the header	
    ###### now, print the user's name and address
     $self->{PDF}->writeLine( 16-$xDiff, 321-$yDiff, 'X');
     $self->{PDF}->writeLine( 16-$xDiff, 721-$yDiff, 'X');
     $self->{PDF}->writeLine( 318-$xDiff,280-$yDiff, 'X');
     $self->{PDF}->writeLine( 318-$xDiff,682-$yDiff, 'X');
     $self->{PDF}->writeLine( 16-$xDiff, 665-$yDiff, 'X');
     $self->{PDF}->writeLine( 16-$xDiff, 265-$yDiff, 'X');
     $self->{PDF}->writeLine( 16-$xDiff, 211-$yDiff, 'X');
     $self->{PDF}->writeLine( 16-$xDiff, 611-$yDiff, 'X');
     if($reprintData->{CERTIFICATE_NUMBER}){
     	$self->{PDF}->writeLine( 322-$xDiff, 320-$yDiff, 'X');
     	$self->{PDF}->writeLine( 322-$xDiff, 722-$yDiff, 'X');
     	$self->{PDF}->writeLine( 452-$xDiff, 321-$yDiff, $reprintData->{CERTIFICATE_NUMBER});
     	$self->{PDF}->writeLine( 452-$xDiff, 722-$yDiff, $reprintData->{CERTIFICATE_NUMBER});
	
     }

    my @compDateArr=split(/\//,$userData->{COMPLETION_DATE});
 
    $self->{PDF}->writeLine( 484-$xDiff, 280-$yDiff, $compDateArr[0]);
    $self->{PDF}->writeLine( 511-$xDiff, 280-$yDiff, $compDateArr[1]);
    $self->{PDF}->writeLine( 534-$xDiff, 280-$yDiff, $compDateArr[2]);
    $self->{PDF}->writeLine( 486-$xDiff, 680-$yDiff, $compDateArr[0]);
    $self->{PDF}->writeLine( 511-$xDiff, 680-$yDiff, $compDateArr[1]);
    $self->{PDF}->writeLine( 534-$xDiff, 680-$yDiff, $compDateArr[2]);

    $self->{PDF}->writeLine( 392-$xDiff,255-$yDiff, 'P');
    $self->{PDF}->writeLine( 492-$xDiff,255-$yDiff, 'P');	
    $self->{PDF}->writeLine( 392-$xDiff,655-$yDiff, 'P');
    $self->{PDF}->writeLine( 492-$xDiff,656-$yDiff, 'P');	

    $self->{PDF}->writeLine( 59-$xDiff, 178-$yDiff, $userData->{LAST_NAME} );
    $self->{PDF}->writeLine( 212-$xDiff, 178-$yDiff, $userData->{FIRST_NAME} );
    $self->{PDF}->writeLine( 59-$xDiff, 577-$yDiff, $userData->{LAST_NAME} );
    $self->{PDF}->writeLine( 212-$xDiff, 577-$yDiff, $userData->{FIRST_NAME} );
    if($userData->{DATE_OF_BIRTH} =~ m/\-/g){
	my @birthDateArr1=split(/\-/,$userData->{DATE_OF_BIRTH});
	$birthDateArr1[1]=uc $birthDateArr1[1];
	$birthDateArr1[1]=$self->{SETTINGS}->{MONTH_NUM}->{$birthDateArr1[1]};
	$userData->{DATE_OF_BIRTH}=$birthDateArr1[1].'/'.$birthDateArr1[0].'/'.$birthDateArr1[2]
    }
    my @birthDateArr=split(/\//,$userData->{DATE_OF_BIRTH});
    $self->{PDF}->writeLine( 429-$xDiff, 176-$yDiff, $birthDateArr[0]);
    $self->{PDF}->writeLine( 450-$xDiff, 176-$yDiff, $birthDateArr[1]);
    $self->{PDF}->writeLine( 468-$xDiff, 176-$yDiff, $birthDateArr[2]);
    $self->{PDF}->writeLine( 429-$xDiff, 576-$yDiff, $birthDateArr[0]);
    $self->{PDF}->writeLine( 450-$xDiff, 576-$yDiff, $birthDateArr[1]);
    $self->{PDF}->writeLine( 468-$xDiff, 576-$yDiff, $birthDateArr[2]);
    if($userData->{SEX} && $userData->{SEX} eq 'M'){
     	$self->{PDF}->writeLine( 499-$xDiff, 178-$yDiff, 'X');
     	$self->{PDF}->writeLine( 499-$xDiff, 578-$yDiff, 'X');
                                       
    }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
     	$self->{PDF}->writeLine( 541-$xDiff, 178-$yDiff, 'X');
     	$self->{PDF}->writeLine( 541-$xDiff, 578-$yDiff, 'X');
    }

    $self->{PDF}->writeLine( 292-$xDiff, 119-$yDiff, '4433');
    $self->{PDF}->writeLine( 452-$xDiff, 119-$yDiff, 'I DRIVE SAFELY');
    $self->{PDF}->writeLine( 292-$xDiff, 518-$yDiff, '4433');
    $self->{PDF}->writeLine( 452-$xDiff, 518-$yDiff, 'I DRIVE SAFELY');

    if($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq '12') {
	##Signature not required for EML delivery, the signatures already available on the certificate image
    } else {
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/julio.jpg",
                                54-$xDiff, 118-$yDiff, 60, 20,1050,305);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/michaelblack.jpg",
                                54-$xDiff, 88-$yDiff, 60, 20,1050,305);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/julio.jpg",
                                54-$xDiff, 517-$yDiff, 60, 20,1050,305);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/michaelblack.jpg",
                                54-$xDiff, 489-$yDiff, 60, 20,1050,305);
    }
    $self->{PDF}->writeLine( 292-$xDiff,91-$yDiff, 'C2267');
    $self->{PDF}->writeLine( 466-$xDiff, 91-$yDiff, Settings::getDateFormat());
    $self->{PDF}->writeLine( 292-$xDiff,491-$yDiff, 'C2267');
    $self->{PDF}->writeLine( 466-$xDiff, 491-$yDiff, Settings::getDateFormat());

   ###### print the certificate number
    my $variableDataStr='';
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
    	$printId=$self->MysqlDB::getNextId('contact_id');
    }
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    $userData->{DELIVERY_ID} = ($userData->{DELIVERY_ID}) ? $userData->{DELIVERY_ID} : 1; 
    if($userData->{DELIVERY_ID} && ($userData->{DELIVERY_ID} eq '1' || $userData->{DELIVERY_ID} eq '18')){
	$self->printAdultLabel($userId, $userData);
    }
    return ($self->{PDF},$printId);

}

sub printAdultLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    if(!$userData->{DELIVERY_ID} || ($userData->{DELIVERY_ID} && ($userData->{DELIVERY_ID} eq '1' || $userData->{DELIVERY_ID} eq '18'))){

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/ADULT_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    $self->{PDF}->setTemplate($top,$bottom,$full);
    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    my $xDiff='';
    $self->_printCorporateAddress(21-$xDiff,662, $OFFICECA,'adultdrivered.idrivesafely.com');
    
    
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
    my $st='XX';   ##########  Default state, we have mentioned as XX;
    my $productId=18;  ##### This is for Adult 
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

}

sub constructor
{
	my $self = shift;
	my ($userId,$top,$bottom,$faxEmail)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId);

	my $certificateImage = "adultTX.jpg";
	if($faxEmail) {
		$certificateImage = "IDSAdultTXColorImage.jpg";
	}

                $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/$certificateImage",
                                0, 0, 612, 396,934,604);
                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/$certificateImage",
                                0, 400, 612, 396,934,604);

	 return $self;

}

1;
