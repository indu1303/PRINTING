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

package Certificate::SellerServerNY;

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
    $self->{PDF} = Certificate::PDF->new($userId."_F",'','','','','',612,792);
    if($faxEmail){
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_ss_ny.jpg",0, 0, 612, 792,1275,1650);
    }else{
    	my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/Generic_Template_Court_SS.pdf";
    	my $bottom = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/Generic_Template_Student_SS.pdf";
    	$self->{PDF}->setTemplate($top,$bottom);
    }

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
	$userData->{EXPIRATION_DATE}=$userData->{EXPIRATION_DATE3}
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
	if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'NY'){
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

     $self->{PDF}->getCertificate;

#     $self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_F.pdf",0,0,'q2');
#     $self->{PDF}->getCertificate;
    if($faxEmail){
    $self->{PDF} = Certificate::PDF->new($userId."_B",'','','','','',612,792);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/SellerServerNY.jpg",0, 0, 612, 792,1275,1650);
    $self->{PDF}->setFont('HELVETICABOLD', 13);
    my $courseType='Off-Premises';
    if($userData->{COURSE_ID} eq '40005'){
        $courseType='On-Premises';
    }
    my $headerDesc = "Certificate of Completion<BR>Of an $courseType approved Online<BR>Alcohol Training Awareness Program";

   my @arr = split("<BR>",$headerDesc);
    $headerDesc =~ s/<BR>/ /g;
    my $yPos=742;

    foreach my $str(@arr) {
            my $strLen=length($str);
            my $fontMatrix=5.5*$strLen;
            $self->{PDF}->writeLine((612-$fontMatrix)/2, $yPos, $str);
            $yPos -=18;
    }

    $self->{PDF}->setFont('HELVETICABOLD', 10);

    $self->{PDF}->writeLine( 65, 594, 'I Drive Safely LLC Seller Server');
    $self->{PDF}->writeLine( 418, 594, $userData->{COMPLETION_DATE});
    my $schoolApprovalNumber='AT-0011';
    for(my $j=0;$j<length($schoolApprovalNumber);$j++){
            my $appChar=substr($schoolApprovalNumber,$j,1);
            $self->{PDF}->writeLine( 422+($j*20), 641, $appChar);
    }
    my $address=$userData->{ADDRESS_1};
    if($userData->{ADDRESS_2}){
        $address .= ", $userData->{ADDRESS_2}";
    }
    $self->{PDF}->writeLine( 250, 513, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME});
    $self->{PDF}->writeLine( 250, 487, $address);
    $address ="$userData->{CITY}, $userData->{STATE} $userData->{ZIP}";
    $self->{PDF}->writeLine( 250, 461, $address);
    $self->{PDF}->setFont('HELVETICABOLD', 12);
    if($userData->{DATE_OF_BIRTH}){
        for(my $j=0;$j<10;$j++){
                my $dobChar=substr($userData->{DATE_OF_BIRTH},$j,1);
                if($dobChar && ($dobChar eq '/' || $dobChar eq '-')){
                        next
                }
                $self->{PDF}->writeLine( 268+($j*26), 431, $dobChar);
        }
    }
    if(!$userData->{CITATION}->{SOCIAL_SECURITY_NUMBER} && $userData->{CITATION}->{SSN}){
                $userData->{CITATION}->{SOCIAL_SECURITY_NUMBER}=substr($userData->{CITATION}->{SSN},length($userData->{CITATION}->{SSN})-4);
    }
    if($userData->{CITATION}->{SOCIAL_SECURITY_NUMBER}){
        for(my $j=0;$j<4;$j++){
                my $ssnChar=substr($userData->{CITATION}->{SOCIAL_SECURITY_NUMBER},$j,1);
                $self->{PDF}->writeLine( 268+($j*26), 396, $ssnChar);
        }
    }
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/CStokes-Signature.jpg",
                                160, 190, 68, 34,500,270);
    if(!$userData->{PRINT_DATE}){
        $userData->{PRINT_DATE}=$userData->{CURR_DATE};
    }
    $self->{PDF}->writeLine( 468, 190, $userData->{PRINT_DATE});
    $self->{PDF}->setFont('HELVETICABOLD', 10);
    if($userData->{CITATION}->{NAME_OF_CURRENT_EMPLOYER}){
        $self->{PDF}->writeLine( 253, 361, $userData->{CITATION}->{NAME_OF_CURRENT_EMPLOYER});
    }
     $self->{PDF}->getCertificate;
    }
    ###### as we do w/ all things, let's start at the top.  Print the header  
     # my $ret=$self->_generateCertificateAlternate($userId, $userData,$printId,$productId,$rePrintData,$faxEmail);
     # if($ret){
#		$self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_B.pdf",0,0,'','');
     # }
     $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
     $self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_F.pdf",0,0,'','NoNewPage');
     if($faxEmail){
     	$self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_B.pdf",0,0,'','');
     	unlink "/tmp/$userId"."_B.pdf";
     }else{
	$self->_generateCertificateAlternate($userId, $userData,$printId,$productId,$rePrintData,$faxEmail);
     }

      
     unlink "/tmp/$userId"."_F.pdf";

    return ($self->{PDF},$printId,'',$self->{PS});
}


