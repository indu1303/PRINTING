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

package Certificate::AAASeniors;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;

my $STATES = {'AK'=>'Alaska', 'AR'=>'Arkansas', 'AL'=>'Alabama', 'AZ'=>'Arizona', 'CA'=>'California', 'CO'=>'Colorado', 'CT'=>'Connecticut', 'DC'=>'Washington DC', 'DE'=>'Delaware', 'FL'=>'Florida', 'GA'=>'Georgia', 'HI'=>'Hawaii', 'IA'=>'Iowa', 'ID'=>'Idaho', 'IL'=>'Illinois', 'IN'=>'Indiana', 'KS'=>'Kansas', 'KY'=>'Kentucky', 'LA'=>'Louisiana', 'MA'=>'Massachusetts', 'MD'=>'Maryland', 'ME'=>'Maine', 'MI'=>'Michigan', 'MN'=>'Minnesota', 'MO'=>'Missouri', 'MS'=>'Mississippi', 'MT'=>'Montana', 'NC'=>'North Carolina', 'ND'=>'North Dakota', 'NE'=>'Nebraska', 'NH'=>'New Hampshire', 'NJ'=>'New-Jersey', 'NM'=>'New Mexico', 'NV'=>'Nevada', 'NY'=>'New-York', 'OH'=>'Ohio', 'OK'=>'Oklahoma', 'OR'=>'Oregon', 'PA'=>'Pennsylvania', 'RI'=>'Rhode Island', 'SC'=>'South Carolina', 'SD'=>'South Dakota', 'TN'=>'Tennessee', 'TX'=>'Texas', 'UT'=>'Utah', 'VA'=>'Virginia', 'VT'=>'Vermont', 'WA'=>'Washington', 'WI'=>'Wisconsin', 'WV'=>'West Virginia', 'WY'=>'Wyoming' };

