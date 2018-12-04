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

package Certificate::INTeen;

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
    
    my @discMsg=split /~/, $self->getCertificateDisclaimer($layout->{DISCLAIMER});
    foreach my $cc(@discMsg)
    {
        $self->{PDF}->writeLine (350-$xDiff, $yDisclaimer, $cc);
        $yDisclaimer -=12;
    }
    
    $yDisclaimer -= 15;

    ###### print the signature
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    $OFFICECA->{PHONE}='(800) 990-2813';
    if(!$faxEmail){
    	$self->_printSignature($yDisclaimer, $layout->{SIGNATURE},1);
  	$self->_printCorporateAddress(60-$xDiff,686, $OFFICECA,'teen.idrivesafely.com');
        $self->_printCorporateAddress(60-$xDiff,89, $OFFICECA,'teen.idrivesafely.com');
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
         $self->{PDF}->writeLine( 480-$xDiff, 60,$certMsgBottom);
    }

    if($userData->{COURSE_STATE} eq 'VA') {
	my $vaContent = "This course does not include the 90-minute parent/student driver<br>education component required for residents of District 8<br>(counties of Arlington, Fairfax, Loudoun and Prince William <br>and the cities of Alexandria, Fairfax, Falls Church, Manassas <br>and Manassas Park). <br>";
	my @vaContentArr = split("<br>",$vaContent);
	$self->{PDF}->setFont('HELVETICA', 8);
	$yPos=120;
	foreach my $vaStr(@vaContentArr) {
 		$self->{PDF}->writeLine( 280-$xDiff, $yPos, $vaStr);
		$yPos -=12;
	}
    }

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $y = 700;
    my $xOffset = 300;
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

            $self->{PDF}->writeLine( $xOffset + $field->{XPOS}-$xDiff, $y, "$field->{DEFINITION}:" );

            if ($field->{DEFAULT})
            {
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
	if($faxEmail){
		$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/certfinal_cstokes.jpg",
                                0, 0, 612, 792,1275,1650);
        }else{
		$self->{PDF} = Certificate::PDF->new($userId);
		$top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
		$bottom = ($bottom)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$bottom":'';
		my $full=(!$bottom)?1:0;

	    ###### get the appropriate templates
		 if($top || $bottom){
         		$self->{PDF}->setTemplate($top,$bottom,$full);
	 	 }
	 }
	 return $self;

}

1;
