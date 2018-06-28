#!/usr/bin/perl

use lib qw(/ids/tools/PRINTING/lib);

use strict;
use printerSite;
use MysqlDB;

package Certificate::NY;

=head1 NAME

NewYork

=head1 Description

This class will generate a New York Certificate

=head1 METHODS

=head2 new

object declaration for New York certificates

=cut


sub new
{
    my $invocant    = shift;
    my $class       = ref($invocant) || $invocant;
    
    my $self = { @_ };
    
    bless ($self, $class);
    
    return $self; 
}


=head2 generateCertificate

print out a certificate for the particular user

=cut

sub generateCertificate
{
    ###### add some code for the CRM
    my $self = shift;
    my %in             = @_;
    my $city_address   = "$in{-city}, $in{-state} $in{-zipcode}";
    my($student_id,$certificate_no,$today);

#    mysqlDB->MysqldbConnect(); 
#    my $result = mysqlDB->MysqlNextId('contact_id');

    $today = $in{-today};
    $certificate_no = $in{-certificate_no};
    $student_id = $in{-student_id};
    #.ps files generated from .ai files need to edited by first running mac2unix on them
    # and then making sure that all <IDS:*> tags are contiguous in the file
    my %replace = (
                 CERT_NO          => $in{-certificate_no},
                 DELIV_NO         => $in{-agency_no},
                 INSTRUCTOR_NO    => $in{-instructor_no},
                 LOCATION_ID      => $in{-location_id},
                 STUDENT_ID       => $in{-student_id},
                 LICENSE_NO       => $in{-license_no},
                 COMPLETION_DATE  => $in{-completion_date},
                 FIRST            => $in{-first},
                 LAST             => $in{-last},
                 STREET           => $in{-address},
                 CITY_ADDRESS     => $city_address,
                 IDS_STREET       => '283 4th st Unit 301',
                 IDS_CITY         => 'Oakland, CA 94607',
                 IDS_PHONE        => '(877) 374-8388',
                 SIGN_DATE        => $today,
                 TEXT1            => 'CONGRATULATIONS! You have successfully completed the I DRIVE SAFELY - New York Point &',
                 TEXT2            => 'Insurance Reduction Program. Here is some important data for your records',
   );
    
    print STDERR "printing student '$in{-last}, $in{-first}' ($student_id/$certificate_no)\n";

    open IN, "/ids/tools/PRINTING/templates/printing/ny_certificate.ps";
    
    open( LOG, ">>/www/logs/printing/.ny_certificates.log" );
    open (OUT , ">/tmp/nycert.ps");
    while( <IN> )
    {
        s/\<IDS\:([^\>]+)\>/$replace{$1}/g;
        print OUT $_;
    }
    close IN;
    close OUT;
    my $ph;
    system("/usr/bin/ps2pdf /tmp/nycert.ps /tmp/nycert.pdf");
    my $printer = 0;
    my $media = 0;
    my $st='NY';   ##########  Default state, we have mentioned as XX;
    my $productId=10;  ##### This is for Classroom Ny
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERT');
    if(!$printer){
                $printer = 'HP-PDF2-TX';
    }
    if(!$media){
                    $media='Tray3';
    }


    system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media /tmp/nycert.pdf");
    unlink "/tmp/nycert.ps";
    unlink "/tmp/nycert.pdf";

    open( LOG, ">>/www/logs/printing/.ny_certificates.log" );
    print LOG "$today\t$certificate_no\t$student_id\t$in{-last}\t$in{-first}\n";

    close LOG;
    return 1;
}

1;
