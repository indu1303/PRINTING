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
$headlineText->translate( 60, 320);
$headlineText->text( 'THE FOLLOWING PERSON HAS COMPLETED AN APPROVED HOME STUDY TRAFFIC SCHOOL COURSE' );


#$headlineText->translate( 480, 20);
##$headlineText->text( 'COURT COPY' );

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
$headlineText->text( 'TrafficSchoolToGo.com' );
$headlineText->font($pdf->corefont('Helvetica'),8);
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( '674 Via De La Valle, Suite 300' );
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( 'Solana Beach, CA 92075' );
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( 'support@trafficschooltogo.com' );
$headlineText->translate( $xIndent, $yOffset);  $yOffset -= 10;
$headlineText->text( '(888) 349-8425' );


###### let's add Craig's signature since it won't change from course to course
$headlineText->font($pdf->corefont('Helvetica'),7);

$yOffset = 150;
my $xOffset = 275;
$headlineText->translate( $xOffset, $yOffset);  $yOffset -= 12;
$headlineText->text( 'I certify under penalty of perjury that I, and I alone, completed all the requirements of this ');

$headlineText->translate( $xOffset, $yOffset);  $yOffset -= 30;
$headlineText->text( 'course (perjury is punishable by imprisonment, fine or both).');

$headlineText->translate( $xOffset, $yOffset);  $yOffset -= 50;
$headlineText->font($pdf->corefont('Helvetica'),11);
$headlineText->text( 'STUDENT SIGNATURE:___________________________');


$headlineText->translate( $xOffset, $yOffset);  
$headlineText->text( 'By:' );

my $gfx = $page->gfx;
my $sig = $pdf->image_gif("/ids/tools/PRINTING/lib/sig2.gif");
$gfx->image($sig, 300, $yOffset, 125, 35);      $yOffset -= 10;

$headlineText->translate( $xOffset, $yOffset);  $yOffset -= 30;
$headlineText->font($pdf->corefont('Helvetica'),8);
$headlineText->text( 'Authorized Signature of ' );
$headlineText->font($pdf->corefont('Helvetica-Bold'),8);
$headlineText->text( 'TrafficSchoolToGo.com' ); 


$headlineText->translate( $xOffset, 20);

$pdf->saveas('../TSTG_Template_Court.pdf');
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
$headlineText->text( 'You have successfully completed a TrafficSchoolToGo.com online traffic safety course.' );


$headlineText->translate( 60, 320);
$headlineText->text( 'Course Description:' );

$headlineText->translate( 60, 305);
$headlineText->text( 'Here is some important data for your records' );


$headlineText->font($pdf->corefont('Helvetica'),9);

$headlineText->translate( 60, 120);
$headlineText->text( 'Please drive safely!' );

$headlineText->translate( 60, 100);
$headlineText->text( 'TrafficSchoolToGo.com' );
$headlineText->translate( 60, 90);
$headlineText->text( '674 Via De La Valle, Suite 300' );
$headlineText->translate( 60, 80);
$headlineText->text( 'Solana Beach, CA  92075' );
$headlineText->translate( 60, 70);
$headlineText->text( 'support@trafficschooltogo.com' );
$headlineText->translate( 60, 60);
$headlineText->text( '(888) 349-8425' );

$pdf->saveas('../TSTG_Template_Student.pdf');
$pdf->end;

