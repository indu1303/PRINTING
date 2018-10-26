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

package Certificate::DIPTexas;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;
sub _generateCertificate {
    my $self = shift;
    my ($userId, $userData,$printId,$productId,$reprintData,$faxEmail) = @_;
#print STDERR "\n USER HERE --- $userId, $userData,$printId,$productId,$reprintData,$faxEmail \n";
#print Dumper($reprintData);
print Dumper($userData);
#exit;
    my $ycoord = 0;
    my $ctrMysql=0;
    my $xDiff=0;
    my @variableData;
    my $stateId=$userData->{COURSE_STATE};
    my $regDef = $$userData{REGULATOR_DEF};
    my $office = 1;
    my $deliveryId=($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;

    ##### Let's give a delivery flag
    my $flag = ($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} == 11) ? '(ONM)' 
            : ($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} == 2) ? '(ONA)' 
            : ($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} == 7)?'(TDX)' 
            : '';
    
    $userData->{DELIEVRY_DEF}=$flag;
    ##### Now, let's assemble the classroom / instructor information based on the course the user
    ##### signed up for 

    ###### default case
    my $classroom = "C1635-001";
    if($userData->{DD_SCHOOL_NUM}){
       $classroom = "C1828-001";
    }  
    my $instructor = "REYNA, CARLOS (7014)";
    my $reasonForAttendance = "Traffic Citation";
    my $headerRef = 'REGULAR';
    my $courseProvider = '';
    my $seatBeltCourse = 0;
    my $certNumber = $userData->{CERTIFICATE_NUMBER};
    my $printDate = Settings::getDate();
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
    	$OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    if ($userData->{COURSE_ID} eq "1006" || $userData->{COURSE_ID} eq "1005")
    {
        $certNumber = "SP225-" . $certNumber;
        $reasonForAttendance = "Citation";
        if ($reprintData && $reprintData->{CERTIFICATE_NUMBER})
        {
            $reprintData->{CERTIFICATE_NUMBER} = "SP225-" . $reprintData->{CERTIFICATE_NUMBER};
        }
        $headerRef = 'OCPS';
        $seatBeltCourse = 'SPECIALIZED "SEAT BELT" COURSE';
	$courseProvider = "CP225-C1635";
    }
    elsif($productId && $productId eq '25'){
    	my $productName=$self->{SETTINGS}->{PRODUCT_NAME}->{$productId};
	$OFFICECA = $self->{SETTINGS}->getOfficeCa($productName);
        if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && !$faxEmail){
    		if(exists $self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName}){
			$OFFICECA=$self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName};
    		}else{
    			$OFFICECA = $self->{SETTINGS}->getOfficeCa($productName);
		}
    	} 
	$instructor = "Rick Hernandez (7088)";
	$certNumber = "CP490-" . $certNumber;
	$classroom=$userData->{DISTRIBUTOR_SCHOOL_CODE};
        if ($reprintData && $reprintData->{CERTIFICATE_NUMBER})
        {
            $reprintData->{CERTIFICATE_NUMBER} = "CP490-" . $reprintData->{CERTIFICATE_NUMBER};
        }
	$courseProvider = "CP490-C0399";

    }
    else
    {
	if($userData->{COURSE_ID} eq '1015' && $productId eq '1'){
        	$certNumber = "CP490-" . $certNumber;
	        if ($reprintData && $reprintData->{CERTIFICATE_NUMBER})
        	{
	            $reprintData->{CERTIFICATE_NUMBER} = "CP490-" . $reprintData->{CERTIFICATE_NUMBER};
        	}
		$courseProvider = "CP490-C0399";
	}else{
        	$certNumber = "CP225-" . $certNumber;
	        if ($reprintData && $reprintData->{CERTIFICATE_NUMBER})
        	{
	            $reprintData->{CERTIFICATE_NUMBER} = "CP225-" . $reprintData->{CERTIFICATE_NUMBER};
        	}
		$courseProvider = "CP225-C1635";
	}
    }


    if ($userData->{COURSE_ID} eq "1006")
    {
        $instructor = "REYNA, CARLOS (7014)";
    }
    elsif ($userData->{COURSE_ID} eq "1005" || $userData->{COURSE_ID} eq "1007")
    {
        ###### these are classroom taught courses.  Get the appropriate information from the database
        $classroom = $userData->{LOCATION_ID};
        $instructor = "$userData->{INSTRUCTOR_NAME} ($userData->{EDUCATOR_ID})";
    }
    ##EMAINT-522
    if($userData->{COURSE_ID} eq '1011' || $userData->{COURSE_ID} eq '1015') {
        $instructor = "RENTERIA, REBECCA (7948)";
    }
    

    if ($reprintData) {
	$userData->{COMPLETION_DATE} = $userData->{COMPLETIONDATE};
    }
    my @cData = split(/ /,$userData->{COMPLETION_DATE});
    $cData[0] =~ s/\-/\//g;
    $userData->{COMPLETION_DATE} = $cData[0];
