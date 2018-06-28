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

package Certificate::CertForStudent;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use PDF::Reuse;
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

    my $yPos=725;
    my $yPS=350;
    ###### let's print the disclaimer on the right
    $self->{PDF}->setFont('HELVETICA', 6);
    
    ###### print the signature
    my $address = $userData->{ADDRESS_1} ;
    if($userData->{ADDRESS_2}){
    	$address .= ', ' . $userData->{ADDRESS_2};
    }	
    my $userInformation = $userData->{CITY} . ', '. $userData->{STATE} . ' ' . $userData->{ZIP};

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICA', 12);
    $self->{PDF}->writeLine( 485-$xDiff, 752, $userData->{CERTIFICATE_NUMBER} );
    $self->{PDF}->setFont('HELVETICA', 12);

	my $courseDesc = $userData->{COURSE_AGGREGATE_DESC};
	my @courseDescArr = split(/\s+/, $courseDesc);
	my $i = 1;
	my $modifiedDesc = "";
	foreach my $word(@courseDescArr) {
		$modifiedDesc .= "$word ";
		if($i%5==0) {
			 $modifiedDesc .= "<BR>";
		}
		$i++;
	}
	$courseDesc = $modifiedDesc;
	my @arr = split("<BR>",$courseDesc);
	$courseDesc =~ s/<BR>/ /g;
	my $ypos = 680;
	foreach my $str(@arr) {
		prText(315, $ypos, $str, 'center');
		$ypos -= 14;
	}
    #if(length($userData->{COURSE_AGGREGATE_DESC})>40){
    #	prText(425, 685, uc $userData->{COURSE_AGGREGATE_DESC}, 'right');
    #}else{
    #	prText(425, 685, uc $userData->{COURSE_AGGREGATE_DESC}, 'right');
    #}
    $self->{PDF}->setFont('HELVETICA', 10);
    $self->{PDF}->writeLine(60-$xDiff, 560, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $self->{PDF}->writeLine(60-$xDiff, 548, $address );
    $self->{PDF}->writeLine(60-$xDiff, 536, $userInformation );
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('IDSPOC');
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}))
    {
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    if ($productId && $productId eq '1' && $userData->{COURSE_STATE} eq 'AK') {
	$OFFICECA = $self->{SETTINGS}->getOfficeCa('IDS_OAKLAND_NEW');
    }
    if($productId && $productId eq '25'){
	my $productName=$self->{SETTINGS}->{PRODUCT_NAME}->{$productId};
        $OFFICECA = $self->{SETTINGS}->getOfficeCa($productName);
        if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
                if(exists $self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName}){
                        $OFFICECA=$self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName};
                }else{
                        $OFFICECA = $self->{SETTINGS}->getOfficeCa($productName);
                }
        }
    }

    $self->{PDF}->writeLine(60-$xDiff, 686, "I DRIVE SAFELY" );
    $self->_printCorporateAddress(60-$xDiff,675, $OFFICECA,'');
    if($productId && $productId eq '25'){
	$self->_printHorzCorporateAddress({X => 60-$xDiff, Y => 85, OFFICE => $OFFICECA, DOMAIN => 'www.takehome.com', SEPARATOR => '|', PHONE => 1})
    }else{
    	$self->_printHorzCorporateAddress({X => 60-$xDiff, Y => 48, OFFICE => $OFFICECA, DOMAIN => 'www.idrivesafely.com', SEPARATOR => '|', PHONE => 1});
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
    my $y = 350;
    $yPS = 567;
    my $xOffset = 60;
    my $courseData='';
    $self->{PDF}->setFont('HELVETICABOLD', 10);
    my @variableData;

    for (my $i=0; $i < 1; ++$i)
    {
	my $arrCtr=0;
        foreach my $rank(sort keys %$fields)
        {
	    my $fieldId = $fields->{$rank};
            my $field = $self->getCertificateField($fieldId);
	    $field->{XPOS} = 0;
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

            }
            $variableData[$arrCtr++]="$field->{DEFINITION}:$fieldValue"; 
            ##### reset the y
            $y -= 22;
        }

	$self->{PDF}->writeLine ( 350-$xDiff, 140,'By:');
        $self->{PDF}->writeLine ( 350-$xDiff, 118,'(Authorized Signature of I DRIVE SAFELY)');


    	if ($userData->{COURSE_STATE} eq 'AK')
    	{	
    		$self->{PDF}->setFont('HELVETICABOLD', 8);
    		$self->{PDF}->writeLine ( 160-$xDiff, 75, "VALID FOR POINT REDUCTION AT DMV, NOT FOR COURT USE" );
    	}
	$self->{PDF}->setFont('HELVETICABOLD', 9);
	$self->{PDF}->writeLine (100-$xDiff,62,"THIS PROOF IS FOR STUDENT RECORDS ONLY. DO NOT SUBMIT THIS PROOF TO THE COURT.");

        $y = 250;
        $xOffset = 215;
    }
        if(!$printId && !$userData->{UPSELLEMAIL}){
                $printId=$self->MysqlDB::getNextId('contact_id');
        }

	##For Fedex POC - start - Jira - IDSUIUX-243
	if($userData->{UPSELLMAILFEDEXOVA}) {
		my $variableDataStr = join '~',@variableData;
		my $fixedData=Certificate::_generateFixedData($userData);
		if(!$faxEmail){
			if(!$printId){
				$printId=$self->MysqlDB::getNextId('contact_id');
			}
			if(!$userData->{NOMANIFEST}){
				$self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
			}
		}
	}
	##For Fedex POC - end - Jira - IDSUIUX-243


    ###### how about the course def
    return ($self->{PDF},$printId,'',$self->{PS});
}

sub constructor
{
	my $self = shift;
	my ($userId,$top,$bottom,$faxEmail, $residentState, $countyId, $productId, $pocMail, $pocEmail)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
	my $certImage = "CertificateForStudent.jpg";
	if($pocMail) {
		$certImage = "CertificateForStudent.jpg";
	} elsif($pocEmail) {
		$certImage = "CertificateForStudentBG.jpg";
	}
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/$certImage",
					0, 0, 612, 792,1275,1650);
	return $self;
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: dharmateja $

=item $Date: 2009-09-23 16:09:43 $

=item $Rev: 71 $

=cut

1;
