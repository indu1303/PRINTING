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

package Certificate::TXTeen32;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;

sub _generate6HRPermitCertificate
{
    my $self = shift;
    my ($userId,$userData,$outputType,$printId,$printerKey,$accompanyLetter,$productId,$rePrintData)=@_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $yDiff=0;
    my $outputFile = "/tmp/$userId.pdf";
    if($userData->{PARTIAL_TRANSFER}){
    $self->{PDF} = Certificate::PDF->new($userId."_F",'','','','','',612,792);
#	$yDiff='396';
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32.jpg",
                                20, 320, 580, 468,1280,1000);

            $self->{PDF}->setFont('HELVETICA', 10);
            if($userData->{DUPLICATE_CERTS}){
                $self->{PDF}->writeLine(331-$xDiff, 722-$yDiff, 'X' );
                $self->{PDF}->writeLine(465-$xDiff, 722-$yDiff, $userData->{CERTIFICATE_REPLACED});
            }
            $self->{PDF}->writeLine(44-$xDiff, 722-$yDiff, 'X' );
            $self->{PDF}->writeLine(177-$xDiff, 722-$yDiff, 'X' );


            $self->{PDF}->setFont('HELVETICA', 12);

            $self->{PDF}->writeLine( 485-$xDiff, 755-$yDiff, $userData->{CERTIFICATE_NUMBER} );
            $self->{PDF}->writeLine( 70-$xDiff, 755-$yDiff, 'DPS COPY' );

            $self->{PDF}->setFont('HELVETICA', 10);


            $self->{PDF}->writeLine( 88-$xDiff, 660-$yDiff, $userData->{LAST_NAME} );
            $self->{PDF}->writeLine( 230-$xDiff, 660-$yDiff, $userData->{FIRST_NAME} );
            $self->{PDF}->writeLine( 432-$xDiff, 660-$yDiff, $userData->{DATE_OF_BIRTH} );
            my $dateofbirth=$userData->{DATE_OF_BIRTH};
            $userData->{DATE_OF_BIRTH} =~ s/\// /g;
            my @dob=split(/ /, $userData->{DATE_OF_BIRTH});
            $userData->{DATE_OF_BIRTH}=$dob[0]. '    ' . $dob[1]. '     ' . $dob[2];
            if($userData->{SEX} && $userData->{SEX} eq 'M'){
                $self->{PDF}->writeLine( 492-$xDiff, 658-$yDiff, 'X' );
            }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
                $self->{PDF}->writeLine( 533-$xDiff, 658-$yDiff, 'X' );
        }
        my $completionDate=$userData->{COMPLETION_DATE};
        $userData->{COMPLETION_DATE} =~ s/\// /g;
        my @compDate=split(/ /, $userData->{COMPLETION_DATE});
        $userData->{COMPLETION_DATE}=$compDate[0]. '    ' . $compDate[1]. '     ' . $compDate[2];
#        $self->{PDF}->writeLine( 270-$xDiff, 634-$yDiff, $userData->{COMPLETION_DATE});
        if($userData->{INSTRUCTORDATA}->{INSTRUCTORID}){
                my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATA}->{INSTRUCTORID}.".jpg";
                if(-e $sig){
                        $self->{PDF}->genImage($sig,130, 601-$yDiff, 42, 14,1050,305);
                }
        }
	if($userData->{INSTRUCTORDATA}->{OLD_INSTRUCTOR_DATA}){
        	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg",
                              130-$xDiff, 571-$yDiff, 42, 14,1050,305);
	}else{
        	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg",
                              130-$xDiff, 571-$yDiff, 42, 14,1050,305);
	}
        $self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATA}->{TEANUMBER});
        $self->{PDF}->writeLine( 500-$xDiff, 570-$yDiff, ''); ########## License Number
        $self->{PDF}->writeLine( 470-$xDiff, 597-$yDiff, 'I DRIVE SAFELY');
        $self->{PDF}->writeLine( 300-$xDiff, 571-$yDiff, 'C2267');
#      if($userData->{PERMIT_CERT_PRINT_DATE}){  ########## Partial Transfer
#        $self->{PDF}->writeLine( 470-$xDiff, 571-$yDiff, $userData->{PERMIT_CERT_PRINT_DATE});
#      }else{
        $self->{PDF}->writeLine( 470-$xDiff, 571-$yDiff, 'XX/XX/XXXX');
#      }

    $self->{PDF}->getCertificate;

     $self->{PDF} = Certificate::PDF->new("$userId"."_B",'','','','','',612,792);	 
     $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32Transfer.jpg",	 
                                 20, 310, 580, 468,1280,1000);	 
     $self->{PDF}->setFont('HELVETICA', 10);	 
