#!/usr/local/bin/perl

package Certificate::LosAngeles;

use lib qw(/ids/tools/PRINTING/lib);

use strict;
use Symbol;
use MIME::Lite;
use HTML::Template;
use MysqlDB;
use Data::Dumper;
use Certificate;
use Certificate::PDF;
use Certificate::CertForStudent;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

sub faxLACertificates
{
    my $self = shift;
    my ($uidArr,$faxNumber,$regulatorDef,$ha,$print) = @_;
    my $templatePath = "/ids/tools/PRINTING/templates/printing/";
    my $sendfaxNumber = $faxNumber;
    my $count = @$uidArr;
    my $msg;
    my @USERIDS;
    my $htmlDocs='';
    my @fileNames;
    for my $uHash ( @$uidArr )
    {
          my $userData=$uHash->{USER_DATA};
          push @USERIDS,$userData->{USER_ID};
    }
    my $allUsers=join (',',@USERIDS);

    ##### ok, let's see if we need to attach a cover sheet for this regulator
    ######## ok, we have the cover sheet, now let's prepare each certificate and attach it to the email
    my $transmittalDate = Settings::getDateTime();
    use Certificate::CertForStudent;
    my $laCert = Certificate::CertForStudent->new; 
    for my $uHash ( @$uidArr )
    {
        my $templateFile = ($ha) ? $ha.'_LA_Certificate.tmpl' : 'CA_LOSANGELES_CERTIFICATE.tmpl';
        my $certTemplate   
                = HTML::Template->new(filename => "$templatePath/$templateFile" );

        my $userData=$uHash->{USER_DATA};
        $transmittalDate=($userData->{PRINT_DATE})?$userData->{PRINT_DATE}:$transmittalDate;
        my $userId=$userData->{USER_ID};
        my $userCitation = $userData->{CITATION}->{CITATION_NUMBER}; 
        my $citation       = (defined $userCitation) ? 
                             $userCitation : 'NONE';
        
        my $address = "<p>$userData->{ADDRESS_1}</p>" .
                        (($userData->{ADDRESS_2}) ? "<p>$userData->{ADDRESS_2}</p>" : "") .
                            "<p>$userData->{CITY}, $userData->{STATE}  $userData->{ZIP}</p>";
	my $courseDesc = 'English Internet';
	if($ha){
                $courseDesc = ($self->{SETTINGS}->{LA_CERT_COURSE_DESC}->{$ha}->{$userData->{COURSE_ID}})?$self->{SETTINGS}->{LA_CERT_COURSE_DESC}->{$ha}->{$userData->{COURSE_ID}}:'English Internet';
	}
	if($userData->{DISK_ID} || $userData->{DISTRIBUTOR_SCHOOL_CODE}) {
		$courseDesc = 'English DVD';
	}
        
        $certTemplate->param( DATE_OF_BIRTH     => $userData->{DATE_OF_BIRTH} ); 
        $certTemplate->param( FINAL_SCORE       => $userData->{FINAL_SCORE} ); 
        $certTemplate->param( DRIVERS_LICENSE   => $userData->{DRIVERS_LICENSE} ); 
        $certTemplate->param( REGULATOR_DEF     => $regulatorDef ); 
        $certTemplate->param( COMPLETION_DATE   => $userData->{COMPLETION_DATE} ); 
        $certTemplate->param( CITATION_NUMBER   => $citation ); 
        $certTemplate->param( CERTIFICATE_NUMBER=> $userData->{CERTIFICATE_NUMBER} ); 
        $certTemplate->param( STUDENT_NAME      => "$userData->{FIRST_NAME} $userData->{LAST_NAME}" );
        $certTemplate->param( ADDRESS           => $address ); 
        $certTemplate->param( PRINT_DATE        => $transmittalDate ); 
        $certTemplate->param( CERTIFICATE_TRANSMITTAL_DATE  => $transmittalDate ); 
        $certTemplate->param( COURSE_DESC  => $courseDesc ); 
        $certTemplate->param( DATE_OF_REGISTRATION  => $userData->{DATE_OF_REGISTRATION} ); 
        if ($print)
        {
		 my $templatePDFFile = ($ha) ? $ha.'_LA_Certificate.pdf' : 'CA_LOSANGELES_CERTIFICATE.pdf';
            	 my $userId      =   $uHash->{USER_ID};
		 $self->constructor($userId,$templatePDFFile);
		 $self->{PDF}->setFont('HELVETICA', 9);
                 $self->{PDF}->writeLine(450, 695, $userData->{CERTIFICATE_NUMBER});
		 $self->{PDF}->setFont('HELVETICA', 8);
		 my $ceritify="This Certifies that $userData->{FIRST_NAME} $userData->{LAST_NAME} has completed on $userData->{COMPLETION_DATE} a Los Angeles Superior Court-approved $courseDesc HSTS course, and has correcly answered $userData->{FINAL_SCORE}% of the questions on the final exam for this course.";
		 my $mainPrintVal = $self->maxHeaderLineWidth($ceritify,100);
                 $self->{PDF}->writeLine(75, 638, $mainPrintVal->{MAINLINE});
		 if($mainPrintVal->{REM}){
			$self->{PDF}->writeLine(75, 628, $mainPrintVal->{REM});
		 }
                 $self->{PDF}->writeLine(175, 555, $userData->{DRIVERS_LICENSE});
                 $self->{PDF}->writeLine(467, 555, $userData->{DATE_OF_BIRTH});
                 $self->{PDF}->writeLine(165, 494, $regulatorDef);
                 $self->{PDF}->writeLine(238, 520, $citation);
		 my $ypos=450;
                 $self->{PDF}->writeLine(70, $ypos, $userData->{ADDRESS_1});
		 if($userData->{ADDRESS_2}){
			$ypos -=12;
                 	$self->{PDF}->writeLine(70, $ypos, $userData->{ADDRESS_2});
		 }
		 $ypos -=12;
                 $self->{PDF}->writeLine(70, $ypos, "$userData->{CITY}, $userData->{STATE}  $userData->{ZIP}");
                 $self->{PDF}->writeLine(465, 460, 'Oakland, California');
                 $self->{PDF}->writeLine(465, 425, $userData->{DATE_OF_REGISTRATION});
                 $self->{PDF}->writeLine(465, 397, $transmittalDate);
                 $self->{PDF}->writeLine(465, 360, $transmittalDate);
                 $self->{PDF}->writeLine(76, 241, $transmittalDate);
		 my $cert = $self->{PDF};
        	 my $outputFile = "/tmp/$userId.pdf";
                 $cert->getCertificate;
            	 $self->printPDF($outputFile, 'TX',0,$ha);
        }else{
    	$htmlDocs =$certTemplate->output;
         my $htmlFileName="/tmp/FAX_$userId.html";
         my $pdfFileName="/tmp/FAX_$userId.pdf";
         open W ,">$htmlFileName" || die "unable to write to file \n";
         print W $htmlDocs;
         close W;

##### convert this file to PDF
         my $cmd = <<CMD;
/usr/bin/htmldoc -f $pdfFileName --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 --size letter $htmlFileName
CMD
         $ENV{TMPDIR}='/tmp/';
         $ENV{HTMLDOC_NOCGI}=1;
         system($cmd);
         unlink ($htmlFileName);
         push @fileNames,$pdfFileName;
         if($userData->{UPSELLEMAIL}){
		my $pId=$laCert->printCertificate($userId, $userData, { EMAIL => $userData->{EMAIL} },1,'CA',0,1);
	}elsif($userData->{UPSELLMAIL}){
		my $pId=$laCert->printCertificate($userId, $userData, { PRINTER => 1 },1,'CA',0,1);
	}

	}
    }
   
    ###### now actually send the certificate 
    if(!$print && @fileNames){
         $self->dbSendFax($sendfaxNumber,@fileNames);
    }
}


