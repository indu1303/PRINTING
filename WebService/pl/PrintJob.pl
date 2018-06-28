#!/usr/bin/perl -w 

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI
    -> dispatch_to('IDSPrintJob')
    -> handle;

package IDSPrintJob;

use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use Settings;
use Printing::DIP;
use Certificate::PDF;
use MysqlDB;
use Data::Dumper;

use strict;
no strict "refs";

sub new
{
    my $self = shift;
    my $class = ref($self) || $self;
    bless {} => $class;
}


######### run a print job
sub runDIPJob
{
    my $self = shift;
    my ($state, $type, $mode, $printerKey, $ha, $courseId, $fedex) = @_;
 
    my $script = " -K DIP";

    if ($courseId)  {        $script .= " -c $courseId"; }
    if ($state && ! $courseId)     
                    {        $script .= " -s $state";    }
    if ($type)
    {
        if ($type eq 'STC')         
        { 
            ######### Run STC
            $script .= ' -S';      
        }
        elsif ($type eq 'DUPL')     
        {   
            ######### Run duplicates
            $script .= ' -R';      
        }
        elsif ($type eq 'ACMPNLTR') 
        {            
            ########## Run accompany letter
            $script .= ' -A';      
        }
    }

    if ($fedex)
    {
        if ($fedex eq 'PRIORITY')
        {
            $script .= ' -G';      
        }
        elsif ($fedex eq 'NON-PRIORITY')
        {
            $script .= ' -F';      
        }
    }


    if ($mode)              {        $script .= " -d $mode";        }
    if ($printerKey)        {        $script .= " -p $printerKey";  }

    ######## run hosted affiliates

    $self->_runPrintJob($script);
    return 1;
}

sub runFleetJob
{
    my $self = shift;
    my ($fleetAccountId, $courseId, $printerKey) = @_;

    my $script = " -K FLEET";
   
    if ($fleetAccountId)
    {
        $script .= " -f $fleetAccountId";    
    }

    if ($courseId)          {        $script .= " -c $courseId";    }
    if ($printerKey)        {        $script .= " -p $printerKey";  }
 

    $self->_runPrintJob($script); 
    return 1;

}
sub runAZTSJob
{
    my $self = shift;
    my ($state, $type, $mode, $printerKey, $ha, $courseId, $fedex) = @_;

    my $script = " -K AZTS";

    if ($courseId)  {        $script .= " -c $courseId"; }
    if ($state && ! $courseId)
                    {        $script .= " -s $state";    }
    if ($type)
    {
        if ($type eq 'DUPL')
        {
            ######### Run duplicates
            $script .= ' -R';
        }
    }

    if ($fedex)
    {
        if ($fedex eq 'PRIORITY')
        {
            $script .= ' -G';
        }
        elsif ($fedex eq 'NON-PRIORITY')
        {
            $script .= ' -F';
        }
    }


    if ($mode)              {        $script .= " -d $mode";        }
    if ($printerKey)        {        $script .= " -p $printerKey";  }

    ######## run hosted affiliates
    $self->_runPrintJob($script); 

    return 1;
}

sub runClassroomJob
{
    my $self = shift;
    my ($courseId, $printerKey) = @_;

    my $script = " -K CLASSROOM";
   
    if ($courseId)          {        $script .= " -c $courseId";    }
    if ($printerKey)        {        $script .= " -p $printerKey";  }
    
    $self->_runPrintJob($script);
    return 1;
}


######### add a call for workorders
sub sendMBEWorkorder
{
    my $self = shift;
    my ($name, $userId, $date, $mbeStore, $mbeNumber, $address, $password,$product,$testCenterId,$mbePhone,$testCenterEmail) = @_;
    use WorkOrder::MBE;
    my $mbe = WorkOrder::MBE->new;
    if($testCenterEmail) {
    	$mbe->sendWorkOrder($userId, $name, $userId, $date, $mbeStore, $mbeNumber, $address, $password,{EMAIL=>$testCenterEmail},'',$product,$testCenterId,$mbePhone);
    } else {
    	$mbe->sendWorkOrder($userId, $name, $userId, $date, $mbeStore, $mbeNumber, $address, $password,{FAX=>$mbeNumber},'',$product,$testCenterId,$mbePhone);
    }

    return 1;
}