#   if($userData->{PARTIAL_TRANSFER} && $userData->{PERMIT_CERT_PRINT_DATE}){ ########## Partial Transfer
#     $self->{PDF}->writeLine( 45-$xDiff, 732-$yDiff, '12' );
#   }else{
     $self->{PDF}->writeLine( 45-$xDiff, 732-$yDiff, '32' );	 
#   }
     $self->{PDF}->writeLine(136-$xDiff, 732-$yDiff, 'X' );	 
     $self->{PDF}->writeLine(308-$xDiff, 732-$yDiff, 'X' );	 
     $self->{PDF}->writeLine(433-$xDiff, 732-$yDiff, 'X' );	 
     $self->{PDF}->writeLine(521-$xDiff, 732-$yDiff, 'X' );	 


        my $schoolData1;
        $schoolData1->{FIRST_NAME}=($userData->{SCHOOLNAME})?$userData->{SCHOOLNAME}:$userData->{PARENTNAME};
        $schoolData1->{LAST_NAME}='';
        $schoolData1->{ADDRESS_1}=$userData->{SCHOOLADDRESS};
        $schoolData1->{CITY}=$userData->{SCHOOLCITY};
        $schoolData1->{STATE}=$userData->{SCHOOLSTATE};
        $schoolData1->{ZIP}=$userData->{SCHOOLZIP};
	$self->{PDF}->writeLine(136-$xDiff, 689-$yDiff, $schoolData1->{FIRST_NAME} );	 
	$self->{PDF}->writeLine(328-$xDiff, 689-$yDiff, "$schoolData1->{ADDRESS_1},$schoolData1->{CITY},$schoolData1->{STATE} $schoolData1->{ZIP}" );	 

     $self->{PDF}->getCertificate;	 

     $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);	 
    # $self->{PDF}->addPDF("/tmp/$userId"."_B.pdf");	 
     #$self->{PDF}->addPDF("/tmp/$userId"."_F.pdf");	 
     $self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_B.pdf",0,0,'q2','NoNewPage');	 
     $self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_F.pdf",0,0,'q2');	 
     $self->{PDF}->getCertificate;
     unlink "/tmp/$userId"."_F.pdf";	 
     unlink "/tmp/$userId"."_B.pdf";	 




    }else{
    $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
    $yDiff=-20;
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32LearnerPermit.jpg",
                                20, -70+$yDiff, 580, 468,1280,1000);

    	###### as we do w/ all things, let's start at the top.  Print the header	
    	###### now, print the user's name and address
    	


	    $self->{PDF}->setFont('HELVETICA', 10);
	    if($userData->{DUPLICATE_CERTS}){
                $self->{PDF}->writeLine(339, 322+$yDiff, 'X' );
                $self->{PDF}->writeLine(470, 322+$yDiff, $userData->{CERTIFICATE_REPLACED} );
            }
            $self->{PDF}->writeLine(47, 322+$yDiff, 'X' );
            $self->{PDF}->writeLine(47, 303+$yDiff, 'X' );

	    if($userData->{DPSPERMITEXAM_ROADRULESSCORE}) {
            	$self->{PDF}->writeLine(440, 270+$yDiff, $userData->{DPSPERMITEXAM_ROADRULESSCORE} );
            	$self->{PDF}->writeLine(520, 270+$yDiff, $userData->{DPSPERMITEXAM_ROADSIGNSSCORE} );
            	$self->{PDF}->writeLine(47, 269+$yDiff, 'X' ); ##The exam taken at IDS
	    } else {
            	$self->{PDF}->writeLine(47, 285+$yDiff, 'X' ); ## Must take road rules/signs exam at DPS
	    }

            $self->{PDF}->setFont('HELVETICA', 12);
                $self->{PDF}->writeLine( 493, 364+$yDiff, $userData->{CERTIFICATE_NUMBER} );
                $self->{PDF}->writeLine( 50, 365+$yDiff, 'DPS COPY' );

	    $self->{PDF}->setFont('HELVETICA', 10);


            $self->{PDF}->writeLine( 75, 188+$yDiff, $userData->{LAST_NAME} );
            $self->{PDF}->writeLine( 228, 188+$yDiff, $userData->{FIRST_NAME} );
            $userData->{DATE_OF_BIRTH} =~ s/\// /g;
	    my @dob = split / /,$userData->{DATE_OF_BIRTH};
            $self->{PDF}->writeLine( 410, 188+$yDiff, $dob[0]."    ". $dob[1]."    ". $dob[2] );
            if($userData->{SEX} && $userData->{SEX} eq 'M'){
                $self->{PDF}->writeLine( 493, 186+$yDiff, 'X' );
            }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
                $self->{PDF}->writeLine( 533, 186+$yDiff, 'X' );
	    }
	my $completionDate=$userData->{COMPLETION_DATE};
	if($userData->{INSTRUCTORDATA}->{INSTRUCTORID}){
		my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATA}->{INSTRUCTORID}.".jpg";
		if(-e $sig){
        		$self->{PDF}->genImage($sig,114, 138+$yDiff, 42, 14,1050,305);
		}
	}
	if($userData->{INSTRUCTORDATA}->{OLD_INSTRUCTOR_DATA}){
        	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg",
                              114, 114+$yDiff, 42, 14,1050,305);
	}else{
		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg",
                              114, 114+$yDiff, 42, 14,1050,305);
	}
        $self->{PDF}->writeLine( 300, 138+$yDiff, $userData->{INSTRUCTORDATA}->{TEANUMBER});
        $self->{PDF}->writeLine( 470, 138+$yDiff, 'I DRIVE SAFELY');
 	$self->{PDF}->writeLine( 300, 116+$yDiff, 'C2267');
	if($userData->{PARTIAL_TRANSFER}){
        		$self->{PDF}->writeLine( 475, 116+$yDiff, 'XX/XX/XXXX');
	}else{
		if(!$userData->{PERMIT_CERT_PRINT_DATE}){
        		$self->{PDF}->writeLine( 475, 116+$yDiff, Settings::getDateFormat());
		}else{
        		$self->{PDF}->writeLine( 475, 116+$yDiff, $userData->{PERMIT_CERT_PRINT_DATE});
		}
	}
	
    	$self->{PDF}->getCertificate;
	}
    ###### print the certificate number
    my $faxEmail=0;
    my $variableDataStr='';
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$faxEmail){
        if(!$printId){
                $printId=$self->MysqlDB::getNextId('contact_id');
        }
        if(!$userData->{NOMANIFEST}){
                $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
        }
    }
    my $st='TX';   ##########  Default state, we have mentioned as XX;
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    my ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32');
    if(!$printer){
        $printer='HP-PDF-HOU06';
        $media='Tray5';
    }
    my $ph;
    my $certType = 'GREEN_CERT';
    if(!$userData->{PARTIAL_TRANSFER}){
	    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media $outputFile");
	    close $ph;
    }else{
	    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o sides=two-sided-long-edge -o media=$media $outputFile");
	    close $ph;
    }
    if(-e $outputFile){
        unlink $outputFile;
    }

    if($userData->{PARTIAL_TRANSFER}){
	my $schoolData;
	$schoolData->{FIRST_NAME}=($userData->{SCHOOLNAME})?$userData->{SCHOOLNAME}:$userData->{PARENTNAME};
	$schoolData->{LAST_NAME}='';
	$schoolData->{ADDRESS_1}=$userData->{SCHOOLADDRESS};
	$schoolData->{CITY}=$userData->{SCHOOLCITY};
	$schoolData->{STATE}=$userData->{SCHOOLSTATE};
	$schoolData->{ZIP}=$userData->{SCHOOLZIP};
    	$self->printRegularLabel($userId, $schoolData);
    }else{
    	$self->printRegularLabel($userId, $userData);
    }
    if($userData->{PARTIAL_TRANSFER} && $userData->{PERMIT_CERT_PRINT_DATE}){
    	$self->printISRFootPrint($userId,$userData);
    }
    return $printId;

}

