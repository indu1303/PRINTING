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

package Certificate::DENVTeen;

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
    $productId = 41; ##This is for Driversed
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    if($productId eq '41' && exists $self->{SETTINGS}->{DRIVERSED_COURSE_MAPPING}->{$userData->{COURSE_ID}}){
	$userData->{COURSE_ID} = $self->{SETTINGS}->{DRIVERSED_COURSE_MAPPING}->{$userData->{COURSE_ID}};
    }
    my $layout = $self->getCourseCertificateLayout($userData->{COURSE_ID},$productId);

    ##### Let's give a delivery flag
    my $flag = ($userData->{DELIVERY_ID} == 4) ? '(ONM)'
            : ($userData->{DELIVERY_ID} == 3) ? '(ONA)'
            : ($userData->{DELIVERY_ID} == 2)?'(TDX)'
            : '';
    ###### add the delivery flag
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine(140-$xDiff, 700, $flag);


	###### as we do w/ all things, let's start at the top.  Print the header	
    $self->{PDF}->setFont('HELVETICA', 8);
    my @arr = split("<BR>",$self->getCertificateHeader($layout->{HEADER}));
    my $yPos=725;
    foreach my $str(@arr) {
            $self->{PDF}->writeLine( 60-$xDiff, $yPos, $str);
            $yPos -=12;
    }

	
    ###### let's print the disclaimer on the right
    $self->{PDF}->setFont('HELVETICA', 6);
    my $yDisclaimer = 555;
    my $courseId = $userData->{COURSE_ID}; 
    
    if($userData->{PRODUCT_ID} eq 'C0000023' || $userData->{PRODUCT_ID} eq 'C0000053' || $userData->{PRODUCT_ID} eq 'C0000056' || $userData->{PRODUCT_ID} eq 'C0000025') {
		$yDisclaimer = 600;
		if($userData->{PRODUCT_ID} eq 'C0000025') {
			##No Student Declaration for OK Teen
		} else {
	        $self->{PDF}->setFont('HELVETICABOLD', 8);
		$self->{PDF}->writeLine (290, 650, 'STUDENT DECLARATION');
	        $self->{PDF}->setFont('HELVETICA', 7);
		$self->{PDF}->writeLine (290, 638, 'I declare under penalty of perjury that I have personally studied the course material and');
		$self->{PDF}->writeLine (290, 626, 'satisfactorially answered the test questions provided to me by DriversEd.com.');
		$self->{PDF}->writeLine (290, 608, 'SIGNATURE_______________________________________ DATE_______________');
		}

		if($userData->{PRODUCT_ID} eq 'C0000025') {
		        $self->{PDF}->setFont('HELVETICABOLD', 8);
			$self->{PDF}->writeLine (290, 594, 'PARENT/GUARDIAN AND INSTRUCTOR DECLARATION');
		        $self->{PDF}->setFont('HELVETICA', 7);
			$self->{PDF}->writeLine (290, 582, 'I declare under penalty of perjury that my child has personally studied the course material,');
			$self->{PDF}->writeLine (290, 570, 'satisfactorily answered the test questions provided to me by DriversEd.com,');
			$self->{PDF}->writeLine (290, 558, 'and completed the 56 hours of In Car Training.');
			$self->{PDF}->writeLine (290, 536, 'SIGNATURE_______________________________________ DATE_______________');

		        $self->{PDF}->setFont('HELVETICABOLD', 8);
			$self->{PDF}->writeLine (290, 520, 'COURSE PROVIDER DECLARATION');
		        $self->{PDF}->setFont('HELVETICA', 7);
			$self->{PDF}->writeLine (290, 508, 'I hereby certify that the above name student has successfully completed DriversEd.com course');
			$self->{PDF}->writeLine (290, 496, 'based on the information in the DriversEd.com database.');
			$self->{PDF}->writeLine (290, 460, 'SIGNATURE_______________________________________ DATE_______________');
		} else {
		        $self->{PDF}->setFont('HELVETICABOLD', 8);
			$self->{PDF}->writeLine (290, 594, 'PARENT/GUARDIAN DECLARATION');
		        $self->{PDF}->setFont('HELVETICA', 7);
			$self->{PDF}->writeLine (290, 582, 'I declare under penalty of perjury that my child has personally studied the course material and');
			$self->{PDF}->writeLine (290, 570, 'satisfactorily answered the test questions provided to me by DriversEd.com.');
			$self->{PDF}->writeLine (290, 542, 'SIGNATURE_______________________________________ DATE_______________');

		        $self->{PDF}->setFont('HELVETICABOLD', 8);
			$self->{PDF}->writeLine (290, 520, 'INSTRUCTOR DECLARATION');
		        $self->{PDF}->setFont('HELVETICA', 7);
			$self->{PDF}->writeLine (290, 508, 'I hereby certify that the above name student has successfully completed DriversEd.com course');
			$self->{PDF}->writeLine (290, 496, 'based on the information in the DriversEd.com database.');
			$self->{PDF}->writeLine (290, 460, 'SIGNATURE_______________________________________ DATE_______________');
		}
    } else {
    	    my @discMsg=split /~/, $self->getCertificateDisclaimer($layout->{DISCLAIMER});
	    foreach my $cc(@discMsg)
	    {
        	$self->{PDF}->writeLine (350-$xDiff, $yDisclaimer, $cc);
	        $yDisclaimer -=12;
	    }
    }
    
    $yDisclaimer -= 15;

    ###### print the signature
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('DRIVERSEDTX');

    if(!$faxEmail){
	if($userData->{PRODUCT_ID} eq 'C0000023' || $userData->{PRODUCT_ID} eq 'C0000053' || $userData->{PRODUCT_ID} eq 'C0000056' || $userData->{PRODUCT_ID} eq 'C0000025') { 
    		$self->_printSignature(470, $layout->{SIGNATURE},1,1);
	} else {
    		$self->_printSignature($yDisclaimer, $layout->{SIGNATURE},1);
	}
  	$self->_printCorporateAddress(60-$xDiff,690, $OFFICECA,'www.driversed.com');
        $self->_printCorporateAddress(60-$xDiff,89, $OFFICECA,'www.driversed.com');
    }

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    $self->{PDF}->writeLine( 90-$xDiff, 350, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME}.',' );
    $self->_printAddress( 550, $userData);

    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICABOLD', 12);
    $self->{PDF}->writeLine( 500-$xDiff, 738, $userData->{CERTIFICATE_NUMBER} );
    if(exists $self->{SETTINGS}->{CERT_MSG_TOP}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}}){
        $userData->{CERT_1}=$self->{SETTINGS}->{CERT_MSG_TOP}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}};
    }
    $self->{PDF}->writeLine( 480-$xDiff, 420, $userData->{CERT_1});
    if(exists $self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}}){
         my $certMsgBottom=$self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}};
         $self->{PDF}->writeLine( 480-$xDiff, 60,$certMsgBottom);
    }

    if($userData->{COURSE_STATE} eq 'VA') {
	my $vaContent = "This course does not include the 90-minute parent/student driver<br>education component required for residents of District 8<br>(counties of Arlington, Fairfax, Loudoun and Prince William <br>and the cities of Alexandria, Fairfax, Falls Church, Manassas <br>and Manassas Park). <br>";
	my @vaContentArr = split("<br>",$vaContent);
	$self->{PDF}->setFont('HELVETICA', 8);
	$yPos=120;
	foreach my $vaStr(@vaContentArr) {
 		#$self->{PDF}->writeLine( 280-$xDiff, $yPos, $vaStr);
		$yPos -=12;
	}
    }

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $y = 700;
    my $xOffset = 300;
    if($userData->{PRODUCT_ID} eq 'C0000023' || $userData->{PRODUCT_ID} eq 'C0000053' || $userData->{PRODUCT_ID} eq 'C0000056' || $userData->{PRODUCT_ID} eq 'C0000025') { 
		$xOffset = 288;
		$y = 680
    }
    $self->{PDF}->setFont('HELVETICA', 8);
    my @variableData;
    my $LINESPACE=12;
    for (my $i=0; $i < 2; ++$i)
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
    
	    my $xDiffValue = $xDiff;
	    if($userData->{PRODUCT_ID} eq 'C0000023' || $userData->{PRODUCT_ID} eq 'C0000053' || $userData->{PRODUCT_ID} eq 'C0000056' || $userData->{PRODUCT_ID} eq 'C0000025') { 
			$field->{XPOS} = 0;
			$xDiffValue = 48;
	    }

            $self->{PDF}->writeLine( $xOffset + $field->{XPOS}-$xDiff, $y, "$field->{DEFINITION}:" );

            if ($field->{DEFAULT})
            {
                my $mainPrintVal = Certificate::maxLineWidth($field->{DEFAULT});
                $self->{PDF}->writeLine( $xOffset + 110-$xDiffValue, $y, $mainPrintVal->{MAINLINE} );

                if ($mainPrintVal->{REM})
                {
                        $y -= $LINESPACE-2;
                        $self->{PDF}->writeLine( $xOffset + 110-$xDiffValue, $y, $mainPrintVal->{REM});
                }
                $fieldValue=$field->{DEFAULT};

            }
            elsif ($field->{CITATION})
            {
                ##### is this citation information
                $self->{PDF}->writeLine( $xOffset + 110-$xDiffValue, $y, "value:".$userData->{CITATION}->{$field->{DATA_MAP}} );
		$fieldValue=$userData->{CITATION}->{$field->{DATA_MAP}};
            }
            else
            {
                ##### default case
		$userData->{$field->{DATA_MAP}}=($userData->{$field->{DATA_MAP}})?$userData->{$field->{DATA_MAP}}:'NONE';
		if(length($field->{DEFINITION}) > 20) {
                $self->{PDF}->writeLine( $xOffset + 110-$xDiffValue, $y, "                 ".$userData->{$field->{DATA_MAP}} );
		} else {
                $self->{PDF}->writeLine( $xOffset + 110-$xDiffValue, $y, $userData->{$field->{DATA_MAP}} );
		}
		$fieldValue=$userData->{$field->{DATA_MAP}};
            }
            $variableData[$arrCtr++]="$field->{DEFINITION}:$fieldValue";
             
            ##### reset the y
            $y -= 12;
        }
        
        $y = 250;
        $xOffset = 215;
    }

    ###### how about the course def
    $self->{PDF}->setFont('HELVETICA', 8);
    $userData->{COURSE_AGGREGATE_DESC}=($self->Settings::getCourseAggregateOverride($courseId,$productId))?$self->Settings::getCourseAggregateOverride($courseId,$productId):$userData->{COURSE_AGGREGATE_DESC};
    $userData->{COURSE_AGGREGATE_DESC} =~ s/<BR>/ /gi;
    $self->{PDF}->writeLine ( 135-$xDiff, 320, $userData->{COURSE_AGGREGATE_DESC} );
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
	my ($userId,$top,$bottom,$faxEmail)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId);
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
