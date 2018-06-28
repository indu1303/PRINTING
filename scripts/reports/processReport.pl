#!/usr/bin/perl -I /ids/tools/PRINTING/lib

use strict;
use Symbol;
use printerSite;
use Settings;
use Accessory;
use Data::Dumper;
use Report;
use MysqlDB;
use Getopt::Std;
my $self= Settings->new;
my $product='DIP';
my $productId       = 1;
my $printingAPI     = 'DIP';
my $API;
my %opts;
my $SLEEPTIME = 15;
my $MAX_PRIORITY = 12;
my $MAX_WAIT = 90;
my $PRINT_QUEUE = '/var/spool/print';
my $STOP = 0;
my $lastModule='';

my $SERVER_NAME     = (split(/\./,qx/uname -n/))[0];
my $printer         = '';
my $dryRun          = 0;
my $showError       = 0;
my $printerKey      = 'CA';
my $lockFile        = 0;
my $runCounter      = 0;
my $limitedRun      = 0;
my $priority        = 1;
my $ping            = 1;
my $state           = "";
my $dateRange = 0;
my $printLog;
my $error_msg = undef;
my $numberofdays = 7;
my $type='PDF';
my $stateList;
getopt('KpscA:', \%opts);
print "\nRunning IDS Printing Job\n";
print "Job running on $SERVER_NAME\n";
print "**************************\n\n";

################# process all incoming options
################# options are as follows:
#
#    -c course   Run a perticular Course Id
#    -D          Dry Run
#    -K product  Product
#    -P          Do not ping the printer
#    -p printer  Print to the (CA|TX) printer
#    -s          Run a single state only
#    -A num      Last Number of days to now

   ####  Get the Product Id
my @productArr;
if($opts{K})
{
	@productArr = split /_/,$opts{K};
        $productId = ($self->{PRODUCT_ID}->{$opts{K}})?$self->{PRODUCT_ID}->{$opts{K}}:1;
        $printingAPI = ($self->{PRINTING_API}->{$opts{K}})?$self->{PRINTING_API}->{$opts{K}}:$product;
	$product=$opts{K};
	
}else{
	push @productArr,'DIP';
}
my $startTime         = time;
my $totalTime         = time;
if (exists $opts{h})
{
    print <<OUT;
usage: processCertificate.pl [options]
Options:
    -h              this screen

    -D              Perform a dry run.  Will display users who are eligible to print, their course id
                    and their delivery id only.  No printing or updating of accounts will occur

    -p printer      Print to the printer.  By default, all jobs will print to the
                        default printer for that particular course

    -P              The printer will not be ping'd

    -s state        run a single state only.  Use the two-letter state abbreviation or FLEET for
                    fleet certs

    -c courseId     Run a perticular Course Id

    -K product      Product

    -A num          From Last Number of days to now.


OUT
    exit;
}

if ($opts{D})
{
    ##### order a dry run of the system
    print "Performing a Dry Run\n";
    $dryRun = 1;
}
 ######## are we doing the limited days
if ($opts{A})
{
    $numberofdays = $opts{A};
    print "From Last  $numberofdays Days(s) to now will be Processed\n";
}

######## Is the printer to be ping'd?
if ($opts{P})
{
    ##### Do not ping the printer
    print "Printer will not be ping'd\n";
    $ping = 0;
}
####### now let's set up the printer
if ($opts{p})
{
    ###### a printer option has been passed in.  Let's make sure this is a valid entry
    my $printk = uc($opts{p});

        $printerKey = $printk;
}

