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

package DriverRecord;
use strict;
use Symbol;
use MIME::Lite;
use MysqlDB;
use Settings;
use Printing;
use Data::Dumper;
use HTML::Template;
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
        my($stc) = @_;


	bless ($self, $class);
	my $dbConnects = $self->_dbConnect();
	if (! $dbConnects)
	{
		die();
	}
	####### ASSERT:  The db connections were successful.  Assign
	$self->{CRM_CON}      = $dbConnects->{CRM_CON};
	$self->{STC}        = $stc;
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

sub printDRAppForm
{
	my $self = shift;
	my ($userId,$userData,$outputType,$printerKey)=@_;
	$self->constructor($userId);
	my $cert;
	my $pId=0;
	($cert, $pId) = $self->_generateDriverRecordAppForm($userId,$userData);
		
	$cert->getCertificate;
	my $outputFile = "/tmp/$userId.pdf";
	if(!$pId || $pId==0 || $pId ==-1){
		if(-e $outputFile){
			unlink $outputFile;
		}	
		return $pId;
	}
	###### ok, we have the certificate.  now, based on the following parameters from when the class
	###### was declared, we're going to do something w/ it:
	###### EMAIL:  Email it to the user
	
	$printerKey = 'TX';

	if ($outputType->{FILE} && $outputFile)
	{
		####### print this certificate to a file
		system("/bin/mv $outputFile $outputType->{FILE}");
	}
	if ($outputType->{STDOUT} && $outputFile)
	{
		######## default case.  Output to STDOUT
		system("/bin/cat  $outputFile");
	}
	if (($outputType->{PRINTER} && $outputFile) || ( ! $outputType->{STDOUT} && ! $outputType->{FILE} && ! $outputType->{EMAIL} && ! $outputType->{FAX} ))
	{
		######## send the certificate to the printer
		my $printer = 0;
		my $media = 'Tray2';
                my $st='TX';   ##########  Default state, we have mentioned as XX;
                my $productId=1;   ##### Tgis is default for DIP
                $st=($userData->{DR_STATE})?$userData->{DR_STATE}:$st;
		($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'DRLBL');
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

sub _printCorporateAddress
{
    my $self = shift;
    my ($xPos,$yPos, $OFFICE,$domain) = @_;
    my $xDiff=0;
    my $helvetica       = 'HELVETICA';
    $self->{PDF}->setFont($helvetica, 8);
    $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{ADDRESS});
    $yPos -=10;
    $self->{PDF}->writeLine($xPos, $yPos, "$OFFICE->{CITY}, $OFFICE->{STATE} $OFFICE->{ZIP}");
    if($domain){
        $yPos -=10;
        $self->{PDF}->writeLine($xPos, $yPos, $domain);
        $yPos -=11;
        $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{PHONE});
    }else{
        $yPos -=11;
        $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{PHONE});
    }

}


=pod

head1 AUTHOR

hari@ed-ventures-online.com

=item $Author: hari $

=cut

1;
