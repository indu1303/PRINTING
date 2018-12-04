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

package Certificate::AAADIPCertificate;

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
    my $flag = ($userData->{DELIVERY_ID} == 11) ? '(ONM)'
            : ($userData->{DELIVERY_ID} == 2) ? '(ONA)'
            : ($userData->{DELIVERY_ID} == 7)?'(TDX)' 
            : '';
    ###### add the delivery flag
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine(200-$xDiff, 700, $flag);

    ###### as we do w/ all things, let's start at the top.  Print the header	
    $self->{PDF}->setFont('HELVETICA', 8);
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

    my $OFFICECA;
    
    if($userData->{COURSE_ID} == 42004 || $userData->{COURSE_ID} == 42003){
	if (!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
        	$OFFICECA = $self->{SETTINGS}->getOfficeCa('AAADIP',1);
	}else{
        	$OFFICECA = $self->{SETTINGS}->getOfficeCa('AAADIP');
	}
    }else{
        	$OFFICECA = $self->{SETTINGS}->getOfficeCa('AAADIP',1);
    }

    ###### print the signature
    if (!$faxEmail)
    {
        $self->_printCorporateAddress(60-$xDiff, 690, $OFFICECA,'www.aaa.com/onlineDIP');
        $self->_printCorporateAddress(60-$xDiff, 89, $OFFICECA,'www.aaa.com/onlineDIP');
    }

    $self->{PDF}->writeLine ( 350-$xDiff, $yDisclaimer,'By:');
    $yDisclaimer -= 30;
    if($userData->{COURSE_ID} == 42004 || $userData->{COURSE_ID} == 42003){
    	$self->{PDF}->writeLine ( 350-$xDiff, $yDisclaimer,'(Authorized Signature of AAA Oklahoma)');
    } elsif($userData->{AAA_TIDEWATER_CLUB} && $userData->{AAA_TIDEWATER_CLUB} eq '1') {
	$self->{PDF}->writeLine ( 350-$xDiff, $yDisclaimer,'(Authorized Signature of AAA Tidewater Virginia)');
    }else{
        $self->{PDF}->writeLine ( 350-$xDiff, $yDisclaimer,'(Authorized Signature of AAA Mid-Atlantic)');
    }

    ###### print the signature

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    $self->{PDF}->writeLine( 90-$xDiff, 350, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $self->_printAddress( 550, $userData);
    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICABOLD', 12);
    $self->{PDF}->writeLine( 500-$xDiff, 738, $userData->{CERTIFICATE_NUMBER} );
    if(exists $self->{SETTINGS}->{CERT_MSG_TOP}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}}){
        $userData->{CERT_1}=$self->{SETTINGS}->{CERT_MSG_TOP}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}};
    }
    my $coupon = $userData->{COUPON};
    if($coupon){
	if(exists $self->{SETTINGS}->{CERT_MSG_TOP}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{COUPON}->{$coupon}->{$userData->{COURSE_ID}}){
	        $userData->{CERT_1}=$self->{SETTINGS}->{CERT_MSG_TOP}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{COUPON}->{$coupon}->{$userData->{COURSE_ID}};
	}
    }
    if(!$userData->{UPSELLEMAIL} && !$userData->{UPSELLMAIL}){
    	$self->{PDF}->writeLine( 480-$xDiff, 420, $userData->{CERT_1});
    }	
    if(exists $self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}}){
         my $certMsgBottom=$self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}};
         $self->{PDF}->writeLine( 480-$xDiff, 40,$certMsgBottom);
    }

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $countyId = $userData->{COUNTY_ID};
    my $courseId = $userData->{COURSE_ID};
    $userData->{COUNTY_DEF}=($userData->{COUNTY_DEF})?$userData->{COUNTY_DEF}:$userData->{REGULATOR_DEF};
    if($countyId && exists $self->{SETTINGS}->{CTSI_COUNTY}->{$countyId}){
	my $rankNo=(keys %$fields) +1;
	$fields->{$rankNo}=15;		
	$rankNo++;
	$fields->{$rankNo}=2;		
    }
    my $y = 700;
    $yPS = 467;
    my $xOffset = 300;
    my $courseData='';
    $self->{PDF}->setFont('HELVETICA', 8);
    my @variableData;

    for (my $i=0; $i < 2; ++$i)
    {
	my $arrCtr=0;
        foreach my $rank(sort keys %$fields)
        {
	    my $fieldId = $fields->{$rank};
	    if ($userData->{COURSE_ID} == 42003 && ($fieldId == 32 || $fieldId == 33 ||  $fieldId == 34)){
                                next;
            }

            my $field = $self->getCertificateField($fieldId);
	    my $miscData=$self->getCourseMiscellaneousData($fieldId,$courseId,$productId);
	    if(exists $miscData->{DEFAULT} && $miscData->{DEFAULT}){
			$field->{DEFAULT}=$miscData->{DEFAULT};
	    }
	    my $fieldValue='';

            $self->{PDF}->writeLine( $xOffset + $field->{XPOS}-$xDiff, $y, "$field->{DEFINITION}:" );

            if ($field->{DEFAULT})
            {
                ##### is there a default value which needs to be filled in?
	 	my $mainPrintVal = Certificate::maxLineWidth($field->{DEFAULT});
		if($userData->{AAA_TIDEWATER_CLUB} && $userData->{AAA_TIDEWATER_CLUB} eq '1' && $mainPrintVal->{MAINLINE} eq '5086') {
	        $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, '5112' );
		} else {
	        $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $mainPrintVal->{MAINLINE} );
		}
    
        	if ($mainPrintVal->{REM})
	        {
        	        $y -= $LINESPACE-2;
                	$self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $mainPrintVal->{REM});
	        }
		$fieldValue=$field->{DEFAULT};
            }
            elsif ($field->{CITATION})
            {
		$userData->{CITATION}->{$field->{DATA_MAP}}=($userData->{CITATION}->{$field->{DATA_MAP}})?$userData->{CITATION}->{$field->{DATA_MAP}}:'NONE';
                ##### is this citation information
                my $mainPrintVal = Certificate::maxLineWidth($userData->{CITATION}->{$field->{DATA_MAP}});
                $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $mainPrintVal->{MAINLINE});

                if ($mainPrintVal->{REM})
                {
                        $y -= $LINESPACE-2;
                        $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $mainPrintVal->{REM});
                }
		$fieldValue=$userData->{CITATION}->{$field->{DATA_MAP}};
            }
            else
            {
                ##### default case
                if($userData->{COURSE_ID} == 42004 && $fieldId == 6){
			$userData->{$field->{DATA_MAP}}='Insurance';
		}else{
			$userData->{$field->{DATA_MAP}}=($userData->{$field->{DATA_MAP}})?$userData->{$field->{DATA_MAP}}:'NONE';
		}

		$userData->{$field->{DATA_MAP}}=($userData->{$field->{DATA_MAP}})?$userData->{$field->{DATA_MAP}}:'NONE';
                my $mainPrintVal = Certificate::maxLineWidth($userData->{$field->{DATA_MAP}});
                $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $mainPrintVal->{MAINLINE});

                if ($mainPrintVal->{REM})
                {
                        $y -= $LINESPACE-2;
                        $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $mainPrintVal->{REM});
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
        $y = 250;
        $xOffset = 215;
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
    if($userData->{COURSE_ID} == 42004){
	$userData->{COURSE_AGGREGATE_DESC} = 'Online Motor Vehicle Crash Prevention Course';
    }
    $self->{PDF}->writeLine( 135-$xDiff, 320, $userData->{COURSE_AGGREGATE_DESC} );

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

