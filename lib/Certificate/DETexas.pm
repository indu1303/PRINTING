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

package Certificate::DETexas;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Printing::DriversEd;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;
sub _generateCertificate
{
    my $self = shift;
    my ($userId, $userData,$printId,$productId,$reprintData,$faxEmail) = @_;
print Dumper($userData);
    $reprintData = $userData->{DATA}; ##Got the data from $userData
print Dumper($reprintData);
    my $ycoord = 0;
    my $ctrMysql=0;
    my $xDiff=0;
    my @variableData;
    my $stateId=$userData->{COURSE_STATE};
    my $regDef = $$userData{REGULATOR_DEF};
    my $office = 1;
    my $deliveryId=($userData->{DELIVERY_ID})?$userData->{DELIVERY_ID}:1;

    ##### Let's give a delivery flag
    my $flag = ($userData->{DELIVERY_ID} == 11) ? '(ONM)' 
            : ($userData->{DELIVERY_ID} == 2) ? '(ONA)' 
            : ($userData->{DELIVERY_ID} == 7)?'(TDX)' 
            : '';
    
    $userData->{DELIEVRY_DEF}=$flag;
    ##### Now, let's assemble the classroom / instructor information based on the course the user
    ##### signed up for 

    ###### default case
    my $classroom = 'C2548';
    my $instructor = 'Dr. Michael Black (6541)';
    my $reasonForAttendance = "Traffic Citation";
    my $headerRef = 'REGULAR';
    my $courseProvider = '';
    my $seatBeltCourse = 0;
    my $certNumber = $userData->{CERTIFICATE_NUMBER};
    my $printDate = Settings::getDate();
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('DRIVERSEDTX');
    if ($userData->{COURSE_ID} eq "1006" || $userData->{COURSE_ID} eq "1005")
    {
        $certNumber = "SP548-" . $certNumber;
        $reasonForAttendance = "Citation";
        if ($reprintData && $reprintData->{CERTIFICATE_NUMBER})
        {
            $reprintData->{CERTIFICATE_NUMBER} = "SP548-" . $reprintData->{CERTIFICATE_NUMBER};
        }
        $headerRef = 'OCPS';
        $seatBeltCourse = 'SPECIALIZED "SEAT BELT" COURSE';
    }
    else
    {
	if($userData->{COURSE_ID} eq '1015' && $productId eq '1'){
        	$certNumber = "CP490-" . $certNumber;
	        if ($reprintData && $reprintData->{CERTIFICATE_NUMBER})
        	{
	            $reprintData->{CERTIFICATE_NUMBER} = "CP490-" . $reprintData->{CERTIFICATE_NUMBER};
        	}
	}else{
        	$certNumber = "CP548-" . $certNumber;
	        if ($reprintData && $reprintData->{CERTIFICATE_NUMBER})
        	{
	            $reprintData->{CERTIFICATE_NUMBER} = "CP548-" . $reprintData->{CERTIFICATE_NUMBER};
        	}
		$courseProvider = 'CP548-C2548';
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
    

    my @cData = split(/ /,$userData->{COMPLETION_DATE});
    $cData[0] =~ s/\-/\//g;
    $userData->{COMPLETION_DATE} = $cData[0];
  
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
        my $userAddressInfo;
        my $userDLInfo;
        my $nameChange = 0;
        my $addressChange = 0;
        my $dlChange = 0;
        my $dobChanged = 0;
        my $userDOBInfo;

        if ($reprintData) {
                if ($reprintData->{FIRST_NAME} &&  lc $reprintData->{FIRST_NAME} ne lc $userData->{FIRST_NAME}) {
                        $nameChange = 1;
                        $userAddressInfo->{FIRST_NAME} = $reprintData->{FIRST_NAME};
                } else {
                        $userAddressInfo->{FIRST_NAME} = $userData->{FIRST_NAME};
                }
                if ($reprintData->{LAST_NAME} &&  lc $reprintData->{LAST_NAME} ne lc $userData->{LAST_NAME}) {
                        $nameChange = 1;
                        $userAddressInfo->{LAST_NAME} = $reprintData->{LAST_NAME};
                } else {
                        $userAddressInfo->{LAST_NAME} = $userData->{LAST_NAME};
                }

                if ($reprintData->{ADDRESS_1} &&  $reprintData->{ADDRESS_1} ne $userData->{ADDRESS_1}) {
                        $addressChange = 1;
                        $userAddressInfo->{ADDRESS_1} = $reprintData->{ADDRESS_1};
                } else {
                        $userAddressInfo->{ADDRESS_1} = $userData->{ADDRESS_1};
                }
                if ($reprintData->{ADDRESS_2} && $reprintData->{ADDRESS_2} ne $userData->{ADDRESS_2}) {
                        $addressChange = 1;
                        $userAddressInfo->{ADDRESS_2} = $reprintData->{ADDRESS_2};
                } else {
                        $userAddressInfo->{ADDRESS_2} = $userData->{ADDRESS_2};
                }
                if ($reprintData->{CITY} &&  $reprintData->{CITY} ne $userData->{CITY}) {
                        $addressChange = 1;
                        $userAddressInfo->{CITY} = $reprintData->{CITY};
                } else {
                        $userAddressInfo->{CITY} = $userData->{CITY};
                }
                if ($reprintData->{STATE} && $reprintData->{STATE} ne $userData->{STATE}) {
                        $addressChange = 1;
                        $userAddressInfo->{STATE} = $reprintData->{STATE};
                } else {
                        $userAddressInfo->{STATE} = $userData->{STATE};
                }
                if ($reprintData->{ZIP} &&  $reprintData->{ZIP} ne $userData->{ZIP}) {
                        $addressChange = 1;
                        $userAddressInfo->{ZIP} = $reprintData->{ZIP};
                } else {
                        $userAddressInfo->{ZIP} = $userData->{ZIP};
                }
                if ($reprintData->{DRIVERS_LICENSE} &&  $reprintData->{DRIVERS_LICENSE} ne $userData->{DRIVERS_LICENSE}) {
                        $dlChange = 1;
                        $userDLInfo->{DRIVERS_LICENSE} = $reprintData->{DRIVERS_LICENSE};
                } else {
                        $userDLInfo->{DRIVERS_LICENSE} = $userData->{DRIVERS_LICENSE};
                }
                if ($reprintData->{DATE_OF_BIRTH} &&  $reprintData->{DATE_OF_BIRTH} ne $userData->{DATE_OF_BIRTH}) {
                        $dobChanged = 1;
                        $userDOBInfo->{DATE_OF_BIRTH} = $reprintData->{DATE_OF_BIRTH};
                } else {
                        $userDOBInfo->{DATE_OF_BIRTH} = $userData->{DATE_OF_BIRTH};
                }
        } else {
                $userAddressInfo = $userData;

	}

        ##print Student Addresse
        $self->{PDF}->setFont($helvetica, 9);
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
print "Reprint DOB ->$reprintData->{DATE_OF_BIRTH}<-  DOBFORMATTED->$userData->{DATE_OF_BIRTH}<--DATE_OF_BIRTH->$userData->{DATE_OF_BIRTH}<-\n";
        if($dobChanged) {
                print "\n HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n";
                $self->{PDF}->setFont($helvetica, 8);
                $self->{PDF}->writeLine(445, 256, "$userDOBInfo->{DATE_OF_BIRTH}");
                $self->{PDF}->writeLine(445, 640, "$userDOBInfo->{DATE_OF_BIRTH}");

                $self->{PDF}->setFont($helvetica, 7);
                $self->{PDF}->writeLine(445, 245, "Changed from: $userData->{DATE_OF_BIRTH}");
                $self->{PDF}->writeLine(445, 630, "Changed from: $userData->{DATE_OF_BIRTH}");
        } else {
                print "\n ELSE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! $userData->{DATE_OF_BIRTH}  !!!\n";
                $self->{PDF}->setFont($helvetica, 8);
		$self->{PDF}->writeLine(445, 256, "$userData->{DATE_OF_BIRTH}");
                $self->{PDF}->writeLine(445, 640, "$userData->{DATE_OF_BIRTH}");
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
        if($reprintData) {
                if($userData->{DATA}->{REGULATOR_DEF}) {
                        $regDef = $userData->{DATA}->{REGULATOR_DEF};
                }
        }
        $self->{PDF}->writeLine(38, 560, "$regDef");
        #print "$regDef ->>> if($reprintData && $userData->{DATA}->{REGULATOR_DEF} ne $userData->{REGULATOR_DEF}) { \n";
        if($reprintData && $userData->{DATA}->{REGULATOR_DEF} && $userData->{DATA}->{REGULATOR_DEF} ne $userData->{REGULATOR_DEF}) {
                $self->{PDF}->setFont($helvetica, 7);
                $self->{PDF}->writeLine(38, 550, "Changed from: $userData->{REGULATOR_DEF}");
        }
        $self->{PDF}->setFont($helvetica, 8);

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

    my $insertData      = "";


    ###### add the delivery flag
    $self->{PDF}->setFont($helveticaBold, 9);
    $self->{PDF}->writeLine(140-$xDiff, 696, $flag);
    $self->{PDF}->setFont($helvetica, 10);

    for (my $i = 1; $i <= 2; ++$i)
    {
        if ($i == 1 && $reprintData && $reprintData->{CERTIFICATE_NUMBER})
        {
           $variableData[$ctrMysql++] = "Replaces Certificate Number:$reprintData->{CERTIFICATE_NUMBER}";
        }

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
    }
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
            ####### add the "changed from" row
            if ($i == 0 && ! $txFieldNames->{$id}[3])
            {
                $insertData="$txFieldNames->{$id}[1]";
            }
            if ($i == 0 && $txFieldNames->{$id}[3])
            {
                $insertData = "$txFieldNames->{$id}[3] CHANGED FROM {$id}[1]";
            }
        }

        my $newField = $txFieldNames->{$id}[0];
        my $searchStr = "'";
        my $replaceStr = "''";
        $newField =~ s/$searchStr/$replaceStr/gi;
        $variableData[$ctrMysql++]="$newField:$insertData";
    }

    my $variableDataStr=join '~',@variableData;
print "\nvariableDataStr || $variableDataStr \n";
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

    ###### get the appropriate templates
    ##### Texas only has one template for all of it's TEA-Reported courses
        $self->{PDF}->setTemplate($self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top",'',1);

}


####### the following private functions are in place because STCs and California certificates
####### will contain the same court-based information.  However, since they're declared in two
####### different functions, it's easier this way to keep everything in one place

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/Texas.pm $

=item $Author: kumar $

=item $Date: 2008-12-02 19:20:11 $

=item $Rev: 65 $

=cut

1;