sub _generateCertificateAlternate
{
    my $self = shift;
    my ($userId, $userData,$printId,$productId,$rePrintData,$faxEmail) = @_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $LINESPACE       = 12;
    $self->{PDF2} = Certificate::PDF->new($userId."_B",'','','','','',612,792);
    $self->{PDF2}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/SellerServerNY.jpg",0, 0, 612, 792,1275,1650);
    ###### as we do w/ all things, let's start at the top.  Print the header	
    
    $self->{PDF2}->setFont('HELVETICABOLD', 13);
    my $courseType='Off-Premises';
    if($userData->{COURSE_ID} eq '40005'){
    	$courseType='On-Premises';
    }
    my $headerDesc = "Certificate of Completion<BR>Of an $courseType approved Online<BR>Alcohol Training Awareness Program";

   my @arr = split("<BR>",$headerDesc);
    $headerDesc =~ s/<BR>/ /g;
    my $yPos=742;

    foreach my $str(@arr) {
            my $strLen=length($str);
            my $fontMatrix=5.5*$strLen;
            $self->{PDF2}->writeLine((612-$fontMatrix)/2, $yPos, $str);
            $yPos -=18;
    }

    $self->{PDF2}->setFont('HELVETICABOLD', 10);
     
    $self->{PDF2}->writeLine( 65, 594, 'I Drive Safely LLC Seller Server');
    $self->{PDF2}->writeLine( 418, 594, $userData->{COMPLETION_DATE});
    my $schoolApprovalNumber='AT-0011';
    for(my $j=0;$j<length($schoolApprovalNumber);$j++){
	    my $appChar=substr($schoolApprovalNumber,$j,1);
            $self->{PDF2}->writeLine( 422+($j*20), 641, $appChar);
    }
    my $address=$userData->{ADDRESS_1};
    if($userData->{ADDRESS_2}){
	$address .= ", $userData->{ADDRESS_2}";
    }
    $self->{PDF2}->writeLine( 250, 513, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME});
    $self->{PDF2}->writeLine( 250, 487, $address);
    $address ="$userData->{CITY}, $userData->{STATE} $userData->{ZIP}";
    $self->{PDF2}->writeLine( 250, 461, $address);
    $self->{PDF2}->setFont('HELVETICABOLD', 12);
    if($userData->{DATE_OF_BIRTH}){
    	for(my $j=0;$j<10;$j++){
		my $dobChar=substr($userData->{DATE_OF_BIRTH},$j,1);
		if($dobChar && ($dobChar eq '/' || $dobChar eq '-')){
			next
		}
	    	$self->{PDF2}->writeLine( 268+($j*26), 431, $dobChar);
    	}
    }
    if(!$userData->{CITATION}->{SOCIAL_SECURITY_NUMBER} && $userData->{CITATION}->{SSN}){
		$userData->{CITATION}->{SOCIAL_SECURITY_NUMBER}=substr($userData->{CITATION}->{SSN},length($userData->{CITATION}->{SSN})-4);
    }
    if($userData->{CITATION}->{SOCIAL_SECURITY_NUMBER}){
    	for(my $j=0;$j<4;$j++){
		my $ssnChar=substr($userData->{CITATION}->{SOCIAL_SECURITY_NUMBER},$j,1);
    		$self->{PDF2}->writeLine( 268+($j*26), 396, $ssnChar);
    	}
    }
    $self->{PDF2}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/CStokes-Signature.jpg",
                                160, 190, 68, 34,500,270); 
    if(!$userData->{PRINT_DATE}){
	$userData->{PRINT_DATE}=$userData->{CURR_DATE};
    }
    $self->{PDF2}->writeLine( 468, 190, $userData->{PRINT_DATE});
    $self->{PDF2}->setFont('HELVETICABOLD', 10);
    if($userData->{CITATION}->{NAME_OF_CURRENT_EMPLOYER}){
	$self->{PDF2}->writeLine( 253, 361, $userData->{CITATION}->{NAME_OF_CURRENT_EMPLOYER});
    }
    ###### now, let's print out the fields....
    $self->{PDF2}->getCertificate;
    my $printer = 0;
    my $media = 0;
    my $st='TX';
    $productId=27;
    $st = $userData->{COURSE_STATE};
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
    if(!$printer){
                $printer = 'HP-PDF-HOU05';
    }
    if(!$media){
                $media='Tray4';
    }

    my $outputFile = "/tmp/$userId"."_B.pdf";

    my $ph;
    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
    close $ph;
    if(-e $outputFile){
	     unlink $outputFile;
    }
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

sub constructor
{
        my $self = shift;
        my ($userId,$top,$bottom,$faxEmail,$residentState,$countyId,$productId,$courseState)=@_;
        return $self;
}

1;
