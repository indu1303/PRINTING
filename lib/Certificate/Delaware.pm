#!/usr/local/bin/perl

package Certificate::Delaware;

use lib qw(/ids/tools/PRINTING/lib);

use strict;
use Symbol;
use Certificate;
use Settings;

use vars qw(@ISA);
@ISA=qw(Certificate);
sub _generateCertificate
{
    my $self = shift;
    my ($userId, $userData,$printId,$productId) = @_;

    ###### get the template for the appropriate state
    my $transmittalDate     = Settings::getDate();
    my $printDate     = Settings::getDateTime();
    my $studentName         = "$userData->{FIRST_NAME} $userData->{LAST_NAME}";
    my $coverSheetTemplate
            = HTML::Template->new(filename => $self->{SETTINGS}->{TEMPLATESPATH} ."/printing/DE_CoverSheet.tmpl");
    my $certificateTemplate
            = HTML::Template->new(filename => $self->{PDF});

    $coverSheetTemplate->param( TRANSMITTAL_DATE => $transmittalDate );
    $certificateTemplate->param( TRANSMITTAL_DATE => $transmittalDate,
                                 CERTIFICATE_NUMBER => $userData->{CERTIFICATE_NUMBER},
                                 STUDENT_NAME       => $studentName,
                                 HOUR               => $userData->{COURSE_LENGTH},
                                 COMPLETION_DATE    => $userData->{COMPLETION_DATE},
                                 DRIVERS_LICENSE    => $userData->{DRIVERS_LICENSE},
                                 DATE_OF_BIRTH      => $userData->{DATE_OF_BIRTH},
                                 ADDRESS            => $userData->{ADDRESS_1},
                                 ADDRESS_2          => $userData->{ADDRESS_2},
                                 CITY               => $userData->{CITY},
                                 STATE              => $userData->{STATE},
                                 ZIP                => $userData->{ZIP},
                                 PRINT_DATE         => $printDate,
                                 TRANSMITTAL_DATE   => $transmittalDate );

    return ($certificateTemplate->output,1,$coverSheetTemplate->output);
}

sub constructor
{
        my $self = shift;
        my ($userId,$top,$bottom)=@_;
        ###### let's create our certificate pdf object
        $self->{PDF} = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/$top";
 	return $self;

}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/Delaware.pm $

=item $Author: hari $

=item $Date: 2007/02/16 10:40:46 $

=item $Rev: 54 $

=cut

1;