sub _generateMultipleCertificate
{
    my $self = shift;
    my ($userId, $userData,$printId,$userId_1, $userData_1,$printId_1,$productId) = @_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function

    my $loop = 1;
    my @returnArr;
    my $xDiff=0;
    if(!$printId){
	$printId=$self->MysqlDB::getNextId('contact_id');
    }
    if($userId_1 && !$printId_1){
	$printId_1=$self->MysqlDB::getNextId('contact_id');
    }
    if ($userId_1)              {        $loop = 2;    }
    my $yOffset = 0; 
    for (my $i=0; $i < $loop; ++$i)
    {
    my $layout = $self->getCourseCertificateLayout($userData->{COURSE_ID},$productId);

	###### as we do w/ all things, let's start at the top.  Print the header
    $self->{PDF}->setFont('HELVETICA', 8);
    my $headerDesc=$self->getCertificateHeader($layout->{HEADER});
    $headerDesc =~ s/\[!IDS::COUNTY!\]/$userData->{COUNTY_DEF}/g;
    $headerDesc =~ s/\[!IDS::REGULATOR!\]/$userData->{REGULATOR_DEF}/g;
    $headerDesc =~ s/\[!IDS::STATE!\]/$userData->{COURSE_STATE}/g;
    $headerDesc =~ s/\[!IDS::COURSE DESC!\]/$userData->{COURSE_AGGREGATE_DESC}/g;

    my @arr = split("<BR>",$headerDesc);
    my $yPos=725;
    foreach my $str(@arr) {
            $self->{PDF}->writeLine( 60-$xDiff, $yPos - $yOffset, $str);
            $yPos -=12;
    }

	
    ###### let's print the disclaimer on the right
    $self->{PDF}->setFont('HELVETICA', 6);
    my $yDisclaimer = 555; 
    
    my @discMsg=split /~/, $self->getCertificateDisclaimer($layout->{DISCLAIMER});
    foreach my $cc(@discMsg)
    {
        $self->{PDF}->writeLine (350-$xDiff, $yDisclaimer-$yOffset, $cc);
        $yDisclaimer -=12;
    }
    
    $yDisclaimer -= 15;
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('AAADIP');
    if (!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}))
    {
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('AAADIP',1);
    }

    $self->_printCorporateAddress(60-$xDiff, 690, $OFFICECA,'www.aaa.com/onlineDIP');
    $self->_printCorporateAddress(60-$xDiff, 89, $OFFICECA,'www.aaa.com/onlineDIP');

    ###### print the signature
    $self->_printSignature($yDisclaimer - $yOffset, $layout->{SIGNATURE});

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    $self->_printAddress( 550 - $yOffset, $userData);

    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICABOLD', 12);
    $self->{PDF}->writeLine( 500-$xDiff, 738-$yOffset, $userData->{CERTIFICATE_NUMBER} );
    $self->{PDF}->writeLine( 480-$xDiff, 420-$yOffset, $userData->{CERT_1} ); 
    

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $countyId = $userData->{COUNTY_ID};
    my $courseId = $userData->{COURSE_ID};
    $userData->{COUNTY_DEF}=($userData->{COUNTY_DEF})?$userData->{COUNTY_DEF}:$userData->{REGULATOR_DEF};
    if($countyId && exists $self->{SETTINGS}->{CTSI_COUNTY}->{$countyId}){
        my $rankNo=(keys %$fields) +1;
        $fields->{$rankNo}=15;
        $rankNo++;
        $fields->{$rankNo}=2;
    }

    my $y = 700;
    my $xOffset = 300;
    $self->{PDF}->setFont('HELVETICA', 8);
    my @variableData;

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

            $self->{PDF}->writeLine( $xOffset + $field->{XPOS}-$xDiff, ($y-$yOffset), "$field->{DEFINITION}:" );

            if ($field->{DEFAULT})
            {
                ##### is there a default value which needs to be filled in?
                $self->{PDF}->writeLine( $xOffset + 110-$xDiff, ($y-$yOffset), $field->{DEFAULT} );
		$fieldValue=$field->{DEFAULT};
            }
            elsif ($field->{CITATION})
            {
                ##### is this citation information
		$userData->{CITATION}->{$field->{DATA_MAP}}=($userData->{CITATION}->{$field->{DATA_MAP}})?$userData->{CITATION}->{$field->{DATA_MAP}}:'NONE';
                $self->{PDF}->writeLine( $xOffset + 110-$xDiff, ($y-$yOffset), $userData->{CITATION}->{$field->{DATA_MAP}} );
		$fieldValue=$userData->{CITATION}->{$field->{DATA_MAP}};
            }
            else
            {
                ##### default case
		$userData->{$field->{DATA_MAP}}=($userData->{$field->{DATA_MAP}})?$userData->{$field->{DATA_MAP}}:'NONE';
                $self->{PDF}->writeLine( $xOffset + 110-$xDiff, ($y-$yOffset), $userData->{$field->{DATA_MAP}} );
		$fieldValue=$userData->{$field->{DATA_MAP}};
            }
	    $variableData[$arrCtr++]="$field->{DEFINITION}:$fieldValue";
             
            ##### reset the y
            $y -= 12;
        }
        $y = 250;
        $xOffset = 215;
    	my $variableDataStr=join '~',@variableData;
	push @returnArr,$printId;
        my $fixedData=Certificate::_generateFixedData($userData);
        $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);

        if ($i < ($loop-1))
        {
            ###### this is a multiple STC cert.  swap out the data w/ the 2nd STC
            $userId     = $userId_1;
            $userData   = $userData_1;
	    $printId = $printId_1;
	    $yOffset = 400;
	    @variableData = ();
	}
   }
   return ($self->{PDF},@returnArr);
}

