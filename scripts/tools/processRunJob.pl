#!/usr/bin/perl -I/www/lib

use strict;

###################################
#### this file represents a "hack"  Unfortunately, when a request is made from the CRM, 
#### the soap script returns before the job actually can run properly.  In order to get 
#### around this issue, the request is actually written to a temp file.  The temp file 
#### is then read by this script and the appropriate job is run.  Once the job is complete,
#### the temp file is deleted.
#### This script will be run every min so the delay in processing should be minimal
##################################

my $PROCESSFILE = "/tmp/printJob.dat";

if(-e $PROCESSFILE)
{
    open IN, $PROCESSFILE;
    while(<IN>)
    {
	    chomp;
	    system($_);
    }
    close IN;
    unlink $PROCESSFILE;
}
