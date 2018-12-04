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

package Certificate::DETXAdult;

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
    $self->{PDF}->writeLine( 510-$xDiff, 354-$yDiff, $userData->{CERTIFICATE_NUMBER});
    $self->{PDF}->writeLine( 510-$xDiff, 754-$yDiff, $userData->{CERTIFICATE_NUMBER});
    $self->{PDF}->writeLine( 33-$xDiff,  758-$yDiff, 'DPS COPY');
    $self->{PDF}->writeLine( 33-$xDiff, 358-$yDiff, 'STUDENT COPY');
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    ###### as we do w/ all things, let's start at the top.  Print the header	
    ###### now, print the user's name and address
     $self->{PDF}->writeLine( 24-$xDiff, 320-$yDiff, 'X');
     $self->{PDF}->writeLine( 24-$xDiff, 720-$yDiff, 'X');
     $self->{PDF}->writeLine( 325-$xDiff,280-$yDiff, 'X');
     $self->{PDF}->writeLine( 325-$xDiff,680-$yDiff, 'X');
     $self->{PDF}->writeLine( 24-$xDiff, 665-$yDiff, 'X');
     $self->{PDF}->writeLine( 24-$xDiff, 265-$yDiff, 'X');
     $self->{PDF}->writeLine( 24-$xDiff, 211-$yDiff, 'X');
     $self->{PDF}->writeLine( 24-$xDiff, 611-$yDiff, 'X');
     if($userData->{REPLACED_CERTIFICATE_NUMBER}){
     	$self->{PDF}->writeLine( 330-$xDiff, 320-$yDiff, 'X');
     	$self->{PDF}->writeLine( 330-$xDiff, 720-$yDiff, 'X');
     	$self->{PDF}->writeLine( 460-$xDiff, 320-$yDiff, $userData->{REPLACED_CERTIFICATE_NUMBER});
     	$self->{PDF}->writeLine( 460-$xDiff, 720-$yDiff, $userData->{REPLACED_CERTIFICATE_NUMBER});
	
     }

    my @compDateArr=split(/\//,$userData->{COMPLETION_DATE});
 
    $self->{PDF}->writeLine( 492-$xDiff, 280-$yDiff, $compDateArr[0]);
    $self->{PDF}->writeLine( 519-$xDiff, 280-$yDiff, $compDateArr[1]);
    $self->{PDF}->writeLine( 542-$xDiff, 280-$yDiff, $compDateArr[2]);
    $self->{PDF}->writeLine( 492-$xDiff, 680-$yDiff, $compDateArr[0]);
    $self->{PDF}->writeLine( 519-$xDiff, 680-$yDiff, $compDateArr[1]);
    $self->{PDF}->writeLine( 542-$xDiff, 680-$yDiff, $compDateArr[2]);

    $self->{PDF}->writeLine( 395-$xDiff,255-$yDiff, 'P');
    $self->{PDF}->writeLine( 500-$xDiff,255-$yDiff, 'P');	
    $self->{PDF}->writeLine( 395-$xDiff,655-$yDiff, 'P');
    $self->{PDF}->writeLine( 500-$xDiff,655-$yDiff, 'P');	

    $self->{PDF}->writeLine( 67-$xDiff, 181-$yDiff, $userData->{LAST_NAME} );
    $self->{PDF}->writeLine( 220-$xDiff, 181-$yDiff, $userData->{FIRST_NAME} );
    $self->{PDF}->writeLine( 67-$xDiff, 581-$yDiff, $userData->{LAST_NAME} );
    $self->{PDF}->writeLine( 220-$xDiff, 581-$yDiff, $userData->{FIRST_NAME} );
    if($userData->{DATE_OF_BIRTH} =~ m/\-/g){
	my @birthDateArr1=split(/\-/,$userData->{DATE_OF_BIRTH});
	$birthDateArr1[1]=uc $birthDateArr1[1];
	$birthDateArr1[1]=$self->{SETTINGS}->{MONTH_NUM}->{$birthDateArr1[1]};
	$userData->{DATE_OF_BIRTH}=$birthDateArr1[1].'/'.$birthDateArr1[0].'/'.$birthDateArr1[2]
    }
    my @birthDateArr=split(/\//,$userData->{DATE_OF_BIRTH});
    $self->{PDF}->writeLine( 437-$xDiff, 178-$yDiff, $birthDateArr[0]);
    $self->{PDF}->writeLine( 458-$xDiff, 178-$yDiff, $birthDateArr[1]);
    $self->{PDF}->writeLine( 476-$xDiff, 178-$yDiff, $birthDateArr[2]);
    $self->{PDF}->writeLine( 437-$xDiff, 578-$yDiff, $birthDateArr[0]);
    $self->{PDF}->writeLine( 458-$xDiff, 578-$yDiff, $birthDateArr[1]);
    $self->{PDF}->writeLine( 476-$xDiff, 578-$yDiff, $birthDateArr[2]);
    if($userData->{SEX} && $userData->{SEX} eq 'M'){
     	$self->{PDF}->writeLine( 507-$xDiff, 178-$yDiff, 'X');
     	$self->{PDF}->writeLine( 507-$xDiff, 578-$yDiff, 'X');
                                       
    }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
     	$self->{PDF}->writeLine( 549-$xDiff, 178-$yDiff, 'X');
     	$self->{PDF}->writeLine( 549-$xDiff, 578-$yDiff, 'X');
    }

    $self->{PDF}->writeLine( 300-$xDiff, 120-$yDiff, '6541');
    $self->{PDF}->writeLine( 393-$xDiff, 120-$yDiff, 'Easy Driving School, LLC dba DriversEd.com');
    $self->{PDF}->writeLine( 300-$xDiff, 520-$yDiff, '6541');
    $self->{PDF}->writeLine( 393-$xDiff, 520-$yDiff, 'Easy Driving School, LLC dba DriversEd.com');

    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/Michael_Black_Signature.jpg",
                                62-$xDiff, 120-$yDiff, 57, 17,228,68);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/CStokes-Signature.jpg",
                                62-$xDiff, 92-$yDiff, 34, 17,500,270);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/Michael_Black_Signature.jpg",
                                62-$xDiff, 520-$yDiff, 57, 17,228,68);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/CStokes-Signature.jpg",
                                62-$xDiff, 492-$yDiff, 34, 17,500,270);
    $self->{PDF}->writeLine( 300-$xDiff,93-$yDiff, 'C2548');
    $self->{PDF}->writeLine( 474-$xDiff, 93-$yDiff, Settings::getDateFormat());
    $self->{PDF}->writeLine( 180-$xDiff, 66-$yDiff, 'DriversEd.com 888-651-2886');
    $self->{PDF}->writeLine( 300-$xDiff,493-$yDiff, 'C2548');
    $self->{PDF}->writeLine( 474-$xDiff, 493-$yDiff, Settings::getDateFormat());
    $self->{PDF}->writeLine( 180-$xDiff, 466-$yDiff, 'DriversEd.com 888-651-2886');

   ###### print the certificate number
    my $variableDataStr='';
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
    	$printId=$self->MysqlDB::getNextId('contact_id');
    }
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);

    if($userData->{DELIVERY_ID} && ($userData->{DELIVERY_ID} eq '1')){
	if($userData->{DELIVERY_DEF} && $userData->{DELIVERY_DEF} eq 'DWNLD') {
	#No Label printing for DWNLD Users
	} else {
	$self->printDriversEdLabel($userId, $userData);
	}
    }
    return ($self->{PDF},$printId);

}

sub printDriversEdLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    #my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/DRIVERSED_Certificate_Label.pdf";
    #my $full=1;
    #my $bottom='';
    #$self->{PDF}->setTemplate($top,$bottom,$full);
    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
 
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('DRIVERSED');
    $self->{PRODUCT}='DRIVERSED';
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
 	if(exists $self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$self->{PRODUCT}}){
        	$OFFICECA=$self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$self->{PRODUCT}};   ####### Set for Houston Offfice with product'
        }
    }
    my $xDiff='';
    $self->{PDF}->setFont('HELVETICA', 9);
    $self->_printCorporateAddress2(21-$xDiff,662, $OFFICECA,'DriversEd.com');
    
    
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
    my $productId=41;  ##### This is for Adult 
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
    if(!$printer){
                $printer = 'HP-PDF-MANUAL';
    }
    if(!$media){
                $media='Tray4';
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
                $self->{PDF} = Certificate::PDF->new($userId);
		$top='DEadultTX.pdf';
		$bottom='DEadultTX.pdf';
                $top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
                $bottom = ($bottom)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$bottom":'';
                $self->{PDF}->setTemplate($top,$bottom);
	 return $self;

}

1;
