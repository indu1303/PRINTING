# -tr~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

package DriverRecord::DPS;

use lib qw(/ids/tools/PRINTING/lib);
use DriverRecord;
use Certificate::PDF;
use Data::Dumper;
use Certificate;

use vars qw(@ISA);
@ISA=qw(DriverRecord);

use strict;

sub _generateDriverRecordAppForm
{
    my $self = shift;
    my ($userId, $userData) = @_;
    ##### ok, let's load up the @args array w/ the params to send into the
    ##### print function
    my $xDiff=0;
	###### as we do w/ all things, let's start at the top.  Print the header	
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    my $yPos = 525;
    my $xPos = 65;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{LAST_NAME});
    $xPos = 333;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{FIRST_NAME});
    $xPos=65;
    $yPos = 496;
    my $address=$userData->{ADDRESS1};
    if($userData->{ADDRESS2}){
         $address .= ', ' . $userData->{ADDRESS2};
    }
    $self->{PDF}->setFont('HELVETICABOLD',8);
    $self->{PDF}->writeLine( $xPos, $yPos, $address);
    my @variableData;
    my $arrCtr=0;
    $variableData[$arrCtr++]="ADDRESS:$address";
    my $driversLicense=$userData->{DRIVERS_LICENSE};
    $xPos=385;
    for(my $i=0;$i<length($driversLicense);$i++){
          $self->{PDF}->writeLine( $xPos+($i*15), $yPos, substr($driversLicense,$i,1));
    }
    $xPos=65;
    $yPos = 471;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{CITY});
    $variableData[$arrCtr++]="CITY:$userData->{CITY}";
    $xPos=252;
    my $state=$userData->{STATE};
    $variableData[$arrCtr++]="STATE:$userData->{STATE}";
    for(my $i=0;$i<length($state);$i++){
         $self->{PDF}->writeLine( $xPos+($i*15), $yPos, substr($state,$i,1));
    }
    $xPos=292;
    my $zip=$userData->{ZIP};
    $variableData[$arrCtr++]="ZIP:$userData->{ZIP}";
    for(my $i=0;$i<length($zip);$i++){
         $self->{PDF}->writeLine( $xPos+($i*15), $yPos, substr($zip,$i,1));
    }
    $xPos=380;
    my $phone=$userData->{PHONE};
    $variableData[$arrCtr++]="PHONE:$userData->{PHONE}";
    $phone =~ s/\(|\)|\s|-|#//g;
    for(my $i=0;$i<length($phone);$i++){
         if($i==3 || $i==6){
                 $xPos +=15;
         }
         $self->{PDF}->writeLine( $xPos+($i*15), $yPos, substr($phone,$i,1));
    }
    $xPos=57;
    $yPos=337;
    for(my $i=0;$i<length($driversLicense);$i++){
         $self->{PDF}->writeLine( $xPos+($i*15), $yPos, substr($driversLicense,$i,1));
    }
    $yPos=338;
    $xPos = 238;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{LAST_NAME});
    $variableData[$arrCtr++]="LAST_NAME:$userData->{LAST_NAME}";
    $xPos = 60;
    $yPos = 313;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{FIRST_NAME});
    $variableData[$arrCtr++]="FIRST_NAME:$userData->{FIRST_NAME}";
    $yPos = 313;
    $xPos = 409;
    my $dateOfBirth=$userData->{DATE_OF_BIRTH};
    $dateOfBirth =~ s/\///g;
    $dateOfBirth =~ s/\-//g;
    for(my $i=0;$i<length($dateOfBirth);$i++){
         if($i==2 || $i==4){
                 $xPos +=15;
         }
         $self->{PDF}->writeLine( $xPos+($i*15), $yPos, substr($dateOfBirth,$i,1));
    }
    $xPos=60;
    $yPos=249;
    $self->{PDF}->writeLine( $xPos, $yPos, "$userData->{FIRST_NAME} $userData->{LAST_NAME}"); 
    $xPos=451;
    $yPos=209;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{DPS_DATE}); 
    $variableData[$arrCtr++]="DPS_DATE:$userData->{DPS_DATE}";
    $xPos=456;
    $yPos=65;
    $self->{PDF}->writeLine( $xPos, $yPos, $userData->{DPS_DATE});
    my $imageFile=$userId .".jpg";
    use LWP::Simple;
    my $signatureUrl="$self->{SETTINGS}->{SIGNATUREURL}->{DIP}/$imageFile";
    my $pic = get($signatureUrl);
    my $printId=0;
    if($pic){
          open(IMAGE, ">/tmp/$imageFile") || die"image.jpg: $!";
          binmode IMAGE;  # for MSDOS derivations.
          print IMAGE $pic;
          close IMAGE;
          my $signature="/tmp/$imageFile";
	  if(-e  $signature){
          	  $xPos=150;
	          $yPos=63;
		  $self->{PDF}->genImage($signature, $xPos, $yPos, 84, 28,420,138);
	          $yPos=210;
		  $self->{PDF}->genImage($signature, $xPos, $yPos, 84, 20,420,138);
		  my $fixedData=Certificate::_generateFixedData($userData);
	          if(!$printId){
        	        $printId=$self->MysqlDB::getNextId('contact_id');
        	  }
		  my $variableDataStr=join '~',@variableData;
	          $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
        	  unlink($signature);
	  }else{
		  $printId = -1;
	  }
    }else{
	$printId = -1;
    }
    return ($self->{PDF},$printId);
}
sub _generateNonTXDriverRecord
{   
    my $self = shift;
    my ($userId, $userData) = @_; 
    use LWP::Simple;
    my $drUrl="$self->{SETTINGS}->{CRMURL}->{NEW}/userdocs/dip/$userId/DR_$userId.pdf";
    if($userData->{PRODUCTID} && $userData->{PRODUCTID} == 25) {
    	$drUrl="$self->{SETTINGS}->{CRMURL}->{NEW}/userdocs/takehome/$userId/DR_$userId.pdf";
    }
    my $pic = get($drUrl);
    my $pdfFile="DR_$userId.pdf";
    my $printId=0;
    my $printerKey='TX';
    my $outputFile="/tmp/$pdfFile";
    my $printer = 0;
    my $media=0;
    if($pic){
        open(IMAGE, ">/tmp/$pdfFile") || die"image.jpg: $!";
        binmode IMAGE;  # for MSDOS derivations.
        print IMAGE $pic;
        close IMAGE;
	my $state=$userData->{DR_STATE};
        my $st=$state;
        my $productId=1;  ##### Default for DIP
	($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'DR');
    	if(!$printer){
                $printer = 'HP-PDF2-TX';
    	}
    	if(!$media){
                $media='Tray2';
    	}
	if($state && $state eq 'TX'){
		my $password=$userData->{DRIVERS_LICENSE};
		my $withoutPasswordFile="/tmp/DR_NOPWD_$userId.pdf";
		my $cmd="/usr/bin/qpdf --password=$password --decrypt $outputFile $withoutPasswordFile";
		system($cmd);
		if(-e $withoutPasswordFile){
	        	my $ph;
	        	open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media $withoutPasswordFile");
		        close $ph;
        		if(-e $withoutPasswordFile){
                		 unlink($withoutPasswordFile);
	        	}
			unlink($outputFile);
		}
	}else{
	        my $ph;
        	open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media $outputFile");
	        close $ph;
        	if(-e $outputFile){
                	 unlink($outputFile);
	        }
	}

    	return 1;

   }else{
	 return 0;
   }
}

