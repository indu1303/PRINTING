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

package Certificate::HTSCertificate;

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

    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('HTS_PO');
    if (!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail)
    {
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('HTS',1);
    }

    ###### print corporate address
    if (!$faxEmail)
    {
        $self->_printCorporateAddress(60-$xDiff, 690, $OFFICECA,'support@HappyTrafficSchool.com');
        $self->_printCorporateAddress(60-$xDiff, 89, $OFFICECA,'support@HappyTrafficSchool.com');
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
 
    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $countyId = $userData->{COUNTY_ID};
    my $courseId = $userData->{COURSE_ID};
    if($countyId && exists $self->{SETTINGS}->{CTSI_COUNTY}->{$countyId}){
        my $rankNo=(keys %$fields) +1;
        $fields->{$rankNo}=15;
        $rankNo++;
        $fields->{$rankNo}=2;

        $self->{PDF}->setFont('HELVETICA', 7.5);
        $self->{PDF}->writeLine( 430-$xDiff, 460, "      Simona Di Sabatino" );
        $self->{PDF}->writeLine( 275-$xDiff, 440, "CTSI #2039 - L.A. Superior Court TVS #10050 - CCS Approved - NTSA Approved" );
    }
    my $y = 700;
    my $xOffset = 300;
    my $yPS=467;
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
    }

    ###### how about the course def
    $self->{PDF}->setFont('HELVETICA', 8);
    $userData->{COURSE_AGGREGATE_DESC} =~ s/<BR>/ /gi;
    $self->{PDF}->writeLine ( 135-$xDiff, 320, $userData->{COURSE_AGGREGATE_DESC} );
    my $variableDataStr=join '~',@variableData;
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
	$printId=$self->MysqlDB::getNextId('contact_id');
    }
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
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

    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('HTS_PO');
    if (!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}))
    {
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('HTS',1);
    }

    $self->_printCorporateAddress(60-$xDiff, 690, $OFFICECA,'support@HappyTrafficSchool.com');
    $self->_printCorporateAddress(60-$xDiff, 89, $OFFICECA,'support@HappyTrafficSchool.com');

	###### as we do w/ all things, let's start at the top.  Print the header
    $self->{PDF}->setFont('HELVETICA', 8);
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
	my ($userId,$top,$bottom,$faxEmail)=@_;
	###### let's create our certificate pdf object
        if($faxEmail){
                $self->{PS} = $self->getFile($self->{SETTINGS}->{TEMPLATESPATH}."/printing/htsUserCert.ps");
        }
	$self->{PDF} = Certificate::PDF->new($userId);
	$top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
	$bottom = ($bottom)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$bottom":'';
	my $full=(!$bottom)?1:0;

    ###### get the appropriate templates
    if ($self->{STC})
    {
        $self->{PDF}->setTemplate($top,$top)
    }
    else
    {
        $self->{PDF}->setTemplate($top,$bottom,$full);
    }
 return $self;

}

sub printRegularLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',595,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/HTS_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    $self->{PDF}->setTemplate($top,$bottom,$full);
    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    my $yPos=160;
    $self->{PDF}->setFont('HELVETICABOLD', 10);
    my $position = 310;
    $self->{PDF}->writeLine( 51, $position, $userData->{SHORT_DESC});
    $self->{PDF}->writeLine( 302, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 302, $yPos, $userData->{ADDRESS_1} );
    $yPos -=11;
    if($userData->{ADDRESS_2}){
        $self->{PDF}->writeLine( 302, $yPos, $userData->{ADDRESS_2} );
        $yPos -=11;
    }
    $self->{PDF}->writeLine( 302, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}");
    $self->{PDF}->getCertificate;
    my $printer = 0;
    my $media = 0;
    my $st='XX';   ##########  Default state, we have mentioned as XX;
    my $productId=13;  ##### This is for HTS 
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERTFEDX');
    if(!$printer){
        $printer = 'HP-PDF';
    }
    if(!$media){
            $media='Tray5';
    }

                my $outputFile = "/tmp/LABEL$userId.pdf";
                ######## send the certificate to the printer

                my $ph;
                open ($ph,  "| /usr/bin/lp -o position=bottom-left -o page-left=50 -o media=$media -q 1 -d $printer $outputFile");
                close $ph;
                if(-e $outputFile){
                        unlink $outputFile;
                }

}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: kishan $

=item $Date: 2009-06-17 12:19:29 $

=item $Rev: 71 $

=cut

1;
