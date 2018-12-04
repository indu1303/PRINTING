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

package Affidavit;
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

sub printAffidavit
{
	my $self = shift;
	my ($userId,$userData,$outputType,$forPrint,$printId)=@_;
        if($forPrint){
		$self->constructor($userId,'CO_TEEN_AFFIDAVIT.pdf');
	}else{
		$self->constructor($userId,'CO_TEEN_AFFIDAVIT_EMAIL.pdf');
	}
	my $cert;
	my $pId;
	if($forPrint){
		($cert, $pId) = $self->_generateCOAffidavitForPrint($userId,$userData,$printId);
	}else{
		($cert, $pId) = $self->_generateCOAffidavit($userId,$userData);
	}
	$cert->getCertificate;
	my $outputFile = "/tmp/$userId.pdf";

	###### ok, we have the certificate.  now, based on the following parameters from when the class
	###### was declared, we're going to do something w/ it:
	###### EMAIL:  Email it to the user
        if(!$forPrint){
		if($userData->{EMAIL}){
			my $DOMAINURL = "http://teen.idrivesafely.com";
			my $emailContent = "";
			$emailContent .=" <html> \n";
			$emailContent .=" <head> \n";
			$emailContent .="         <title>Payment Confirmation</title> \n";
			$emailContent .=" </head> \n";
			$emailContent .=" <body leftmargin=\"0\" marginheight=\"0\" marginwidth=\"0\" topmargin=\"0\"> \n";
			$emailContent .=" <DIV><FONT face=Tahoma size=2></FONT></DIV> \n";
			$emailContent .=" <div align=\"left\"> \n";
			$emailContent .=" <table width=\"500\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"> \n";
			$emailContent .=" <tr height=\"79\"> \n";
			$emailContent .="         <td width=\"500\" height=\"79\"><img src=\"$DOMAINURL/images/comp/INDEX_LOGO_02.gif\" alt=\"\" border=\"0\" NOSEND=\"1\"></td> \n";
			$emailContent .=" </tr> \n";
			$emailContent .=" <tr>  \n";
			$emailContent .=" <td valign=\"top\" width=\"500\"> \n";
			$emailContent .="         <table width=\"500\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"> \n";
			$emailContent .="                 <tr height=\"34\"> \n";
			$emailContent .="                         <td width=\"21\" height=\"34\"></td> \n";
			$emailContent .="                         <td width=\"477\" height=\"34\"> \n";
			$emailContent .="                                 <p><img src=\"$DOMAINURL/images/comp/spacer.gif\" alt=\"\" width=\"20\" height=\"18\" border=\"0\" NOSEND=\"1\"><br> \n";
			$emailContent .=" <span class=\"style3\">Hi $userData->{FIRST_NAME} $userData->{LAST_NAME},</span><BR> \n";
			$emailContent .="                                 <br> \n";
			$emailContent .="                                         </font><font size=\"2\" face=\"Arial\">You have successfully completed course enrollment through I DRIVE SAFELY. Please download the pdf attachment and print your affidavit of enrollment.</font></p> \n";
			$emailContent .="                                 <p><font size=\"3\" face=\"Arial Unicode MS\"> <br> \n";
			$emailContent .="                                 </font> \n";
			$emailContent .="                                 <br> \n";
			$emailContent .="                                 <font size=\"2\" face=\"Arial\"><b>Website Link:</b></font><font size=\"3\" face=\"Arial Unicode MS\"> </font><a href=\"$DOMAINURL/\" target=\"_blank\"><font color=\"#0000FF\" size=\"3\" face=\"Arial Unicode MS\"><b><u>www.teen.idrivesafely.com</u></b></font></a></p> \n";
			$emailContent .="                         <span class=\"style4\"><font color=\"#fe2731\" face=\"Arial\"><b>I DRIVE SAFELY</b><br> \n";
			$emailContent .="                                         1-800-723-1955<br> \n";
			$emailContent .="                                         <br> \n";
			$emailContent .="                                         <a href=\"mailto:support\@idrivesafely.com\">support\@idrivesafely.com</a><br/> \n";
			$emailContent .="                                         <a href=\"$DOMAINURL\">teen.idrivesafely.com</a></span><br/></font> \n";
			$emailContent .="                                         <br> \n";
			$emailContent .="                                         <br> \n";
			$emailContent .="                                         <br> \n";
			$emailContent .="                                 </p> \n";
			$emailContent .="                         </td> \n";
			$emailContent .="                 </tr> \n";
			$emailContent .="         </table> \n";
			$emailContent .=" </td> \n";
			$emailContent .=" </tr> \n";
			$emailContent .=" </table> \n";
			$emailContent .=" </div> \n";
			$emailContent .=" </body> \n";
			$emailContent .=" </html> \n";

	 	# Got the path of the PDF File, now send the mail
        		my $msg = MIME::Lite->new(
                           From    =>'I DRIVE SAFELY <support@IdriveSafely.com>',
                           To      => $userData->{EMAIL},
                           Subject =>"AFFIDAVIT OF LIABILITY AND GUARDIANSHIP",
                           Type    =>'text/html',
             		   Data     => "$emailContent"
                          );
			$msg->attach(Type    => 'application/pdf',
                                             Path     =>$outputFile,
                                             Filename =>'affidavit.pdf',
                                             Disposition => 'attachment');

			$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f support@idrivesafely.com');
			if(-e $outputFile){
				unlink $outputFile;
			}
			return 1;
		}
		return 0;
        }	
	my $printerKey = 'CA';
	my $printerTray = 'Tray5';

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
	if (($outputType->{PRINTER} && $outputFile) || ( ! $outputType->{STDOUT} && ! $outputType->{FILE} && ! $outputType->{EMAIL} && ! $outputType->{FAX} ))
	{
		######## send the certificate to the printer
		my $printer = 0;
		my $media = 'Tray3';
                my $st='XX';   ##########  Default state, we have mentioned as XX;
		my $productId=2;   ##### Tgis is default for TEEN
                $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
	        ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'AFFIDAVIT');
                if(!$printer){
                        $printer = 'HP-PDF-HOU05';
                }
                if(!$media){
                        $media='Tray3';
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
=pod

head1 AUTHOR

hari@ed-ventures-online.com

=cut

1;
