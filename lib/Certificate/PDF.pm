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

package Certificate::PDF;

use lib qw(/ids/tools/PRINTING/lib);
use PDF::Reuse;;
use Data::Dumper;
use strict;
sub new
{
	my $pkg 	= shift;
	my $class 	= ref($pkg) || $pkg;
	my ($userId,$hidetoolbar,$hidemenubar,$hidewindowui,$fitwindow,$centerwindow,$xwidth,$yheigth) =@_;

	###### the PDF doesn't take any objects, therefore we won't use it
	prDocDir('/tmp');
	prFile("$userId.pdf",'',$hidetoolbar,$hidemenubar,$hidewindowui,$fitwindow,$centerwindow,$xwidth,$yheigth);
	my $self = {};
	######
	###### let's create the current PDF
	$self->{FONT}->{HELVETICA} 	= 'Helvetica';
	$self->{FONT}->{HELVETICABOLD} 	= 'Helvetica-Bold';

	$self->{FONT}->{CALIBRI} 	= 'Calibri';
	$self->{FONT}->{CALIBRIBOLD} 	= 'Calibri-Bold';
	bless ($self, $class);

	return $self;
}


########### below are three helper functions to change the font and actually write a line on the
########### certificate
=head2 writeLine

moves the pen object to a specific portion on the page and writes the string

=cut

sub writeLine
{
	my $self = shift;
	my ($xPos, $yPos, $text,$rotate) = @_;
	###### write the selected page to the cert
	if($rotate){
    		prText($xPos, $yPos,$text,'',$rotate);
	}else{
    		prText($xPos, $yPos,$text);
	}
}

sub writeModrenLine
{
	my $self = shift;
	my ($xPos, $yPos, $text, $align, $rotate) = @_;
	###### write the selected page to the cert
    	prText($xPos, $yPos,$text, $align, $rotate);
}
=head2 setFont

Sets the font and size for the pen

=cut

sub setFont
{
	my $self = shift;
	my ($font, $size) = @_;
	
	##### set the pen's font and size	
	prFont($self->{FONT}->{$font});
	prFontSize($size);
}

sub setHalfTemplate
{
	my $self = shift;
	my ($file, $pos) = @_;
        my $xDiff = 0;

    ###### certificates will always be either a top or a bottom as we're always printing 
    ###### on a 8x11 sheet of paper.  With this is mind, we can either send in 'TOP' or 'BOTTOM'
    ###### so we may define the template
    
    if ($pos eq 'TOP')
    {
    	prForm ( {file     => $file, page => 1, x =>0-$xDiff, y=>400} );
    }
    elsif ($pos eq 'BOTTOM')
    {
    	prForm ( {file     => $file, page => 1, x =>0-$xDiff, y=>0} );
    }

    ###### all is right w/ the world
    return 1;
}

sub setTemplate
{
    my $self = shift;
    my ($top, $bottom,$full) = @_;
    my $xDiff = 0;
    my $fullPage =($full)?0:400;
    prForm ( {file     => $top, page => 1, x =>0-$xDiff, y=>$fullPage} );
 
    if ($bottom && -e $bottom)
    {
    prForm ( {file     => $bottom, page => 1, x =>0-$xDiff, y=>0} );
    }
}


sub genImage
{
    my $self = shift;

    my ($img, $x, $y, $dx, $dy,$sizeW,$sizeH) = @_;
my $intName = prJpeg("$img",         # Define the image 
                         $sizeW,         # in the document
                         $sizeH);


   my $str = "q\n";   
   $str   .= "$dx 0 0 $dy $x $y cm\n";
   $str   .= "/$intName Do\n";
   $str   .= "Q\n";
   prAdd($str);

}

sub getCertificate 
{
    my $self = shift;
	prEnd();

}

sub setDPSTemplate
{
     my $self = shift;
     my ($top) = @_; 
     my $xDiff = 0;
     prForm ( {file => $top, page => 2, x =>0-$xDiff, y=>0} );
}

sub setCustomTemplate
{
    my $self = shift;
    my ($file, $x,$y,$rotation) = @_;
    if(!$rotation){
	$rotation=0;
    }
    prForm ( {file     => $file, page => 1, x =>$x, y=>$y , rotate=>$rotation} );

}

sub addPDF
{
    my $self = shift;
    my ($file) = @_;
    prDoc( { file  => $file});
}

sub setNewCustomTemplate
{
    my $self = shift;
    my ($file, $x,$y,$rotation,$noNewPage) = @_;
    if(!$rotation){
	$rotation=0;
    }
    if(!$noNewPage){
    	prPage();
    }
    prForm ( {file     => $file, page => 1, x =>$x, y=>$y , rotate=>$rotation} );

}
=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/PDF.pm $

=item $Author: kumar $

=item $Date: 2009-10-19 07:55:02 $

=item $Rev: 65 $

=cut

1;
