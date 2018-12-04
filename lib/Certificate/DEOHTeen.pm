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
package Certificate::DEOHTeen;
    
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
    my @variableData;
    my $completionDate = $userData->{COMPLETION_DATE};
    $completionDate=~ s/\// \/ /g;
    $variableData[0]="COMPLETION DATE:$completionDate";
    my $variableDataStr=join '~',@variableData;

    my $fixedData=Certificate::_generateFixedData($userData);
    if(!$printId){
        $printId=$self->MysqlDB::getNextId('contact_id');
    }
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    #return ($self->{PDF},$printId);
    return ('',$printId);
}

sub printStudentOHCerts {
	my $self = shift;
	my ($userId, $userData, $reprintCheck) = @_;
	my $enrollmentFileName = "$userId-".time().".pdf";
	my $urlAppend = "&CertificatePrintingRequestID=$userData->{PRINTING_REQUEST_ID}";
	#$urlAppend = '';
	my $SERVER_NAME     = qx/uname -n/;
	if($reprintCheck) {
		$urlAppend .= "&task=reprint";
	}
	if($userData->{OH_ENROLLMENTS_USERS}) {
		##The request for OH Enrollment Certificate, get the certificates and submit the file for printing
		my $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD_GET_OH_CERTIFICATES};
		my $enrollmentURL = "$host?schoolID=DRVEDCA&productID=$userData->{COURSE_ID}&type=partcert$urlAppend";
		use File::Fetch;
		my $ff = File::Fetch->new(uri => $enrollmentURL);
		my $where = $ff->fetch(to => '/ids/tools/PRINTING/lib/Certificate/');
		system("mv $where /tmp/$enrollmentFileName");
		my $filesize = -s "/tmp/$enrollmentFileName";
		if($filesize < 30720) {
			##If the filesize < 30KB, not to print the cert
			Settings::pSendMail(['supportmanager@IDriveSafely.com','rajesh@ed-ventures-online.com'], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "DriversEd OH Student Enrollment Certificate Issue: " . Settings::getDateTime() . " - $SERVER_NAME", "$enrollmentURL - File Size: $filesize");
			next;
		}
	} elsif($userData->{OHOT_COMPLETION_CERT_NUMBER}) {
		##The request for OH Completion Certificate, get the certificates and submit the file for printing
		my $host = $self->{SETTINGS}->{DRIVERSED_CONSTRAINTS}->{URL}->{PROD_GET_OH_CERTIFICATES};
		my $enrollmentURL = "$host?schoolID=DRVEDCA&productID=$userData->{COURSE_ID}&type=completion$urlAppend";
		use File::Fetch;
		my $ff = File::Fetch->new(uri => $enrollmentURL);
		my $where = $ff->fetch(to => '/ids/tools/PRINTING/lib/Certificate/');
		system("mv $where /tmp/$enrollmentFileName");
		my $filesize = -s "/tmp/$enrollmentFileName";
		if($filesize < 30720) {
			##If the filesize < 30KB, not to print the cert
			Settings::pSendMail(['supportmanager@IDriveSafely.com','rajesh@ed-ventures-online.com'], 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', "DriversEd OH Student Completion Certificate Issue: " . Settings::getDateTime() . " - $SERVER_NAME", "$enrollmentURL - File Size: $filesize");
			next;
		}
	}
    	my $printer = 0;
	my $media = 0;	
	my $st='CO';   ##########  Default state, we have mentioned as XX;
	my $productId=41;  ##### This is for Mature
	$st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
	($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERT');
	my $outputFile = "/tmp/$enrollmentFileName";
	######### send the label to the printer
	my $ph;
	open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
	close $ph;
	if(-e $outputFile){
		unlink $outputFile;
	}
    
	if(!$reprintCheck) {
		my @variableData;
		my $completionDate = $userData->{COMPLETION_DATE};
		$completionDate=~ s/\// \/ /g;
		$variableData[0]="COMPLETION DATE:$completionDate";
		my $variableDataStr=join '~',@variableData;
		my $fixedData=Certificate::_generateFixedData($userData);
		my $printId = 0;
		if(!$printId){
			$printId=$self->MysqlDB::getNextId('contact_id');
		}
		$self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
	}
}

sub printOHTeenLabel
{
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $xDiff='';
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('FDK');
    $self->{PRODUCT}='DRIVERSED';
    $self->{PDF}->setFont('HELVETICA', 9);
    $self->_printCorporateAddress2(21-$xDiff,662, $OFFICECA,'DriversEd.com');


    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    if($userData->{PRODUCT_ID} eq 'C0000023_NM') {
    } else {
	if($userData->{DATE_OF_BIRTH}){
		$self->{PDF}->writeLine(452, $yPos, "DOB : $userData->{DATE_OF_BIRTH}" );
       	}
    }
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS_1} );
    if($userData->{PRODUCT_ID} eq 'C0000023_NM') {
    } else {
	     if($userData->{COMPLETION_DATE}){
	    	$self->{PDF}->writeLine( 452, $yPos, "Completion Date : $userData->{COMPLETION_DATE}" );
	     }
    }
    $yPos -=11;
    if($userData->{ADDRESS_2}){
    	$self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS_2} );
	$yPos -=11;
    }
    $self->{PDF}->writeLine( 21, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}");
    $self->{PDF}->getCertificate;

    my $printer = 0;
    my $media = 0;
    my $st='CO';   ##########  Default state, we have mentioned as XX;
    my $productId=41;  ##### This is for Mature
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
    if(!$printer){
        $printer = 'HP-PDF2-MANUAL';
    }
    if(!$media){
            $media='Tray2';
    }
    my $outputFile = "/tmp/LABEL$userId.pdf";
    ######## send the label to the printer
	
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
	my ($userId,$template)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
	return $self;

}
1;
