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
#!/usr/bin/perl -w 

package Report::UserStateReport;

use strict;
use lib qw(/ids/tools/PRINTING/lib);
use Report;
use Certificate::PDF;
use Data::Dumper;
use HTML::Template;

use vars qw(@ISA);
@ISA=qw(Report);


sub _printMOReport
{
    my $self = shift;
    my ($reportDate, $userData, $printerKey) = @_;

    $self->{PDF}->setFont('HELVETICA',10);
    $self->{PDF}->writeLine( 90, 600, $userData->{DRIVERS_LICENSE} );
    $self->{PDF}->writeLine( 240, 600, $userData->{DATE_OF_BIRTH} );

    #### now add the sex.  base the x-translation on whether or not the student is M/F
    $self->{PDF}->setFont('HELVETICA',18);
    my $x = ($userData->{SEX} eq 'M') ? '413' : 476;
    $self->{PDF}->writeLine($x, 604, 'X' );
    $self->{PDF}->setFont('HELVETICA',10);

    #### user name and address
    $self->{PDF}->writeLine( 90, 572 , "$userData->{LAST_NAME}, $userData->{FIRST_NAME}" );

    my $address = $userData->{ADDRESS_1} . ' ' .
                (($userData->{ADDRESS_2}) ? $userData->{ADDRESS_2} : '');
    $self->{PDF}->writeLine( 90, 544 , $address );

    $self->{PDF}->writeLine( 90, 516, $userData->{CITY} );
    $self->{PDF}->writeLine( 320, 516, $userData->{STATE} );
    $self->{PDF}->writeLine( 385, 516, $userData->{ZIP} );

    #### telephone number
    $userData->{PHONE} =~ s/[^0-9a-zA-Z]//g;

    if (length($userData->{PHONE}) < 10)
    {
        $userData->{PHONE} = '0' x (10 - length($userData->{PHONE})) . $userData->{PHONE};
    }

    my $areaCode = substr $userData->{PHONE}, 0, 3;
    my $phone    = substr $userData->{PHONE}, 3, length($userData->{PHONE});

    $phone = substr($phone,0,3) . '-' . substr($phone,3,4) . ' ' . substr($phone,7,length($phone));

    $self->{PDF}->writeLine( 394, 550 , $areaCode );
    $self->{PDF}->writeLine( 425, 550 , $phone );

    #### violation
    $self->{PDF}->writeLine( 90, 488 , $userData->{LAST_NAME} );

    #### Accident
    $self->{PDF}->setFont('HELVETICA',18);
    $x = ($userData->{CITATION}->{ACCIDENT_INVOLVED}) ? 404 : 440;
    $self->{PDF}->writeLine( $x, 487 , 'X' );

    $self->{PDF}->setFont('HELVETICA',10);
    ##### originator number
    $self->{PDF}->writeLine( 90, 445 , $userData->{CITATION}->{COURT_ORIGINATOR_NUMBER} );

    ##### regulator definition
    $self->{PDF}->writeLine( 238, 445 , $userData->{REGULATOR_DEF} );

    ##### case number
    $self->{PDF}->writeLine( 90, 417 , $userData->{CITATION}->{CITATION_NUMBER} );


    ##### conviction date
    $self->{PDF}->writeLine( 385, 417 , $userData->{CITATION}->{CONVICTION_DATE} );

    ##### conviction date
    $self->{PDF}->writeLine( 385, 196 , $userData->{COMPLETION_DATE} );


    return ($self->{PDF},1);
}


