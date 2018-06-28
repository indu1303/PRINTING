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

package Certificate::AAA;

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
    #if (!($userData->{COUPON} && $userData->{COUPON} eq 'AAANCC') && $userData->{COURSE_STATE} eq 'NC'){
	#$layout->{HEADER}=13;
    #}
    #if($self->{SETTINGS}->{NCCOURSEAAACOUNTIES}->{$userData->{COUNTY_ID}} && $userData->{COURSE_STATE} eq 'NC') {
	#$layout->{HEADER}=43;
    #}
    if($userData->{COURSE_STATE} eq 'NC'){
	if($userData->{AAANCCUSER} && $userData->{AAANCCUSER} == 2) {
		if($userData->{COURSE_ID} == 35004) {
			$layout->{HEADER}=65;
		} else {
			$layout->{HEADER}=64;
		}
	} elsif($userData->{AAANCCUSER} && $userData->{AAANCCUSER} == 1) {
		if($userData->{COURSE_ID} == 35004) {
			$layout->{HEADER}=63;
		} else {
			$layout->{HEADER}=43;
		}
	}
    }
    my $headerDesc=$self->getCertificateHeader($layout->{HEADER});
    $headerDesc =~ s/\[!IDS::COUNTY!\]/$userData->{COUNTY_DEF}/g;
    $headerDesc =~ s/\[!IDS::REGULATOR!\]/$userData->{REGULATOR_DEF}/g;
    $headerDesc =~ s/\[!IDS::STATE!\]/$userData->{COURSE_STATE}/g;
    $headerDesc =~ s/\[!IDS::COURSE DESC!\]/$userData->{COURSE_AGGREGATE_DESC}/g;

    my @arr = split("<BR>",$headerDesc);
    my $yPos=725;
    foreach my $str(@arr) {
            $self->{PDF}->writeLine( 60-$xDiff, $yPos, $str);
            $yPos -=12;
    }
	
    ###### let's print the disclaimer on the right
    $self->{PDF}->setFont('HELVETICA', 6);
    my $yDisclaimer = 555;
    my $courseId = $userData->{COURSE_ID}; 
    
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
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }

    if(!$faxEmail){
	###### print the signature
    	$self->_printSignature($yDisclaimer, $layout->{SIGNATURE});
        $self->_printCorporateAddress(60-$xDiff,686, $OFFICECA,'www.idrivesafely.com');
        if(($productId ==1 && $userData->{COURSE_STATE} eq 'OH' && (!$userData->{COUPON} || ($userData->{COUPON} &&  $userData->{COUPON} ne 'AAA0HC'))) &&( $userData->{RESIDENT_STATE} ne 'NONOH') ) {
		$self->_printCorporateAddress(60-$xDiff,89, $OFFICECA,'www.idrivesafely.com');
        }elsif($productId ==1 && $userData->{COURSE_STATE} eq 'SC' && $userData->{REGULATOR_ID} == 105930){
		$self->_printCorporateAddress(60-$xDiff,89, $OFFICECA,'www.idrivesafely.com');
        }else{
        	$self->_printCorporateAddress(401-$xDiff,89, $OFFICECA,'www.idrivesafely.com');
	}

    }

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
    if($userData->{RESIDENT_STATE} && $userData->{RESIDENT_STATE} eq 'NONOH' && $userData->{COURSE_STATE} eq 'OH') {
	$userData->{CERT_1} = 'STATE COPY';
    }
    $self->{PDF}->writeLine( 480-$xDiff, 420, $userData->{CERT_1});
    if(exists $self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}}){
         my $certMsgBottom=$self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}};
         $self->{PDF}->writeLine( 480-$xDiff, 60,$certMsgBottom);
    }

    

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $y = 700;
    my $xOffset = 300;
    $yPS = 467;
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

            $self->{PDF}->writeLine( $xOffset + $field->{XPOS}-$xDiff, $y, "$field->{DEFINITION}:" );

            if ($field->{DEFAULT})
            {
                ##### is there a default value which needs to be filled in?
		if($userData->{AAANCCUSER}) {
			if($userData->{AAANCCUSER} == 2) {
                		$self->{PDF}->writeLine( $xOffset + 105-$xDiff, $y, "North Carolina Approved Online Traffic Safety Course");
			} elsif($userData->{AAANCCUSER} == 1) {
	                	$self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $field->{DEFAULT} );
			}
		} else {
                	$self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $field->{DEFAULT} );
		}
		$fieldValue=$field->{DEFAULT};
            }
            elsif ($field->{CITATION})
            {
                ##### is this citation information
		$userData->{CITATION}->{$field->{DATA_MAP}}=($userData->{CITATION}->{$field->{DATA_MAP}})?$userData->{CITATION}->{$field->{DATA_MAP}}:'NONE';
                $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $userData->{CITATION}->{$field->{DATA_MAP}} );
		$fieldValue=$userData->{CITATION}->{$field->{DATA_MAP}};
            }
            else
            {
                ##### default case
		$userData->{$field->{DATA_MAP}}=($userData->{$field->{DATA_MAP}})?$userData->{$field->{DATA_MAP}}:'NONE';
                $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $userData->{$field->{DATA_MAP}} );
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
    ###### how about the course def
    $self->{PDF}->setFont('HELVETICA', 8);
	
    if($userData->{COURSE_STATE} eq 'NC') {
    	#if($userData->{COUPON} && $userData->{COUPON} eq 'AAANCC'){
        #        $userData->{COURSE_AGGREGATE_DESC}="North Carolina AAA-Approved Online Traffic Safety Course";
	#} elsif($self->{SETTINGS}->{NCCOURSEAAACOUNTIES}->{$userData->{COUNTY_ID}}) {
        #        	$userData->{COURSE_AGGREGATE_DESC}="AAA Online 4-Hour Traffic Safety Course";
    	#} else {
        #        $userData->{COURSE_AGGREGATE_DESC}="North Carolina Approved Online Traffic Safety Course";
    	#}
	if($userData->{AAANCCUSER} && $userData->{AAANCCUSER} == 2) {
		if($userData->{COURSE_ID} == 35004) {
			$userData->{COURSE_AGGREGATE_DESC}="North Carolina Approved 8 Hour Online Traffic Safety Course";
		} else {
			$userData->{COURSE_AGGREGATE_DESC}="North Carolina Approved 4 Hour Online Traffic Safety Course";
		}
	} elsif($userData->{AAANCCUSER} && $userData->{AAANCCUSER} == 2) {	
		if($userData->{COURSE_ID} == 35004) {
			$userData->{COURSE_AGGREGATE_DESC}="AAA Online Traffic Safety Course - 8-hour";
		} else {
			$userData->{COURSE_AGGREGATE_DESC}="AAA Online Traffic Safety Course - 4-hour";
		}
	}
    }
    if($userData->{COUPON} && $userData->{COUPON} eq 'AAA0HC' && $userData->{COURSE_STATE} eq 'OH'){
                $userData->{COURSE_AGGREGATE_DESC}="Ohio AAA-Approved Online Traffic Safety Course";
    }
    $userData->{COURSE_AGGREGATE_DESC} =~ s/<BR>/ /gi;

    $self->{PDF}->writeLine ( 135-$xDiff, 320, $userData->{COURSE_AGGREGATE_DESC} );
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
	my ($userId,$top,$bottom,$faxEmail,$residentState, $countyId, $ncUser, $scUser)=@_;
	###### let's create our certificate pdf object
	if($faxEmail){
		$self->{PS} = $self->getFile($self->{SETTINGS}->{TEMPLATESPATH}."/printing/userCert.ps");
		$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
		my $certFinalImage = "certfinal.jpg";
		if($ncUser && $ncUser == 1) {
			$certFinalImage = "certfinal_aaa.jpg";
		}

               	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/$certFinalImage",
                                0, 0, 612, 792,1275,1650);
        }else{
		$self->{PDF} = Certificate::PDF->new($userId);
		if($ncUser && $ncUser == 2) {
			$top = 'NC_Template_Court.pdf';
			$bottom = 'NC_Template_Student.pdf';
		}
		if($scUser && $scUser == 2) {
			$top = 'SC_Template_Court.pdf';
			$bottom = 'SC_Template_Student.pdf';
		}
	        $top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
        	$bottom = ($bottom)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$bottom":'';
	        my $full=(!$bottom)?1:0;

		if($top || $bottom){
		  ###### get the appropriate templates
		  $self->{PDF}->setTemplate($top,$bottom,$full);
		}
	}
	 return $self;
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: kumar $

=item $Date: 2008/11/07 12:13:41 $

=item $Rev: 71 $

=cut

1;
