#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Copyright Idrivesafely.com, Inc. 2006
# All Rights Reserved. Licensed Software.
#
# THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF Idrivesafely.com, Inc.
# The copyright notice above does not evidence any actual or
# intended publication of such source code.
#
# PROPRIETARY INFORMATION, PROPERTY OF Idrivesafely.com, Inc.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#!/usr/bin/perl -w 

package Certificate::DEBTWTXTeen32;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Printing::DriversEd;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;

sub printCertificate {
	my $self = shift;
	my ($userId,$userData,$outputType,$printId,$printerKey,$accompanyLetter,$productId,$rePrintData)=@_;
	##### ok, let's load up the @args array w/ the params to send into the
	##### print function
	my $xDiff=0;
	my $yDiff=0;
	my $outputFile = "/tmp/$userId.pdf";
	$self->{PDF} = Certificate::PDF->new("$userId"."_A",'','','','','',612,792);	 
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/DETXTeen32.jpg", 20, 320, 580, 468,1280,1000);

	$self->{PDF}->setFont('HELVETICA', 10);
	if($userData->{REPLACED_CERTIFICATE_NUMBER}){
		$self->{PDF}->writeLine(331-$xDiff, 722-$yDiff, 'X' );
		$self->{PDF}->writeLine(465-$xDiff, 722-$yDiff, $userData->{REPLACED_CERTIFICATE_NUMBER});
	}
	$self->{PDF}->writeLine(44-$xDiff, 722-$yDiff, 'X' ); ##Driver Education School
	$self->{PDF}->writeLine(178-$xDiff, 722-$yDiff, 'X' ); ##Transfer
	#if($userData->{COURSE_REASON}) {
		#if($userData->{COURSE_REASON} eq 'DEDS') {
			###For DEDS, not to check the Transfer(See Back of Details)
			###To Check the 7Hours of BTW + 7Hrs of Incar Observation
			$self->{PDF}->writeLine(44-$xDiff, 687-$yDiff, 'X' );
			$self->{PDF}->writeLine(90-$xDiff, 633-$yDiff, $userData->{LEARNERSPERMITNUMBER} );
		#} else {
			#$self->{PDF}->writeLine(177-$xDiff, 722-$yDiff, 'X' );
		#}
	#}

	my $incarCompletionDate = $userData->{INCAR_COMPLETION_DATE};
	if($incarCompletionDate) {
		$incarCompletionDate =~ s/\// /g;
		my @incarCompDate=split(/ /, $incarCompletionDate);
		$incarCompletionDate = $incarCompDate[0]. '  /  ' . $incarCompDate[1]. '   /  ' . $incarCompDate[2];
		$self->{PDF}->writeLine( 480-$xDiff, 634-$yDiff, $incarCompletionDate);
	}

        my $laboratoryCompletionDate = $userData->{LABORATORYCOMPLETIONDATE};
        if($laboratoryCompletionDate) {
                $laboratoryCompletionDate =~ s/\// /g;
                my @laboratoryCompDate=split(/ /, $laboratoryCompletionDate);
                $laboratoryCompletionDate = $laboratoryCompDate[0]. '  /  ' . $laboratoryCompDate[1]. '   /  ' . $laboratoryCompDate[2];
                $self->{PDF}->writeLine( 480-$xDiff, 634-$yDiff, $laboratoryCompletionDate);
        }


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
	#$self->{PDF}->writeLine( 270-$xDiff, 634-$yDiff, $userData->{COMPLETION_DATE}); ##There will not be course completion date for BTW Transfer students
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
			$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg", 130-$xDiff, 571-$yDiff, 42, 14,1050,305);
		}else{
			$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME_DE}.".jpg", 130-$xDiff, 571-$yDiff, 42, 14,1050,305);
		}
		$self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATABYCOMPDATE}->{TEANUMBER});
	}else{
		if($userData->{INSTRUCTORDATA}->{OLD_INSTRUCTOR_DATA}){
			$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg", 130-$xDiff, 571-$yDiff, 42, 14,1050,305);
		}else{
			$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME_DE}.".jpg", 130-$xDiff, 595-$yDiff, 42, 14,1050,305);
			$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg", 130-$xDiff, 571-$yDiff, 42, 14,1050,305);
		}
		$self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATA}->{TEANUMBER});
	}
	$self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, '4433'); ########## License Number
	$self->{PDF}->writeLine( 470-$xDiff, 609-$yDiff, 'Easy Driving School LLC');
	$self->{PDF}->writeLine( 470-$xDiff, 597-$yDiff, 'dba Driversed.com');
	$self->{PDF}->writeLine( 300-$xDiff, 571-$yDiff, 'C2548');
	$self->{PDF}->writeLine( 470-$xDiff, 571-$yDiff, Settings::getDateFormat());
	$self->{PDF}->getCertificate;
	$self->{PDF} = Certificate::PDF->new("$userId"."_B",'','','','','',612,792);

	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/DETXTeen32Transfer.jpg", 20, 310, 580, 468,1280,1000);	 
	my $schoolData1;

	#if($userData->{COURSE_REASON} && $userData->{COURSE_REASON} eq 'DEDS') {
	#	##For DEDS, no backside information to print
	#} else {
	#
	##For Back-page printing
	
		my $btwInstructions = $userData->{SEVENBTWINSTRUCTION};
		my $incarObservation = $userData->{SEVENINCAROBSERVATION};

		#$self->{PDF}->writeLine(320-$xDiff, 495-$yDiff, 'C2548' ); #Second Page
		$self->{PDF}->setFont('HELVETICA', 10);	 
		#$self->{PDF}->writeLine( 45-$xDiff, 732-$yDiff, '32' );
		$self->{PDF}->writeLine(136-$xDiff, 732-$yDiff, $btwInstructions );
		$self->{PDF}->writeLine(308-$xDiff, 732-$yDiff, $incarObservation );
		#$self->{PDF}->writeLine(433-$xDiff, 732-$yDiff, 'X' );
		#$self->{PDF}->writeLine(521-$xDiff, 732-$yDiff, 'X' );

		#if($userData->{COURSE_REASON}) {
			#if($userData->{COURSE_REASON} eq 'PARENTTAUGHTOPT' || $userData->{COURSE_REASON} eq 'PARENTTAUGHTCOURSE') {
				#$schoolData1->{FIRST_NAME}=$userData->{PARENTNAME};
				#$schoolData1->{LAST_NAME}='';
				#$schoolData1->{ADDRESS_1}=$userData->{PARENTADDRESSLINE1};
				#$schoolData1->{CITY}=$userData->{PARENTADDRESSCITY};
				#$schoolData1->{STATE}=$userData->{PARENTADDRESSSTATE};
				#$schoolData1->{ZIP}=$userData->{PARENTADDRESSPOSTCODE};
				#$self->{PDF}->writeLine(136-$xDiff, 689-$yDiff, $schoolData1->{FIRST_NAME} );
				#$self->{PDF}->writeLine(328-$xDiff, 689-$yDiff, "$schoolData1->{ADDRESS_1},$schoolData1->{CITY},$schoolData1->{STATE} $schoolData1->{ZIP}" );
			#} elsif($userData->{COURSE_REASON} eq 'OTHERDS') {
				$schoolData1->{FIRST_NAME}="DriversEd.com";#$userData->{DSPROVIDER};
				$schoolData1->{LAST_NAME}='';
				$schoolData1->{ADDRESS_1}="4201 FM 1960 WEST, STE. 100"; #$userData->{DSADDRESS};
				$schoolData1->{CITY}="HOUSTON"; #$userData->{DSCITY};
				$schoolData1->{STATE}='TX'; #$userData->{DSSTATE};
				$schoolData1->{ZIP}='77068'; #$userData->{DSZIPCODE};
				$self->{PDF}->writeLine(136-$xDiff, 689-$yDiff, $schoolData1->{FIRST_NAME} );
				$self->{PDF}->writeLine(328-$xDiff, 689-$yDiff, "$schoolData1->{ADDRESS_1},$schoolData1->{CITY},$schoolData1->{STATE} $schoolData1->{ZIP}" );
			#}
		#}
	#}

	############################## Second Cert ########################################
	$self->{PDF}->setFont('HELVETICA', 10);	 
	$self->{PDF}->getCertificate;	 
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);	 
	#$self->{PDF}->addPDF("/tmp/$userId"."_B.pdf");	
	#$self->{PDF}->addPDF("/tmp/$userId"."_A.pdf");	 
	$self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_B.pdf",0,0,'q2','NoNewPage'); 
	my $sig = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}."-b.jpg";
	#if($userData->{COURSE_REASON} && $userData->{COURSE_REASON} eq 'DEDS') {
		###DEDS, no backside information to print
	#} else {
		#$self->{PDF}->genImage($sig,475, 285, 42, 14,1050,305);
	#}
	$self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_A.pdf",0,0,'q2'); 
	unlink "/tmp/$userId"."_A.pdf";	 
	unlink "/tmp/$userId"."_B.pdf";	 
	$self->{PDF}->getCertificate;
	my $st='TX'; ##########Default state, we have mentioned as XX;
	$st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
	my ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32');
	if(!$printer){
		$printer='HP-PDF-HOU04';
		$media='Tray3';
	}
	my $ph;
	my $certType = 'GREEN_CERT';
	open ($ph,"| /usr/bin/lp -o nobanner -q 1 -d $printer -o sides=two-sided-long-edge -o media=$media $outputFile");
	close $ph;
	if(-e $outputFile){
		#print STDERR "\n printCertificate -- /usr/bin/lp -o nobanner -q 1 -d $printer -o sides=two-sided-long-edge -o media=$media $outputFile \n";
		unlink $outputFile;
	}
	$self->{PDF} = Certificate::PDF->new($userId."_F",'','','','','',612,792);
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/DETXTeen32.jpg", 20, 320, 580, 468,1280,1000);
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/DETXTeen32LearnerPermit.jpg", 20, -70, 580, 468,1280,1000);
	if($userData->{REPLACED_CERTIFICATE_NUMBER}){
		$self->{PDF}->writeLine(331-$xDiff, 722-$yDiff, 'X' );
		$self->{PDF}->writeLine(465-$xDiff, 722-$yDiff, $userData->{REPLACED_CERTIFICATE_NUMBER});
	}

	$self->{PDF}->writeLine(44-$xDiff, 722-$yDiff, 'X' ); ##Driver Education School
	$self->{PDF}->writeLine(178-$xDiff, 722-$yDiff, 'X' ); ##Transfer
	$self->{PDF}->writeLine(44-$xDiff, 687-$yDiff, 'X' ); ##7hrs BTW
	$self->{PDF}->writeLine(90-$xDiff, 633-$yDiff, $userData->{LEARNERSPERMITNUMBER} );

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
	#$self->{PDF}->writeLine( 270-$xDiff, 634-$yDiff, $userData->{COMPLETION_DATE}); ##There will not be course completion date for BTW Transfer students

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
		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg", 130-$xDiff, 571-$yDiff, 42, 14,1050,305);
	}else{
		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME_DE}.".jpg", 130-$xDiff, 595-$yDiff, 42, 14,1050,305);
		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg", 130-$xDiff, 571-$yDiff, 42, 14,1050,305);
	}
	if($userData->{INSTRUCTORDATABYCOMPDATE}->{INSTRUCTORID}){
		$self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATABYCOMPDATE}->{TEANUMBER});
	}else{
		$self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, $userData->{INSTRUCTORDATA}->{TEANUMBER});
	}
	$self->{PDF}->writeLine( 300-$xDiff, 597-$yDiff, '4433'); ########## License Number
	$self->{PDF}->writeLine( 470-$xDiff, 609-$yDiff, 'Easy Driving School LLC');
	$self->{PDF}->writeLine( 470-$xDiff, 597-$yDiff, 'dba Driversed.com');
	$self->{PDF}->writeLine( 300-$xDiff, 571-$yDiff, 'C2548');
	$self->{PDF}->writeLine( 470-$xDiff, 571-$yDiff, Settings::getDateFormat());

	if($userData->{ISDPSTESTSKIPPED} && lc $userData->{ISDPSTESTSKIPPED} eq 'true') {
		$self->{PDF}->writeLine(40, 285+$yDiff, 'X' );
	} else {
		if($userData->{HASTXDPSTEST} && lc $userData->{HASTXDPSTEST} eq 'false') {
			#$self->{PDF}->writeLine(47, 285+$yDiff, 'X' );
		} elsif($userData->{HASTXDPSTEST} && lc $userData->{HASTXDPSTEST} eq 'true' && $userData->{ROADRULESSCORE} && $userData->{ROADSIGNSSCORE}) {
			$self->{PDF}->writeLine(47, 268+$yDiff, 'X' );
			$self->{PDF}->writeLine(435, 268+$yDiff, $userData->{ROADRULESSCORE} );
			$self->{PDF}->writeLine(520, 268+$yDiff, $userData->{ROADSIGNSSCORE} );
		}
	}

	$incarCompletionDate = $userData->{INCAR_COMPLETION_DATE};

	if($incarCompletionDate) {
		$incarCompletionDate =~ s/\// /g;
		my @incarCompDate=split(/ /, $incarCompletionDate);
		$incarCompletionDate = $incarCompDate[0]. '  /  ' . $incarCompDate[1]. '   /  ' . $incarCompDate[2];
		$self->{PDF}->writeLine( 480-$xDiff, 634-$yDiff, $incarCompletionDate);
	}

        $laboratoryCompletionDate = $userData->{LABORATORYCOMPLETIONDATE};
        if($laboratoryCompletionDate) {
                $laboratoryCompletionDate =~ s/\// /g;
                my @laboratoryCompDate=split(/ /, $laboratoryCompletionDate);
                $laboratoryCompletionDate = $laboratoryCompDate[0]. '  /  ' . $laboratoryCompDate[1]. '   /  ' . $laboratoryCompDate[2];
                $self->{PDF}->writeLine( 480-$xDiff, 634-$yDiff, $laboratoryCompletionDate);
	}
	#############Next Page##########################333
	#$self->{PDF}->setFont('HELVETICA', 10);
	#if($userData->{REPLACED_CERTIFICATE_NUMBER}){
	#	$self->{PDF}->writeLine(339-$xDiff, 322-$yDiff, 'X' );
	#	$self->{PDF}->writeLine(470-$xDiff, 322-$yDiff, $userData->{REPLACED_CERTIFICATE_NUMBER} );
	#}
	#$self->{PDF}->writeLine(47-$xDiff, 322-$yDiff, 'X' );
	#$self->{PDF}->writeLine(47-$xDiff, 303-$yDiff, 'X' );
	#if($userData->{HASTXDPSTEST} && lc $userData->{HASTXDPSTEST} eq 'true' && $userData->{ROADRULESSCORE} &&  $userData->{ROADSIGNSSCORE}) {
	#	##for road rules/signs no check for Must take class C. If these value obtained, then tick Has passed Class C.
	#} else {
	#	$self->{PDF}->writeLine(47-$xDiff, 285-$yDiff, 'X' );
	#}

	#$self->{PDF}->setFont('HELVETICA', 12);
	#$self->{PDF}->writeLine( 493-$xDiff, 364-$yDiff, $userData->{CERTIFICATE_NUMBER} );
	#$self->{PDF}->writeLine( 50-$xDiff, 365-$yDiff, 'INSURANCE COPY' );

	#$self->{PDF}->setFont('HELVETICA', 10);
	#$self->{PDF}->writeLine( 75-$xDiff, 188-$yDiff, $userData->{LAST_NAME} );
	#$self->{PDF}->writeLine( 228-$xDiff, 188-$yDiff, $userData->{FIRST_NAME} );
	#$userData->{DATE_OF_BIRTH}=$dob[0]. '    ' . $dob[1]. '     ' . $dob[2];
	#$self->{PDF}->writeLine( 408-$xDiff, 188-$yDiff, $userData->{DATE_OF_BIRTH} );
	#if($userData->{SEX} && $userData->{SEX} eq 'M'){
	#	$self->{PDF}->writeLine( 493-$xDiff, 186-$yDiff, 'X' );
	#}elsif($userData->{SEX} && $userData->{SEX} eq 'F'){
	#	$self->{PDF}->writeLine( 533-$xDiff, 186-$yDiff, 'X' );
	#}
	#if($userData->{INSTRUCTORDATA}->{INSTRUCTORID}){
	#	my $sig=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TXTEEN32/".$userData->{INSTRUCTORDATA}->{INSTRUCTORID}.".jpg";
	#	if(-e $sig){
	#		$self->{PDF}->genImage($sig,114, 138-$yDiff, 42, 14,1050,305);
	#	}
	#}
	#if($userData->{INSTRUCTORDATA}->{OLD_INSTRUCTOR_DATA}){
	#	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/carlos.jpg", 114-$xDiff, 114-$yDiff, 42, 14,1050,305);
	#}else{
	#	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME_DE}.".jpg", 114-$xDiff, 140-$yDiff, 42, 14,1050,305);
	#	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}.".jpg", 114-$xDiff, 114-$yDiff, 42, 14,1050,305);
	#}
	#$self->{PDF}->writeLine( 300-$xDiff, 138-$yDiff, $userData->{INSTRUCTORDATA}->{TEANUMBER});
	#$self->{PDF}->writeLine( 300-$xDiff, 138-$yDiff, '4433');
	#$self->{PDF}->writeLine( 470-$xDiff, 150-$yDiff, 'Easy Driving School LLC');
	#$self->{PDF}->writeLine( 470-$xDiff, 138-$yDiff, 'dba Driversed.com');
	#$self->{PDF}->writeLine( 300-$xDiff, 116-$yDiff, 'C2548');
	#if(!$userData->{PERMIT_CERT_PRINT_DATE}){
	#	$self->{PDF}->writeLine( 475-$xDiff, 116-$yDiff, Settings::getDateFormat());
	#}else{
	#	$self->{PDF}->writeLine( 475-$xDiff, 116-$yDiff, $userData->{PERMIT_CERT_PRINT_DATE});
	#}

	$self->{PDF}->getCertificate;
	$self->{PDF} = Certificate::PDF->new("$userId"."_B",'','','','','',612,792);
	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/DETXTeen32Transfer.jpg", 20, 310, 580, 468,1280,1000);

	$self->{PDF}->setFont('HELVETICA', 10);
	#if($userData->{COURSE_REASON} && $userData->{COURSE_REASON} eq 'DEDS') {
	#	##For DEDS, no backside information to print
	#} else {
		$btwInstructions = $userData->{SEVENBTWINSTRUCTION};
		$incarObservation = $userData->{SEVENINCAROBSERVATION};

		#$self->{PDF}->writeLine( 45-$xDiff, 732-$yDiff, '32' );
		$self->{PDF}->writeLine(136-$xDiff, 732-$yDiff, $btwInstructions );
		$self->{PDF}->writeLine(308-$xDiff, 732-$yDiff, $incarObservation );
		#$self->{PDF}->writeLine(433-$xDiff, 732-$yDiff, 'X' );
		#$self->{PDF}->writeLine(521-$xDiff, 732-$yDiff, 'X' );
		
		if($userData->{COURSE_REASON}) {
			if($userData->{COURSE_REASON} eq 'OTHERDS') {
				$schoolData1->{FIRST_NAME}=$userData->{DSPROVIDER};
				$schoolData1->{LAST_NAME}='';
				$schoolData1->{ADDRESS_1}=$userData->{DSADDRESS};
				$schoolData1->{CITY}=$userData->{DSCITY};
				$schoolData1->{STATE}=$userData->{DSSTATE};
				$schoolData1->{ZIP}=$userData->{DSZIPCODE};

				$self->{PDF}->writeLine(136-$xDiff, 689-$yDiff, $schoolData1->{FIRST_NAME} );
				$self->{PDF}->writeLine(328-$xDiff, 689-$yDiff, "$schoolData1->{ADDRESS_1},$schoolData1->{CITY},$schoolData1->{STATE} $schoolData1->{ZIP}" );
			} elsif($userData->{COURSE_REASON} eq 'PARENTTAUGHTOPT' || $userData->{COURSE_REASON} eq 'PARENTTAUGHTCOURSE') {
				$schoolData1->{FIRST_NAME}=$userData->{PARENTNAME};
				$schoolData1->{LAST_NAME}='';
				$schoolData1->{ADDRESS_1}=$userData->{PARENTADDRESSLINE1};
				$schoolData1->{CITY}=$userData->{PARENTADDRESSCITY};
				$schoolData1->{STATE}=$userData->{PARENTADDRESSSTATE};
				$schoolData1->{ZIP}=$userData->{PARENTADDRESSPOSTCODE};
				$self->{PDF}->writeLine(136-$xDiff, 689-$yDiff, $schoolData1->{FIRST_NAME} );
				$self->{PDF}->writeLine(328-$xDiff, 689-$yDiff, "$schoolData1->{ADDRESS_1},$schoolData1->{CITY},$schoolData1->{STATE} $schoolData1->{ZIP}" );
			}
		}
		#$self->{PDF}->writeLine(320, 495, 'C2548' );#Second Page
	#}

	$self->{PDF}->getCertificate;
	$self->{PDF} = Certificate::PDF->new($userId."CERT",'','','','','',612,792);
	$self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_B.pdf",0,0,'q2','NoNewPage'); 
	$sig = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $self->{SETTINGS}->{DIRECTOR_OF_SCHOOL_SIGNATURE_NAME}."-b.jpg";
	#if($userData->{COURSE_REASON} && $userData->{COURSE_REASON} eq 'DEDS') {
	#	##DEDS, no backside information to print
	#} else {
		#$self->{PDF}->genImage($sig,475, 285, 42, 14,1050,305);
	#}
	$self->{PDF}->setNewCustomTemplate("/tmp/$userId"."_F.pdf",0,0,'q2'); 
	$self->{PDF}->getCertificate;
	unlink "/tmp/$userId"."_F.pdf";
	unlink "/tmp/$userId"."_B.pdf";


	$st='TX'; ##########Default state, we have mentioned as XX;
	$st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
	($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32');
	if(!$printer){
		$printer='HP-PDF-HOU04';
		$media='Tray3';
	}
	$certType = 'GREEN_CERT';
	$outputFile = "/tmp/".$userId."CERT.pdf";
	open ($ph,"| /usr/bin/lp -o nobanner -q 1 -d $printer -o sides=two-sided-long-edge -o media=$media $outputFile");
	close $ph;
	if(-e $outputFile){
		unlink $outputFile;
		#print STDERR "\nCert lable: /usr/bin/lp -o nobanner -q 1 -d $printer -o sides=two-sided-long-edge -o media=$media $outputFile \n";
	}

	my $schoolData;
	$schoolData->{FIRST_NAME}=$userData->{FIRST_NAME};
	$schoolData->{LAST_NAME}=$userData->{LAST_NAME};
	if($userData->{ADDRESS_2}) {
		$userData->{ADDRESS_1} .= ", $userData->{ADDRESS_2}";
	}
	$schoolData->{ADDRESS_1}=$userData->{ADDRESS_1};
	$schoolData->{CITY}=$userData->{CITY};
	$schoolData->{STATE}=$userData->{STATE};
	$schoolData->{ZIP}=$userData->{ZIP};

	if($userData->{COURSE_REASON}) {
		if($userData->{COURSE_REASON} eq 'OTHERDS') {
			$schoolData->{FIRST_NAME}=$userData->{DSPROVIDER};
			$schoolData->{LAST_NAME}='';
			$schoolData->{ADDRESS_1}=$userData->{DSADDRESS};
			$schoolData->{CITY}=$userData->{DSCITY};
			$schoolData->{STATE}=$userData->{DSSTATE};
			$schoolData->{ZIP}=$userData->{DSZIPCODE};
		}
	}

	if($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq '1') {
		$schoolData->{DELIVERY_ID} = 1;		
		$self->printRegularLabel($userId, $schoolData);
	}
	#$self->printISRFootPrint($userId,$userData);
	#if($userData->{COURSE_REASON}) {
	#	if($userData->{COURSE_REASON} ne 'DEDS') {
	#		$self->printTXTeenStudentLog($userId,$userData);
	#	}
	#}

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
}

sub printRegularLabel {
	my $self = shift;
	my ($userId, $userData) = @_;
	$self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
	my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/DE_CA_TEEN_Certificate_Label.pdf";
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
	my $productId=41;
	($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT32LBL');
	if(!$printer){
		$printer = 'HP-PDF-HOU04';
	}
	if(!$media){
		$media='Tray4';
	}

	my $outputFile = "/tmp/LABEL$userId.pdf";

	if($userData->{DELIVERY_ID} eq '1') {
		my $ph;
		open ($ph,"| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media $outputFile");
		close $ph;
		if(-e $outputFile){
			#print STDERR "\n printRegularLabel :: /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media $outputFile \n";
			unlink $outputFile;
		}
	}
}

sub constructor {
	my $self = shift;
	return $self;
}

1;
