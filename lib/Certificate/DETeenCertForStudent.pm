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

package Certificate::TeenCertForStudent;

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
    my $userInformation .= ' ' . $userData->{CITY} . ', '. $userData->{STATE} . ' ' . $userData->{ZIP};

    ###### now, print the user's name and address
    $self->{PDF}->setFont('HELVETICA', 10);
    ###### print the certificate number
    $self->{PDF}->setFont('HELVETICA', 9);
    $self->{PDF}->writeLine( 455-$xDiff, 666, 'No: '.$userData->{CERTIFICATE_NUMBER} );
    $self->{PDF}->setFont('HELVETICA', 9);
    if(length($userData->{COURSE_AGGREGATE_DESC})>40){
    	prText(530, 533, uc $userData->{COURSE_AGGREGATE_DESC}, 'right');
    }else{
    	prText(500, 533, uc $userData->{COURSE_AGGREGATE_DESC}, 'right');
    }
    $self->{PDF}->writeLine(45-$xDiff, 527, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $self->{PDF}->writeLine(45-$xDiff, 515, $address );
    $self->{PDF}->writeLine(43-$xDiff, 503, $userInformation );
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('IDSPOC');
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}))
    {
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    $self->_printCorporateAddress(45-$xDiff,612, $OFFICECA,'');
    $self->_printHorzCorporateAddress({X => 43-$xDiff, Y => 45, OFFICE => $OFFICECA, DOMAIN => 'teen.idrivesafely.com', SEPARATOR => '|', PHONE => 1});

    ###### now, let's print out the fields....
    my $fields = $layout->{FIELDS};
    my $courseId = $userData->{COURSE_ID};
    my $y = 400;
    $yPS = 567;
    my $xOffset = 185;
    my $courseData='';
    $self->{PDF}->setFont('HELVETICA', 8);
    my @variableData;

    for (my $i=0; $i < 1; ++$i)
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
	        $self->{PDF}->writeLine( $xOffset + $field->{XPOS}+110-$xDiff, $y, $mainPrintVal->{MAINLINE} );
    
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
             
            ##### reset the y
            $y -= 22;
        }
        $y = 250;
        $xOffset = 215;
    }
    ###### how about the course def
    return ($self->{PDF},$printId,'',$self->{PS});
}

sub constructor
{
	my $self = shift;
	my ($userId,$top,$bottom,$faxEmail)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
	$top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/Certificate_For_Student.pdf";
	$bottom = '';
	my $full=1;
	###### get the appropriate templates
	$self->{PDF}->setTemplate($top,$bottom,$full);
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