sub printCertificate
{
    my $self = shift;
    my ($userId,$userData,$outputType,$printId,$printerKey,$accompanyLetter,$productId,$rePrintData)=@_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $yDiff=0;

    my $outputFile = "/tmp/$userId.pdf";
    $self->{PDF} = Certificate::PDF->new("$userId"."_A",'','','','','',612,792);	 
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32.jpg",
                                20, 320, 580, 468,1280,1000);

	    $self->{PDF}->setFont('HELVETICA', 10);
	    if($userData->{DUPLICATE_CERTS}){
    		$self->{PDF}->writeLine(331-$xDiff, 722-$yDiff, 'X' );
    		$self->{PDF}->writeLine(465-$xDiff, 722-$yDiff, $userData->{CERTIFICATE_REPLACED});
   	    }
 	    $self->{PDF}->writeLine(44-$xDiff, 722-$yDiff, 'X' );
 	    $self->{PDF}->writeLine(177-$xDiff, 722-$yDiff, 'X' );
	
	
	    $self->{PDF}->setFont('HELVETICA', 12);

	    $self->{PDF}->writeLine( 485-$xDiff, 755-$yDiff, $userData->{CERTIFICATE_NUMBER} );
	    $self->{PDF}->writeLine( 70-$xDiff, 755-$yDiff, 'DPS COPY' );
    
	    $self->{PDF}->setFont('HELVETICA', 10);


	    $self->{PDF}->writeLine( 88-$xDiff, 660-$yDiff, $userData->{LAST_NAME} );
	    $self->{PDF}->writeLine( 230-$xDiff, 660-$yDiff, $userData->{FIRST_NAME} );
	    $self->{PDF}->writeLine( 432-$xDiff, 660-$yDiff, $userData->{DATE_OF_BIRTH} );
	    my $dateofbirth=$userData->{DATE_OF_BIRTH};
	    $userData->{DATE_OF_BIRTH} =~ s/\// /g;
	    my @dob=split(/ /, $userData->{DATE_OF_BIRTH});
	    $userData->{DATE_OF_BIRTH}=$dob[0]. '    ' . $dob[1]. '     ' . $dob[2];
	    if($userData->{SEX} && $userData->{SEX} eq 'M'){
	    	$self->{PDF}->writeLine( 492-$xDiff, 658-$yDiff, 'X' );
	    }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
    		$self->{PDF}->writeLine( 533-$xDiff, 658-$yDiff, 'X' );
    	}
	my $completionDate=$userData->{COMPLETION_DATE};
	$userData->{COMPLETION_DATE} =~ s/\// /g;
	my @compDate=split(/ /, $userData->{COMPLETION_DATE});
	$userData->{COMPLETION_DATE}=$compDate[0]. '    ' . $compDate[1]. '     ' . $compDate[2];
	$self->{PDF}->writeLine( 270-$xDiff, 634-$yDiff, $userData->{COMPLETION_DATE});
        if($userData->{INSTRUCTORDATABYCOMPDATE}->{INSTRUCTORID}){
                my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATABYCOMPDATE}->{INSTRUCTORID}.".jpg";
                if(-e $sig){
                        $self->{PDF}->genImage($sig,130, 601-$yDiff, 42, 14,1050,305);
                }
	}elsif($userData->{INSTRUCTORDATA}->{INSTRUCTORID}){
                my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATA}->{INSTRUCTORID}.".jpg";
                if(-e $sig){
                        $self->{PDF}->genImage($sig,130, 601-$yDiff, 42, 14,1050,305);
                }
	}
	if($userData->{INSTRUCTORDATABYCOMPDATE}->{INSTRUCTORID}){
		if($userData->{INSTRUCTORDATABYCOMPDATE}->{OLD_INSTRUCTOR_DATA}){
        		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg",
                        	      130-$xDiff, 571-$yDiff, 42, 14,1050,305);
		}else{
			$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg",
                	              130-$xDiff, 571-$yDiff, 42, 14,1050,305);
		}
		$self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATABYCOMPDATE}->{TEANUMBER});
	}else{
		if($userData->{INSTRUCTORDATA}->{OLD_INSTRUCTOR_DATA}){
        		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg",
                	              130-$xDiff, 571-$yDiff, 42, 14,1050,305);
		}else{
			$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg",
                	              130-$xDiff, 571-$yDiff, 42, 14,1050,305);
		}
		$self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATA}->{TEANUMBER});
	}
	$self->{PDF}->writeLine( 500-$xDiff, 570-$yDiff, ''); ########## License Number
	$self->{PDF}->writeLine( 470-$xDiff, 597-$yDiff, 'I DRIVE SAFELY');
 	$self->{PDF}->writeLine( 300-$xDiff, 571-$yDiff, 'C2267');
	$self->{PDF}->writeLine( 470-$xDiff, 571-$yDiff, Settings::getDateFormat());


    $self->{PDF}->getCertificate;
     $self->{PDF} = Certificate::PDF->new("$userId"."_B",'','','','','',612,792);	 
     $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32Transfer.jpg",	 
                                 20, 310, 580, 468,1280,1000);	 
     $self->{PDF}->setFont('HELVETICA', 10);	 
     $self->{PDF}->writeLine( 45-$xDiff, 732-$yDiff, '32' );
     $self->{PDF}->writeLine(136-$xDiff, 732-$yDiff, 'X' );
     $self->{PDF}->writeLine(308-$xDiff, 732-$yDiff, 'X' );
     $self->{PDF}->writeLine(433-$xDiff, 732-$yDiff, 'X' );
     $self->{PDF}->writeLine(521-$xDiff, 732-$yDiff, 'X' );

        my $schoolData1;
        $schoolData1->{FIRST_NAME}=($userData->{SCHOOLNAME})?$userData->{SCHOOLNAME}:$userData->{PARENTNAME};
        $schoolData1->{LAST_NAME}='';
        $schoolData1->{ADDRESS_1}=$userData->{SCHOOLADDRESS};
        $schoolData1->{CITY}=$userData->{SCHOOLCITY};
        $schoolData1->{STATE}=$userData->{SCHOOLSTATE};
        $schoolData1->{ZIP}=$userData->{SCHOOLZIP};
        $self->{PDF}->writeLine(136-$xDiff, 689-$yDiff, $schoolData1->{FIRST_NAME} );
        $self->{PDF}->writeLine(328-$xDiff, 689-$yDiff, "$schoolData1->{ADDRESS_1},$schoolData1->{CITY},$schoolData1->{STATE} $schoolData1->{ZIP}" );

     $self->{PDF}->getCertificate;	 
     $self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);	 
     #$self->{PDF}->addPDF("/tmp/$userId"."_B.pdf");	
     #$self->{PDF}->addPDF("/tmp/$userId"."_A.pdf");	 
     $self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_B.pdf",0,0,'q2','NoNewPage'); 
     $self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_A.pdf",0,0,'q2'); 
     unlink "/tmp/$userId"."_A.pdf";	 
     unlink "/tmp/$userId"."_B.pdf";	 
     $self->{PDF}->getCertificate;
    my $st='TX';   ##########  Default state, we have mentioned as XX;
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    my ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32');
    if(!$printer){
        $printer='HP-PDF-HOU06';
        $media='Tray5';
    }
    my $ph;
    my $certType = 'GREEN_CERT';
    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer  -o sides=two-sided-long-edge -o media=$media $outputFile");
    close $ph;
    if(-e $outputFile){
       unlink $outputFile;
    }
    $self->{PDF} = Certificate::PDF->new($userId."_F",'','','','','',612,792);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32.jpg",
                                20, 320, 580, 468,1280,1000);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32LearnerPermit.jpg",
                                20, -70, 580, 468,1280,1000);