######### below are helper functions.  They should never be instantiated by anyone except 
######### other members in this class
sub _runPrintJob
{
    my $self = shift;


    my ($script,$fedexKinkos) = @_;
    if($fedexKinkos){
    	$script = "/ids/tools/PRINTING/scripts/fedexKinkosManualPrint.pl " . $script;
    }else{
    	$script = "/ids/tools/PRINTING/scripts/processCertificate.pl " . $script;
    }
    my $PROCESSFILE = "/tmp/printJob.dat";
    my $found=0;
    if(-e $PROCESSFILE)
    {
    	open IN, $PROCESSFILE;
	while(<IN>)
    	{
            chomp;
	    if($script eq $_){
		$found=1;
		last;
	    }
    	}
	close IN;
    }
    if(!$found){
    	open (OUT,">>/tmp/printJob.dat");
	print OUT "$script\n";
    	close OUT;
    }
}

sub runTeenJob
{
    my $self = shift;
    my ($state, $courseId) = @_;

    my $script = " -K TEEN";


    if ($state)             {        $script .= " -s $state";    }
    if ($courseId)          {        $script .= " -c $courseId";    }

    $self->_runPrintJob($script);
    return 1;

}

sub runTSTGJob
{
    my $self = shift;
    my ($state, $type, $mode, $printerKey, $ha, $courseId, $fedex) = @_;
 
    my $script = " -K TSTG";

    if ($courseId)  {        $script .= " -c $courseId"; }
    if ($state && ! $courseId)     
                    {        $script .= " -s $state";    }
    if ($type)
    {
        if ($type eq 'STC')         
        { 
            ######### Run STC
            $script .= ' -S';      
        }
        elsif ($type eq 'DUPL')     
        {   
            ######### Run duplicates
            $script .= ' -R';      
        }
    }

    if ($fedex)
    {
        if ($fedex eq 'PRIORITY')
        {
            $script .= ' -G';      
        }
        elsif ($fedex eq 'NON-PRIORITY')
        {
            $script .= ' -F';      
        }
    }


    if ($mode)              {        $script .= " -d $mode";        }
    if ($printerKey)        {        $script .= " -p $printerKey";  }
    $self->_runPrintJob($script);

    return 1;

}

sub runClassJob
{
    my $self = shift;
    my ($courseId, $printerKey) = @_;

    my $script = " -K CLASS";
    
    if ($courseId)          {        $script .= " -c $courseId";    }
    if ($printerKey)        {        $script .= " -p $printerKey";  }

    $self->_runPrintJob($script);
    return 1;
}

sub runFedexKinkosJob
{
   my $self = shift;
   my ($manifestId,$courseId,$userId,$printerKey) = @_;

   my $script = "";

   if ($manifestId)        {        $script .= " -m $manifestId";  }
   if ($courseId)          {        $script .= " -c $courseId";    }
   if ($printerKey)        {        $script .= " -p $printerKey";  }
   if ($userId)            {        $script .= " -m $userId";  }

   $self->_runPrintJob($script,1);
   return 1;

}

sub runAdultJob
{
    my $self = shift;
    my ($state, $courseId) = @_;

    my $script = " -K ADULT";


    if ($state)             {        $script .= " -s $state";    }
    if ($courseId)          {        $script .= " -c $courseId";    }

    $self->_runPrintJob($script);
    return 1;

}

#my $test = IDSPrintJob->new;

#my $retval = $test->sendMBEWorkorder('paul dimitriu', 8370658, '05/05/2006', 'IDRIVESAFELY', '18587240041', '674 Via de la valle', 'test','DIP');
