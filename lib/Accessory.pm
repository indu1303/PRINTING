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
package Accessory;
use strict;
use DBI;
use Symbol;
use IO::Socket;
use Net::Ping;
use MIME::Lite;
use MIME::Base64;
use Data::Dumper;

use Fcntl ':flock';
use FileHandle;

my $VERSION = 0.5;

=head1 NAME

Accessory

=head1 Synopsis

This module will be the base class for all printing systems.  All children will derive from this base class
(this class should never be instantiated)

=head1 METHODS

=head2 new

=cut

sub new
{
   
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant;
    my $self = {    
                    @_,
               };
    
    bless($self, $class);
    return $self;
}


sub constructor
{
   my $self = shift;
}



sub pPingTest
{
    my($code, $courseId, $printerKey) = @_;
    my $status = 1;
    my $pinger = Net::Ping->new('icmp') or print STDERR "$!\n";
    if(!$pinger->ping($code,5))
    {
	$status = 0;
	my $mess = <<MESS;
	Printer at IP address not responding to Ping - $code
	Verify printer is active and rerun print job for $courseId
MESS
	my $msg = MIME::Lite->new(From => 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>', 
		To => 'supportmanager@idrivesafely.com', 
		Subject => "$printerKey Printer Process Error",
		Type => 'TEXT', 
		Data => $mess);
#		$msg->send;
    }

    $pinger->close;
    return $status;
}

sub pAcquireLock 
{
  ############### create a lock file based on the course id being passed in
  my ($courseId) = @_; 
  my $lockFile = "/var/tmp/lock.dailyProcess_" . $courseId;

  my $retry = 5;
  my $LOCK_FH   = FileHandle->new( ">>$lockFile" );
  $LOCK_FH->autoflush();
  while( $retry ) 
  {
    # lock the process
    if( flock( $LOCK_FH, LOCK_EX | LOCK_NB ) ) 
    {
      $LOCK_FH->print( "$$\n" );
      return $LOCK_FH;
    } 
    else 
    {
      $retry--;
      sleep 3;
    }
  }
  # we get here, we failed to get a lock;
  $LOCK_FH->close();
  return undef;
}


sub pReleaseLock 
{
  my ($courseId, $lockFH) = @_; 
  my $lockFile = "/var/tmp/lock.dailyProcess_" . $courseId;
  
  if( $lockFH ) 
  {
    $lockFH->close();
    unlink $lockFile;
  }
}

sub DESTROY
{
    my $self = shift;
}

1;