#	    $self->{PDF}->setFont('HELVETICA', 10);
	    if($userData->{DUPLICATE_CERTS}){
    		$self->{PDF}->writeLine(331-$xDiff, 722-$yDiff, 'X' );
    		$self->{PDF}->writeLine(465-$xDiff, 722-$yDiff, $userData->{CERTIFICATE_REPLACED});
   	    }
 	    $self->{PDF}->writeLine(44-$xDiff, 722-$yDiff, 'X' );
 	    $self->{PDF}->writeLine(177-$xDiff, 722-$yDiff, 'X' );
	
	
	    $self->{PDF}->setFont('HELVETICA', 12);

	    $self->{PDF}->writeLine( 485-$xDiff, 755-$yDiff, $userData->{CERTIFICATE_NUMBER} );
	    $self->{PDF}->writeLine( 50-$xDiff, 755-$yDiff, 'INSURANCE COPY' );
    
	    $self->{PDF}->setFont('HELVETICA', 10);


	    $self->{PDF}->writeLine( 88-$xDiff, 660-$yDiff, $userData->{LAST_NAME} );
	    $self->{PDF}->writeLine( 230-$xDiff, 660-$yDiff, $userData->{FIRST_NAME} );
	    $self->{PDF}->writeLine( 432-$xDiff, 660-$yDiff, $dateofbirth );
	    $userData->{DATE_OF_BIRTH}=$dob[0]. '    ' . $dob[1]. '     ' . $dob[2];
	    if($userData->{SEX} && $userData->{SEX} eq 'M'){
	    	$self->{PDF}->writeLine( 492-$xDiff, 658-$yDiff, 'X' );
	    }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
    		$self->{PDF}->writeLine( 533-$xDiff, 658-$yDiff, 'X' );
    	}
	$userData->{COMPLETION_DATE}=$compDate[0]. '    ' . $compDate[1]. '     ' . $compDate[2];
	$self->{PDF}->writeLine( 270-$xDiff, 634-$yDiff, $userData->{COMPLETION_DATE});


        if($userData->{INSTRUCTORDATABYCOMPDATE}->{INSTRUCTORID}){
                my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATABYCOMPDATE}->{INSTRUCTORID}.".jpg";
                if(-e $sig){
                        $self->{PDF}->genImage($sig,130, 601-$yDiff, 42, 14,1050,305);
                }
        }elsif($userData->{INSTRUCTORDATA}->{INSTRUCTORID}){
                my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATA}->{INSTRUCTORID}.".jpg";
                if(-e $sig){
                        $self->{PDF}->genImage($sig,130, 601-$yDiff, 42, 14,1050,305);
                }
        }

	if($userData->{INSTRUCTORDATABYCOMPDATE}->{OLD_INSTRUCTOR_DATA}){
	        $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg",
                              130-$xDiff, 571-$yDiff, 42, 14,1050,305);
	}else{
		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg",
                              130-$xDiff, 571-$yDiff, 42, 14,1050,305);
	}
        if($userData->{INSTRUCTORDATABYCOMPDATE}->{INSTRUCTORID}){
         $self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATABYCOMPDATE}->{TEANUMBER});  
        }else{   
        $self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATA}->{TEANUMBER});
         }
        $self->{PDF}->writeLine( 500-$xDiff, 570-$yDiff, ''); ########## License Number
        $self->{PDF}->writeLine( 470-$xDiff, 597-$yDiff, 'I DRIVE SAFELY');
 	$self->{PDF}->writeLine( 300-$xDiff, 571-$yDiff, 'C2267');
        $self->{PDF}->writeLine( 470-$xDiff, 571-$yDiff, Settings::getDateFormat());