############### Get a lock file for this particular course
if(! ($lockFile = Accessory::pAcquireLock($opts{c})))
{
    ##### send an alert to the CRM
    $API->MysqlDB::dbInsertAlerts(7);
    exit();
}
####### check to see if a dry run was ordered.  If so, the system will only print out a list of students
####### who will print.
my $userList;
my $ctr=111;
foreach $product(@productArr){
	my %hashProcessCourse;
        $productId = ($self->{PRODUCT_ID}->{$product})?$self->{PRODUCT_ID}->{$product}:1;
        $printingAPI = ($self->{PRINTING_API}->{$product})?$self->{PRINTING_API}->{$product}:$product;
	eval("use Printing::$printingAPI");
	$API = ("Printing::$printingAPI")->new;
	print "Database connection  time:  " . int(time - $startTime) . " seconds\n";
	$API->{PRODUCT}=$product;
	$self->{PRODUCT}=$product;
	$self->{PRODUCT_CON}=$API->{PRODUCT_CON};
	$self->{CRM_CON}=$API->{CRM_CON};
	$API->constructor;



if ($opts{s})
{
    ##### Check the requested state
    $stateList = {};
    my $stateAbbr = uc ($opts{s});
    my $allStates = $API->{STATES};
    $hashProcessCourse{STATE}= $stateAbbr; 
    if (exists $allStates->{$stateAbbr})
    {
        $state = $stateAbbr;
    }
    else
    {
        print "$opts{s} is not a valid state\n";
        exit;
    }

    ####### let's get all the associated courses available for this particular state
    my $course= $API->getCourseSelection($state);

    foreach my $cId(keys %$course)
    {
        $stateList->{$cId} = 1;
    }


    print "Only $state certs will print.\n";
}

if ($opts{c})
{
        #### Check the course Id #####
        $stateList = {};
        my $cId = $opts{c};
        $stateList->{$cId} = 1;
        $hashProcessCourse{COURSE}= $cId; 
	my $courses = $API->getCourseDescription($cId);
    if (exists $courses->{$cId})
    {
        print "Course $cId : $courses->{$cId}->{DEFINITION} will be processed\n";
    }
    else
    {
        print "Course Id $cId does not exist\nExiting...\n";
        exit;
    }
}
$hashProcessCourse{NUMBEROFDAYS}= $numberofdays;
##################### let's set up a couple of conditionals to see if we're allowed to print

####### ASSERT:  No lock file exists and the printer properly passed the ping test.  Let's collect the
####### Required data and start the print job
my @processed = ();
my $users;

$startTime = time;
$users =  $API->getCompleteUsersList(\%hashProcessCourse);
	foreach my $k(keys %$users){
		$userList->{$ctr}->{USER_ID}=$users->{$k}->{USER_ID};
		$userList->{$ctr++}->{USER_DATA}=$users->{$k}->{USER_DATA};
	}
}
print "Users retrieved.  execution time:  " . int(time - $startTime) . " seconds\n";
print "Number of users retrieved:  " . (keys %$userList) . "\n";
$startTime = time;

#= pGetAllHostedAffiliateCourses();
print "Users processed.  execution time:  " . int(time - $startTime) . " seconds\n";
$startTime = time;
if(keys %$userList)
{
        printReport($userList);
}
print "Users Print processed.  execution time:  " . int(time - $startTime) . " seconds\n";
exit;
##################### Define the different script printing types

sub printReport
{

    my ($printUsers)=@_;
    my $currentCertificate;
    my $processCourse = 'CA';
    if(!$printerKey)
    {
        $printerKey = 'CA';
    }
    if(! ($lockFile = Accessory::pAcquireLock($processCourse)))
    {
        ##### send an alert to the CRM
        $API->MysqlDB::dbInsertAlerts(7);
        exit();
    }

    ######  ASSERT:  The job is allowed to print.  Let's prep some stuff for the CRM
    my @keys = sort keys %$printUsers;
    print STDERR "num of users ready to process " . @keys . " \n";
    if(@keys)
    {
        $printLog = gensym;
        open $printLog, ">>$printerSite::SITE_ADMIN_LOG_DIR/print_log_ca" or print STDERR "PRINT LOG ERROR: $!\n";;
        print $printLog "Job started at " . Settings::getDateTime() . "\n";
        if ($dryRun)
        {
                ####### simply output the user and his delivery option.  No changes will be made to the database
         }else{
		my $reportModule=$state."Report";
		eval("use Report::$reportModule");
		my $report=("Report::$reportModule")->new;
		my $result=$report->printReport($printUsers,{ PRINTER => 1},$printerKey);
	 }

    }
        close $printLog;
}