print "\n ____Comp Dte:  $userData->{COMPLETION_DATE} \n";
  
    @cData = split(/-/, $printDate);
    if ($cData[0] <10)  { $cData[0] = "0" . $cData[0];  };
    my $tempDate = $cData[0];
    $cData[0] = $self->{SETTINGS}->{MONTH_NUM}->{uc $cData[1]};
    $cData[1] = $tempDate;
    $printDate = join('/',@cData);
    if(!$reprintData  && $userData->{PRINT_DATE}){
	$printDate =$userData->{PRINT_DATE};
    }

#aabbcc
    	my $helvetica       = 'HELVETICA';
	my $helveticaBold   = 'HELVETICABOLD';


	
    	my $yPos = 124;
        my $userAddressInfo;
        my $userDLInfo;
        my $nameChange = 0;
        my $addressChange = 0;
	my $dlChange = 0;

        if ($reprintData) {
                if ($reprintData->{FIRST_NAME} && 
                        $reprintData->{FIRST_NAME} ne $userData->{FIRST_NAME})
                {
                        $nameChange = 1;
                        $userAddressInfo->{FIRST_NAME} = $reprintData->{FIRST_NAME};
                }
                else
                {
                        $userAddressInfo->{FIRST_NAME} = $userData->{FIRST_NAME};
                }
                
                if ($reprintData->{LAST_NAME} && 
                        $reprintData->{LAST_NAME} ne $userData->{LAST_NAME})
                {
                        $nameChange = 1;
                        $userAddressInfo->{LAST_NAME} = $reprintData->{LAST_NAME};
                }
                else
                {
                        $userAddressInfo->{LAST_NAME} = $userData->{LAST_NAME};
                }
                
                if ($reprintData->{ADDRESS_1} && 
                        $reprintData->{ADDRESS_1} ne $userData->{ADDRESS_1})
                {
                        $addressChange = 1;
                        $userAddressInfo->{ADDRESS_1} = $reprintData->{ADDRESS_1};
                }
                else
                {
                        $userAddressInfo->{ADDRESS_1} = $userData->{ADDRESS_1};
                }
                if ($reprintData->{ADDRESS_2} && 
                        $reprintData->{ADDRESS_2} ne $userData->{ADDRESS_2})
                {
                        $addressChange = 1;
                        $userAddressInfo->{ADDRESS_2} = $reprintData->{ADDRESS_2};
                }
                else
                {
                        $userAddressInfo->{ADDRESS_2} = $userData->{ADDRESS_2};
                }
                if ($reprintData->{CITY} && 
                        $reprintData->{CITY} ne $userData->{CITY})
                {
                        $addressChange = 1;
                        $userAddressInfo->{CITY} = $reprintData->{CITY};
                }
                else
                {
                        $userAddressInfo->{CITY} = $userData->{CITY};
                }
                if ($reprintData->{STATE} && 
                        $reprintData->{STATE} ne $userData->{STATE})
                {
                        $addressChange = 1;
                        $userAddressInfo->{STATE} = $reprintData->{STATE};
                }
                else
                {
                        $userAddressInfo->{STATE} = $userData->{STATE};
                }
                if ($reprintData->{ZIP} && 
                        $reprintData->{ZIP} ne $userData->{ZIP})
                {
                        $addressChange = 1;
                        $userAddressInfo->{ZIP} = $reprintData->{ZIP};
                }
                else
                {
                        $userAddressInfo->{ZIP} = $userData->{ZIP};
                }
		if ($reprintData->{DRIVERS_LICENSE} && 
                        $reprintData->{DRIVERS_LICENSE} ne $userData->{DRIVERS_LICENSE})
                {
                        $dlChange = 1;
                        $userDLInfo->{DRIVERS_LICENSE} = $reprintData->{DRIVERS_LICENSE};
                }
                else
                {
                        $userDLInfo->{DRIVERS_LICENSE} = $userData->{DRIVERS_LICENSE};
                }

        }
        else
        {
                $userAddressInfo = $userData;
        }

	##print Student Addresse
	
        $self->_printAddress(124, $userAddressInfo);
        $self->_printAddress(500, $userAddressInfo);

	##Certificate Number
	if($reprintData) {
		$self->{PDF}->setFont($helvetica, 8);
	        $self->{PDF}->writeLine(515, 376, $certNumber);
        	$self->{PDF}->writeLine(515, 759, $certNumber);

		$self->{PDF}->setFont($helvetica, 7);
		$self->{PDF}->writeLine(445, 366, "Changed from: $reprintData->{CERTIFICATE_NUMBER}");
		$self->{PDF}->writeLine(445, 749, "Changed from: $reprintData->{CERTIFICATE_NUMBER}");

	} else {
		$self->{PDF}->setFont($helvetica, 8);
	        $self->{PDF}->writeLine(515, 376, $certNumber);
        	$self->{PDF}->writeLine(515, 759, $certNumber);
	}
	##Student Name