sub _printNVReport
{
    my $self=shift;
    my ($userId, $state, $reportDate, $printerKey,$userData, $printingState) = @_;
    my $templatePath = $self->{SETTINGS}->{TEMPLATESPATH}."/reports/";

    my $stateFile = $state . "_report.tmpl";
    my $certificateTemplate
                = HTML::Template->new(filename => $templatePath . $stateFile);

    ###### this is a workaround.....
    my $reportFields = {
            NV =>
                { CITATION_INFO => [ 'I_HAVE_TRAFFIC_VIOLATIONS_PENDING_DURING_MY_ENROLLMENT_IN_THIS_COURSE',
                    'THE_COURT_IS_REDUCING_OR_DISMISSING_MY_TICKET_UPON_COMPLETION_OF_TRAFFIC_SCHOOL',
                    'I_HAVE_COMPLETED_A_TRAFFIC_SAFETY_COURSE_FOR_CREDIT_WITHIN_THE_PAST_12_MONTH_PERIOD',
                    'NUMBER_OF_TRAFFIC_VIOLATIONS_IN_THE_PAST_12_MONTHS_(EXCLUDING_CURRENT_VIOLATION)',
                                    ],
                  USER_INFO => ['COMPLETION_DATE','DRIVERS_LICENSE'],
                  USER_CONTACT => ['DATE_OF_BIRTH'],
                  MISC         => ['TEST_SCORE', 'STUDENT_NAME', 'ADDRESS' ]
                },
             };

    ###### let's do some sanity checks....make sure everything is complete
    my $userCitation=$userData->{CITATION};
    $userCitation->{CASE_NUMBER} = (defined $userCitation->{CASE_NUMBER}) ? $userCitation->{CASE_NUMBER} : 'NONE';
    my $studentName = "$userData->{FIRST_NAME} $userData->{LAST_NAME}";

    ####### now, get the settings for the correct state and get each individual field
    my $certSettings = $reportFields->{$state};

    ####### do the user info table
    my @userInfoArr = @{$reportFields->{$state}->{USER_INFO}};

    foreach my $val(@userInfoArr)
    {
        $certificateTemplate->param( $val => $userData->{$val} );
    }

    my @userContactArr = @{$reportFields->{$state}->{USER_CONTACT}};
    foreach my $val(@userContactArr)
    {
        $certificateTemplate->param( $val => $userData->{$val} );
    }

    my @citationInfoArr = @{$reportFields->{$state}->{CITATION_INFO}};
    foreach my $val(@citationInfoArr)
    {
        $certificateTemplate->param( $val => $userCitation->{$val} );
    }

    my @miscArray = @{$reportFields->{$state}->{MISC}};
    foreach my $val(@miscArray)
    {
        if ($val eq 'TEST_SCORE')
        {
            $certificateTemplate->param( $val => $userData->{FINAL_SCORE});
        }
        elsif ($val eq 'STUDENT_NAME')
        {
            $certificateTemplate->param( $val => $studentName );
        }
        elsif ($val eq 'REGULATOR')
        {
            $certificateTemplate->param( $val => $userData->{REGULATOR_DEF} );
        }
        elsif ($val eq 'ADDRESS')
        {
            my $address = $userData->{ADDRESS_1}. ' ';
            if ($userData->{ADDRESS_2})
            {
                $address .= $userData->{ADDRESS_2} . ' ';
            }
            $address .= $userData->{CITY} . ', ' . $userData->{STATE} . '  ' . $userData->{ZIP};

            $certificateTemplate->param( $val => $address );
        }
    }


    $certificateTemplate->param( REPORT_DATE => $reportDate );

    ##### everything should've been substituted.  Now, let's go ahead, open the file and print the stuff out
        my $fileName    =   "/tmp/REPORT$userId.html";
    my $pdfFileName =   "/tmp/REPORT$userId.pdf";

        open W ,">$fileName" || die "unable to write to file \n";
        print W $certificateTemplate->output;
        close W;

    ##### convert this file to PDF
    my $cmd = <<CMD;
/usr/bin/htmldoc -f $pdfFileName --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 --size letter $fileName
CMD

    $ENV{TMPDIR}='/tmp/';
    $ENV{HTMLDOC_NOCGI}=1;

    system($cmd);

    if (-e $pdfFileName)
    {
        ######## Now print the file
	my $pid=0;	
        my $printer = 0;
        my $media = 0;
        my $st=$state;
        my $productId=1;  ##### Default for DIP
	$st = ($printingState) ? $printingState : $st;
       ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RPT');
       if(!$printer){
 	      $printer = 'HP-PDF-HOU01';
       }
       if(!$media){
       	      $media='Tray4';
       }

	if (! $printer)
        {
                   ###### error out.....printer is not set
        	$pid=0;
        }
	print STDERR "/usr/bin/lp -d $printer -o media=$media $pdfFileName";
	system("/usr/bin/lp -d $printer -o media=$media $pdfFileName");

        ######## All should be right w/ the world, so go ahead and delete the temp files
        unlink ($pdfFileName);
        unlink ($fileName);
        return $pid;
    }

    print STDERR "error:  User $userId not printed\n";
    return 0;
}



sub constructor
{
	my $self = shift;
	my ($userId,$state)=@_;
	###### let's create our certificate pdf object
	my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/". $state. "_report_img.jpg";
	if(-e $top){
		$self->{PDF} = Certificate::PDF->new($userId,'','','','','',612,792);
                $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/MO_report_img.jpg",
                              0, 0, 612, 792,1275,1650);
	}
	 return $self;

}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate/California.pm $

=item $Author: kumar $

=item $Date: 2009/03/06 18:34:18 $

=item $Rev: 71 $

=cut

1;
