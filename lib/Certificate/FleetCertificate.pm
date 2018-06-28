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

package Certificate::FleetCertificate;

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

    my @variableData;
	if($userData->{BUNDLE_USER}) {
		##For bundle coruse
	my $OFFICECA = $self->{SETTINGS}->getOfficeCa('FLEET');
	if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
		$OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
	}

	my $emailDelivery = ($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq '12') ? 1 : 0;
	
  	$self->{PDF}->setFont('HELVETICA', 10);
	if($emailDelivery) {
		$self->{PDF}->writeLine( 105-$xDiff, 740, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
	} else {
		$self->{PDF}->writeLine( 105-$xDiff, 750, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
	}
	$self->_printAddress( 120, $userData);
	if($emailDelivery) {
		$self->_printCorporateAddress(50,488, $OFFICECA,'fleet.idrivesafely.com');
	} else {
		$self->_printCorporateAddress(60,488, $OFFICECA,'fleet.idrivesafely.com');
	}

	$self->{PDF}->setFont('HELVETICA', 8);
	if($emailDelivery) {
		$self->{PDF}->writeLine ( 135-$xDiff, 710, $userData->{BUNDLE_COURSES_DESC} );
	} else {
		$self->{PDF}->writeLine ( 135-$xDiff, 720, $userData->{BUNDLE_COURSES_DESC} );
	}

    	$self->{PDF}->setFont('HELVETICABOLD', 12);
	if($emailDelivery) {
		$self->{PDF}->writeLine( 480-$xDiff, 738, "No: $userData->{CERTIFICATE_NUMBER} " );
		$self->{PDF}->writeLine( 499-$xDiff, 338, " $userData->{CERTIFICATE_NUMBER} " );
	} else {
		$self->{PDF}->writeLine( 480-$xDiff, 770, "No: $userData->{CERTIFICATE_NUMBER} " );
		$self->{PDF}->writeLine( 499-$xDiff, 337, "$userData->{CERTIFICATE_NUMBER} " );
	}

    	$self->{PDF}->setFont('HELVETICABOLD', 14);
	if($emailDelivery) {
		##No logo required for email delivery for bundle user
	} else {
		$self->_printIDSLogo(255,185);
		$self->_printIDSLogo(405,475);
	}
	$self->{PDF}->writeLine( 350, 460, "Drive Safely Certified Driver " );
	$self->{PDF}->writeLine( 200, 170, "Drive Safely Certified Driver " );
    	$self->{PDF}->setFont('HELVETICA', 8);
	$self->{PDF}->writeLine( 360,450, "Successfully completed all core skills courses" );
	$self->{PDF}->writeLine( 210,160, "Successfully completed all core skills courses" );

	##now, let's print out the fields....
	my $fields = $layout->{FIELDS};
	my $countyId = $userData->{COUNTY_ID};
	my $courseId = $userData->{COURSE_ID};
	my $y = 650;
	my $xOffset = 170;
	my $yPS = 467;
	my $courseData='';
	$self->{PDF}->setFont('HELVETICA', 8);

	for (my $i=0; $i < 2; ++$i) {
		my $arrCtr=0;
		foreach my $rank(sort keys %$fields) {
			my $fieldId = $fields->{$rank};
			my $field = $self->getCertificateField($fieldId);
			my $miscData=$self->getCourseMiscellaneousData($fieldId,$courseId,$productId);
			if(exists $miscData->{DEFAULT} && $miscData->{DEFAULT}){
				$field->{DEFAULT}=$miscData->{DEFAULT};
			}

			my $fieldValue='';

			$self->{PDF}->writeLine( $xOffset + $field->{XPOS}-$xDiff, $y, "$field->{DEFINITION}:" );

			if ($field->{DEFAULT}) {
				##### is there a default value which needs to be filled in?
				$self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $field->{DEFAULT} );
				$fieldValue=$field->{DEFAULT};
			} elsif ($field->{CITATION}) {
				##### is this citation information
				$userData->{CITATION}->{$field->{DATA_MAP}}=($userData->{CITATION}->{$field->{DATA_MAP}})?$userData->{CITATION}->{$field->{DATA_MAP}}:'NONE';
				$self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $userData->{CITATION}->{$field->{DATA_MAP}} );
				$fieldValue=$userData->{CITATION}->{$field->{DATA_MAP}};
			} else {
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

		$y = 290;
		$xOffset = 315;
	}



	my $yDisclaimer = 60;
	if(!$faxEmail){
		###print the signature
		$self->_printSignature($yDisclaimer, $layout->{SIGNATURE});
		$self->_printCorporateAddress(60,279, $OFFICECA,'fleet.idrivesafely.com');
	} else {
		$self->_printCorporateAddress(54,279, $OFFICECA,'fleet.idrivesafely.com');
	}

    	$self->{PDF}->setFont('HELVETICA', 6);
	my @discMsg=split /~/, $self->getCertificateDisclaimer($layout->{DISCLAIMER});
	my $certMsgData='';
	$yPS=390;
	$yDisclaimer = 120;
	foreach my $cc(@discMsg) {
		$self->{PDF}->writeLine (350-$xDiff, $yDisclaimer, $cc);
		$yDisclaimer -=12;
		$yPS -=8;
	}
#	my $headerDesc = $self->getCertificateDisclaimer($layout->{DISCLAIMER});
    	$self->{PDF}->setFont('HELVETICA', 8);
    my $headerDesc=$self->getCertificateHeader($layout->{HEADER});
	my @arr = split("<BR>",$headerDesc);
	$headerDesc =~ s/<BR>/ /g;
	my $yPos=325;
    	foreach my $str(@arr) {
 	    if(!$faxEmail){
            $self->{PDF}->writeLine( 60-$xDiff, $yPos, $str);
	    } else {
            $self->{PDF}->writeLine( 54-$xDiff, $yPos, $str);
	    }
            $yPos -=12;
    	}

	} else {

	###### as we do w/ all things, let's start at the top.  Print the header	
    $self->{PDF}->setFont('HELVETICA', 8);
    my $headerDesc=$self->getCertificateHeader($layout->{HEADER});
    my $courseDesc= $userData->{COURSE_AGGREGATE_DESC};
    $courseDesc =~ s/ Course//g;
    $headerDesc =~ s/\[!IDS::COUNTY!\]/$userData->{COUNTY_DEF}/g;
    $headerDesc =~ s/\[!IDS::REGULATOR!\]/$userData->{REGULATOR_DEF}/g;
    $headerDesc =~ s/\[!IDS::STATE!\]/$userData->{COURSE_STATE}/g;
    $headerDesc =~ s/\[!IDS::COURSE DESC!\]/$courseDesc/g;
    $headerDesc = uc  $headerDesc;

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
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('FLEET');
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);

    }
 
    $yDisclaimer -= 15;
    if(!$faxEmail){
    	    ###### print the signature
	    $self->_printSignature($yDisclaimer, $layout->{SIGNATURE});
            $self->_printCorporateAddress(60-$xDiff,686, $OFFICECA,'fleet.idrivesafely.com');
            $self->_printCorporateAddress(60-$xDiff,89, $OFFICECA,'fleet.idrivesafely.com');
    }
    if ($faxEmail && $faxEmail==1)
    {
            $self->_printCorporateAddress(54-$xDiff,686, $OFFICECA,'fleet.idrivesafely.com');
            $self->{PDF}->setFont('HELVETICA', 9);
            $self->{PDF}->writeLine(52-$xDiff, 98, "I DRIVE SAFELY");
            $self->_printCorporateAddress(52-$xDiff,89, $OFFICECA,'fleet.idrivesafely.com');
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
    $self->{PDF}->writeLine( 480-$xDiff, 420, $userData->{CERT_1}); 
    if(exists $self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}}){
         my $certMsgBottom=$self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}};
         $self->{PDF}->writeLine( 480-$xDiff, 40,$certMsgBottom);
    }
 
    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $countyId = $userData->{COUNTY_ID};
    my $courseId = $userData->{COURSE_ID};
    my $y = 700;
    my $xOffset = 300;
    $yPS = 467;
    my $courseData='';
    $self->{PDF}->setFont('HELVETICA', 8);

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
                $self->{PDF}->writeLine( $xOffset + 110-$xDiff, $y, $field->{DEFAULT} );
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
    $userData->{COURSE_AGGREGATE_DESC} =~ s/<BR>/ /gi;
    $self->{PDF}->writeLine ( 135-$xDiff, 320, $userData->{COURSE_AGGREGATE_DESC} );


	} ##end - Bundle user
    my $variableDataStr=join '~',@variableData;
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
	$printId=$self->MysqlDB::getNextId('contact_id');
    }
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    return ($self->{PDF},$printId,'',$self->{PS});
}