print "_________________ $userAddressInfo->{FIRST_NAME} $userAddressInfo->{LAST_NAME} ---- \n";
	if ($nameChange) {
		$self->{PDF}->setFont($helvetica, 8);
		$self->{PDF}->writeLine(445, 330, "$userAddressInfo->{FIRST_NAME} $userAddressInfo->{LAST_NAME}");
		$self->{PDF}->writeLine(445, 709, "$userAddressInfo->{FIRST_NAME} $userAddressInfo->{LAST_NAME}");

		$self->{PDF}->setFont($helvetica, 7);
		$self->{PDF}->writeLine(445, 320, "Changed from: $userData->{FIRST_NAME} $userData->{LAST_NAME}");
		$self->{PDF}->writeLine(445, 700, "Changed from: $userData->{FIRST_NAME} $userData->{LAST_NAME}");		
	} else {
		$self->{PDF}->setFont($helvetica, 8);
		$self->{PDF}->writeLine(445, 330, "$userData->{FIRST_NAME} $userData->{LAST_NAME}");
		$self->{PDF}->writeLine(445, 709, "$userData->{FIRST_NAME} $userData->{LAST_NAME}");
	}

	##DL
	if($dlChange) {
		$self->{PDF}->setFont($helvetica, 8);
		$self->{PDF}->writeLine(445, 295, "$userDLInfo->{DRIVERS_LICENSE}");
		$self->{PDF}->writeLine(445, 676, "$userDLInfo->{DRIVERS_LICENSE}");

		$self->{PDF}->setFont($helvetica, 7);
		$self->{PDF}->writeLine(445, 285, "Changed from: $userData->{DRIVERS_LICENSE}");
		$self->{PDF}->writeLine(445, 666, "Changed from: $userData->{DRIVERS_LICENSE}");		
	} else {
		$self->{PDF}->setFont($helvetica, 8);
		$self->{PDF}->writeLine(445, 295, "$userData->{DRIVERS_LICENSE}");
		$self->{PDF}->writeLine(445, 676, "$userData->{DRIVERS_LICENSE}");
	}

	##DOB
	if($reprintData->{DATE_OF_BIRTH}) {
print "\n HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
		$self->{PDF}->setFont($helvetica, 8);
		$self->{PDF}->writeLine(445, 256, "$reprintData->{DOBFORMATTED}");
		$self->{PDF}->writeLine(445, 640, "$reprintData->{DOBFORMATTED}");

		$self->{PDF}->setFont($helvetica, 7);
		$self->{PDF}->writeLine(445, 245, "Changed from: $userData->{DATE_OF_BIRTH}");
		$self->{PDF}->writeLine(445, 630, "Changed from: $userData->{DATE_OF_BIRTH}");		
	} else {
print "\n ELSE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! $userData->{DATE_OF_BIRTH}  !!!\n";
		$self->{PDF}->setFont($helvetica, 8);
		if($userData->{DOBFORMATTED}) {
			$self->{PDF}->writeLine(445, 256, "$userData->{DOBFORMATTED}");
			$self->{PDF}->writeLine(445, 640, "$userData->{DOBFORMATTED}");
		} else {
			$self->{PDF}->writeLine(445, 256, "$userData->{DATE_OF_BIRTH}");
			$self->{PDF}->writeLine(445, 640, "$userData->{DATE_OF_BIRTH}");
		}
	}
	$self->{PDF}->setFont($helvetica, 8);

	##Course Provider
	$self->{PDF}->writeLine(445, 206, "$courseProvider");
	$self->{PDF}->writeLine(445, 590, "$courseProvider");

	##Shool-Classroom
	$self->{PDF}->writeLine(445, 180, "$classroom");
	$self->{PDF}->writeLine(445, 560, "$classroom");

	##Completion Date
	$self->{PDF}->writeLine(445, 146, "$userData->{COMPLETION_DATE}");
	$self->{PDF}->writeLine(445, 529, "$userData->{COMPLETION_DATE}");
	
	##Issue Date
	$self->{PDF}->writeLine(445, 115, "$printDate");
	$self->{PDF}->writeLine(445, 497, "$printDate");

	#Instructor
	$self->{PDF}->writeLine(444, 82, "$instructor");
	$self->{PDF}->writeLine(444, 461, "$instructor");

	#Reason For Attendance
	$self->{PDF}->writeLine(445, 54, "$reasonForAttendance");
	$self->{PDF}->writeLine(445, 433, "$reasonForAttendance");

	##Court
	$self->{PDF}->writeLine(38, 560, "$regDef");







