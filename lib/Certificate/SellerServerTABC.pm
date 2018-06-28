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

package Certificate::SellerServerTABC;

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
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $LINESPACE       = 12;

    ##### Let's give a delivery flag
    ###### add the delivery flag
    $self->{PDF}->setFont('HELVETICABOLD', 9);

    ###### as we do w/ all things, let's start at the top.  Print the header	
    ###### now, print the user's name and address
    $self->{PDF}->writeLine( 290-$xDiff, 472, $userData->{CERTIFICATE_NUMBER} );
    $self->{PDF}->writeLine( 205-$xDiff, 405, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    my $expirationDate=($userData->{EXPIRATION_DATE_2YEARS_1DAY})?$userData->{EXPIRATION_DATE_2YEARS_1DAY}:$userData->{EXPIRATION_DATE2};
    $self->{PDF}->writeLine( 350-$xDiff, 350, $expirationDate );
    ###### print the certificate number

    ###### now, let's print out the fields....
    my @variableData;

    ###### how about the course def
    if($faxEmail == 2){
	    $self->{PS} =~ s/\[!IDS::FIRST_NAME!\]/$userData->{FIRST_NAME}/g;
	    $self->{PS} =~ s/\[!IDS::LAST_NAME!\]/$userData->{LAST_NAME}/g;
    }
    my $variableDataStr=join '~',@variableData;
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$faxEmail){
	if(!$printId){
		$printId=$self->MysqlDB::getNextId('contact_id');
    	}
    	$self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    }

    if($userData->{DELIVERY_ID} && ($userData->{DELIVERY_ID} eq '1' || $userData->{DELIVERY_ID} eq '24')){
    	$self->printRegularLabel($userId,$userData);
    }

    return ($self->{PDF},$printId,'',$self->{PS});
}


sub printRegularLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/CA_TEEN_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    my $xDiff='';
    $self->{PDF}->setTemplate($top,$bottom,$full);
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{DR_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    $self->_printCorporateAddress(21-$xDiff, 662, $OFFICECA, '');



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
     my $st='TX';
     my $productId=27;
	if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} ne 'TX'){
	    $st = $userData->{COURSE_STATE};
	    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
	} else {
	    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERT');
	}
    if(!$printer){
                $printer = 'HP-PDF-HOU05';
    }
    if(!$media){
                $media='Tray4';
    }

                my $outputFile = "/tmp/LABEL$userId.pdf";


                my $ph;
                open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
                close $ph;
                if(-e $outputFile){
                        unlink $outputFile;
                }

}

sub printRegularLabelForDISK
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/CA_TEEN_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    my $xDiff='-72';
   # $self->{PDF}->setTemplate($top,$bottom,$full);
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{DR_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    $self->{PDF}->setFont('HELVETICABOLD', 11);
    $self->{PDF}->writeLine( 21-$xDiff, 675, 'I DRIVE SAFELY' );
    $self->_printCorporateAddress(21-$xDiff, 662, $OFFICECA, '');



    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 21-$xDiff, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21-$xDiff, $yPos, $userData->{ADDRESS_1} );
    $yPos -=11;
    if($userData->{ADDRESS_2}){
        $self->{PDF}->writeLine( 21-$xDiff, $yPos, $userData->{ADDRESS_2} );
        $yPos -=11;
    }
    $self->{PDF}->writeLine( 21-$xDiff, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}");
    $self->{PDF}->getCertificate;

     my $printer = 0;
     my $media = 0;
     my $st='TX';
     my $productId=27;
     ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'DISKFEDEX');
    if(!$printer){
                $printer = 'HP-PDF-HOU01';
    }
    if(!$media){
                $media='Tray4';
    }

                my $outputFile = "/tmp/LABEL$userId.pdf";


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
        my ($userId,$top,$bottom,$faxEmail,$residentState,$countyId,$productId,$courseState,$weekDay)=@_;
                $self->{PDF} = Certificate::PDF->new($userId);
                $top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
		if($weekDay) {
			my $topFile = $self->{SETTINGS}->{INSTRUCTORINFO}->{$weekDay}->{TEMPLATE};
			my $templateFile = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/$topFile";
			if($topFile && -e $templateFile) {
				$top = $templateFile;
			}
		}
                $bottom = ($bottom)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$bottom":'';
                my $full=(!$bottom)?1:0;

                if($top || $bottom){
                        $self->{PDF}->setTemplate($top,$bottom,$full);
                }
       return $self;
}

1;
