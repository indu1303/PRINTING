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

package Certificate::Oklahoma;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Data::Dumper;
use Image::Info qw(image_info dim);

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;

sub _generateCertificate
{
	my $self = shift;
    	my ($userId, $userData,$printId,$productId,$rePrintData,$faxEmail,$fileMode) = @_;
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

    	###### as we do w/ all things, let's start at the top.  Print the header	 
    	$self->{PDF}->setFont('HELVETICA', 10);
    	my $yPos=775;
    	my $yDiff='40';
	$self->{PDF}->writeLine( 221-$xDiff, 785-$yDiff, 'AAA Online Motor Vehicle Crash Prevention Course');
        $self->{PDF}->writeLine( 238-$xDiff, 773-$yDiff, '2121 East 15th Street');
        $self->{PDF}->writeLine( 255-$xDiff, 761-$yDiff, 'Tulsa, OK 74104');
  
    	$self->{PDF}->writeLine( 245-$xDiff, 737-$yDiff, 'Completion Certificate');
    
    	## Print the Bar Code ## 
	system("/usr/local/bin/php /ids/tools/PRINTING/scripts/tools/barcode.php $userData->{CITATION}->{CITATION_NUMBER} > '/tmp/barcode_$userId.jpg'");
	if (-e "/tmp/barcode_$userId.jpg")
	{
		my $imageInfo = image_info("/tmp/barcode_$userId.jpg");	
		my $iWidth = $imageInfo->{width};
		my $X_Width= (612-$iWidth)/2;
		$self->{PDF}->genImage("/tmp/barcode_$userId.jpg", $X_Width, 670-$yDiff, $iWidth, $imageInfo->{height}, $iWidth, $imageInfo->{height});
	}
    	## Bar Code ## 
	

	### Now let's print the course description
    	my $headerDesc= "This certifies that $userData->{FIRST_NAME} $userData->{LAST_NAME} has successfully completed the AAA Online Motor Vehicle Crash Prevention Course.";
    	$self->{PDF}->writeLine( 40-$xDiff, 665-$yDiff, $headerDesc);


    	###### now, let's print out the fields....
    	my $fields = $layout->{FIELDS};
	my $courseId = $userData->{COURSE_ID};

	### Add 'Court Receipt Number' in fields list ##
	my $rankNo = (keys %$fields) +1;
	if($productId != 21){
		$fields->{$rankNo}=6;	
		$rankNo++;
		$fields->{$rankNo}=32;		
		$rankNo++;
		$fields->{$rankNo}=33;		
		$rankNo++;
		$fields->{$rankNo}=34;		
	}

    	my $y = 617;
    	my $yPS = 467;
    	my $xOffset = 60;
    	my $courseData='';
    	$self->{PDF}->setFont('HELVETICA', 9);
    	my @variableData;

    	for (my $i=0; $i < 1; ++$i)
    	{
		my $arrCtr=0;
        	foreach my $rank(sort {$b <=> $a} keys %$fields)
        	{
	    		my $fieldId = $fields->{$rank};
			if ($fieldId == 7 || $fieldId == 5 ||  $fieldId == 8)
			{
				next;
			}
			if($productId == 21 && $fieldId == 35){
                                next;
                        }

            		my $field = $self->getCertificateField($fieldId);
	    		my $miscData=$self->getCourseMiscellaneousData($fieldId,$courseId,$productId);
	    		if (exists $miscData->{DEFAULT} && $miscData->{DEFAULT})
			{
				$field->{DEFAULT}=$miscData->{DEFAULT};
	    		}
	    		my $fieldValue='';

            		$self->{PDF}->writeLine( $xOffset, $y-$yDiff, "$field->{DEFINITION}:" );

            		if ($field->{DEFAULT})
            		{
                		##### is there a default value which needs to be filled in?
	 			my $mainPrintVal = Certificate::maxLineWidth($field->{DEFAULT});
	        		$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $mainPrintVal->{MAINLINE} );
   	 
        			if ($mainPrintVal->{REM})
	        		{
        	        		$y -= $LINESPACE-2;
                			$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $mainPrintVal->{REM});
	        		}
				$fieldValue=$field->{DEFAULT};
            		}
            		elsif ($field->{CITATION})
            		{		
				$userData->{CITATION}->{$field->{DATA_MAP}}=($userData->{CITATION}->{$field->{DATA_MAP}})?$userData->{CITATION}->{$field->{DATA_MAP}}:'NONE';
               	 		##### is this citation information
                		my $mainPrintVal = Certificate::maxLineWidth($userData->{CITATION}->{$field->{DATA_MAP}});
                		$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $mainPrintVal->{MAINLINE});
                		if ($mainPrintVal->{REM})
				{
                        		$y -= $LINESPACE-2;
                        		$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $mainPrintVal->{REM});
				}

				$fieldValue=$userData->{CITATION}->{$field->{DATA_MAP}};
            		}
            		else
            		{	
               			 ##### default case
				$userData->{$field->{DATA_MAP}}=($userData->{$field->{DATA_MAP}})?$userData->{$field->{DATA_MAP}}:'NONE';
                		my $mainPrintVal = Certificate::maxLineWidth($userData->{$field->{DATA_MAP}});
                		$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $mainPrintVal->{MAINLINE});

                		if ($mainPrintVal->{REM})
                		{
                        		$y -= $LINESPACE-2;
                        		$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $mainPrintVal->{REM});
                		}

				$fieldValue=$userData->{$field->{DATA_MAP}};
            		}
	    		if ($faxEmail == 2 && $i==0)
			{
				$courseData .= $xOffset + $field->{XPOS} ." $yPS moveto ($field->{DEFINITION}:)show\n";
				$courseData .= $xOffset +100 ." $yPS moveto ($fieldValue)show\n";
				$yPS -=12;
	    		}
            		$variableData[$arrCtr++]="$field->{DEFINITION}:$fieldValue";
             
            		##### reset the y
            		$y -= 18;
        	}
    	}
	### Let's print the student's name and Address
	$self->{PDF}->writeLine( $xOffset, $y-$yDiff, "Student Name and Address:" );
	my $studentName = $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME}; 
	$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $studentName);
	$y -= $LINESPACE-2;
	$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $userData->{ADDRESS_1}.' '.$userData->{ADDRESS_2});
	$y -= $LINESPACE-2;
	$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $userData->{CITY}.', '.$userData->{STATE}.' '.$userData->{ZIP});

    	###### print the certificate number
	$y -= 54;
    	$self->{PDF}->setFont('HELVETICA', 10);
	$self->{PDF}->writeLine( $xOffset, $y-$yDiff, "Certificate Number:" );
    	$self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, $userData->{CERTIFICATE_NUMBER} );
	
	## print Signature ##
	$y -= 24;
	$self->{PDF}->writeLine( $xOffset, $y-$yDiff, "Signature:" );
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/chuckmaisign.jpg",
		 $xOffset + 120-$xDiff, $y-$LINESPACE-2-$yDiff, 105, 35,1050,305);
        $y -= 18;
        $self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, 'Chuck Mai' );
        $y -= $LINESPACE-2;
        $self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, 'Vice President, Public Affairs' );
        $y -= $LINESPACE-2;
        $self->{PDF}->writeLine( $xOffset + 120-$xDiff, $y-$yDiff, 'AAA Oklahoma' );

    	###### how about the course def
    	$self->{PDF}->setFont('HELVETICA', 8);
    	$userData->{COURSE_AGGREGATE_DESC} =~ s/<BR>/ /gi;
    	my $variableDataStr=join '~',@variableData;
    	my $fixedData=Certificate::_generateFixedData($userData);
    	if (!$faxEmail)
	{
		if (!$printId)
		{
			$printId=$self->MysqlDB::getNextId('contact_id');
    		}
    		$self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    	}
	if ($userData->{COURSE_STATE} eq 'OK' && $userData->{REGULATOR_ID} && $userData->{REGULATOR_ID} == $self->{SETTINGS}->{OKLAHOMA_CITY_COURT}) {
		if($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq 1){
			if(!$fileMode){
				$self->printRegularLabel($userId,$userData);
			}
		}
	}
    	return ($self->{PDF},$printId,'',$self->{PS});
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
     my $st='XX';
     my $productId=1; 
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'POC');
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
	my ($userId,$top,$bottom,$faxEmail)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
	my $full=(!$bottom)?1:0;
	###### get the appropriate templates
        return $self;
}

=pod

=head1 AUTHOR

teja@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/Oklahoma.pm $

=item $Author: saleem $

=item $Date: 2008/10/14 07:32:35 $

=item $Rev: 71 $

=cut

1;