########################################################
        
    my $txFieldNames =
            {       
                1=>['School-Classroom:',         $classroom,'353'],
                2=>['Instructor:',               $instructor,'389'],
                3=>['Completion Date:',          $userData->{COMPLETION_DATE},'359'],
                4=>['Issue Date:',               $printDate, '383'], 
                5=>["Student's DL Number:",      $userData->{DRIVERS_LICENSE},'339'],
                6=>["Student's DOB:",            $userData->{DATE_OF_BIRTH},'366'],
                7=>["Student's Phone Number:",   $userData->{PHONE},'325'],
                8=>['Court:',                    $regDef,'404'],
                9=>['REASON FOR ATTENDANCE:',    $reasonForAttendance,'302'],
            };

    if ($reprintData)
    {
        ##### let's update some fields:
        if ($reprintData->{PRINT_DATE})             { $txFieldNames->{4}[3] = $reprintData->{PRINT_DATE}; }
        if ($reprintData->{DRIVERS_LICENSE})        { $txFieldNames->{5}[3] = $reprintData->{DRIVERS_LICENSE}; }
        if ($reprintData->{DATE_OF_BIRTH})          { $txFieldNames->{6}[3] = $reprintData->{DATE_OF_BIRTH}; }
        if ($reprintData->{PHONE})                  { $txFieldNames->{7}[3] = $reprintData->{PHONE}; }
        if ($reprintData->{REGULATOR_DEF})          { $txFieldNames->{8}[3] = $reprintData->{REGULATOR_DEF}; }
    }


    my $header =
        {
            REGULAR    => ['STATE OF TEXAS DRIVING SAFETY COURSE UNIFORM CERTIFICATE OF COURSE COMPLETION', 10.5],
            OCPS       => ['STATE OF TEXAS 6HR SPECIALIZED SAFETY COURSE FOR OCCUPANT PROTECTION UNIFORM CERTIFICATE OF COURSE COMPLETION',7.5],
            YPOS       => [0, 755, 363]
        };

    my $fieldCoords =
        {
            CERTIFICATE_NUMBER      => { 1 => [ 440, 730 ], 2 => [ 440, 338 ] },
            STUDENT_NAME            => { 1 => [ 30, 600 ],  2 => [ 30, 96 ]  }
        };

    my $LINESPACE       = 12;
    my $insertData      = "";


    my $yPos = 184;
    
    ###### add the delivery flag
    $self->{PDF}->setFont($helveticaBold, 9);
    $self->{PDF}->writeLine(140-$xDiff, 696, $flag);
    if(!$faxEmail){
	if($productId && $productId eq '25'){
        	$self->_printCorporateAddress(60-$xDiff,686, $OFFICECA,'www.takehome.com');
	        $self->_printCorporateAddress(60-$xDiff,294, $OFFICECA,'www.takehome.com');
	}else{
        	#$self->_printCorporateAddress(60-$xDiff,686, $OFFICECA,'www.idrivesafely.com');
	        #$self->_printCorporateAddress(60-$xDiff,294, $OFFICECA,'www.idrivesafely.com');
	}
    }

    $self->{PDF}->setFont($helvetica, 10);