sub _generateCertificate
{
    my $self = shift;
    my ($userId, $userData,$printId,$productId,$rePrintData,$faxEmail) = @_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $courseState = $userData->{COURSE_STATE};
    my $stateDesc = $STATES->{$courseState};
    my $layout = $self->getCourseCertificateLayout($userData->{COURSE_ID},$productId);
    ##### Let's give a delivery flag
    my $flag = ($userData->{DELIVERY_ID} == 4) ? '(ONM)'
            : ($userData->{DELIVERY_ID} == 3) ? '(ONA)'
            : ($userData->{DELIVERY_ID} == 2)?'(TDX)'
            : '';
    ###### add the delivery flag
    #$self->{PDF}->setFont('HELVETICABOLD', 9);
    #$self->{PDF}->writeLine(170-$xDiff, 700, $flag);


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
    
    my @discMsg=split /~/, $self->getCertificateDisclaimer($layout->{DISCLAIMER});
    foreach my $cc(@discMsg)
    {
        $self->{PDF}->writeLine (350-$xDiff, $yDisclaimer, $cc);
        $yDisclaimer -=12;
    }
    
    $yDisclaimer -= 15;
    my $OFFICECA = {}; 
    if ($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}){
	$OFFICECA = $self->{SETTINGS}->getOfficeCa('AAA_SENIORS');
    }else{
	$OFFICECA = $self->{SETTINGS}->getOfficeCa('AAA_SENIORS_FDK');
    }

    my $OFFICECA_AAA = $self->{SETTINGS}->getOfficeCa('AAA_SENIORS_ADD');

    $flag = '';
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 60, 697, "AAA Driver Training Programs $flag" );
    $self->{PDF}->writeLine( 60, 296, "AAA Driver Training Programs $flag" );
    if(!$faxEmail){
	###### print the signature
    	#$self->_printSignature($yDisclaimer, $layout->{SIGNATURE});
        $self->_printCorporateAddress(60-$xDiff,686, $OFFICECA,'RoadWiseDriver.aaa.com');
	if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'VA') {
		if($userData->{VA_TIDEWATER_CLUB} && $userData->{VA_TIDEWATER_CLUB} == 1) {
    			my $OFFICECA_AAA_TW = $self->{SETTINGS}->getOfficeCa('AAA_SENIORS_ADDTW');
        		$self->_printCorporateAddress(60-$xDiff,286, $OFFICECA_AAA_TW,'RoadWiseDriver.aaa.com');
		} 
		if($userData->{VA_MIDATLANTIC_CLUB} && $userData->{VA_MIDATLANTIC_CLUB} == 1) {
    			my $OFFICECA_AAA_MI = $self->{SETTINGS}->getOfficeCa('AAA_SENIORS_ADDMI');
        		$self->_printCorporateAddress(60-$xDiff,286, $OFFICECA_AAA_MI,'RoadWiseDriver.aaa.com');
		}
	} else {
        	$self->_printCorporateAddress(60-$xDiff,286, $OFFICECA_AAA,'RoadWiseDriver.aaa.com');
	}
    }

    #$self->{PDF}->setFont('HELVETICABOLD', 14);
    #$self->{PDF}->writeLine( 150, 766, "AAA RoadWise Driver Online Course" );

    ##Title tag changes - not from the pdf, to display from here
    $self->{PDF}->setFont('HELVETICABOLD', 14);
    if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'VA') {
    	$self->{PDF}->writeLine( 122, 770, "AAA RoadWise Driver Senior Defensive Driving Course" );
	$self->{PDF}->writeLine( 122, 370, "AAA RoadWise Driver Senior Defensive Driving Course" );
    } else {
        $self->{PDF}->writeLine( 192, 770, "AAA RoadWise Driver Online Course" );
        $self->{PDF}->writeLine( 192, 370, "AAA RoadWise Driver Online Course" );
    }

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    #$self->{PDF}->writeLine( 90-$xDiff, 350, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $self->_printAddress( 550, $userData);
    $self->_printAddress( 156, $userData);

    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICABOLD', 12);
    $self->{PDF}->writeLine( 480-$xDiff, 714, $userData->{CERTIFICATE_NUMBER} );
    $self->{PDF}->writeLine( 480-$xDiff, 314, $userData->{CERTIFICATE_NUMBER} );
    if(exists $self->{SETTINGS}->{CERT_MSG_TOP}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}}){
	#$userData->{CERT_1}=$self->{SETTINGS}->{CERT_MSG_TOP}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}};
    }
    $self->{PDF}->writeLine( 480-$xDiff, 420, $userData->{CERT_1}); 
    if(exists $self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}}){
	# my $certMsgBottom=$self->{SETTINGS}->{CERT_MSG_BOTTOM}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{COURSE_ID}};
	 #$self->{PDF}->writeLine( 480-$xDiff, 60,$certMsgBottom);
    }
    
    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $y = 700;
    my $xOffset = 300;
    $self->{PDF}->setFont('HELVETICA', 8);
    my @variableData;
    my $LINESPACE       = 12;

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
                ##### is this citation information

		$userData->{CITATION}->{$field->{DATA_MAP}}=($userData->{CITATION}->{$field->{DATA_MAP}})?$userData->{CITATION}->{$field->{DATA_MAP}}:'NONE';
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
            $variableData[$arrCtr++]="$field->{DEFINITION}:$fieldValue";
             
            ##### reset the y
            $y -= 12;
        }
        
        $y = 295;
        $xOffset = 315;
    }

    ###### how about the course def
    $self->{PDF}->setFont('HELVETICA', 8);
    #$userData->{COURSE_AGGREGATE_DESC} =~ s/<BR>/ /gi;
    #$self->{PDF}->writeLine ( 135-$xDiff, 320, $userData->{COURSE_AGGREGATE_DESC} );
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
	my ($userId,$top,$bottom,$faxEmail, $clubCheck, $vaMidAtlantic, $vaTidewater)=@_;
	###### let's create our certificate pdf object
        if($faxEmail){
		$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal.jpg",
                                0, 0, 612, 792,1275,1650);
        }else{
		$self->{PDF} = Certificate::PDF->new($userId);
		if($clubCheck && $clubCheck == 1) {
			$top = 'AAA_SENIORS_Template_Court_CT.pdf';
			$bottom = 'AAA_SENIORS_Template_Student_CT.pdf';
		}
		if($vaMidAtlantic && $vaMidAtlantic == 1) {
			$top = 'AAA_SENIORS_VA_Template_Court_MA.pdf';
			$bottom = 'AAA_SENIORS_VA_Template_Student_MA.pdf';
		} 
		if($vaTidewater && $vaTidewater == 1) {
			$top = 'AAA_SENIORS_VA_Template_Court_TW.pdf';
			$bottom = 'AAA_SENIORS_VA_Template_Student_TW.pdf';
		}
		$top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
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

1;