#############Next Page##########################333
            $self->{PDF}->setFont('HELVETICA', 10);
            if($userData->{DUPLICATE_CERTS}){
                $self->{PDF}->writeLine(339-$xDiff, 322-$yDiff, 'X' );
                $self->{PDF}->writeLine(470-$xDiff, 322-$yDiff, $userData->{CERTIFICATE_REPLACED} );
            }
            $self->{PDF}->writeLine(47-$xDiff, 322-$yDiff, 'X' );
            $self->{PDF}->writeLine(47-$xDiff, 303-$yDiff, 'X' );


            $self->{PDF}->setFont('HELVETICA', 12);
                $self->{PDF}->writeLine( 493-$xDiff, 364-$yDiff, $userData->{CERTIFICATE_NUMBER} );
                $self->{PDF}->writeLine( 50-$xDiff, 365-$yDiff, 'INSURANCE COPY' );

            $self->{PDF}->setFont('HELVETICA', 10);


	if($userData->{DPSPERMITEXAM_ROADRULESSCORE}) {
		$self->{PDF}->writeLine(440, 270+$yDiff, $userData->{DPSPERMITEXAM_ROADRULESSCORE} );
		$self->{PDF}->writeLine(520, 270+$yDiff, $userData->{DPSPERMITEXAM_ROADSIGNSSCORE} );
		$self->{PDF}->writeLine(47, 269+$yDiff, 'X' ); ##The exam taken at IDS
	} else {
		$self->{PDF}->writeLine(47, 285+$yDiff, 'X' ); ## Must take road rules/signs exam at DPS
	}


            $self->{PDF}->writeLine( 75-$xDiff, 188-$yDiff, $userData->{LAST_NAME} );
            $self->{PDF}->writeLine( 228-$xDiff, 188-$yDiff, $userData->{FIRST_NAME} );
            $userData->{DATE_OF_BIRTH}=$dob[0]. '    ' . $dob[1]. '     ' . $dob[2];
            $self->{PDF}->writeLine( 408-$xDiff, 188-$yDiff, $userData->{DATE_OF_BIRTH} );
            if($userData->{SEX} && $userData->{SEX} eq 'M'){
                $self->{PDF}->writeLine( 493-$xDiff, 186-$yDiff, 'X' );
            }elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
                $self->{PDF}->writeLine( 533-$xDiff, 186-$yDiff, 'X' );
        }
        if($userData->{INSTRUCTORDATA}->{INSTRUCTORID}){
                my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATA}->{INSTRUCTORID}.".jpg";
                if(-e $sig){
                        $self->{PDF}->genImage($sig,114, 138-$yDiff, 42, 14,1050,305);
                }
        }
	if($userData->{INSTRUCTORDATA}->{OLD_INSTRUCTOR_DATA}){
	        $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg",
                              114-$xDiff, 114-$yDiff, 42, 14,1050,305);
	}else{
		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg",
                              114-$xDiff, 114-$yDiff, 42, 14,1050,305);
	}
        $self->{PDF}->writeLine( 300-$xDiff, 138-$yDiff, $userData->{INSTRUCTORDATA}->{TEANUMBER});
        $self->{PDF}->writeLine( 470-$xDiff, 138-$yDiff, 'I DRIVE SAFELY');
 	$self->{PDF}->writeLine( 300-$xDiff, 116-$yDiff, 'C2267');
	if(!$userData->{PERMIT_CERT_PRINT_DATE}){
        	$self->{PDF}->writeLine( 475-$xDiff, 116-$yDiff, Settings::getDateFormat());
        }else{
                $self->{PDF}->writeLine( 475-$xDiff, 116-$yDiff, $userData->{PERMIT_CERT_PRINT_DATE});
        }


    $self->{PDF}->getCertificate;
     $self->{PDF} = Certificate::PDF->new("$userId"."_B",'','','','','',612,792);
     $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32Transfer.jpg",
                                 20, 310, 580, 468,1280,1000);
     $self->{PDF}->setFont('HELVETICA', 10);
     $self->{PDF}->writeLine( 45-$xDiff, 732-$yDiff, '32' );
     $self->{PDF}->writeLine(136-$xDiff, 732-$yDiff, 'X' );
     $self->{PDF}->writeLine(308-$xDiff, 732-$yDiff, 'X' );
     $self->{PDF}->writeLine(433-$xDiff, 732-$yDiff, 'X' );
     $self->{PDF}->writeLine(521-$xDiff, 732-$yDiff, 'X' );

        $schoolData1->{FIRST_NAME}=($userData->{SCHOOLNAME})?$userData->{SCHOOLNAME}:$userData->{PARENTNAME};
        $schoolData1->{LAST_NAME}='';
        $schoolData1->{ADDRESS_1}=$userData->{SCHOOLADDRESS};
        $schoolData1->{CITY}=$userData->{SCHOOLCITY};
        $schoolData1->{STATE}=$userData->{SCHOOLSTATE};
        $schoolData1->{ZIP}=$userData->{SCHOOLZIP};
        $self->{PDF}->writeLine(136-$xDiff, 689-$yDiff, $schoolData1->{FIRST_NAME} );
        $self->{PDF}->writeLine(328-$xDiff, 689-$yDiff, "$schoolData1->{ADDRESS_1},$schoolData1->{CITY},$schoolData1->{STATE} $schoolData1->{ZIP}" );



     $self->{PDF}->getCertificate;
     $self->{PDF} = Certificate::PDF->new($userId."CERT",'','','','','',612,792);
     $self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_B.pdf",0,0,'q2','NoNewPage'); 
     $self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_F.pdf",0,0,'q2'); 
     $self->{PDF}->getCertificate;
     unlink "/tmp/$userId"."_F.pdf";
     unlink "/tmp/$userId"."_B.pdf";


    $st='TX';   ##########  Default state, we have mentioned as XX;
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32');
    if(!$printer){
        $printer='HP-PDF-HOU06';
        $media='Tray5';
    }
    $certType = 'GREEN_CERT';
    $outputFile = "/tmp/".$userId."CERT.pdf";
    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o sides=two-sided-long-edge -o media=$media $outputFile");
    close $ph;
    if(-e $outputFile){
        unlink $outputFile;
    }

	my $schoolData;
	$schoolData->{FIRST_NAME}=($userData->{SCHOOLNAME})?$userData->{SCHOOLNAME}:$userData->{PARENTNAME};
	$schoolData->{LAST_NAME}='';
	$schoolData->{ADDRESS_1}=$userData->{SCHOOLADDRESS};
	$schoolData->{CITY}=$userData->{SCHOOLCITY};
	$schoolData->{STATE}=$userData->{SCHOOLSTATE};
	$schoolData->{ZIP}=$userData->{SCHOOLZIP};
    	$self->printRegularLabel($userId, $schoolData);
	$self->printISRFootPrint($userId,$userData);
    ###### print the certificate number
    my $faxEmail=0;
    my $variableDataStr='';
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$faxEmail){
        if(!$printId){
                $printId=$self->MysqlDB::getNextId('contact_id');
        }
        if(!$userData->{NOMANIFEST}){
                $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
        }
    }
    return $printId;