sub faxLACoverSheet
{
    my $self = shift;
    my ($regulatorDef, $uidArr, $ha) = @_;
    my $templatePath = "/ids/tools/PRINTING/templates/printing/";
   
    my $templateFile = ($ha) ? $ha . "_LA_CoverSheet.tmpl" : "CA_LOSANGELES_CERTIFICATE_COVERSHEET.tmpl";
    
    my $faxTemplate
                = HTML::Template->new(filename => "$templatePath/$templateFile" );
    
    #### this regulator requires a cover sheet.  Gather all the appropriate data and
    #### send one out.
    my $userData;
    my $emailAddr;
    my @userInfoLoop;
    foreach my $uHash(@$uidArr)
    {
        my %rowData;
        my $userId      =   $uHash->{USER_ID};
        my $uData       =   $uHash->{USER_DATA};
        my $userCitation        = $userData->{USER_CITATION};
        $rowData{NAME}                  = "$uData->{FIRST_NAME} $uData->{LAST_NAME}";
        $rowData{CERTIFICATE_NUMBER}    = $uData->{CERTIFICATE_NUMBER};
        $rowData{COMPLETION_DATE}       = $uData->{COMPLETION_DATE};
        my $citation = $uData->{CITATION}->{CITATION_NUMBER};
        $rowData{CITATION}              = (defined $citation) ? 
                                            $citation : 'NONE';

        push @userInfoLoop, \%rowData;
    }
   
    my $count = @$uidArr;
    
    $faxTemplate->param( FAX_DATE       => Settings::getDate() ); 
    $faxTemplate->param( REGULATOR_DEF  => $regulatorDef ); 
    $faxTemplate->param( COUNT          => $count ); 
    $faxTemplate->param( USER_INFO      => \@userInfoLoop ); 

    ##### all the data has been generated.  Generate the cover letter and return it
    return $faxTemplate->output;
}

