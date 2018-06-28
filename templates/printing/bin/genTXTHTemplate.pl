use strict;
use PDF::API2;
use Symbol;


use constant mm => 25.4/72;
use constant pt =>    1;

my $pdf = PDF::API2->new;
my $page = $pdf->page;
#$page->mediabox(105/mm, 148/mm);


my $fnt = $pdf->corefont('Helvetica-Bold');


#my $gfx = $page->gfx;
#$gfx->textlabel(200,700,$fnt,20,'STATE OF TEXAS DRIVING SAFETY COURSE UNIFORM CERTIFICATE OF COURSE COMPLETION');

my $headlineText = $page->text;
#$headlineText->font($pdf->corefont('Helvetica-Bold'),11);
#$headlineText->translate( 30, 760);
#$headlineText->text( 'STATE OF TEXAS DRIVING SAFETY COURSE UNIFORM CERTIFICATE OF COURSE COMPLETION' );
#$headlineText->translate( 30, 368);
#$headlineText->text( 'STATE OF TEXAS DRIVING SAFETY COURSE UNIFORM CERTIFICATE OF COURSE COMPLETION' );

$headlineText->font($pdf->corefont('Helvetica-Bold'),12);
$headlineText->translate( 60, 726);
$headlineText->text( 'COURSE PROVIDER:' );
$headlineText->translate( 60, 334);
$headlineText->text( 'COURSE PROVIDER:' );



$headlineText->font($pdf->corefont('Helvetica-Bold'),10);
$headlineText->translate( 340, 730);
$headlineText->text( 'Certificate Number:' );
$headlineText->translate( 340, 338);
$headlineText->text( 'Certificate Number' );



$headlineText->font($pdf->corefont('Helvetica-Bold'), 9);
$headlineText->translate( 60, 696);
$headlineText->text( 'I DRIVE SAFELY' );
$headlineText->translate( 60, 304);
$headlineText->text( 'I DRIVE SAFELY' );
=pod
$headlineText->font($pdf->corefont('Helvetica'), 8);
$headlineText->translate( 60, 686);
$headlineText->text( '674 Via De La Valle, Suite 300' );
$headlineText->translate( 60, 676);
$headlineText->text( 'Solana Beach, CA  92075' );
$headlineText->translate( 60, 666);
$headlineText->text( 'www.idrivesafely.com' );
$headlineText->translate( 60, 656);
$headlineText->text( '(800) 723-1955' );

$headlineText->translate( 60, 294);
$headlineText->text( '674 Via De La Valle, Suite 300' );
$headlineText->translate( 60, 284);
$headlineText->text( 'Solana Beach, CA  92075' );
$headlineText->translate( 60, 274);
$headlineText->text( 'www.idrivesafely.com' );
$headlineText->translate( 60, 264);
$headlineText->text( '(800) 723-1955' );
=cut

$headlineText->font($pdf->corefont('Helvetica-Bold'),10);
$headlineText->translate( 60, 556);
$headlineText->text( 'STUDENT:' );
$headlineText->translate( 60, 164);
$headlineText->text( 'STUDENT:' );


my $by = 430;
$headlineText->font($pdf->corefont('Helvetica-Bold'),11);
$headlineText->translate( 60, $by);
$headlineText->text( 'UNLAWFUL IF REPRODUCED OR ALTERED' );
$headlineText->translate( 400, $by);
$headlineText->text( 'COURT COPY' );
my $by = 40;

$headlineText->translate( 60, $by);
$headlineText->text( 'UNLAWFUL IF ALTERED' );
$headlineText->translate( 400, $by);
$headlineText->text( 'INSURANCE COPY' );


my $dy = 540;
my $dx = 358;
$headlineText->font($pdf->corefont('Helvetica'),6);

$headlineText->translate( $dx, $dy);
$headlineText->text( 'This certifices that the student named herein has successfully completed a six (6) hour' );
$dy -= 10;


$headlineText->translate( $dx, $dy);
$headlineText->text( 'driving safety course that is approved and regulated by the Texas Education Agency.' );
$dy -= 17;

$headlineText->translate( $dx, $dy);
$headlineText->text( 'Under penatly of perjury, I certify that I have received (6) hours of instruction.' );
$dy -= 17;

$headlineText->translate( $dx, $dy);
$headlineText->text( 'You must sign this document at the time you submit it to the court, in person or by mail.' );
$dy -= 17;


$headlineText->font($pdf->corefont('Helvetica-Bold'),7);
$headlineText->translate( $dx, $dy);
$headlineText->text( 'Student Signature:' );
$headlineText->translate( $dx + 65, $dy);
$headlineText->font($pdf->corefont('Helvetica-Bold'),.5);
$headlineText->text( 'OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT OFFICIAL DOCUMENT' );
$dy -= 17;

$headlineText->font($pdf->corefont('Helvetica'),6);
$headlineText->translate( $dx, $dy);
$headlineText->text( 'Courts requiring verification of validity may contact:' );
$dy -= 10;

$headlineText->translate( $dx, $dy);
$headlineText->text( 'Owner Contact: (800) 505-5095 and/or www.takehome.com and/or wecare@takehome.com' );


$dy = 170;
$headlineText->font($pdf->corefont('Helvetica'),6);
$headlineText->translate( $dx, $dy);
$headlineText->text( 'This certifices that the student named herein has successfully completed a six (6) hour' );
$dy -= 10;

$headlineText->translate( $dx, $dy);
$headlineText->text( 'driving safety course that is approved and regulated by the Texas Education Agency.' );
$dy -= 17;

$headlineText->translate( $dx, $dy);
$headlineText->text( 'Under penatly of perjury, I certify that I have received (6) hours of instruction.' );
$dy -= 17;

$headlineText->translate( $dx, $dy);
$headlineText->text( 'You must sign this document at the time you submit it to the court, in person or by mail.' );
$dy -= 17;

$headlineText->font($pdf->corefont('Helvetica-Bold'),7);
$headlineText->translate( $dx, $dy);
$headlineText->text( 'Student Signature:__________________________________________' );
$dy -= 17;

$headlineText->font($pdf->corefont('Helvetica'),6);
$headlineText->translate( $dx, $dy);
$headlineText->text( 'Courts requiring verification of validity may contact:' );
$dy -= 10;

$headlineText->translate( $dx, $dy);
$headlineText->text( 'Owner Contact: (800) 505-5095 and/or www.takehome.com and/or wecare@takehome.com' );

#my $ph = gensym;
#open($ph, "| /usr/bin/lp -o nobanner -q 1 -d HP-PDF-TX");
#print $ph $pdf->stringify;
#close $ph;

$pdf->saveas('../TX_TH_Template.pdf');
$pdf->end;

