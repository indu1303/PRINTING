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

package Certificate::AARPVolunteerCertificate;

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
    my $layout = $self->getCourseCertificateLayout($userData->{COURSE_ID},$productId);
    my $LINESPACE       = 12;

    ##### Let's give a delivery flag
    ###### add the delivery flag
    $self->{PDF}->setFont('HELVETICABOLD', 9);

    ###### as we do w/ all things, let's start at the top.  Print the header	
    $userData->{NAME}= $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME};
    $self->{PDF}->setFont('HELVETICA', 8);
    $userData->{EXPIRATION_DATE}=($userData->{EXPIRATION_DATE})?$userData->{EXPIRATION_DATE}:$userData->{EXPIRATION_DATE2};
    my $headerDesc=$self->getCertificateHeader($layout->{HEADER});

    my $yPos=329;
    $yPos -=12;
	
    ###### let's print the disclaimer on the right
    $self->{PDF}->setFont('HELVETICA', 6);
    my $yDisclaimer = 555; 
    
    my $certMsgData='';
    my $yPS=21;
    
    $yDisclaimer -= 15;
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('AARP');
    my $productName=$self->{SETTINGS}->{PRODUCT_NAME}->{$productId};
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
	    if(exists $self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName}){
                        $OFFICECA=$self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName};
                }else{
                        $OFFICECA = $self->{SETTINGS}->getOfficeCa($productName);
            }
    }




    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
        #$OFFICECA = $self->{SETTINGS}->getOfficeCa('AARP',1);
    }
    my $certFor='';	
    my $certFor2='';	
    if($userData->{CERTFOR} && $userData->{CERTFOR} eq 'O'){
		$certFor='DRIVER SAFETY ORIENTATION';
		$certFor2='AARP Driver Safety Orientation';
    }elsif($userData->{CERTFOR} && $userData->{CERTFOR} eq 'I'){
		$certFor='DRIVER SAFETY INSTRUCTIONAL TRAINING';
		$certFor2='AARP Driver Safety Instructional Training';
    }elsif($userData->{CERTFOR} && $userData->{CERTFOR} eq 'A'){
		$certFor='DRIVER SAFETY SYSTEM & ADMINISTRATIVE TRAINING';
		$certFor2='AARP Driver Safety System & Administrative Training';
    }
    
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine(60-$xDiff, 294, 'AARP');
    $self->{PDF}->writeLine(60-$xDiff, 284, $certFor);


    ###### print the signature
    #if(!$faxEmail){
	$self->_printVertCorporateAddress(60-$xDiff,274, $OFFICECA,'www.aarpdriversafety.org');

    #}

    $self->{PDF}->setFont('HELVETICA', 10);
    $self->{PDF}->writeLine( 220-$xDiff, 353,  $certFor2);

    $self->{PDF}->setFont('HELVETICA', 14);
    $self->{PDF}->writeLine( 190-$xDiff, 336,  'CERTIFICATE OF COMPLETION');

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    $self->_printAddress( 158, $userData);
    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICABOLD', 12);
    $self->{PDF}->writeLine( 420-$xDiff, 336, 'Certificate #: '.$userData->{CERTIFICATE_NUMBER} );
    $userData->{CERT_1}='PARTICIPANT COPY';
    my $coupon = $userData->{COUPON};
    if(!$userData->{UPSELLEMAIL} && !$userData->{UPSELLMAIL}){
    	$self->{PDF}->writeLine( 470-$xDiff, 38, $userData->{CERT_1});
        $self->{PDF}->setFont('HELVETICA', 10);
	$self->{PDF}->writeLine( 475-$xDiff, 28,'(Retain for your Records)');
    }	

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $countyId = $userData->{COUNTY_ID};
    my $courseId = $userData->{COURSE_ID};
    my $y = 291;
    $yPS = 138;
    my $xOffset = 320;
    my $courseData='';
    $self->{PDF}->setFont('HELVETICA', 8);
    my @variableData;

    for (my $i=0; $i < 1; ++$i)
    {
	my $arrCtr=0;
        foreach my $rank(sort keys %$fields)
        {
	    my $fieldId = $fields->{$rank};
            my $field = $self->getCertificateField($fieldId);
	    my $miscData=$self->getCourseMiscellaneousData($fieldId,$courseId,$productId);
	    if(exists $miscData->{DEFAULT} && $miscData->{DEFAULT}){
			$field->{DEFAULT}=$miscData->{DEFAULT};
	    }
	    my $fieldValue='';
		if ($field->{DEFINITION} eq 'Date Of Birth') {
                        $field->{XPOS} = 83;
                }
            $self->{PDF}->writeLine( $xOffset + $field->{XPOS}-$xDiff, $y, "$field->{DEFINITION}:" );

            if ($field->{DEFAULT})
            {
                ##### is there a default value which needs to be filled in?
	 	my $mainPrintVal = Certificate::maxLineWidth($field->{DEFAULT});
	        $self->{PDF}->writeLine( $xOffset + 140-$xDiff, $y, $mainPrintVal->{MAINLINE} );
    
        	if ($mainPrintVal->{REM})
	        {
        	        $y -= $LINESPACE-2;
                	$self->{PDF}->writeLine( $xOffset + 140-$xDiff, $y, $mainPrintVal->{REM});
	        }
		$fieldValue=$field->{DEFAULT};
            }
            elsif ($field->{CITATION})
            {
		$userData->{CITATION}->{$field->{DATA_MAP}}=($userData->{CITATION}->{$field->{DATA_MAP}})?$userData->{CITATION}->{$field->{DATA_MAP}}:'NONE';
                ##### is this citation information
                my $mainPrintVal = Certificate::maxLineWidth($userData->{CITATION}->{$field->{DATA_MAP}});
                $self->{PDF}->writeLine( $xOffset + 140-$xDiff, $y, $mainPrintVal->{MAINLINE});

                if ($mainPrintVal->{REM})
                {
                        $y -= $LINESPACE-2;
                        $self->{PDF}->writeLine( $xOffset + 140-$xDiff, $y, $mainPrintVal->{REM});
                }
		$fieldValue=$userData->{CITATION}->{$field->{DATA_MAP}};
            }
            else
            {
                ##### default case
		$userData->{$field->{DATA_MAP}}=($userData->{$field->{DATA_MAP}})?$userData->{$field->{DATA_MAP}}:'NONE';
                my $mainPrintVal = Certificate::maxLineWidth($userData->{$field->{DATA_MAP}});
                $self->{PDF}->writeLine( $xOffset + 140-$xDiff, $y, $mainPrintVal->{MAINLINE});

                if ($mainPrintVal->{REM})
                {
                        $y -= $LINESPACE-2;
                        $self->{PDF}->writeLine( $xOffset + 140-$xDiff, $y, $mainPrintVal->{REM});
                }

		$fieldValue=$userData->{$field->{DATA_MAP}};
            }
	    if($faxEmail == 2 && $i==0){
		$courseData .= $xOffset + $field->{XPOS} ." $yPS moveto ($field->{DEFINITION}:)show\n";
		$courseData .= $xOffset +100 ." $yPS moveto ($fieldValue)show\n";
		$yPS -=12;
	    }
            $variableData[$arrCtr++]="$field->{DEFINITION}:$fieldValue";
             
            ##### reset the y
            $y -= 12;
        }
        $xOffset = 320;
    }
    $self->{PDF}->setFont('HELVETICA', 8);
    return ($self->{PDF},$printId,'');
}


sub constructor
{
        my $self = shift;
        my ($userId,$top,$bottom,$faxEmail)=@_;

                $self->{PS} = $self->getFile($self->{SETTINGS}->{TEMPLATESPATH}."/printing/userCert.ps");
                $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,396);
                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_aarp_volunteer.jpg",
                                0, 0, 612, 396,1275,829);
       return $self;
}

1;