#    return ($self->{PDF},$printId);

}
sub _generateNoticeOfCancellation
{
    my $self = shift;
    my ($userId,$userData,$outputType,$printId,$printerKey,$accompanyLetter,$productId,$rePrintData)=@_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
    my $yDiff=0;
    $self->{PDF} = Certificate::PDF->new("NOTICE$userId",'','','','','',612,792);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTeen32CancellationNotice.jpg",
				20, 380, 580, 375,1275,825);

    	###### as we do w/ all things, let's start at the top.  Print the header	
    	###### now, print the user's name and address
	    $self->{PDF}->setFont('HELVETICA', 12);
	    $self->{PDF}->writeLine( 138-$xDiff, 607-$yDiff, "$userData->{FIRST_NAME}  $userData->{LAST_NAME}" );
	    $userData->{DATE_OF_BIRTH} =~ s/\// /g;
	    my @dob=split(/ /, $userData->{DATE_OF_BIRTH});
	    $userData->{DATE_OF_BIRTH}=$dob[0]. ' / ' . $dob[1]. ' / ' . $dob[2];
	    $self->{PDF}->writeLine( 138-$xDiff, 583-$yDiff, $userData->{DATE_OF_BIRTH} );
	    my $address = $userData->{ADDRESS_1};
	    if($userData->{ADDRESS_2}){
			$address .=", $userData->{ADDRESS_2}"
	    }
	    $address .=", $userData->{CITY} - $userData->{ZIP}";
	    $self->{PDF}->writeLine( 288-$xDiff, 583-$yDiff, $address);
	    if($userData->{DUPLICATE_CERTS}){
    		$self->{PDF}->writeLine(336-$xDiff, 701-$yDiff, 'X' );
    		$self->{PDF}->writeLine(474-$xDiff, 700-$yDiff, $userData->{CERTIFICATE_REPLACED} );
    	    }
	
	
	    $self->{PDF}->setFont('HELVETICA', 12);

	    $self->{PDF}->writeLine( 430-$xDiff, 513-$yDiff, $userData->{CERTIFICATE_NUMBER} );
    
	    $self->{PDF}->setFont('HELVETICA', 10);
	    $self->{PDF}->writeLine( 130-$xDiff, 475-$yDiff, 'I DRIVE SAFELY' );


	my $completionDate=$userData->{COMPLETION_DATE};
        if($userData->{INSTRUCTORDATA}->{INSTRUCTORID}){
                my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATA}->{INSTRUCTORID}.".jpg";
                if(-e $sig){
                        $self->{PDF}->genImage($sig,124, 510-$yDiff, 42, 14,1050,305);
                }
        }
	$self->{PDF}->writeLine( 425-$xDiff, 488-$yDiff, Settings::getDateFormat());



    ###### print the certificate number
    my $faxEmail=0;
    my $variableDataStr='';
    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$faxEmail){
        if(!$printId){
                $printId=$self->MysqlDB::getNextId('contact_id');
        }
        if(!$userData->{NOMANIFEST}){
                $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
        }
    }
    $self->{PDF}->getCertificate;
     my $printer = 0;
     my $media = 0;
     my $st='TX';
     $productId=2;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32LBL');
    if(!$printer){
                $printer = 'HP-PDF-HOU06';
    }
    if(!$media){
                $media='Tray2';
    }

    my $outputFile = "/tmp/NOTICE$userId.pdf";


    my $ph;
    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
    close $ph;
    if(-e $outputFile){
	    unlink $outputFile;
    }
    return $printId;
