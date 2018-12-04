#!/usr/bin/perl -I /ids/tools/PRINTING/lib

use strict;
use Symbol;
use printerSite;
use Settings;
use Accessory;
use Data::Dumper;
use Certificate;
use MysqlDB;
use Getopt::Std;
use PDF::Reuse;
use Net::FTP;
use Image::Info qw(image_info dim);

my $self= Settings->new;
my $product='DSMS';
my $productId       = 19;
my $printingAPI     = 'DSMS';
my $API;
my %opts;
my $SERVER_NAME     = (split(/\./,qx/uname -n/))[0];
my $dryRun          = 0;
my $showError       = 0;
my $printerKey      = 'CA';
my $limitedRun      = 0;
my $priority        = 1;
my $onlyFedex       = 0;
getopt('Kscl:', \%opts);
print "\nRunning IDS Printing Job\n";
print "Job running on $SERVER_NAME\n";
print "**************************\n\n";

################# process all incoming options
################# options are as follows:
#
#    -h          Print out the help file
#    -K product  Product

   ####  Get the Product Id
if($opts{K})
{
        $productId = ($self->{PRODUCT_ID}->{$opts{K}})?$self->{PRODUCT_ID}->{$opts{K}}:1;
        $printingAPI = ($self->{PRINTING_API}->{$opts{K}})?$self->{PRINTING_API}->{$opts{K}}:$product;
	$product=$opts{K};
}
my $startTime         = time;
my $totalTime         = time;
use Printing::DSMS;
$API = ("Printing::DSMS")->new;
print "Database connection  time:  " . int(time - $startTime) . " seconds\n";
$API->{PRODUCT}=$product;
$self->{PRODUCT}=$product;
$self->{PRODUCT_CON}=$API->{PRODUCT_CON};
$self->{CRM_CON}=$API->{CRM_CON};
$API->constructor;

my $printers = $API->{PRINTERS};
#my $mysqlAPI = MysqlDB->new;
if (exists $opts{h})
{
    ######### First, get the available printers:
    my $printerList = join('|', sort keys %$printers);
    print <<OUT;
usage: processCertificate.pl [options]
Options:
    -h              this screen
    -K product      Product

OUT
    exit;
}

$onlyFedex = 1;
####### check to see if a dry run was ordered.  If so, the system will only print out a list of students
####### who will print.
if ($opts{D})
{
    ##### order a dry run of the system
    print "Performing a Dry Run\n";
    $dryRun = 1;
}


############### Get a lock file for this particular course
####### ASSERT:  No lock file exists and the printer properly passed the ping test.  Let's collect the
####### Required data and start the print job
my @processed = ();
my $users;

$startTime = time;

my $dsSchools = $API->getWorkBookOrdersForPrinting();
my $workBookPrintingCount = keys %$dsSchools;
if($workBookPrintingCount == 0) {
	#$API->emailWorkBookOrder('', '', '0')
}
for my $dsSchoolId(keys %$dsSchools) {
	$users =  $API->getCompleteWorkbookOrders($dsSchoolId);
	my $hidetoolbar = '';
	my $hidemenubar = '';
	my $hidewindowui = '';
	my $fitwindow = '';
	my $centerwindow = '';
	my $xwidth = '';
	my $yheigth = '';

	for my $key(keys %$users) {
		my $orderId = $key;
		##First generate the fedex lable and then email the labels
		my $time = time();
		my ($day,$mon,$year) = (localtime($time))[3,4,5];
		$year +=1900;
		$mon = $mon+1;
		$mon = ($mon<10)?"0".$mon:$mon;
		$day = ($day<10)?"0".$day:$day;
		my $todayDate = "$year-$mon-$day";
	 	my $labelPdf = "Cert_Label_".$todayDate."_$dsSchoolId".".pdf";
		if($users->{$orderId}->{DELIVERY_ID}) {
			$API->printDSMSWokbookLabel($orderId,1,'','');
		}
	}
}
#print "Users retrieved.  execution time:  " . int(time - $startTime) . " seconds\n";
#print "Number of users retrieved:  " . (keys %$users) . "\n";
