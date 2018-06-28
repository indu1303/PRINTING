#!/usr/bin/perl
package Certificate::NewYork;
use strict;
use lib qw(/ids/tools/PRINTING/lib);
use printerSite;
use MysqlDB;
use Certificate;
use Data::Dumper;

use vars qw(@ISA);
@ISA=qw(Certificate);
=head1 NAME

NewYork

=head1 Description

This class will generate a New York Certificate

=head1 METHODS

=head2 new

object declaration for New York certificates

=cut


   sub new
{
        my $pkg         = shift;
        my $class       = ref($pkg) || $pkg;
#
    my $self = {
                   CRM_CON =>   { DB => $printerSite::CRM_DATABASE, HOST=>$printerSite::CRM_DATABASE_HOST, USERNAME => $printerSite::CRM_DATABASE_USER, PASSWORD => $printerSite::CRM_DATABASE_PASSWORD },
                    @_,
               };

        bless ($self, $class);

        my $dbConnects = $self->_dbConnect();
        if (! $dbConnects)
        {
                die();
        }

        ####### ASSERT:  The db connections were successful.  Assign 
	my ($userId, $product) = @_;
	$self->{USERID} = $userId;
	$self->{PRODUCT} = $product;
        $self->{CRM_CON}      = $dbConnects->{CRM_CON};
        $self->{SETTINGS} = Settings->new;
	$self->{PRINTERS} = Printing::getPrinters($self);



        ##### let's get some settings
        return $self;
}
 


=head2 generateCertificate

print out a certificate for the particular user

=cut