#    return ($self->{PDF},$printId);

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
     my $st='TX';
     my $productId=2;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32LBL');
    if(!$printer){
                $printer = 'HP-PDF-HOU06';
    }
    if(!$media){
                $media='Tray2';
    }

    my $outputFile = "/tmp/LABEL$userId.pdf";


    my $ph;
    open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
    close $ph;
    if(-e $outputFile){
    	unlink $outputFile;
    }

}


sub printISRFootPrint
{
    my $self = shift;
    my ($userId,$userData) = @_;
    use LWP::Simple;
    my $genISRUrl = "$self->{SETTINGS}->{CRMURL}->{NEW}/teen32/printStudentISRfootprint/userid/$userId/NOREDIRECT/2";
    my $response = get($genISRUrl);
    my $imagePDFFile="ISR_$userId.pdf";
    my $isrUrl="$self->{SETTINGS}->{CRMURL}->{NEW}/userdocs/isrfootprint/$imagePDFFile";
    my $pdf = get($isrUrl);
    my $printId=0;
    my $outputFile = "/tmp/ISR_$userId.pdf";
    if($pdf){
          open(IMAGE, ">/tmp/$imagePDFFile") || die"image.pdf: $!";
          binmode IMAGE;  # for MSDOS derivations.
          print IMAGE $pdf;
          close IMAGE;
          if(-e $outputFile){
		my $printer = 0;
		my $media = 0;
		my $st='TX';
		my $productId=2;
		($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32LBL');
		if(!$printer){
                	$printer = 'HP-PDF-HOU06';
		}
		if(!$media){
                	$media='Tray2';
		}
    		my $ph;
		open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
		close $ph;
	    	unlink $outputFile;
	 }
	
   }
}


sub constructor
{
	my $self = shift;
	 return $self;
}

1;