sub constructor
{
	my $self = shift;
	my ($userId,$top,$bottom,$faxEmail,$aaaTideWaterClub)=@_;
	###### let's create our certificate pdf object
	if($faxEmail){
		$self->{PS} = $self->getFile($self->{SETTINGS}->{TEMPLATESPATH}."/printing/userCert.ps");
		$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
		my $certificateImage = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_aaadip.jpg";
		$certificateImage = ($aaaTideWaterClub) ? $self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_aaadip_tidewater.jpg" : $certificateImage;
		$self->{PDF}->genImage($certificateImage,0, 0, 612, 792,1275,1650);
	}else{
		$self->{PDF} = Certificate::PDF->new($userId);
		$top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
		$top = ($aaaTideWaterClub) ? $self->{SETTINGS}->{TEMPLATESPATH}."/printing/ONLINEDIP_AAA_Template_Court_Tidewater.pdf" : $top;
		$bottom = ($bottom)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$bottom":'';
		my $full=(!$bottom)?1:0;
		###### get the appropriate templates
		if($top || $bottom){
			if ($self->{STC})
			{
				$self->{PDF}->setTemplate($top,$top)
			}
			else
			{
				$self->{PDF}->setTemplate($top,$bottom,$full);
			}
		}
      }
       return $self;
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: saleem $

=item $Date: 2008/10/14 07:32:35 $

=item $Rev: 71 $

=cut

1;
