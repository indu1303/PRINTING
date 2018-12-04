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
package WorkOrder::MBE;

use lib qw(/ids/tools/PRINTING/lib);
use WorkOrder;
use Certificate;
use Certificate::PDF;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(WorkOrder);

use strict;

sub _generateWorkOrder
{
    my $self = shift;
    my ($workOrder, $userName, $userId, $date, $mbeCenter, $mbeFax, $mbeAddress, $password,$testCenterId,$mbePhone) =@_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
	###### as we do w/ all things, let's start at the top.  Print the header
    my $phone=$mbePhone;
    my $fax=$mbeFax;
    $phone =~ s/\W+//g;
    if(length($phone)==10){
    	$phone = '(' . substr($phone,0,3) . ') '. substr($phone,3,3).'-'. substr($phone,6,4);
    }else{
        $phone=$mbePhone;
    }
    $fax =~ s/\W+//g;
    if(length($fax)==10){
	    $fax = '(' . substr($fax,0,3) . ') '. substr($fax,3,3).'-'. substr($fax,6,4);
    }else{
            $fax=$mbeFax;
    }
    $self->{PDF}->setFont('HELVETICABOLD', 14);
    my $xPos = 285;
    my $yPos = 727;
    my $testCenter = $mbeCenter;
    my @testCenter = split(/\s+/,$testCenter);
    my $count = 0;
    my ($tc1, $tc2);
    foreach(@testCenter) {
    	if($count<=3) {
        	$tc1 .=$testCenter[$count]." ";
        } elsif($count >= 4) {
                $tc2 .=$testCenter[$count]." ";
        }
        $count++;
    }
    $self->{PDF}->writeLine( $xPos, $yPos, $tc1);
    if($count >= 4) {
	$yPos=715;
    	$self->{PDF}->writeLine( $xPos, $yPos, $tc2);
    }
    $self->{PDF}->setFont('HELVETICA', 11);
    $yPos=592;
    $xPos=92;
    $self->{PDF}->writeLine( $xPos, $yPos, "Date: $date");
    $xPos=200;
    $self->{PDF}->writeLine( $xPos, $yPos, "Center # $testCenterId");
    $xPos=270;
    $self->{PDF}->writeLine( $xPos, $yPos, "Center Tel. # $phone");
    $xPos=420;
    $self->{PDF}->writeLine( $xPos, $yPos, "Center Fax # $fax");

    $xPos=225;
    $yPos=198;
    $self->{PDF}->writeLine( $xPos, $yPos, $password);

    $self->{PDF}->setFont('HELVETICABOLD', 11);
    $xPos=470;
    $yPos=548;
    $self->{PDF}->writeLine( $xPos, $yPos, $userId);

    $xPos=92;
    $yPos=530;
    $self->{PDF}->writeLine( $xPos, $yPos, $userName);

    return ($self->{PDF},1);
}


sub _generateSSWorkOrder
{
    my $self = shift;
    my ($workOrder, $userName, $userId, $date, $mbeCenter, $mbeFax, $mbeAddress, $password,$product,$testCenterId,$mbePhone) =@_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
	###### as we do w/ all things, let's start at the top.  Print the header
    my $phone=$mbePhone;
    my $fax=$mbeFax;
    $phone =~ s/\W+//g;
    if(length($phone)==10){
    	$phone = '(' . substr($phone,0,3) . ') '. substr($phone,3,3).'-'. substr($phone,6,4);
    }else{
        $phone=$mbePhone;
    }
    $fax =~ s/\W+//g;
    if(length($fax)==10){
	    $fax = '(' . substr($fax,0,3) . ') '. substr($fax,3,3).'-'. substr($fax,6,4);
    }else{
            $fax=$mbeFax;
    }
    $self->{PDF}->setFont('HELVETICABOLD', 14);
    my $xPos = 285;
    my $yPos = 727;
    my $testCenter = $mbeCenter;
    my @testCenter = split(/\s+/,$testCenter);
    my $count = 0;
    my ($tc1, $tc2);
    foreach(@testCenter) {
    	if($count<=3) {
        	$tc1 .=$testCenter[$count]." ";
        } elsif($count >= 4) {
                $tc2 .=$testCenter[$count]." ";
        }
        $count++;
    }
#    $self->{PDF}->writeLine( $xPos, $yPos, "TC1 $tc1");
 #   if($count >= 4) {
#	$yPos=715;
#    	$self->{PDF}->writeLine( $xPos, $yPos, "TC2 $tc2");
#    }
    $self->{PDF}->setFont('HELVETICA', 12);
    $yPos=579;
    $xPos=72;
    $self->{PDF}->writeLine( $xPos, $yPos, "$date");
    $xPos=290;
    $self->{PDF}->writeLine( $xPos, $yPos, "$tc1");
    $yPos=549;
    $xPos=120;
    $self->{PDF}->writeLine( $xPos, $yPos, "$phone");
    $xPos=385;
    $self->{PDF}->writeLine( $xPos, $yPos, "$fax");

    $xPos=195;
    $yPos=222;
    $self->{PDF}->writeLine( $xPos, $yPos, $password);

    $self->{PDF}->setFont('HELVETICABOLD', 11);
    $xPos=240;
    $yPos=484;
    $self->{PDF}->writeLine( $xPos, $yPos, "$userId");

    $xPos=152;
    $yPos=515;
    $self->{PDF}->writeLine( $xPos, $yPos, "$userName");

    return ($self->{PDF},1);

}

sub constructor
{
	my $self = shift;
	my ($userId,$product)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId);
	my $top=$self->{SETTINGS}->{TEMPLATESPATH}."/printing/MBEOrder.pdf";
	if($product && $product eq 'MATURE'){
		$top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/MatureMBEOrder.pdf";
	}
	if($product && $product eq 'AHST'){
		$top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/AHSTMBEorder.pdf";
	}
	if($product && $product eq 'HTS'){
		$top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/HTSMBEorder.pdf";
	}
	if($product && $product eq 'AAADIP'){
		$top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/AAADIPMBEOrder.pdf";
	}
	if($product && $product eq 'SELLERSERVER'){
		$top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/SSMBEOrder.pdf";
	}
	my $full=1;

    ###### get the appropriate templates
    $self->{PDF}->setTemplate($top,'',$full);
 return $self;

}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=item $Author: kumar $

=item $Date: 2009-07-01 07:59:13 $

=item $Rev: 71 $

=cut

1;
