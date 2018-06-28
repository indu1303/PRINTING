#!/usr/bin/perl
package Certificate::DSMSNewYork;
use strict;
use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use MysqlDB;
use Certificate;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);
=head1 NAME

DSMSNewYork

=head1 Description

This class will generate a New York Certificate

=head1 METHODS

=head2 new

object declaration for New York certificates

=cut


   sub new
{
        my $pkg         = shift;
        my $class       = ref($pkg) || $pkg;
#
    my $self = {
                   CRM_CON =>   { DB => $printerSite::CRM_DATABASE, HOST=>$printerSite::CRM_DATABASE_HOST, USERNAME => $printerSite::CRM_DATABASE_USER, PASSWORD => $printerSite::CRM_DATABASE_PASSWORD },
                    @_,
               };

        bless ($self, $class);

        my $dbConnects = $self->_dbConnect();
        if (! $dbConnects)
        {
                die();
        }

        ####### ASSERT:  The db connections were successful.  Assign 
        $self->{CRM_CON}      = $dbConnects->{CRM_CON};
        $self->{SETTINGS} = Settings->new;
	$self->{PRINTERS} = Printing::getPrinters($self);



        ##### let's get some settings
        return $self;
}
 


=head2 generateCertificate

print out a certificate for the particular user

=cut

sub printCertificate
{
    ###### add some code for the CRM
    my $self = shift;
    my ($userId,$userData,$outputType,$printId,$printerKey,$accompanyLetter,$productId,$rePrintData,$ha)=@_;
    my $city_address   = "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}";
    my($student_id,$certificate_no,$today,$address);

#    mysqlDB->MysqldbConnect(); 
#    my $result = mysqlDB->MysqlNextId('contact_id');
    my @variableData;
    $today = Settings::getDate();
    $certificate_no = $userData->{CERTIFICATE_NUMBER};
    $student_id = $userId;
    $address=$userData->{ADDRESS_1};
    if($userData->{ADDRESS_2}){
    	$address .= ' '.$userData->{ADDRESS_2};
    }
    my $idsPhone = '(877) 374-8388';
    if($productId && $productId == 1){
	$userData->{DA_CODE}='INTERNET CLASS'; 
	$userData->{EDUCATOR_ID}='INTERNET CLASS';
	$userData->{LOCATION_ID}='INTERNET CLASS';
	$idsPhone = '(877) 860-5275';
    }
    my $certNumber;
    $certNumber = ($userData->{CERTIFICATE_NUMBER_ISSUED}) ? $userData->{CERTIFICATE_NUMBER_ISSUED} : $certificate_no;
    #.ps files generated from .ai files need to edited by first running mac2unix on them
    # and then making sure that all <IDS:*> tags are contiguous in the file
    my %replace = (
                 CERT_NO          => $certNumber,
                 #DELIV_NO         => $userData->{DA_CODE},
                 DELIV_NO         => $userData->{DS_SCHOOL_ID},
                 INSTRUCTOR_NO    => $userData->{INSTRUCTOR_ID},
                 LOCATION_ID      => $userData->{LOCATION_ID},
                 STUDENT_ID       => $userId,
                 LICENSE_NO       => $userData->{DRIVERS_LICENSE},
                 COMPLETION_DATE  => $userData->{COMPLETION_DATE},
                 FIRST            => $userData->{FIRST_NAME},
                 LAST             => $userData->{LAST_NAME},
                 STREET           => $address,
                 CITY_ADDRESS     => $city_address,
                 IDS_STREET       => '294 La Moree Road',
                 IDS_CITY         => 'San Marcos, CA 92078',
                 IDS_PHONE        => $idsPhone,
                 SIGN_DATE        => $today,
                 TEXT1            => 'CONGRATULATIONS! You have successfully completed the I DRIVE SAFELY - New York Point &',
                 TEXT2            => 'Insurance Reduction Program. Here is some important data for your records',
   );
    my $arrCtr=0;
    foreach my $field(keys %replace){
    	$variableData[$arrCtr++]="$field:$replace{$field}";    
    }
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
    if($outputType->{FAX}){
	my @fileNames;
	push @fileNames,'/tmp/nycert.pdf'; 
        $self->dbSendFax($outputType->{FAX},@fileNames);
    }else{
    my $printer = 0;
    my $media = 0;
    my $st='NY';   ##########  Default state, we have mentioned as XX;
    my $productId=19;  ##### This is for DSMS New York
    $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERT');
    if(!$printer){
        $printer = 'HP-PDF';
    }
    if(!$media){
            $media='Tray5';
    }

	    system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media /tmp/nycert.pdf");
	    unlink "/tmp/nycert.pdf";
    }
    unlink "/tmp/nycert.ps";
    open( LOG, ">>/www/logs/printing/.ny_certificates.log" );
    print LOG "$today\t$certificate_no\t$student_id\t$userData->{FIRST_NAME}\t$userData->{LAST_NAME}\n";

    close LOG;
    if(!$printId){
            $printId=$self->MysqlDB::getNextId('contact_id');
    }
    #my $variableDataStr=join '~',@variableData;
    #my $fixedData=Certificate::_generateFixedData($userData);
    #$self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    return $printId;
}

sub _dbConnect
{
        my $self = shift;

        ####### ok, we just connected to oracle, now let's connect to the mysql db for the CRM
        my $mysqlDBH = DBI->connect("dbi:mysql:$self->{CRM_CON}->{DB}:$self->{CRM_CON}->{HOST}",
                                                $self->{CRM_CON}->{USERNAME},
                                                $self->{CRM_CON}->{PASSWORD});
        if(!$mysqlDBH)
        {
                ####### Error.  Print out the error and return
                print STDERR "Error Connecting to the database: $self->{CRM_CON}->{DB} - $DBI::errstr\n";
                return 0;
        }

        ###### ASSERT:  We connected to both databases.  Return the connections
        my $retval = { 'CRM_CON' => $mysqlDBH };

        return $retval;
}

sub DESTROY
{   
    #### um...yeah, pretty worthless @ this point  :-)
    my $self = shift;
}


1;