sub printCoverSheet
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/FLEET_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    my $xDiff='';
    $self->{PDF}->setTemplate($top,$bottom,$full);

    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    $self->_printCorporateAddress(21-$xDiff,662, $OFFICECA,'fleet.idrivesafely.com');

    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $userData->{LAST_NAME}=($userData->{LAST_NAME})?$userData->{LAST_NAME}:'';
    $self->{PDF}->writeLine( 21, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{NAME} );
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS_1} );
    $yPos -=11;
    if($userData->{ADDRESS_2}){
        $self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS_2} );
        $yPos -=11;
    }
    $self->{PDF}->writeLine( 21, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}");
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21, $yPos, "No Of Certificates : $userData->{NO_OF_CERTIFICATES}" );
    $self->{PDF}->getCertificate;
    my $printer = 0;
    my $media = 0;
    my $st='FC';   ##########  Default state, we have mentioned as XX;
    my $productId=3;  ##### This is for Fleet
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'COVERSHEET');
    if(!$printer){
        $printer = 'HP-PDF2-TX';
    }
    if(!$media){
            $media='Tray2';
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
	my ($userId,$top,$bottom,$faxEmail, $bundleUserCheck)=@_;
	###### let's create our certificate pdf object
	 if($faxEmail){
		$self->{PS} = $self->getFile($self->{SETTINGS}->{TEMPLATESPATH}."/printing/userCert.ps");
		$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
		if($bundleUserCheck) {
                	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/bundle_certfinal_fleet.jpg", 0, 0, 612, 792,1275,1650);
		} else {
	                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_fleet.jpg", 0, 0, 612, 792,1275,1650);
		}
        }else{
		$self->{PDF} = Certificate::PDF->new($userId);
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

=item $Author: ravi $

=item $Date: 2008/02/11 08:47:48 $

=item $Rev: 71 $

=cut

1;
