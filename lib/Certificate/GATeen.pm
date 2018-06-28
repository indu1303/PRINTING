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
package Certificate::GATeen;
    
use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Data::Dumper;
    
use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;
    
sub printCertificate
{
    my $self = shift;
    my ($userId, $userData,$printId,$productId,$rePrintData,$faxEmail) = @_;
    my @variableData;
    my $printDate=$userData->{JOB_PRINT_DATE};
    use LWP::Simple;
    my $certUrl="$self->{SETTINGS}->{CRMURL}->{NEW}/userdocs/gateenCert/GA_TEEN_PDFS/$printDate/$userId.pdf";
    my $pic = get($certUrl);
    my $pdfFile="GA_$userId.pdf";
    my $printerKey='TX';
    my $outputFile="/tmp/$pdfFile";
    my $printer = 0;
    my $media=0;
    if($pic){
        open(IMAGE, ">/tmp/$pdfFile") || die"image.jpg: $!";
        binmode IMAGE;  # for MSDOS derivations.
        print IMAGE $pic;
        close IMAGE;
        my $state=$userData->{COURSE_STATE};
        my $productId=2;  ##### Default for DIP
	$state='GA';
        ($printer,$media)=Settings::getPrintingDetails($self, $productId, $state,'RLBL');
        if(!$printer){
                $printer = 'HP-PDF2-TX';
        }
        if(!$media){
                $media='Tray2';
        }
        my $ph;
        open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media $outputFile");
        close $ph;
        if(-e $outputFile){
        	unlink($outputFile);
        }
    	return $printId;
   }else{
	return 0;
   }

    
}

sub constructor
{
	my $self = shift;
	my ($userId,$template)=@_;
	###### let's create our certificate pdf object
	return $self;

}

=cut

1;
