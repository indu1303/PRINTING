#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
	-> dispatch_to('IDSPrinterDriversEd')
	-> handle;

package IDSPrinterDriversEd;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Printing::DriversEd;
use Settings;
use MysqlDB;
use Settings;
use Certificate::PDF;
use PDF::Reuse;
use Data::Dumper;

use strict;
no strict "refs";

sub new {
	my $self = shift;
	my $class = ref($self) || $self;
	bless {} => $class;
}

sub generateNVCertReport {
	my $API =Printing::DriversEd->new;
	$API->{PRODUCT}='DRIVERSED';
	$API->constructor;
	my $global= Settings->new;
	$global->{PRODUCT}='DRIVERSED';
	$global->{PRODUCT_CON}=$API->{PRODUCT_CON};
	$global->{CRM_CON}=$API->{CRM_CON};

	my $self = shift;
	my $userData = $API->getNVStdentsForReporting();
	#print Dumper($userData);
	my $userCount = keys %$userData;
	my $reportMonthYear;
	if($userCount > 0) {
		##Write the pdf for all students

		my $fileNameStr = '';
		my $reportingFile = "/ids/tools/PRINTING/templates/printing/DE-NV-DIP-Reporting-Template.pdf";
		if(-e $reportingFile) {
			foreach my $userId(keys %$userData) {
				my $firstName = $userData->{$userId}->{FIRST_NAME};
				my $lastName = $userData->{$userId}->{LAST_NAME};
				my $address1 = $userData->{$userId}->{ADDRESS1};
				my $address2 = $userData->{$userId}->{ADDRESS2};
				my $city = $userData->{$userId}->{CITY};
				my $state = $userData->{$userId}->{STATE};
				my $zip = $userData->{$userId}->{ZIP};
				my $dl = $userData->{$userId}->{DL};
				my $dob = $userData->{$userId}->{DOB};
				my $completionDate = $userData->{$userId}->{COMPLETION_DATE};
				my $curDate = $userData->{$userId}->{TODAY_DATE};
				$reportMonthYear = $userData->{$userId}->{MONTH_YEAR};
				#print "\nUserId: $userId $firstName $dob $dl $completionDate<--";
				my $pdfFileName = "";
				$pdfFileName = "/tmp/$userId.pdf";
				$fileNameStr .= "$pdfFileName,";
				prFile($pdfFileName);
				prFont('Helvetica');
				prFontSize(11);
				prText(150,632, "$firstName $lastName");
				prText(150,606, "$address1 $address2");
				prText(322,606, $city);
				prText(430,606, "$state $zip");
				prText(150,563, $dl);
				prText(430,563, $dob);

				if($userData->{$userId}->{SURVEYANS1_TS_PENDINGDURINGENROLL} && uc $userData->{$userId}->{SURVEYANS1_TS_PENDINGDURINGENROLL} eq 'YES') {
					prText(64,500, 'X');
				} elsif($userData->{$userId}->{SURVEYANS1_TS_PENDINGDURINGENROLL} && uc $userData->{$userId}->{SURVEYANS1_TS_PENDINGDURINGENROLL} eq 'NO') {
					prText(140,500, 'X');
				}

				if($userData->{$userId}->{SURVEYANS2_TS_COURTDISMISSINGTICKET} && uc $userData->{$userId}->{SURVEYANS2_TS_COURTDISMISSINGTICKET} eq 'YES') {
					prText(64,455, 'X');
				} elsif($userData->{$userId}->{SURVEYANS2_TS_COURTDISMISSINGTICKET} && uc $userData->{$userId}->{SURVEYANS2_TS_COURTDISMISSINGTICKET} eq 'NO') {
					prText(140,455, 'X');
				}

				if($userData->{$userId}->{SURVEYANS3_TS_COMPLETEDFORCREDIT} && uc $userData->{$userId}->{SURVEYANS3_TS_COMPLETEDFORCREDIT} eq 'YES') {
					prText(64,406, 'X');
				} elsif($userData->{$userId}->{SURVEYANS3_TS_COMPLETEDFORCREDIT} && uc $userData->{$userId}->{SURVEYANS3_TS_COMPLETEDFORCREDIT} eq 'NO') {
					prText(140,406, 'X');
				}
		
				my $finalScore = $userData->{$userId}->{FINALSCORE};
				prText(176,102, $finalScore);

				prText(432,120, $completionDate);

				my $numberOfViolations = ($userData->{$userId}->{SURVEYANS4_TS_VIOLATIONCOUNT}) ? $userData->{$userId}->{SURVEYANS4_TS_VIOLATIONCOUNT} : 'none';
				prText(310,381, $numberOfViolations);

				
				##Signature
				prText(28,228, "$firstName $lastName");
				prText(380,228, $curDate);
				prDoc( { file => $reportingFile,});
				prEnd();
			}
		}
		#print "\n->$fileNameStr<-\n";
		chop($fileNameStr);
		#print "\n->$fileNameStr<-\n";
		my @fileNames = split(/\,/, $fileNameStr);
		my $file = "/tmp/DE-NV-MONTHLY-REPORT-$reportMonthYear.pdf";
		if(-e $file) {
			unlink($file); ##Just to make sure
		}
		prFile($file);
		my $i = 0;
		foreach my $fName(@fileNames) {
			$i = 1;
			if(-e $fName) {
				prDoc( { file => $fName, first => $i, last => $i });	
				unlink($fName);
			}
			$i++;
		}
		prEnd();

		##The file is ready, move the file to the required location
		system("mv $file /ids/tools/PRINTING/WebService/pl/.download/DE/NV/");
	}
}

my $idsPrint = IDSPrinterDriversEd->new;
print Dumper($idsPrint->generateNVCertReport());
