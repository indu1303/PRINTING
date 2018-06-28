#!/usr/local/bin/perl

package Certificate::CaliforniaEvaluation;

use lib qw(/ids/tools/PRINTING/lib);

use strict;
use Symbol;
use MIME::Lite;
use HTML::Template;
use MysqlDB;
use Data::Dumper;
use Certificate;
use Certificate::PDF;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);
sub printCourseEvaluation
{
    my $self = shift;
    my ($user, $userData, $evalData, $printType,$printerKey) = @_;
    my $productId=1;
    my $pdfFileName="/tmp/EVAL$user.pdf";
    $self->{PDF} = Certificate::PDF->new("EVAL$user",'','','','','',612,792);
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/ca_eval.jpg",
                                0, 0, 612, 792,1275,1650);
    $self->{PDF}->setFont('HELVETICABOLD', 7);
    $self->{PDF}->writeLine(60,560,$userData->{FIRST_NAME}.' '.$userData->{LAST_NAME});
    $self->{PDF}->writeLine(60,535,"I DRIVE SAFELY");
    $self->{PDF}->writeLine(460,560,$userData->{COMPLETION_DATE});
    $self->{PDF}->writeLine(460,535, 'E0138');

    my @qIdArr1=(110,111,112,113,114,99,116);
    my @qIdArr2=(117,118,119,120,121,122,123,124);
    my $qIdYCord1=473;
    my $qIdYCord2=199;
    my $qIdXCord2=520;
    my $qcount1=1;
    my $qcount2=1;
    foreach my $qId(@qIdArr1){
	    $self->{PDF}->writeLine(520,$qIdYCord1,$evalData->{$qId}); 
            if($qcount1==4){
	            $qIdYCord1-=25;
            }elsif($qcount1==6){
                    $qIdYCord1-=25;
            }else{
                    $qIdYCord1-=15; 
            }
            ++$qcount1;
    }
    foreach my $qId(@qIdArr2){
	    if($evalData->{$qId} eq 'N/A'){
	            $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH} .'/printing/images/na.jpg',$qIdXCord2,$qIdYCord2,55,10,110,20);
            }elsif($evalData->{$qId} eq 'NO'){
                    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH} .'/printing/images/no.jpg',$qIdXCord2,$qIdYCord2,55,10,110,20);
            }elsif($evalData->{$qId} eq 'YES'){
                    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH} .'/printing/images/yes.jpg',$qIdXCord2,$qIdYCord2,55,10,110,20);
            }else{
                    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH} .'/printing/images/noreply.jpg',$qIdXCord2,$qIdYCord2,55,10,110,20);
            }
            if($qcount2==1){
	            $qIdYCord2-=18;
            }else{
                    $qIdYCord2-=12.4;
            } 
            $qcount2++;
   }

    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    $self->{PDF}->getCertificate;

    if (-e $pdfFileName)
    {
        ######## Now print the file
        my $printer = 0;
        my $media = 0;
        my $st='CA';   ##########  Default state, we have mentioned as CA;
        my $productId=1;  ##### This is for Mature
        ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
        if(!$printer){
                $printer = 'HP-PDF2-TX';
        }
        if(!$media){
                    $media='Tray2';
        }


        system("lp -d $printer -o media=$media $pdfFileName");

        ######## All should be right w/ the world, so go ahead and delete the temp files
        unlink ($pdfFileName);
        return 1;
    }


    ##### ok, let's see if we need to attach a cover sheet for this regulator
    ######## ok, we have the cover sheet, now let's prepare each certificate and attach it to the email
    ###### now actually send the certificate 
}

1;
