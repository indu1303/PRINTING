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

package Certificate::AARP;

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
    my $flag = ($userData->{DELIVERY_ID} == 6) ? '(ONM)'
            : ($userData->{DELIVERY_ID} == 5) ? '(ONA)'
            : ($userData->{DELIVERY_ID} == 4)?'(TDX)' 
            : '';
    ###### add the delivery flag

    ###### as we do w/ all things, let's start at the top.  Print the header	
    $self->{PDF}->setFont('HELVETICA', 8);
    $userData->{EXPIRATION_DATE}=($userData->{EXPIRATION_DATE})?$userData->{EXPIRATION_DATE}:$userData->{EXPIRATION_DATE2};
    my $headerDesc=$self->getCertificateHeader($layout->{HEADER});
    $headerDesc =~ s/\[!IDS::COUNTY!\]/$userData->{COUNTY_DEF}/g;
    $headerDesc =~ s/\[!IDS::REGULATOR!\]/$userData->{REGULATOR_DEF}/g;
    $headerDesc =~ s/\[!IDS::STATE!\]/$userData->{COURSE_STATE}/g;
    $headerDesc =~ s/\[!IDS::COURSE DESC!\]/$userData->{COURSE_AGGREGATE_DESC}/g;
    $headerDesc = uc $headerDesc;
    my @arr = split("<BR>",$headerDesc);
    $headerDesc =~ s/<BR>/ /g;

    my $yPos=725;
    foreach my $str(@arr) {
	    $self->{PDF}->writeLine( 60-$xDiff, $yPos, $str);
            $yPos -=12;
    }
	
    ###### let's print the disclaimer on the right
    $self->{PDF}->setFont('HELVETICA', 6);
    my $yDisclaimer = 555; 
    
    my @discMsg=split /~/, $self->getCertificateDisclaimer($layout->{DISCLAIMER});
    my $certMsgData='';
    my $yPS=350;
    
    foreach my $cc(@discMsg)
    {
        $self->{PDF}->writeLine (350-$xDiff, $yDisclaimer, $cc);
        $yDisclaimer -=12;
	$certMsgData.="310 $yPS moveto ($cc) show\n";
	$yPS -=8;
    }
    
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


    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine(60-$xDiff, 676, "AARP Smart Driver Online Course");
    $self->{PDF}->writeLine(60-$xDiff, 284, 'AARP Smart Driver Online Course');


    ###### print the signature
    #if(!$faxEmail){
	$self->_printVertCorporateAddress(60-$xDiff,666, $OFFICECA,'www.aarpdriversafety.org');
	$self->_printVertCorporateAddress(60-$xDiff,274, $OFFICECA,'www.aarpdriversafety.org');

    #}

    $self->{PDF}->setFont('HELVETICA', 10);

    $self->{PDF}->setFont('HELVETICA', 14);
    $self->{PDF}->writeLine( 190-$xDiff, 728,  'CERTIFICATE OF COMPLETION');
    $self->{PDF}->writeLine( 190-$xDiff, 336,  'CERTIFICATE OF COMPLETION');

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    $self->_printAddress( 550, $userData);
    $self->_printAddress( 158, $userData);
    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICABOLD', 12);
    $self->{PDF}->writeLine( 420-$xDiff, 728, 'Certificate #: '.$userData->{CERTIFICATE_NUMBER} );
    $self->{PDF}->writeLine( 420-$xDiff, 336, 'Certificate #: '.$userData->{CERTIFICATE_NUMBER} );
    $userData->{CERT_1}='PARTICIPANT COPY';
    my $coupon = $userData->{COUPON};
    if(!$userData->{UPSELLEMAIL} && !$userData->{UPSELLMAIL}){
    	$self->{PDF}->writeLine( 470-$xDiff, 430, $userData->{CERT_1});
        $self->{PDF}->setFont('HELVETICA', 10);
	$self->{PDF}->writeLine( 475-$xDiff, 420,'(Retain for your Records)');
    }	
    $self->{PDF}->writeLine(60, 64, 'Present this document to your Insurance Company for motor vehicle insurance premium reduction when applicable.');
	$self->{PDF}->setFont('HELVETICABOLD', 12);
         my $certMsgBottom='INSURANCE COPY';
         $self->{PDF}->writeLine( 470-$xDiff, 40,$certMsgBottom);

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $countyId = $userData->{COUNTY_ID};
    my $courseId = $userData->{COURSE_ID};
    my $y = 650;
    $yPS = 467;
    my $xOffset = 320;
    my $courseData='';
    $self->{PDF}->setFont('HELVETICA', 8);
    my @variableData;

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
        $y = 268;
        $xOffset = 320;
    }
    ###### how about the course def
    if($faxEmail == 2){
	    $self->{PS} =~ s/\[!IDS::COURSE_DATA!\]/$courseData/g;
	    $self->{PS} =~ s/\[!IDS::ATTENTION!\]/$userData->{ATTENTION}/g;
	    $self->{PS} =~ s/\[!IDS::FAXNUMBER!\]/$userData->{FAX}/g;
	    $self->{PS} =~ s/\[!IDS::FIRST_NAME!\]/$userData->{FIRST_NAME}/g;
	    $self->{PS} =~ s/\[!IDS::LAST_NAME!\]/$userData->{LAST_NAME}/g;
	    $self->{PS} =~ s/\[!IDS::ADDRESS!\]/$userData->{ADDRESS_1}/g;
	    $self->{PS} =~ s/\[!IDS::CITY!\]/$userData->{CITY}/g;
	    $self->{PS} =~ s/\[!IDS::STATE!\]/$userData->{STATE}/g;
	    $self->{PS} =~ s/\[!IDS::ZIP!\]/$userData->{ZIP}/g;
	    $self->{PS} =~ s/\[!IDS::CERTNUMBER!\]/$userData->{CERTIFICATE_NUMBER}/g;
    	    $self->{PS} =~ s/\[!IDS::TITLE!\]/$headerDesc/g;
    	    $self->{PS} =~ s/\[!IDS::CERT_MSG!\]/$certMsgData/g;
    }
    $self->{PDF}->setFont('HELVETICA', 8);
    $userData->{COURSE_AGGREGATE_DESC} =~ s/<BR>/ /gi;
    #$self->{PDF}->writeLine ( 135-$xDiff, 320, $userData->{COURSE_AGGREGATE_DESC} );
    my $variableDataStr=join '~',@variableData;
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$faxEmail){
	if(!$printId){
		$printId=$self->MysqlDB::getNextId('contact_id');
    	}
    	$self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    }
    return ($self->{PDF},$printId,'',$self->{PS});
}


sub constructor
{
        my $self = shift;
        my ($userId,$top,$bottom,$faxEmail)=@_;

        if($faxEmail){
                $self->{PS} = $self->getFile($self->{SETTINGS}->{TEMPLATESPATH}."/printing/userCert.ps");
                $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_aarp.jpg",
                                0, 0, 612, 792,1275,1650);
        }else{
                $self->{PDF} = Certificate::PDF->new($userId);
                $top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
                $bottom = ($bottom)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$bottom":'';
                my $full=(!$bottom)?1:0;

                if($top || $bottom){
                        $self->{PDF}->setTemplate($top,$bottom,$full);
                }
      }
       return $self;
}

1;
