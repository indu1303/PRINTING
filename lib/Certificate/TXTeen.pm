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

package Certificate::TXTeen;

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
    my ($userId, $userData,$printId,$productId,$reprintData,$faxEmail) = @_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $yDiff=0;
    if($userData->{PERMITCERTS}){
    	###### as we do w/ all things, let's start at the top.  Print the header	
    	###### now, print the user's name and address
	    $self->{PDF}->setFont('HELVETICABOLD', 12);
	    if($userData->{DUPLICATE_PERMIT_CERTS}){
	    	$self->{PDF}->writeLine( 299-$xDiff, 674-$yDiff, 'X' );
    	    }
	    $self->{PDF}->writeLine( 27-$xDiff, 675-$yDiff, 'X' );
	    $self->{PDF}->writeLine( 27-$xDiff, 642-$yDiff, 'X' );
	
	
	    $self->{PDF}->setFont('HELVETICA', 12);

	    $self->{PDF}->writeLine( 500-$xDiff, 712-$yDiff, 'PT '  . $userData->{CERTIFICATE_NUMBER} );
    
	    $self->{PDF}->setFont('HELVETICABOLD', 10);

	    if($userData->{DUPLICATE_PERMIT_CERTS}){
		$self->{PDF}->writeLine( 450-$xDiff, 680-$yDiff,  $userData->{CERTIFICATE_REPLACED} );
	    }

	    $self->{PDF}->writeLine( 68-$xDiff, 599-$yDiff, $userData->{LAST_NAME} );
	    $self->{PDF}->writeLine( 220-$xDiff, 599-$yDiff, $userData->{FIRST_NAME} );
	    $userData->{DATE_OF_BIRTH} =~ s/\// /g;
	    my @dob=split(/ /, $userData->{DATE_OF_BIRTH});
	    $userData->{DATE_OF_BIRTH}=$dob[0]. '  ' . $dob[1]. '    ' . $dob[2];
	    $self->{PDF}->writeLine( 442-$xDiff, 598-$yDiff, $userData->{DATE_OF_BIRTH} );
	    if($userData->{SEX} && $userData->{SEX} eq 'M'){
	    	$self->{PDF}->writeLine( 513-$xDiff, 598-$yDiff, 'X' );
	    }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
	    	$self->{PDF}->writeLine( 549-$xDiff, 598-$yDiff, 'X' );
    	}
	my $completionDate=$userData->{SECTION_COMPLETE_DATE};


	if($userData->{DPSPERMITEXAM_ROADRULESSCORE}) {
		$self->{PDF}->writeLine(370, 550+$yDiff, $userData->{DPSPERMITEXAM_ROADRULESSCORE} );
		$self->{PDF}->writeLine(480, 550+$yDiff, $userData->{DPSPERMITEXAM_ROADSIGNSSCORE} );
		$self->{PDF}->writeLine(27, 548+$yDiff, 'X' ); ##Exam Completed
	} else {
		$self->{PDF}->writeLine(27,564+$yDiff, 'X' ); ##Exam to take at DPS
	}

	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/sig.jpg",
                                113-$xDiff, 453-$yDiff, 75, 25,1050,305);
	$self->{PDF}->writeLine( 300-$xDiff, 457-$yDiff, '109');
	$self->{PDF}->writeLine( 475-$xDiff, 457-$yDiff, $completionDate);
   }else{
    	###### as we do w/ all things, let's start at the top.  Print the header	
    	###### now, print the user's name and address
	    $self->{PDF}->setFont('HELVETICABOLD', 12);
	    if($userData->{DUPLICATE_CERTS}){
    		$self->{PDF}->writeLine( 327-$xDiff, 716-$yDiff, 'X' );
    	    }
	    $self->{PDF}->writeLine( 26-$xDiff, 715-$yDiff, 'X' );
	
	
	    $self->{PDF}->setFont('HELVETICA', 12);

	    $self->{PDF}->writeLine( 500-$xDiff, 750-$yDiff, 'PT '  . $userData->{CERTIFICATE_NUMBER} );
    
	    $self->{PDF}->setFont('HELVETICABOLD', 10);

	    if($userData->{DUPLICATE_CERTS}){
    		$self->{PDF}->writeLine( 475-$xDiff, 718-$yDiff,  $userData->{CERTIFICATE_REPLACED} );
	    }

	    $self->{PDF}->writeLine( 68-$xDiff, 652-$yDiff, $userData->{LAST_NAME} );
	    $self->{PDF}->writeLine( 220-$xDiff, 652-$yDiff, $userData->{FIRST_NAME} );
	    $userData->{DATE_OF_BIRTH} =~ s/\// /g;
	    my @dob=split(/ /, $userData->{DATE_OF_BIRTH});
	    $userData->{DATE_OF_BIRTH}=$dob[0]. '  ' . $dob[1]. '    ' . $dob[2];
	    $self->{PDF}->writeLine( 442-$xDiff, 652-$yDiff, $userData->{DATE_OF_BIRTH} );
	    if($userData->{SEX} && $userData->{SEX} eq 'M'){
	    	$self->{PDF}->writeLine( 513-$xDiff, 650-$yDiff, 'X' );
	    }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
    		$self->{PDF}->writeLine( 549-$xDiff, 650-$yDiff, 'X' );
    	}
	my $completionDate=$userData->{COMPLETION_DATE};
    		 $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/sig.jpg",
                                120-$xDiff, 548-$yDiff, 75, 25,1050,305);
		 $self->{PDF}->writeLine( 300-$xDiff, 550-$yDiff, '109');
		 $self->{PDF}->writeLine( 475-$xDiff, 550-$yDiff, $completionDate);
	if(($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq '1') || !$userData->{DELIVERY_ID}){
    		my $yPos=257;
		$self->{PDF}->setFont('HELVETICABOLD', 9);
		$self->{PDF}->writeLine( 580, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME},180 );
		$yPos +=11;
		$xDiff=0;
		my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
		if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
		        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
		}
		$self->{PDF}->writeLine( 580,65,'I DRIVE SAFELY',180);
		$self->_printCorporateAddressReverse(580-$xDiff, 77, $OFFICECA,'teen.idrivesafely.com');

		$self->{PDF}->setFont('HELVETICABOLD', 8);
		$self->{PDF}->writeLine( 580, $yPos, $userData->{ADDRESS_1} ,180);
		$yPos +=11;
		 if($userData->{ADDRESS_2}){
		        $self->{PDF}->writeLine( 580, $yPos, $userData->{ADDRESS_2} ,180);
		        $yPos +=11;
		}
		$self->{PDF}->writeLine( 580, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}",180);


	}


   }
    ###### print the certificate number
    my $variableDataStr='';
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$faxEmail){
        if(!$printId){
                $printId=$self->MysqlDB::getNextId('contact_id');
        }
        if(!$userData->{NOMANIFEST}){
                $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
        }
    }
    return ($self->{PDF},$printId);

}

sub constructor
{
	my $self = shift;
	my ($userId,$top,$bottom,$faxEmail,$permitCerts,$regDate)=@_;
	my $imagesName="TXTeenNew.jpg";
	if($regDate && $regDate>'20130831'){
		$imagesName="TXTeenNew.jpg";
	}
	if($permitCerts){
		$imagesName="TXTeenPermit.jpg";
	}
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/$imagesName",
                                0, 387, 612, 396,1275,825);
	 return $self;
}

1;