sub printDRLabel
{   
    my $self = shift;
    my ($userId, $userData) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$userId",'','','','','',612,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/CA_TEEN_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    my $xDiff='';
    $self->{PDF}->setTemplate($top,$bottom,$full);
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{DR_STATE}})){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    $self->_printCorporateAddress(21-$xDiff, 662, $OFFICECA, '');
    

    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} );
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS1} );
    $yPos -=11;
    if($userData->{ADDRESS2}){
        $self->{PDF}->writeLine( 21, $yPos, $userData->{ADDRESS2} );
        $yPos -=11;
    }
    $self->{PDF}->writeLine( 21, $yPos, "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}");
    $self->{PDF}->getCertificate;

     my $printer = 0;
     my $media = 0;
     my $st=$userData->{DR_STATE};
     my $productId=1;  ##### Default for DIP
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'DRLBL');
    if(!$printer){
                $printer = 'HP-PDF2-TX';
    }
    if(!$media){
                $media='Tray2';
    }

                my $outputFile = "/tmp/LABEL$userId.pdf";
                ######## send the certificate to the printer

                my $ph;
                open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
                close $ph;
                if(-e $outputFile){
                        unlink $outputFile;
                }

}


sub constructor
{
	my $self = shift;
	my ($userId)=@_;
	###### let's create our certificate pdf object
	$self->{PDF} = Certificate::PDF->new($userId);
	my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/PaidDPSapp.pdf";
	my $full=1;

	###### get the appropriate templates
	$self->{PDF}->setDPSTemplate($top);
 	return $self;

}

=pod

=head1 AUTHOR

hari@ed-ventures-online.com

=item $Author: kumar $

=item $Date: 2009-10-19 07:55:02 $

=item $Rev: 71 $

=cut

1;
