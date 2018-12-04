use strict;
use PDF::API2;
use Symbol;


use constant mm => 25.4/72;
use constant pt =>    1;

my $pdf = PDF::API2->new;
my $page = $pdf->page;
$page->mediabox(612, 396);

my $fnt = $pdf->corefont('Helvetica-Bold');

my $headlineText = $page->text;
$headlineText->font($pdf->corefont('Helvetica'),7);
$headlineText->translate( 30, 350);
#$headlineText->text( 'THIS CERTIFIES THE FOLLOWING PERSON COMPLETED AN APPROVED HOME STUDY TRAFFIC SAFETY COURSE' );


#$headlineText->translate( 480, 20);
#$headlineText->text( 'COURT COPY' );

$headlineText->font($pdf->corefont('Helvetica'),13);
#$headlineText->translate( 200, 315);
$headlineText->translate( 205, 350);
$headlineText->text( 'CERTIFICATE OF COMPLETION' );

$headlineText->font($pdf->corefont('Helvetica'),6);
$headlineText->translate( 60, 20);
$headlineText->text( 'Only original certificates are accepted by the court, photocopies are not acceptable' );


$headlineText->font($pdf->corefont('Helvetica-Bold'),12);
$headlineText->translate( 475, 338);
$headlineText->text( 'No:' );

$headlineText->font($pdf->corefont('Helvetica-Bold'),9);


my $xIndent = 60;
my $yOffset = 300;
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( 'I DRIVE SAFELY' );
$headlineText->font($pdf->corefont('Helvetica'),8);
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( '674 Via De La Valle, Suite 300' );
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( 'Solana Beach, CA 92075' );
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( 'www.idrivesafely.com' );
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( '(800) 723-1955' );

#my $ph = gensym;
#open($ph, "| /usr/bin/lp -o nobanner -q 1 -d HP-PDF-TX");
#print $ph $pdf->stringify;
#close $ph;

$pdf->saveas('../CA_Template_Court.pdf');
$pdf->end;



####### generate the student template
$pdf = PDF::API2->new;
my $page = $pdf->page;
$page->mediabox(612, 396);

my $headlineText = $page->text;
$headlineText->font($pdf->corefont('Helvetica'),12);

$headlineText->translate( 60, 350);
$headlineText->text( 'Dear' );

$headlineText->font($pdf->corefont('Helvetica'),8);
$headlineText->translate( 60, 335);
$headlineText->text( 'You have successfully completed an I DRIVE SAFELY online traffic safety course.' );


$headlineText->translate( 60, 320);
$headlineText->text( 'Course Description:' );

$headlineText->translate( 60, 305);
$headlineText->text( 'Here is some important data for your records' );


$headlineText->font($pdf->corefont('Helvetica'),9);

$headlineText->translate( 60, 120);
$headlineText->text( 'Please drive safely!' );

$headlineText->translate( 60, 100);
$headlineText->text( 'I DRIVE SAFELY' );
$headlineText->translate( 60, 90);
$headlineText->text( '674 Via De La Valle, Suite 300' );
$headlineText->translate( 60, 80);
$headlineText->text( 'Solana Beach, CA  92075' );
$headlineText->translate( 60, 70);
$headlineText->text( 'www.idrivesafely.com' );
$headlineText->translate( 60, 60);
$headlineText->text( '(800) 723-1955' );

$pdf->saveas('../CA_Template_Student.pdf');
$pdf->end;

