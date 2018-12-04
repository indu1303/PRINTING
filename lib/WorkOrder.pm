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
#!/usr/bin/perl 

use lib qw(/ids/tools/PRINTING/lib);

package WorkOrder;
use strict;
use Symbol;
use MIME::Lite;
use MysqlDB;
use Settings; 
use Printing;
use Data::Dumper;
use MIME::Lite;
use vars qw();

=head1 NAME

=head1 SYNOPSIS

Base Class Only.  Should not be instantiated

=head1 DESCRIPTION

=head1 METHODS

=head2 new (Constructor)

=cut

sub new
{
	my $pkg 	= shift;
	my $class 	= ref($pkg) || $pkg;

        my $self = {    CRM_CON =>   { DB => $printerSite::CRM_DATABASE, HOST=>$printerSite::CRM_DATABASE_HOST, USERNAME => $printerSite::CRM_DATABASE_USER, PASSWORD => $printerSite::CRM_DATABASE_PASSWORD },
 
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
        ##### let's get some settings
        $self->{SETTINGS} = Settings->new;
        $self->{PRINTERS} = Printing::getPrinters($self);

	return $self;
}


=pod

=head2 constructor

Method for children to do something during a call to new

=cut

sub constructor
{
	my $self = shift;
	return 1;
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
        my $retval = { 'CRM_CON' => $mysqlDBH};

        return $retval;
}


sub DESTROY
{
    #### um...yeah, pretty worthless @ this point  :-)
    my $self = shift;
}
=head2 printStateReport

Actually print out the certificate

=cut

sub sendWorkOrder
{
	my $self = shift;
	my ($workOrder, $userName, $userId, $date, $mbeCenter, $mbeFax, $mbeAddress, $password,$outputType,$printerKey,$product,$testCenterId,$mbePhone)=@_;
	$self->constructor($workOrder,$product);
	my $cert;
	my $pId=0;
	if($product eq 'SELLERSERVER'){
		($cert, $pId) = $self->_generateSSWorkOrder($workOrder, $userName, $userId, $date, $mbeCenter, $mbeFax, $mbeAddress, $password, $product,$testCenterId,$mbePhone);
	} else {
		($cert, $pId) = $self->_generateWorkOrder($workOrder, $userName, $userId, $date, $mbeCenter, $mbeFax, $mbeAddress, $password, $product,$testCenterId,$mbePhone);
	}
		
	$cert->getCertificate;
	my $outputFile = "/tmp/$userId.pdf";
	my $pdfCoverFile="/tmp/COVER_$userId.pdf";
	if(!$pId || $pId==0){
		if(-e $outputFile){
			unlink $outputFile;
		}	
		return $pId;
	}
	###### ok, we have the certificate.  now, based on the following parameters from when the class
	###### was declared, we're going to do something w/ it:
	###### EMAIL:  Email it to the user
	
	$printerKey = ($printerKey)?$printerKey:'TX';

	if ($outputType->{FILE} && $outputFile)
	{
		####### print this certificate to a file
		system("/bin/mv $outputFile $outputType->{FILE}");
			$pId =1 ;
	}
	if ($outputType->{STDOUT} && $outputFile)
	{
		######## default case.  Output to STDOUT
		system("/bin/cat  $outputFile");
			$pId =1 ;
	}
        my @fromArr;
        my @toArr;
	if ($outputType->{FAX})
        {
	        my @fileNames;
		##The cover sheet not required for any of the products now!!
	        push @fileNames,$outputFile;
        	$self->dbSendFax($outputType->{FAX},@fileNames);	
        }

        if ($outputType->{EMAIL})
        {
            push @toArr, $outputType->{EMAIL};
            push @fromArr, 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>';
        

        my $from    = join(",", @fromArr);
        my $to      = join(",", @toArr);

        my $msg = MIME::Lite->new(From => $from,
                  To => $to,
                  Subject => "MBE Fax - $userId",
                  Type => 'multipart/mixed');
           $msg->attach(Type    => 'application/pdf',
                        Path     =>$outputFile,
                        Filename =>'certificate.pdf');
	   $msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f wecare@idrivesafely.com');
	   }
           $pId =1 ;
	if (($outputType->{PRINTER} && $outputFile) || ( ! $outputType->{STDOUT} && ! $outputType->{FILE} && ! $outputType->{EMAIL} && ! $outputType->{FAX} ))
	{
		######## send the certificate to the printer

                my $printer=0;
                my $media=0;
	        ($printer,$media)=Settings::getPrintingDetails($self, 1, 'XX','RPT');
                if(!$printer){
                      $printer = 'HP-PDF2-TX';
                }
                if(!$media){
                      $media='Tray2';
                }

		if (! $printer)
		{
			###### error out.....printer is not set
			$pId=0;	
		}

		my $ph = gensym;
		open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media $outputFile");
		close $ph;
	}
	if(-e $outputFile){
		unlink $outputFile;
	}
	return $pId;
}

sub dbSendFax {
        my $self = shift;
        my ($faxNumber,@fileNames) =@_;

        if(length($faxNumber)>10 && substr($faxNumber,0,1) eq '1'){
                $faxNumber=substr($faxNumber,1);
        }
        $faxNumber =~ s/(\s+|\(|\)|\-|\.)//ig;
        my $to  = $faxNumber.'@rcfax.com';

        my $msg = MIME::Lite->new(
                From    => 'I Drive Safely <reports@idrivesafely.com>',
                To      => $to,
                Subject => "Fax to $faxNumber",
                Type    => 'multipart/mixed'
        );
	
	foreach my $filePath(@fileNames) {
                my $fileName = $filePath;
                $fileName =~ s/\/tmp\///ig;
                  $msg->attach(Type => 'application/pdf',
                                Path     => $filePath,
                                Filename => $fileName,
                                Disposition => 'attachment'
                );
        }
       $msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');
}

=pod

head1 AUTHOR

hari@ed-ventures-online.com

=item $Author: kumar $

=cut

1;