=pod
    for (my $i = 1; $i <= 2; ++$i)
    {
        $self->{PDF}->writeLine( $fieldCoords->{CERTIFICATE_NUMBER}->{$i}[0]-$xDiff,
                                $fieldCoords->{CERTIFICATE_NUMBER}->{$i}[1],$certNumber);

        if ($i == 1 && $reprintData && $reprintData->{CERTIFICATE_NUMBER})
        {
           $self->{PDF}->writeLine($fieldCoords->{CERTIFICATE_NUMBER}->{1}[0]-$xDiff, $fieldCoords->{CERTIFICATE_NUMBER}->{1}[1] - $LINESPACE,$reprintData->{CERTIFICATE_NUMBER});

           $self->{PDF}->setFont($helveticaBold,10);
           $self->{PDF}->writeLine(293-$xDiff, $fieldCoords->{CERTIFICATE_NUMBER}->{1}[1] - $LINESPACE,"Replaces Certificate Number:");
           $variableData[$ctrMysql++] = "Replaces Certificate Number:$reprintData->{CERTIFICATE_NUMBER}";
        }

        $yPos -= 35;
        $self->{PDF}->setFont($helvetica, 10);

        my $userAddressInfo;
        my $nameChange = 0;
        my $addressChange = 0;

        ###### reprint data 
        if ($reprintData)
        {
                if ($reprintData->{FIRST_NAME} && 
                        $reprintData->{FIRST_NAME} ne $userData->{FIRST_NAME})
                {
                        $nameChange = 1;
                        $userAddressInfo->{FIRST_NAME} = $reprintData->{FIRST_NAME};
                }
                else
                {
                        $userAddressInfo->{FIRST_NAME} = $userData->{FIRST_NAME};
                }
                
                if ($reprintData->{LAST_NAME} && 
                        $reprintData->{LAST_NAME} ne $userData->{LAST_NAME})
                {
                        $nameChange = 1;
                        $userAddressInfo->{LAST_NAME} = $reprintData->{LAST_NAME};
                }
                else
                {
                        $userAddressInfo->{LAST_NAME} = $userData->{LAST_NAME};
                }
                
                if ($reprintData->{ADDRESS_1} && 
                        $reprintData->{ADDRESS_1} ne $userData->{ADDRESS_1})
                {
                        $addressChange = 1;
                        $userAddressInfo->{ADDRESS_1} = $reprintData->{ADDRESS_1};
                }
                else
                {
                        $userAddressInfo->{ADDRESS_1} = $userData->{ADDRESS_1};
                }
                if ($reprintData->{ADDRESS_2} && 
                        $reprintData->{ADDRESS_2} ne $userData->{ADDRESS_2})
                {
                        $addressChange = 1;
                        $userAddressInfo->{ADDRESS_2} = $reprintData->{ADDRESS_2};
                }
                else
                {
                        $userAddressInfo->{ADDRESS_2} = $userData->{ADDRESS_2};
                }
                if ($reprintData->{CITY} && 
                        $reprintData->{CITY} ne $userData->{CITY})
                {
                        $addressChange = 1;
                        $userAddressInfo->{CITY} = $reprintData->{CITY};
                }
                else
                {
                        $userAddressInfo->{CITY} = $userData->{CITY};
                }
                if ($reprintData->{STATE} && 
                        $reprintData->{STATE} ne $userData->{STATE})
                {
                        $addressChange = 1;
                        $userAddressInfo->{STATE} = $reprintData->{DATA}->{STATE};
                }
                else
                {
                        $userAddressInfo->{STATE} = $userData->{STATE};
                }
                if ($reprintData->{ZIP} && 
                        $reprintData->{ZIP} ne $userData->{ZIP})
                {
                        $addressChange = 1;
                        $userAddressInfo->{ZIP} = $reprintData->{ZIP};
                }
                else
                {
                        $userAddressInfo->{ZIP} = $userData->{ZIP};
                }
        }
        else
        {
                $userAddressInfo = $userData;
        }

        $self->_printAddress($yPos, $userAddressInfo);
        
        if ($nameChange && $i == 1)
        {
                $yPos = 472;
                $self->{PDF}->setFont($helveticaBold, 7);
                $self->{PDF}->writeLine(60-$xDiff, $yPos, "NAME CHANGED FROM:");

                $yPos -= 8;
                $self->{PDF}->setFont($helvetica, 7);
                $self->{PDF}->writeLine(60-$xDiff, $yPos, "$userData->{FIRST_NAME} $userData->{LAST_NAME}");

        }
        
        if ($addressChange && $i == 1)
        {
                $yPos = 472;
                my $xPos = ($nameChange) ? 150 : 60;
                $self->{PDF}->setFont($helveticaBold, 7);
                $self->{PDF}->writeLine($xPos-$xDiff, $yPos, "ADDRESS CHANGED FROM:");

                $yPos -= 8;
                $self->{PDF}->setFont($helvetica, 7);
                $self->{PDF}->writeLine($xPos-$xDiff, $yPos, $userData->{ADDRESS_1});

                $yPos -= 8;
                if ($userData->{ADDRESS_2})
                {
                        $self->{PDF}->writeLine($xPos-$xDiff, $yPos, $userData->{ADDRESS_2});
                        $yPos -= 8;
                }
                $self->{PDF}->writeLine($xPos-$xDiff, $yPos, "$userData->{CITY}, $userData->{STATE}  $userData->{ZIP}");

                $yPos = 472;
        }
      
        if ($seatBeltCourse)
        {
            $self->{PDF}->setFont($helvetica, 12);
            $self->{PDF}->writeLine(60-$xDiff, 600, $seatBeltCourse);
        }
       
        $yPos = 576;
        $self->{PDF}->setFont($helveticaBold, $header->{$headerRef}[1]);
        $self->{PDF}->writeLine(60-$xDiff, $header->{YPOS}[$i], $header->{$headerRef}[0]);
        $self->{PDF}->setFont($helvetica, 10);
 
    }
