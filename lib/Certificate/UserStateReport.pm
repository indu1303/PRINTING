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

package Certificate::UserStateReport;

use lib qw(/ids/tools/PRINTING/lib);
use Certificate;
use Certificate::PDF;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);

use strict;

sub _printMOReport
{
    my $self = shift;
    my ($reportDate, $userData, $printerKey) = @_;

    $self->{PDF}->setFont('HELVETICA',10);
    $self->{PDF}->writeLine( 90, 600, $userData->{DRIVERS_LICENSE} );
    $self->{PDF}->writeLine( 240, 600, $userData->{DATE_OF_BIRTH} );

    #### now add the sex.  base the x-translation on whether or not the student is M/F
    $self->{PDF}->setFont('HELVETICA',18);
    my $x = ($userData->{SEX} eq 'M') ? '413' : 476;
    $self->{PDF}->writeLine($x, 604, 'X' );
    $self->{PDF}->setFont('HELVETICA',10);

    #### user name and address
    $self->{PDF}->writeLine( 90, 572 , "$userData->{LAST_NAME}, $userData->{FIRST_NAME}" );

    my $address = $userData->{ADDRESS_1} . ' ' .
                (($userData->{ADDRESS_2}) ? $userData->{ADDRESS_2} : '');
    $self->{PDF}->writeLine( 90, 544 , $address );

    $self->{PDF}->writeLine( 90, 516, $userData->{CITY} );
    $self->{PDF}->writeLine( 320, 516, $userData->{STATE} );
    $self->{PDF}->writeLine( 385, 516, $userData->{ZIP} );

    #### telephone number
    $userData->{PHONE} =~ s/[^0-9a-zA-Z]//g;

    if (length($userData->{PHONE}) < 10)
    {
        $userData->{PHONE} = '0' x (10 - length($userData->{PHONE})) . $userData->{PHONE};
    }

    my $areaCode = substr $userData->{PHONE}, 0, 3;
    my $phone    = substr $userData->{PHONE}, 3, length($userData->{PHONE});

    $phone = substr($phone,0,3) . '-' . substr($phone,3,4) . ' ' . substr($phone,7,length($phone));

    $self->{PDF}->writeLine( 394, 550 , $areaCode );
    $self->{PDF}->writeLine( 425, 550 , $phone );

    #### violation
    $self->{PDF}->writeLine( 90, 488 , $userData->{LAST_NAME} );

    #### Accident
    $self->{PDF}->setFont('HELVETICA',18);
    $x = ($userData->{USER_CITATION}->{ACCIDENT_INVOLVED}) ? 404 : 440;
    $self->{PDF}->writeLine( $x, 487 , 'X' );

    $self->{PDF}->setFont('HELVETICA',10);
    ##### originator number
    $self->{PDF}->writeLine( 90, 445 , $userData->{USER_CITATION}->{COURT_ORIGINATOR_NUMBER} );

    ##### regulator definition
    $self->{PDF}->writeLine( 238, 445 , $userData->{REGULATOR_DEF} );

    ##### case number
    $self->{PDF}->writeLine( 90, 417 , $userData->{USER_CITATION}->{CASE_NUMBER} );


    ##### conviction date
    $self->{PDF}->writeLine( 385, 417 , $userData->{USER_CITATION}->{CONVICTION_DATE} );

    ##### conviction date
    $self->{PDF}->writeLine( 385, 196 , $userData->{COMPLETION_DATE} );


    #open (OUT, ">/ids/tools/PRINTING/templates/test.pdf");
    #print OUT $moCert->stringify;
    #close OUT;


    ##### Now print the cert
   # my $printer = $printing::pPRINTERS->{$printerKey}->{PDF2};
   # print "printer:  $printer\n";
   # my $ph = gensym;
   # print $ph $moCert->stringify;
   # close $ph;

    return ($self->{PDF},1);
}





sub constructor
{
	my $self = shift;
	my ($userId,$state)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId);
	my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/reports/". $state. "_report.pdf";
	my $full=1;
    ###### get the appropriate templates
        $self->{PDF}->setTemplate($top,'',$full);
	 return $self;

}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: hari $

=item $Date: 2006/12/21 05:33:29 $

=item $Rev: 71 $

=cut

1;