sub printPDF
{
    my $self=shift;
    my ($pdfFileName, $printerKey, $noUnlink,$ha) = @_;
    ##### convert this file to PDF

    if (-e $pdfFileName)
    {
        ######## Now print the file
    	my $printer = 0;
	my $media = 0;
	my $st='CA';   ##########  Default state, we have mentioned as CA;
	my $productId=1;  ##### This is for Mature
	$productId=($ha)?$self->{SETTINGS}->{PRODUCT_ID}->{$ha}:$productId;
        ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
        if(!$printer){
        	$printer = 'HP-PDF2-TX';
    	}
        if(!$media){
        	    $media='Tray2';
    	}


        system("lp -d $printer -o media=$media $pdfFileName");

        ######## All should be right w/ the world, so go ahead and delete the temp files
	if(!$noUnlink){
        	unlink ($pdfFileName);
	}
        return 1;
    }
}


sub constructor
{
        my $self = shift;
        my ($userId,$top)=@_;
        ###### let's create our certificate pdf object
        $self->{PDF} = Certificate::PDF->new($userId);
        $top = ($top)?$self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top":'';
        my $full=1;
        $self->{PDF}->setTemplate($top,'',$full);
       return $self;
}



sub maxHeaderLineWidth
{
    my $self = shift;
    my ($line,$size) = @_;
    ###### maximum character length for the court row is 25 characters.  anymore
    ###### and we're going to split the line
    my $mainLine = "";
    my $rem = "";
    if(!$size){$size=100;}
    if (length($line) > $size)
    {
        my @regNameArray = split(/ /, $line);
        my $regField = 0;

        while (length($mainLine) <= $size)
        {
            my $tmp = $mainLine . $regNameArray[$regField] . " ";
            if (length($tmp) <= $size)
            {
                $mainLine .= $regNameArray[$regField] . " ";
                ++$regField;
            }
            else
            {
                last;
            }
        }
        while ($regField < @regNameArray)
        {
            $rem .= $regNameArray[$regField] . " ";
            ++$regField;
        }
    }
    else
    {
        $mainLine = $line;
    }

    my $retval = { MAINLINE => $mainLine, REM => $rem };
    return $retval;
}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/LosAngeles.pm $

=item $Author: saleem $

=item $Date: 2009-07-17 13:45:18 $

=item $Rev: 52 $

=cut

1;