=cut
=pod
  $self->{PDF}->setFont($helvetica, 9);
   my @yPosArr = ( 690, 318);
    foreach my $id (sort keys %$txFieldNames)
    {
        ###### we're going to do this in two different areas
        for (my $i=0; $i < 2; ++$i)
        {
            if (($id == 9 || $id == 8) && $i == 1 )
            {
                ####### do not print out the attendance reason
                next;
            }
            $yPos = $yPosArr[$i];
            my $id2 = ($txFieldNames->{$id}[3]) ? 3 : 1;

            $self->{PDF}->writeLine( $txFieldNames->{$id}[2]-$xDiff, $yPos, $txFieldNames->{$id}[0] );


            ###### let's make an allowance for the court.  Some courts are going to be
            ###### too long for the row.  For this, we're going to split the court based
            ###### on a space

            my $mainPrintVal = Certificate::maxLineWidth($txFieldNames->{$id}[$id2]);
            $self->{PDF}->writeLine( 440-$xDiff, $yPos, $mainPrintVal->{MAINLINE} );

            if ($mainPrintVal->{REM})
            {
                $yPosArr[$i] -= $LINESPACE-2;
                $yPos = $yPosArr[$i];
                $self->{PDF}->writeLine( 440-$xDiff, $yPos, $mainPrintVal->{REM});
            }


            ###### add the "changed from" row
            if ($i == 0 && ! $txFieldNames->{$id}[3])
            {
                $insertData="$txFieldNames->{$id}[1]";
            }
            if ($i == 0 && $txFieldNames->{$id}[3])
            {
                $insertData = "$txFieldNames->{$id}[3] CHANGED FROM {$id}[1]";
                $yPos -= $LINESPACE-4;


                my $changedPrintVal = Certificate::maxLineWidth($txFieldNames->{$id}[1]);
                $self->{PDF}->setFont($helveticaBold, 8);
                $self->{PDF}->writeLine( 360-$xDiff, $yPos, 'CHANGED FROM:');
                $self->{PDF}->writeLine( 440-$xDiff, $yPos, $changedPrintVal->{MAINLINE} );

                if ($changedPrintVal->{REM})
                {
                    $yPos -= 10;

                    $self->{PDF}->writeLine( 440-$xDiff, $yPos, $changedPrintVal->{REM} );
                    $yPosArr[$i] -= $LINESPACE;
                }

                $yPosArr[$i] -= $LINESPACE;
                $self->{PDF}->setFont($helvetica, 9);
            }
	    $yPosArr[$i] -= $LINESPACE;
        }


        my $newField = $txFieldNames->{$id}[0];
        my $searchStr = "'";
        my $replaceStr = "''";
        $newField =~ s/$searchStr/$replaceStr/gi;
        $variableData[$ctrMysql++]="$newField:$insertData";
    }

=cut

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
        my ($userId,$top,$bottom)=@_;
        ###### let's create our certificate pdf object
        $self->{PDF} = Certificate::PDF->new($userId);
print STDERR "\nTemplate: $self->{SETTINGS}->{TEMPLATESPATH}/printing/$top \n";

    	###### get the appropriate templates
	##### Texas only has one template for all of it's TEA-Reported courses
        $self->{PDF}->setTemplate($self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top",'',1);

}


####### the following private functions are in place because STCs and California certificates
####### will contain the same court-based information.  However, since they're declared in two
####### different functions, it's easier this way to keep everything in one place

=pod

=head1 AUTHOR

rajesh@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/DIPTexas.pm $

=item $Author: rajesh $

=item $Date: 2008-12-02 19:20:11 $

=item $Rev: 65 $

=cut

1;