sub printCertificate
{
    ###### add some code for the CRM
    my $self = shift;
    my ($userId,$userData,$outputType,$printId,$printerKey,$accompanyLetter,$productId,$rePrintData,$ha)=@_;
    my $city_address   = "$userData->{CITY}, $userData->{STATE} $userData->{ZIP}";
    my($student_id,$certificate_no,$today,$address);

#    mysqlDB->MysqldbConnect(); 
#    my $result = mysqlDB->MysqlNextId('contact_id');
    my @variableData;
    $today = Settings::getDate();
    $certificate_no = $userData->{CERTIFICATE_NUMBER};
    $student_id = $userId;
    $address=$userData->{ADDRESS_1};
    if($userData->{ADDRESS_2}){
    	$address .= ' '.$userData->{ADDRESS_2};
    }
    my $idsPhone = '(877) 374-8388';
    my ($daName, $daAddress1, $daCityZip, $daPhone);
    my $dvdText = ""; my $dvdText1 = ""; my $dvdText2 = ""; my $dvdText3 = ""; my $dvdText4 = ""; my $dvdText5 = ""; my $dvdText6 = "";
    if($productId && $productId == 1){
	$userData->{DA_CODE}='INTERNET CLASS'; 
	$userData->{EDUCATOR_ID}='INTERNET CLASS';
	$userData->{LOCATION_ID}='INTERNET CLASS';
	$idsPhone = '(877) 860-5275';
    }elsif($productId && ($productId ==22 || $productId == 25)){
	$userData->{DA_CODE}='DVD CLASS'; 
	$userData->{EDUCATOR_ID}='DVD CLASS';
	$userData->{LOCATION_ID}='DVD CLASS';
	$idsPhone = '(800) 505-5095';

	$dvdText = "New York's New Texting Law (as of July 2011)";
	$dvdText1 = "ATTENTION: As of July 2011, it is illegal for drivers to use a hand-held electronic";
	$dvdText2 = "device to compose, send, read, access, browse, transmit, save, or retrieve text messages,";
	$dvdText3 = "email, webpages, images, or games while behind the wheel. Violation of this law will";
	$dvdText4 = "result in a fine of up to \$150 and will add three points against your license. ";
	$dvdText5 = "New York is a primary enforcement state, which means you can be pulled over by the police";
	$dvdText6 = "for the use of any hand-held electronic device while driving.";
    }
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa();
    if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}}) && $productId && ($productId == 1 || $productId==25 || $productId==22)){
        $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    }
    if($productId && $productId eq '25'){
	my $productName=$self->{SETTINGS}->{PRODUCT_NAME}->{$productId};
        $OFFICECA = $self->{SETTINGS}->getOfficeCa($productName);
        if(!($userData->{COURSE_STATE} && exists $self->{SETTINGS}->{WEST_COAST_STATES}->{$userData->{COURSE_STATE}})){
                if(exists $self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName}){
                        $OFFICECA=$self->{SETTINGS}->{NON_WEST_COAST_STATES_OFFICE_ADDRESS}->{$productName};
                }else{
                        $OFFICECA = $self->{SETTINGS}->getOfficeCa($productName);
                }
        }
    }

    my $officeAddress1 = '283 4th st Unit 301';
    my $officeAddress2 = 'Oakland, CA 94607';
    ##For DSMS
    $daName = (defined $userData->{DA_SCHOOL_NAME} && $userData->{DA_SCHOOL_NAME}) ? 'C/O '.$userData->{DA_SCHOOL_NAME} : '';
    if(defined $userData->{DA_ADDRESS1}){
    	$daAddress1 = "$userData->{DA_ADDRESS1} $userData->{DA_ADDRESS2}";
        $officeAddress1 = '4201 FM 1960 West, Ste. 100';
        $officeAddress2 = 'Houston, TX 77068';
    }else{
    	$daAddress1 = $OFFICECA->{ADDRESS};
    }
    if(defined $userData->{DA_CITY}){
    	$daCityZip = "$userData->{DA_CITY} $userData->{DA_STATE} $userData->{DA_ZIP}"; 
    }else{
    	$daCityZip = "$OFFICECA->{CITY}, $OFFICECA->{STATE} $OFFICECA->{ZIP}"; 
    }
    if(defined $userData->{DA_PHONE1}){
    	$daPhone = $userData->{DA_PHONE1};
    	$daPhone =~ s/\-//g;$daPhone =~ s/\s+//g;$daPhone =~ s/\(//g;$daPhone =~ s/\)//g;$daPhone = substr($daPhone, 0,10);
    	$daPhone = "(".substr($daPhone, 0,3).") ".substr($daPhone, 3, 3)."-".substr($daPhone, length($daPhone)-4, length($daPhone));
    }

    #.ps files generated from .ai files need to edited by first running mac2unix on them
    # and then making sure that all <IDS:*> tags are contiguous in the file
    my %replace = (
                 CERT_NO          => $userData->{CERTIFICATE_NUMBER},
                 DELIV_NO         => $userData->{DA_CODE},
                 INSTRUCTOR_NO    => $userData->{EDUCATOR_ID},
                 LOCATION_ID      => $userData->{LOCATION_ID},
                 STUDENT_ID       => $userId,
                 LICENSE_NO       => $userData->{DRIVERS_LICENSE},
                 COMPLETION_DATE  => $userData->{COMPLETION_DATE},
                 FIRST            => $userData->{FIRST_NAME},
                 LAST             => $userData->{LAST_NAME},
                 STREET           => $address,
                 CITY_ADDRESS     => $city_address,
                 IDS_DELIVERY_AGENCY => $daName,
                 IDS_STREET       => $daAddress1,
                 IDS_CITY         => $daCityZip,
                 IDS_PHONE        => $daPhone,
                 SIGN_DATE        => $today,
                 TEXT1            => 'CONGRATULATIONS! You have successfully completed the I DRIVE SAFELY - New York Point &',
                 TEXT2            => 'Insurance Reduction Program. Here is some important data for your records',
		 IDS_CO_STREET       => $officeAddress1,
	         IDS_CO_CITY         => $officeAddress2,
		 IDS_CO_PHONE        => $idsPhone,
		 DVD_TEXT	  => $dvdText,
		 DVD_TEXT1	  => $dvdText1,
		 DVD_TEXT2	  => $dvdText2,
		 DVD_TEXT3	  => $dvdText3,
		 DVD_TEXT4	  => $dvdText4,
		 DVD_TEXT5	  => $dvdText5,
		 DVD_TEXT6	  => $dvdText6,
   );
    my $arrCtr=0;
    foreach my $field(keys %replace){
    	$variableData[$arrCtr++]="$field:$replace{$field}";    
    }
    open IN, "/ids/tools/PRINTING/templates/printing/ny_certificate.ps";
    
    open( LOG, ">>/www/logs/printing/.ny_certificates.log" ); 
    open (OUT , ">/tmp/nycert$userId.ps");
    while( <IN> ) 
    {
        s/\<IDS\:([^\>]+)\>/$replace{$1}/g;
        print OUT $_;
    }
    close IN;
    close OUT;
    my $ph;
    system("/usr/bin/ps2pdf /tmp/nycert$userId.ps /tmp/nycert$userId.pdf");
    if(!$printId){
            $printId=$self->MysqlDB::getNextId('contact_id');
    }
    if($outputType->{FILE}){
	system("cp /tmp/nycert$userId.pdf /tmp/$userId.pdf");
	system("chmod 777 /tmp/$userId.pdf");
        unlink "/tmp/nycert$userId.pdf";
    	my $variableDataStr=join '~',@variableData;
	my $fixedData=Certificate::_generateFixedData($userData);
    	$self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
	return $printId;
    }
    if($outputType->{FAX}){
	my @fileNames;
	push @fileNames,"/tmp/nycert$userId.pdf"; 
        $self->dbSendFax($outputType->{FAX},@fileNames);
    }else{
    	my $printer = 0;
	my $media = 0;
    	my $st='NY';   ##########  Default state, we have mentioned as XX;
    	$st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    	($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERT');
    	if(!$printer){
                $printer = 'HP-PDF2-TX';
    	}
    	if(!$media){
                    $media='Tray3';
    	}


	    system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media /tmp/nycert$userId.pdf");
	    unlink "/tmp/nycert$userId.pdf";
	    Printing::updateCertsStock(1);
    }
    unlink "/tmp/nycert$userId.ps";
    open( LOG, ">>/www/logs/printing/.ny_certificates.log" );
    print LOG "$today\t$certificate_no\t$student_id\t$userData->{FIRST_NAME}\t$userData->{LAST_NAME}\n";

    close LOG;
    my $variableDataStr=join '~',@variableData;
    my $fixedData=Certificate::_generateFixedData($userData);
    $self->MysqlDB::dbInsertPrintManifestStudentInfo($printId,$fixedData,$variableDataStr);
    return $printId;
}

