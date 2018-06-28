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

package Certificate::SellerServer;

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
    $self->{PDF}->writeLine(140-$xDiff, 700, $flag);

    ###### as we do w/ all things, let's start at the top.  Print the header	
    $self->{PDF}->setFont('HELVETICA', 8);
    if($userData->{COURSE_STATE} eq 'IL'){
	$userData->{EXPIRATION_DATE}=$userData->{EXPIRATION_DATE4}
    }else{
    	$userData->{EXPIRATION_DATE}=($userData->{EXPIRATION_DATE})?$userData->{EXPIRATION_DATE}:$userData->{EXPIRATION_DATE2};
    }
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
	    my $strLen=length($str);
	    my $fontMatrix=4.9*$strLen;
	    if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'NY'){
	    	$self->{PDF}->writeLine((612-$fontMatrix)/2-$xDiff, $yPos, $str);
	    }else{
	    	$self->{PDF}->writeLine(60-$xDiff, $yPos, $str);
	    }
            $yPos -=12;
    }
	
    ###### let's print the disclaimer on the right
    $self->{PDF}->setFont('HELVETICA', 6);
    my $yDisclaimer = 555; 
    
    my @discMsg=split /~/, $self->getCertificateDisclaimer($layout->{DISCLAIMER});
    my $certMsgData='';
    my $yPS=350;
    if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'NY'){
	$yDisclaimer = 605;
	@discMsg=split /~/, '                                                BY MARKING THE CERTIFICATION BOX ONLINE I~CERTIFY THAT I COMPLETED ALL LESSONS, QUIZZES AND FINAL EXAM~REQUIRED DEMONSTRATING MASTERY OF ALL MATERIAL. MY CERTIFICATION~TO THAT FACT IF NOT TRUE MAY CONSTITUTE FILING A FALSE INSTRUMENT,~MAY SUBJECT MY EMPLOYERTO DISCIPLINARY ACTION BY THE STATE~LIQUOR AUTHORITY, AND WILL SUBJECT THIS CERTIFICATE TO BE REVOKED.';
    
    	    $self->{PDF}->setFont('HELVETICABOLD', 6);
	    $self->{PDF}->writeLine (350-$xDiff,$yDisclaimer,'STUDENT CERTIFICATION:'); 
	    $self->{PDF}->setFont('HELVETICA', 6);
    }

    foreach my $cc(@discMsg)
    {
        $self->{PDF}->writeLine (350-$xDiff, $yDisclaimer, $cc);
        $yDisclaimer -=12;
	$certMsgData.="310 $yPS moveto ($cc) show\n";
	$yPS -=8;
    }
    if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'NY'){
        $yDisclaimer -=12;
	@discMsg=split /~/, '                                                I CERTIFY THAT I AM THE DIRECTOR OF THE SCHOOL~DESCRIBED ABOVE AND THAT THE ABOVE STUDENT SUCCESSFULLY~COMPLETED THE ENTIRE PROGRAM.';
    
    	$self->{PDF}->setFont('HELVETICABOLD', 6);
	$self->{PDF}->writeLine (350-$xDiff,$yDisclaimer,'SCHOOL CERTIFICATION:'); 
    	$self->{PDF}->setFont('HELVETICA', 6);
    	foreach my $cc(@discMsg)
    	{
	        $self->{PDF}->writeLine (350-$xDiff, $yDisclaimer, $cc);
        	$yDisclaimer -=12;
		$certMsgData.="310 $yPS moveto ($cc) show\n";
		$yPS -=8;
	}
    }
    $yDisclaimer -= 15;
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('SS');
    my $productName=$self->{SETTINGS}->{PRODUCT_NAME}->{$productId};
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
	    if(exists $self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName}){
                        $OFFICECA=$self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName};
                }else{
                        $OFFICECA = $self->{SETTINGS}->getOfficeCa($productName);
            }
    }




    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
        #$OFFICECA = $self->{SETTINGS}->getOfficeCa('SS',1);
    }


    ###### print the signature
    if(!$faxEmail){
	if($userData->{COURSE_STATE} && ($userData->{COURSE_STATE} eq 'NY' ||  $userData->{COURSE_STATE} eq 'NE' || $userData->{COURSE_STATE} eq 'TN' || $userData->{COURSE_STATE} eq 'IL')){
    		$self->_printSignature($yDisclaimer, $layout->{SIGNATURE},1);
	}else{
    		$self->_printSignature($yDisclaimer, $layout->{SIGNATURE});
	}
	$self->_printCorporateAddress(60-$xDiff,686, $OFFICECA,'');
	$self->_printCorporateAddress(60-$xDiff,89, $OFFICECA,'');

    }

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    $self->{PDF}->writeLine( 90-$xDiff, 350, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME}.',' );
    $self->_printAddress( 550, $userData);
    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICABOLD', 12);
    $self->{PDF}->writeLine( 500-$xDiff, 738, $userData->{CERTIFICATE_NUMBER} );
    $userData->{CERT_1}='OFFICIAL COPY';
    my $coupon = $userData->{COUPON};
    if(!$userData->{UPSELLEMAIL} && !$userData->{UPSELLMAIL}){
    	$self->{PDF}->writeLine( 480-$xDiff, 420, $userData->{CERT_1});
    }	
         my $certMsgBottom='STUDENT COPY';
         $self->{PDF}->writeLine( 480-$xDiff, 40,$certMsgBottom);

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $countyId = $userData->{COUNTY_ID};
    my $courseId = $userData->{COURSE_ID};
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
	    #### This chanegs Start for RT 14166
	    my $companyId=$userData->{COMPANY_ID};
	    if($companyId && $self->{SETTINGS}->{NOTTOPRINTFIELD}->{SS}->{$companyId}){
			if(exists  $self->{SETTINGS}->{NOTTOPRINTFIELD}->{SS}->{$companyId}->{$fieldId}){
				next;
			}
	    } 
	    #### This chanegs END for RT 14166
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
	        $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $mainPrintVal->{MAINLINE} );
    
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
    $self->{PDF}->writeLine ( 135-$xDiff, 320, $userData->{COURSE_AGGREGATE_DESC} );
	if($userData->{COURSE_STATE} eq 'WI')   {
                $self->{PDF}->setFont('HELVETICA', 7);
                $self->{PDF}->writeLine ( 60, 455, "SellerServer.com is approved by the Wisconsin Department of Revenue ");
                $self->{PDF}->writeLine ( 60, 445, "and fully complies with statutes 125.04 and 125.17. Present this certificate ");
                $self->{PDF}->writeLine ( 60, 435, "to you local municipal clerk's office to receive your Operator's or Retail license." );
                $self->{PDF}->setFont('HELVETICA', 8);
        }
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
        my ($userId,$top,$bottom,$faxEmail,$residentState,$countyId,$productId,$courseState)=@_;
        if($faxEmail){
                $self->{PS} = $self->getFile($self->{SETTINGS}->{TEMPLATESPATH}."/printing/userCert.ps");
                $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
		if($courseState && $courseState eq 'NM'){
                        $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_ss_nm.jpg",0, 0, 612, 792,1275,1650);
		}elsif($courseState && $courseState eq 'NY'){
                        $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_ss_ny.jpg",0, 0, 612, 792,1275,1650);
		}elsif($courseState && $courseState eq 'TN'){
                        $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_ss_tn.jpg",0, 0, 612, 792,1275,1650);
                } else{
                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_ss.jpg",0, 0, 612, 792,1275,1650);
		}
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