sub printDSMSRegulatorMailLabel
{
    my $self = shift;
    my ($classId, $shippingData, $clasStudentsCount) = @_;

    $self->{PDF} = Certificate::PDF->new("LABEL$classId",'','','','','',612,792);
    my $top = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/CA_TEEN_Certificate_Label.pdf";
    my $full=1;
    my $bottom='';
    my $xDiff='';
    $self->{PDF}->setTemplate($top,$bottom,$full);
    my $OFFICECA = $self->{SETTINGS}->getOfficeCa('',1);
    $self->_printCorporateAddress(21-$xDiff,662, $OFFICECA,'dsms.idrivesafely.com');

    ###### as we do w/ all things, let's start at the top.  Print the header
    ###### now, print the user's name and address
    my $yPos=579;
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 116, $yPos+97, "($clasStudentsCount Students)");
    $self->{PDF}->setFont('HELVETICABOLD', 9);
    $self->{PDF}->writeLine( 21, $yPos, $shippingData->{SCHOOL_NAME} );
    $yPos -=11;
    $self->{PDF}->setFont('HELVETICABOLD', 8);
    $self->{PDF}->writeLine( 21, $yPos, $shippingData->{ADDRESS} );
    $yPos -=11;
    if($shippingData->{ADDRESS_2}){
        $self->{PDF}->writeLine( 21, $yPos, $shippingData->{ADDRESS_2} );
        $yPos -=11;
    }
    $self->{PDF}->writeLine( 21, $yPos, "$shippingData->{CITY}, $shippingData->{STATE} $shippingData->{ZIP}");
    $self->{PDF}->getCertificate;
    my $printer = 0;
    my $media = 0;
    my $st='NY';   ##########  Default state, we have mentioned as XX;
    my $productId=19;  ##### This is for DSMS
    $st=($shippingData->{STATE})?$shippingData->{STATE}:$st;
    ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'RLBL');
    if(!$printer){
                $printer = 'HP-PDF2-TX';
    }
    if(!$media){
                    $media='Tray2';
    }

    my $outputFile = "/tmp/LABEL$classId.pdf";
                ######## send the certificate to the printer

                my $ph;
                open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media  $outputFile");
                close $ph;
                if(-e $outputFile){
                        unlink $outputFile;
                }
}

sub printBlankCertificateForDSMS {
    my $self = shift;
    my $outputFile = '/ids/tools/PRINTING/templates/printing/DSMS_Blank_Certificate.pdf';
    my $printer = 0;
    my $media = 0;
    my $st='NY';   ##########  Default state, we have mentioned as XX;
    my $productId=19;  ##### This is for DSMS
    if(exists $self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{CERT}->{PRINTIERID} &&  $self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{CERT}->{PRINTIERID}){
        my $printerId=$self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{CERT}->{PRINTIERID};
        $printer=$self->{PRINTERS}->{$printerId}->{PRINTER_NAME};
        $media=$self->{PRINTERS}->{$printerId}->{TRAY};
    }else{
        my $printerId=$self->{PRINTERS}->{PRINTINGDATA}->{0}->{XX}->{CERT}->{PRINTIERID};
        $printer=$self->{PRINTERS}->{$printerId}->{PRINTER_NAME};
        $media=$self->{PRINTERS}->{$printerId}->{TRAY};
    }

	system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media $outputFile");
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
        my $retval = { 'CRM_CON' => $mysqlDBH };

        return $retval;
}

sub DESTROY
{   
    #### um...yeah, pretty worthless @ this point  :-)
    my $self = shift;
}

sub prinCOAForDSMS {
    my $self = shift;
    my ($outputFile) = @_;
    my $printer = 0;
    my $media = 0;
    my $st='NY';   ##########  Default state, we have mentioned as XX;
    my $productId=19;  ##### This is for DSMS
    if(exists $self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{CERT}->{PRINTIERID} &&  $self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{CERT}->{PRINTIERID}){
        my $printerId=$self->{PRINTERS}->{PRINTINGDATA}->{$productId}->{$st}->{CERT}->{PRINTIERID};
        $printer=$self->{PRINTERS}->{$printerId}->{PRINTER_NAME};
        $media=$self->{PRINTERS}->{$printerId}->{TRAY};
    }else{
        my $printerId=$self->{PRINTERS}->{PRINTINGDATA}->{0}->{XX}->{CERT}->{PRINTIERID};
        $printer=$self->{PRINTERS}->{$printerId}->{PRINTER_NAME};
        $media=$self->{PRINTERS}->{$printerId}->{TRAY};
    }

        system("/usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media $outputFile");
}

1;
