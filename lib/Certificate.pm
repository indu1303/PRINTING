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

package Certificate;
use strict;
use Symbol;
use MIME::Lite;
use MysqlDB;
use Settings;
use Printing;
use Data::Dumper;
use HTML::Template;
use MIME::Lite;
use IO::File;
use vars qw();

=head1 NAME

Ids::Certificate

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
        #my($stc) = @_;
        my($userId, $product) = @_;


	bless ($self, $class);
	my $dbConnects = $self->_dbConnect();
	if (! $dbConnects)
	{
		die();
	}
	####### ASSERT:  The db connections were successful.  Assign
	$self->{CRM_CON}      = $dbConnects->{CRM_CON};
	$self->{CRM_CON}->do("SET SESSION wait_timeout = 50800");
#	$self->{STC}        = $stc;
	$self->{USERID} = $userId;
	$self->{PRODUCT} = $product;
    	##### let's get some settings
	$self->{SETTINGS} = Settings->new;
	$self->{PRINTERS} = Printing::getPrinters($self);
	return $self;
}

=head2 printCertificate

Actually print out the certificate

=cut

sub printCertificate
{
	my $self = shift;
	my ($userId,$userData,$outputType,$printId,$printerKey,$accompanyLetter,$productId,$rePrintData,$ha)=@_;
	$productId=($productId)?$productId:1;
	my $crsId=$userData->{COURSE_ID};
	if(($productId ==1 && $userData->{COURSE_STATE} eq 'OH' && (!$userData->{COUPON} || ($userData->{COUPON} &&  $userData->{COUPON} ne 'AAA0HC'))) &&( $userData->{RESIDENT_STATE} ne 'NONOH') ) {
		## Set the user for a generic Course..
		$crsId = '56002';
	}
	if($productId ==1 && $userData->{COURSE_STATE} eq 'SC' && $userData->{AAASCCUSER} == 2){
		$crsId = '56002';		
	}
	my $templates=$self->getCourseCertificateTemplate($crsId,$productId);
	if($productId eq '41' && exists $self->{SETTINGS}->{DRIVERSED_COURSE_MAPPING}->{$crsId}){
		$templates=$self->getCourseCertificateTemplate($self->{SETTINGS}->{DRIVERSED_COURSE_MAPPING}->{$crsId},$productId);
	}	
        my $faxEmail=0;
	my $fileMode=0;
	if(($userData->{DELIVERY_ID} && ($userData->{DELIVERY_ID} == '12' || $userData->{DELIVERY_ID} == '13' || $userData->{DELIVERY_ID} == '24')) || $outputType->{FAX} || $outputType->{MYACCOUNT} || (($productId == 3 || $productId == 16) && $outputType->{EMAIL}) || ($productId && $productId==28 && $userData->{DELIVERY_ID} && ($userData->{DELIVERY_ID} == '2'))) {
		$faxEmail=1;
		$faxEmail=($outputType->{FAX})?2:$faxEmail;
	}
	if($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq '24' && $productId && $productId  eq '41') {
		$faxEmail = 0;
	}
	##CRM-623, SS User, Delivery Id 23/24 - Need to print the certificate, no faxing
	if($userData->{DELIVERY_ID} && $productId && $productId == 27 && ($userData->{DELIVERY_ID} == '23' || $userData->{DELIVERY_ID} == '24')) {
		$faxEmail=0;
	}
	if($productId==18) {
		$faxEmail= 0;
		if($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq '12' && $outputType->{EMAIL}) {
			$faxEmail = 1;
		}
	}
	if($productId == 28 && $outputType->{STDOUT}) {
		$faxEmail = 1;
	}
	##For FL Cert Printing check - RT 10371
	if(($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} eq '12' && $userData->{PRINTCHECK}) || ($userData->{DELIVERY_ID} && $productId && $productId eq '28' && $userData->{DELIVERY_ID} == '2' && $userData->{PRINTCHECK})) {
		##Should print the certificates for Email Delivery opted users
		$faxEmail = 0;
	}
	if($productId && $productId==25){
		$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{RESIDENT_STATE}, $userData->{COUNTY_ID},$productId);
	}
	elsif($productId && $productId==27){
		$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{RESIDENT_STATE}, $userData->{COUNTY_ID},$productId,$userData->{COURSE_STATE},$userData->{TABC_WEEKDAY});
	}elsif($productId && $productId==2 && $userData->{COURSE_STATE} eq 'TX'){
		if($userData->{PERMITCERTS}){
			$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{PERMITCERTS});
		}else{
			$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,'',$userData->{REGISTRATION_DATE_FORMAT});
		}
	}elsif($productId && $productId==2 && $userData->{COURSE_STATE} eq 'CO'){
		$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{COURSE_STATE});
	}elsif($productId && $productId==1 && $userData->{COURSE_STATE} eq 'NC'){
			$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{RESIDENT_STATE}, $userData->{COUNTY_ID}, $userData->{AAANCCUSER});
	}elsif($productId && $productId==1 && $userData->{COURSE_STATE} eq 'SC'){
			$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{RESIDENT_STATE}, $userData->{COUNTY_ID},$productId,'', $userData->{AAASCCUSER});
	} elsif($productId && $productId==3) {
		$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{BUNDLE_USER});
	} elsif($productId && $productId==38) {
		$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail, $userData->{CT_240_CLUB}, $userData->{VA_MIDATLANTIC_CLUB}, $userData->{VA_TIDEWATER_CLUB});
	} elsif($productId && $productId==21) {
		$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{AAA_TIDEWATER_CLUB} );
	}else{
		$self->constructor($userId,$templates->{TOP},$templates->{BOTTOM},$faxEmail,$userData->{RESIDENT_STATE}, $userData->{COUNTY_ID}, $productId, $userData->{UPSELLMAIL}, $userData->{UPSELLEMAIL}, $userData->{COURSE_STATE} );
	}
	if($outputType->{FILE}){
		$fileMode=1;
	}
	my ($cert, $pId,$faxCourse,$ps) = $self->_generateCertificate($userId,$userData,$printId,$productId,$rePrintData,$faxEmail,$fileMode);
	my $outputFile = ($templates->{TEMPLATE_TYPE} == 1)?"/tmp/$userId.pdf":'';
	if($outputFile){
		$cert->getCertificate;
	}
	my $emailCertneedtoSentAlongPrinting=0;
	my $emailCertneedtoSenttoDistributor=0;
	if($productId==27 &&  $userData->{COURSE_STATE} eq 'TX'){
		if($outputType->{PRINTER}){
			$emailCertneedtoSentAlongPrinting=1;
		}
	}
	if($productId==27 &&  $userData->{SEND_CERT_TO_DISTRIBUTOR} && $userData->{DISTRIBUTOR_EMAIL}){
		if(!$userData->{CERT_SENT_VIA_EMAIL_TO_DISTRIBUTOR}){
			$emailCertneedtoSenttoDistributor=1;
		}
	}
	if (($productId==1 || $productId==21) && $userData->{COURSE_STATE} eq 'OK' && $userData->{REGULATOR_ID} == $self->{SETTINGS}->{OKLAHOMA_CITY_COURT})
	{
		if (-e $outputFile && -e "/tmp/barcode_$userId.jpg")
		{
			unlink("/tmp/barcode_$userId.jpg");
		}
		else
		{
			unlink($outputFile);
			return 0;
		}
	}
	if(($userData->{DELIVERY_ID} && $userData->{DELIVERY_ID} == 13) || $outputType->{PDF}){
	        if(-e $outputFile){
			my $cmd="/bin/cat  $outputFile";
			my $certData = qx/$cmd/;
        	        unlink $outputFile;
			return $certData;
		}else{
			return 0;
		}
        }

	
	###### ok, we have the certificate.  now, based on the following parameters from when the class
	###### was declared, we're going to do something w/ it:
	###### EMAIL:  Email it to the user
	
	$printerKey = ($printerKey)?$printerKey:'CA';
	if ($outputType->{MYACCOUNT})
	{
		$pId = 1;
		my $cmd = "cp $outputFile /ids/tools/PRINTING/PNG/Certificate/";
                system($cmd);
	}

	if ($outputType->{FAX})
	{
		###### set up the fax number
		my @fileNames;
		my $htmlDoc='';
		if(!$accompanyLetter && $outputType->{FAX} && $faxCourse){
                        my $htmlFileName="/tmp/FAX_COVER_$userId.html";
                        open W ,">$htmlFileName" || die "unable to write to file \n";
                        print W $faxCourse;
                        close W;
			my $pdfCoverFileName="/tmp/FAX_COVER_$userId.pdf";

##### convert this file to PDF
                        my $cmd = <<CMD;
/usr/bin/htmldoc -f $pdfCoverFileName --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 $htmlFileName
CMD

                        $ENV{TMPDIR}='/tmp/';
                        $ENV{HTMLDOC_NOCGI}=1;
                        system($cmd);
                        unlink ($htmlFileName);
			push @fileNames,$pdfCoverFileName;


		}
        
		my $pdfFileName="/tmp/FAX_$userId.pdf";
		my $psFileName="/tmp/FAX_$userId.ps";
		if($templates->{TEMPLATE_TYPE} == 1 && !$faxCourse){
			
			if((($productId == 3 && exists $self->{SETTINGS}->{FAXCOURSE}->{FLEET}->{$userData->{COURSE_ID}}) || ($productId ==1 && $userData->{REGULATOR_ID} == 20021)) || ($productId ==1 && $userData->{RESIDENT_STATE} eq 'NONOH') || $productId == 28 || $productId == 27 || $productId == 29) {
				$pdfFileName=$outputFile;
			}else{
				open W ,">$psFileName" || die "unable to write to file \n";
				print W $ps;
				close W;
				my $cmd="/usr/bin/ps2pdf $psFileName $pdfFileName";
				system($cmd);
				unlink ($psFileName);
			}

		}else{
			$htmlDoc .= $cert;
		}
		if($htmlDoc){
			my $htmlFileName="/tmp/FAX_$userId.html";
			open W ,">$htmlFileName" || die "unable to write to file \n";
			print W $htmlDoc;
			close W;

##### convert this file to PDF
			my $cmd = <<CMD;
/usr/bin/htmldoc -f $pdfFileName --no-numbered --tocheader blank --tocfooter blank --left margin --top margin --webpage  --no-numbered --left .3in --right .3in --fontsize 10 $htmlFileName
CMD

			$ENV{TMPDIR}='/tmp/';
			$ENV{HTMLDOC_NOCGI}=1;
			system($cmd);
			unlink ($htmlFileName);

		}
		push @fileNames,$pdfFileName;
		$self->dbSendFax($outputType->{FAX},@fileNames);
		$pId =1 ;
	}
	if ($outputType->{EMAIL} || $emailCertneedtoSentAlongPrinting || $emailCertneedtoSenttoDistributor)
	{
		###### set up the fax number
	my @fromArr;
	my $fromEmail='';
        my @toArr;
        if ($outputType->{EMAIL} || $emailCertneedtoSentAlongPrinting || $emailCertneedtoSenttoDistributor)
        {
	    if($emailCertneedtoSentAlongPrinting || $emailCertneedtoSenttoDistributor){
		if($emailCertneedtoSenttoDistributor){
            		push @toArr, $userData->{DISTRIBUTOR_EMAIL};
		}
		if($emailCertneedtoSentAlongPrinting || $outputType->{EMAIL}){
	            	push @toArr, $userData->{EMAIL};
		}
	    }else{
		if($emailCertneedtoSenttoDistributor){
            		push @toArr, $userData->{DISTRIBUTOR_EMAIL};
		}
            	push @toArr, $outputType->{EMAIL};
	    }
            ###Here we change the From address for fleet certificate  ###
            if ($productId == 3  && defined $userData->{ACCOUNT_MANAGER_EMAIL} && $userData->{ACCOUNT_MANAGER_EMAIL}) {
            	push @fromArr, 'I DRIVE SAFELY <fleetservice@idrivesafely.com>';
		$fromEmail='fleetservice@idrivesafely.com';
            } elsif ($productId == 26) {
		push @fromArr, 'Canadian Automobile Assocation - <fleetservice@idrivesafely.com>';
		$fromEmail='fleetservice@idrivesafely.com';
            } elsif ($productId == 37) {
		push @fromArr, 'I DRIVE SAFELY - <fleetservice@idrivesafely.ca>';
		$fromEmail='fleetservice@idrivesafely.ca';
            } elsif ($productId == 27) {
		$fromEmail='wecare@sellerserver.com';
		push @fromArr, 'SELLER SERVER - Customer Service <wecare@sellerserver.com>';
	    } elsif ($productId   == 28 || $productId   == 29) {
		$fromEmail='customerservice@aarpdriversafety.org';
		push @fromArr, 'AARP - Customer Service <customerservice@aarpdriversafety.org>';
	    } else {
		$fromEmail='wecare@idrivesafely.com';
            	push @fromArr, 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>';
            }
        }
        my $from    = join(",", @fromArr);
        my $to      = join(",", @toArr);
	my $subject = "Your Notice of Course Completion";
	if($userData->{COURSE_STATE} && $userData->{COURSE_STATE} eq 'FL'){
		#$subject = "Your Certificate of Completion for $userData->{SHORT_DESC}";
		if($userData->{COURSE_ID} eq '10007' || $userData->{COURSE_ID} eq '10010'){
	                 $subject = 'Your Certificate of Completion for First-Time Driver Course (TLSAE/D.A.T.A)';
                }
	}
	if(($productId eq '3' || $productId eq '16' || $productId eq '37') && $userData->{ACCOUNT_MANAGER_EMAIL}) {
		$subject = 'Course Completion Certificate Attached';
	}
	if ($productId eq 26) {
		$subject = 'CAA - Fleet Course Completion Certificate';
	}
        if($productId eq '2' && $userData->{PERMITCERTS}){
                $subject = '6-Hour Permit Qualification Certificate Enclosed';
        }
        my $msg = MIME::Lite->new(From => $from, 
                  To => $to,
                  Cc => ( ($productId eq '3' || $productId eq '16'|| $productId eq '26' || $productId eq '37') && $userData->{ACCOUNT_MANAGER_EMAIL}) ? $userData->{ACCOUNT_MANAGER_EMAIL} : '',
                       Subject => $subject,
                       Type => 'multipart/mixed');
		my $newCoverSheetCheck = 0;
                if (!$accompanyLetter && $templates->{COVERSHEET} && ($outputType->{EMAIL} || $emailCertneedtoSentAlongPrinting || $emailCertneedtoSenttoDistributor))   {
                        #my $from        = "";
                        my $template    = "";

                        $template = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/" . $templates->{COVERSHEET};
			if($userData->{UPSELLEMAIL} && ($productId == 1 || $productId == 2)) {
				if($productId == 1) {
					if($self->{SETTINGS}->{NEW_EMAIL_POC_STATES}->{DIP}->{$userData->{COURSE_STATE}}) {
						$newCoverSheetCheck = 1;
					}
				} elsif($productId == 2) {
					if($self->{SETTINGS}->{NEW_EMAIL_POC_STATES}->{TEEN}->{$userData->{COURSE_STATE}}) {
						$newCoverSheetCheck = 1;
					}
				}
				if($newCoverSheetCheck) {
                        		$template = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/NEW_" . $templates->{COVERSHEET};
				}
			}
			if($productId == 18 && $outputType->{EMAIL}) {
				$newCoverSheetCheck = 1;
			}
                        my $emailTemplate = HTML::Template->new(filename  => $template, die_on_bad_params => 0);

			my ($min,$hour,$mday,$mon,$year,$wday) = (localtime(time()))[1,2,3,4,5,6];
			$mon  =$mon+1;
			$year = $year+1900;
			my $curDate = "$mon/$mday/$year";
			if($newCoverSheetCheck) {
				my $downloadUrl = "";
				if($productId == 1) {
					my $productURL = $printerSite::SITE_PROD_URL;
					my $eUserId = Settings::encryptId($self, $userData->{USER_ID});
					$downloadUrl = "$productURL/course/displayMyAccount.pl?USERID=$eUserId";
				} elsif($productId == 2) {
					my $eUserId = Settings::encryptId($self, $userData->{USER_ID});
					my $productURL = $printerSite::SITE_PROD_TEEN_URL;
					$downloadUrl = "$productURL/course/?rm=displayMyAccount&USERID=$eUserId";
				} elsif($productId == 18) {
					my $eUserId = Settings::encryptId($self, $userData->{USER_ID});
					my $productURL = $printerSite::SITE_PROD_ADULT_URL;
					$downloadUrl = "$productURL/course/displayMyAccount.pl?USERID=$eUserId";
				}
                        	$emailTemplate->param( DOWNLOADLINK	=> $downloadUrl, );
			}

                        $emailTemplate->param( FIRST_NAME   => $userData->{FIRST_NAME} );
                        $emailTemplate->param( COURSE       => $userData->{SHORT_DESC} );
			if( ($productId eq '3' || $productId eq '16' || $productId eq '26' || $productId eq '37') && $userData->{ACCOUNT_MANAGER_EMAIL}) {
	                        $emailTemplate->param( DATEADDED    => $curDate );
        	                $emailTemplate->param( COMPLETIONDATE => $userData->{COMPLETION_DATE} );
                	        $emailTemplate->param( EMAIL        => $userData->{EMAIL} );
				if($productId eq '3' && $userData->{SHORT_DESC} =~ / Course/ig) {
					$userData->{SHORT_DESC} =~ s/ Course//ig;
					$emailTemplate->param( COURSE       => $userData->{SHORT_DESC} );
				}
			}
			if($productId eq '33') {
				##DSMS BTW
	                        $emailTemplate->param( DATEADDED    => $curDate );
        	                $emailTemplate->param( COMPLETIONDATE => $userData->{COMPLETION_DATE} );
                	        $emailTemplate->param( EMAIL        => $userData->{EMAIL} );
			}

			if($userData->{COURSE_STATE} eq 'FL' && $productId ne '28' && !$userData->{UPSELLEMAIL}){
                        	$template = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/flemaildelivery.html";
				if($userData->{COURSE_STATE} eq 'FL' && $productId eq '2' && ($userData->{COURSE_ID} eq '10007' || $userData->{COURSE_ID} eq '10010')){
					$template = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/flemaildeliveryCombo.html";
				}
                        	$emailTemplate = HTML::Template->new(filename  => $template, die_on_bad_params => 0);
                        	$emailTemplate->param( FIRST_NAME   => $userData->{FIRST_NAME} );
                        	$emailTemplate->param( SHORT_DESC       => $userData->{SHORT_DESC} );
				## Encrypt UserId ##
				my $x = int(rand 7) + 2;
				my $y = int(rand 3) + 2;
				my $eUserId =  $x . sprintf('%X', ($userId*$x*$y)) . $y;
				### 
                        	$emailTemplate->param( DATEADDED        => $curDate,
			       			       SITE_URL		=> $printerSite::SITE_PROD_URL,	  		
						       EMAIL		=> $to,
						       USERID		=> $eUserId,
						     );
			}
                         if($productId eq '2' && $userData->{PERMITCERTS}){
                                $template = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/Teen_6Hours_Permit_Certificate.html";
                                $emailTemplate = HTML::Template->new(filename  => $template, die_on_bad_params => 0);
                                $emailTemplate->param( FIRST_NAME   => $userData->{FIRST_NAME} );
                                ## Encrypt UserId ##
                                my $x = int(rand 7) + 2;
                                my $y = int(rand 3) + 2;
                                my $eUserId =  $x . sprintf('%X', ($userId*$x*$y)) . $y;
                                ### 
                                $emailTemplate->param( DATEADDED        => $curDate,
                                                       DUSERID           => $userId,
                                                     );
                        }

                        ####### attach an accompany letter
                        $msg->attach(Type => 'text/html',  Data => $emailTemplate->output       );


                }
        
        	if ($accompanyLetter)	{
	        	#my $from        = "";
	        	my $template    = "";
			my $productName=(exists $self->{SETTINGS}->{PRODUCT_NAME}->{$productId})?$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}:'DIP';
			$template = $self->{SETTINGS}->{TEMPLATESPATH}."/printing/".$productName."_Accompany_Letter.tmpl";

	        	my $accompanyTemplate = HTML::Template->new(filename  => $template,die_on_bad_params => 0);
		        $accompanyTemplate->param( FIRST_NAME   => $userData->{FIRST_NAME} );
        		$accompanyTemplate->param( COURSE       => $userData->{SHORT_DESC} );
		        $accompanyTemplate->param( COURT        => $userData->{REGULATOR_DEF} );

			####### attach an accompany letter
		        $msg->attach(Type => 'text/html',  Data => $accompanyTemplate->output       );

		
		}
			if($productId eq '1' && ($userData->{COURSE_ID} eq '20003' || $userData->{COURSE_ID} eq '20004')){
                                $msg->attach(Type     => 'application/pdf',
                                             Path     => $self->{SETTINGS}->{TEMPLATESPATH}."/printing/DMV_Participant_Approval.pdf",
                                             Filename => 'DMV_Participant_Approval.pdf',
                                             Disposition => 'attachment');

                        }
			if(!$newCoverSheetCheck) { ##ISE-164
			if($templates->{TEMPLATE_TYPE} == 1){
	            			$msg->attach(Type    => 'application/pdf',
                                	     Path     =>$outputFile,
	                                     Filename =>'certificate.pdf',
        	                             Disposition => 'attachment');
			}else{
            			$msg->attach(Type    => 'text/html',
                                	     Data     =>$cert,)
			}
			}

			$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f ' . $fromEmail);
			#$msg->send('smtp', '192.168.1.214');
			if(!($emailCertneedtoSentAlongPrinting || $emailCertneedtoSenttoDistributor)){
				$pId =1 ;
			}
	}
	if ($outputType->{FILE} && $outputFile)
	{
		####### print this certificate to a file
			return $pId;
	}
	if ($outputType->{DOWNLOAD} && $outputFile)
	{
		####### DE Users, Download option seelcted
			return $pId;
	}
	if ($outputType->{STDOUT} && $outputFile)
	{
		######## default case.  Output to STDOUT
		#system("/bin/cat  $outputFile");
		#$pId =1 ;
		if($productId == 28 && $outputType->{STDOUT} && $outputType->{STDOUT} eq '1' && $userData->{COURSE_STATE} && $userData->{COURSE_STATE} ne 'CA' && $userData->{COURSE_STATE} ne 'NY') {
			##AARP Download certificate
			my $outputFileName = "/ids/tools/PRINTING/WebService/pl/.download/AARP/$userId.pdf";
			if(-e $outputFileName) {
				unlink($outputFileName);
			}
			system("mv $outputFile $outputFileName");
			##Now, conert the pdf to image
			my $jpgFile = "/ids/tools/PRINTING/WebService/pl/.download/AARP/$userId.jpg";
			#$jpgFile = "$userId.jpg";
			system("/usr/bin/convert -density 300 $outputFileName -quality 70 $jpgFile");
			##Now, convert the image to pdf
			system("/usr/bin/convert -density 300 $jpgFile -quality 70 $outputFileName");
			system("/usr/bin/chmod 775 $outputFileName");
			##Now, remove the jpg image
			#unlink($jpgFile);

			if(-e $outputFileName){
				#my $certData = qx{/bin/cat  $outputFileName};
				#unlink $outputFileName;
				#print STDERR "\n$outputFileName -- \n";
				#use MIME::Base64;
				#return encode_base64($certData);
				return "/.download/AARP/$userId.pdf";
			}
		} else {
			my $outputContent = qx{/bin/cat  $outputFile};
			return $outputContent;
		}
	}
	if (($outputType->{PRINTER} && $outputFile) || ( ! $outputType->{STDOUT} && ! $outputType->{FILE} && ! $outputType->{EMAIL} && ! $outputType->{FAX} && !$outputType->{DOWNLOAD} ))
	{
		######## send the certificate to the printer
		my $printer = 0;
		my $media = 0;
		my $st='XX';   ##########  Default state, we have mentioned as XX;
		$st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
    		if ($userData->{UPSELLMAIL} || ($productId == 1 && !$userData->{UPSELLEMAIL} && $userData->{COURSE_STATE} eq 'CA'))
		{
			($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'POC');
		}
		elsif ($userData->{PERMITCERTS})
               {
                       ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT');
               }
		elsif (($productId == 1 || $productId == 21)&& $userData->{COURSE_STATE} eq 'OK'  && $userData->{REGULATOR_ID} && $userData->{REGULATOR_ID} == $self->{SETTINGS}->{OKLAHOMA_CITY_COURT}) {
			($printer,$media)=Settings::getPrintingDetails($self, $productId, 'XX','POC');
        	} elsif($productId == 41 && $userData->{COURSE_ID} eq 'C0000020') {
			($printer,$media)=Settings::getPrintingDetails($self, $productId, 'TT','CERT');
			#($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERTWHITEPAPER');
		}
		else
		{
			my $printerLabel = 'CERT';
			if(exists $self->{SETTINGS}->{CERTIFICATE_ON_WHITE_PAPER}->{$productId}->{$userData->{COURSE_ID}}) {
				$printerLabel = 'CERTWHITEPAPER';
			}
			($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,$printerLabel);
		}
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
		my $certType = 'RED_CERT';
		if(($userData->{COURSE_ID} eq '5001' || $userData->{COURSE_ID} eq '5002' || $userData->{COURSE_ID} eq '5003' || $userData->{COURSE_ID} eq '5013') && ($productId == 2 || $productId == 32)){
			open ($ph,  "| /usr/bin/lp -o nobanner  -q 1 -d $printer -o media=$media $outputFile");
			$certType = 'CATEEN_CERT';
		}elsif($userData->{COURSE_ID} eq '6002' && $productId == 2){
			open ($ph,  "| /usr/bin/lp -o nobanner  -q 1 -d $printer -o media=$media $outputFile");
			$certType = 'COTEEN_CERT';
		}elsif($userData->{COURSE_ID} eq '44003' && $productId == 2){
			my $loginDate=$userData->{LOGIN_DATE};
	                $loginDate =~ s/(\-|\ |\:)//g;
			if($loginDate<20121001000000){
                       		($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERT');
			}else{
                       		($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'PERMITCERT');
			}
			open ($ph,  "| /usr/bin/lp -o nobanner  -q 1 -d $printer -o media=$media $outputFile");
			$certType = 'TXTEEN_CERT';
		}elsif(($userData->{COURSE_ID} eq '44004' || $userData->{COURSE_ID} eq '44005')  && $productId == 18){
			open ($ph,  "| /usr/bin/lp -o nobanner  -q 1 -d $printer -o media=$media $outputFile");
			$certType = 'TXADULT_CERT';
		}elsif(($userData->{COURSE_ID} eq '200005' || $userData->{COURSE_ID} eq '100005' || $userData->{COURSE_ID} eq '400005') && $productId == 8){
			open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media $outputFile");
			$certType = 'CAMATURE_CERT';
		} elsif ($productId == 28 && ($userData->{COURSE_ID} eq '5001' || $userData->{COURSE_ID} eq '5002' || $userData->{COURSE_ID} eq '5003' || $userData->{COURSE_ID} eq '5011' || $userData->{COURSE_ID} eq '5012')) {
			open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media  $outputFile");
			$certType = 'CAAARP_CERT';
		} else{
			open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer  -o media=$media $outputFile");
		}
		close $ph;
		if (exists $self->{SETTINGS}->{WHITE_PAPER_CERTS}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}} && exists $self->{SETTINGS}->{WHITE_PAPER_CERTS}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$st})
		{
			$certType = "";	
		}
		my $productName = $self->{SETTINGS}->{PRODUCT_NAME}{$productId};
		if (exists $self->{SETTINGS}->{HOSTED_AFFILIATE_PRODUCT_ID}{$productName})
		{
			$certType = 'BLUE_CERT';
		}
		if ($certType)
		{
        		$self->updateCertsStock($self->{SETTINGS}->{CERT_ORDERS_MAP}->{$certType});
			if (($certType eq 'RED_CERT' || $certType eq 'BLUE_CERT') && !exists $self->{SETTINGS}->{PREMIUMDELIVERY}->{$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}}->{$userData->{DELIVERY_ID}})
			{
        			$self->updateCertsStock(1);
			}
		}
	}
#	$cert->end;
	if(-e $outputFile){
		unlink $outputFile;
	}
	return $pId;
}

=head2 printMultipleCertificate

Actually print out the mutiple certificate

=cut

sub printMultipleCertificate
{
	my $self = shift;
	my ($userId,$userData,$printId,$userId_1,$userData_1,$printId_1,$outputType,$printerKey,$productId,$ha)=@_;
	$productId=($productId)?$productId:1;
	my $templates=$self->getCourseCertificateTemplate($userData->{COURSE_ID},$productId);
        if(!$userId_1){
                $templates->{BOTTOM}='blank_court.pdf';
        }else{
		$self->{STC}=1;
	}
        $self->constructor($userId,$templates->{TOP},$templates->{BOTTOM});

	my ($cert, @pId) = $self->_generateMultipleCertificate($userId,$userData,$printId,$userId_1,$userData_1,$printId_1,$productId);
        $cert->getCertificate;
	my $outputFile="/tmp/$userId.pdf";
	

	###### ok, we have the certificate.  now, based on the following parameters from when the class
	###### was declared, we're going to do something w/ it:
	###### EMAIL:  Email it to the user
	
	$printerKey = ($printerKey)?$printerKey:'CA';

	if ($outputType->{EMAIL} || $outputType->{FAX})
	{
		###### set up the fax number
	my @fromArr;
	my @toArr;
	if ($outputType->{FAX})
	{
		my @fileNames;
     		if($productId ==1 && $userData->{REGULATOR_ID} == 20021) {
                                push @fileNames, $outputFile;
				$self->dbSendFax($outputType->{FAX},@fileNames);
		}
	}else{
       		if ($outputType->{EMAIL})
        	{
	            push @toArr, $outputType->{EMAIL};
		    push @fromArr, 'I DRIVE SAFELY - Customer Service <wecare@idrivesafely.com>';
        	}

	        my $from    = join(",", @fromArr);
        	my $to      = join(",", @toArr);

	        my $msg = MIME::Lite->new(From => $from, 
        	          To => $to,
                	       Subject => 'Your Notice of Course Completion',
	                       Type => 'multipart/mixed');
        	    	$msg->attach(Type    => 'application/pdf',
                	        	Filename => 'certificate.pdf',
					Path     =>$outputFile,
					Disposition => 'attachment');
   
			$msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f wecare@idrivesafely.com');
		}
	}
	if ($outputType->{FILE})
	{
	
		####### print this certificate to a file
	       system("/bin/mv $outputFile $outputType->{FILE}");
        }
        if ($outputType->{STDOUT})
        {
                ######## default case.  Output to STDOUT
                system("/bin/cat  $outputFile");
	}
	if ($outputType->{PRINTER} || ( ! $outputType->{STDOUT} && ! $outputType->{FILE} && ! $outputType->{EMAIL} && ! $outputType->{FAX} ))
	{
		my $printer = 0;
		my $media = 0;
		my $st='XX';   ##########  Default state, we have mentioned as XX;
                $st=($userData->{COURSE_STATE})?$userData->{COURSE_STATE}:$st;
	        ($printer,$media)=Settings::getPrintingDetails($self, $productId, $st,'CERT');
                if(!$printer){
                        $printer = 'HP-PDF-HOU05';
                }
                if(!$media){
                        $media='Tray3';
                }

		if (! $printer)
		{
			###### error out.....printer is not set
			@pId=();	
		}

		my $ph = gensym;
		open ($ph,  "| /usr/bin/lp -o nobanner -q 1 -d $printer -o media=$media $outputFile");
		close $ph;
	}
	if(-e $outputFile){
		unlink $outputFile;
	}
	return @pId;
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

=head2 _generateCertificate

Sets the parameters and all variable text for each individual cert.  In the end, the only thing that
really needs to be set is the user data

=cut

sub _generateCertificate
{
	#### since this is the base class, it's pretty worthless for now   :-)
	my $self = shift;
	return 1;
}

=head2 getCertificateHeader

Return the header from the header id

=cut

sub getCertificateHeader
{
	my $self = shift;
	my ($headerId) = @_;

    ##### Let's see if we already have this header in memory
    if (! exists $self->{CERTIFICATE_HEADER}->{$headerId})
    {
	    $self->{CERTIFICATE_HEADER}->{$headerId} = 
            $self->{CRM_CON}->selectrow_array("select header from printing_header where header_id= ?", {}, $headerId);
    }

	##### return the appropriate header
    return $self->{CERTIFICATE_HEADER}->{$headerId};
}

=head2 getCertificateDisclaimer

Return the disclaimer for the certificate

=cut

sub getCertificateDisclaimer
{
	my $self = shift;
	my ($disclaimerId) = @_;

    ##### Let's see if we already have this header in memory
    if (! exists $self->{CERTIFICATE_DISCLAIMER}->{$disclaimerId})
    {
	    $self->{CERTIFICATE_DISCLAIMER}->{$disclaimerId} = 
            $self->{CRM_CON}->selectrow_array("select disclaimer from printing_disclaimer where disclaimer_id= ?", 
                            {}, $disclaimerId);
    }

	##### return the appropriate header
    return $self->{CERTIFICATE_DISCLAIMER}->{$disclaimerId};
}


=head2 getCertificateSignature

Return the signature for the certificate

=cut

sub getCertificateSignature
{
	my $self = shift;
	my ($signatureId) = @_;

    ##### Let's see if we already have this header in memory
    if (! exists $self->{CERTIFICATE_SIGNATURE}->{$signatureId})
    {
	    my @row = $self->{CRM_CON}->selectrow_array("select * from printing_signature where signature_id = ?", 
                            {}, $signatureId);

        $self->{CERTIFICATE_SIGNATURE}->{$signatureId}->{INSTRUCTOR} = $row[1];
        $self->{CERTIFICATE_SIGNATURE}->{$signatureId}->{INSTRUCTOR_SIGNATURE} = $row[2];
        $self->{CERTIFICATE_SIGNATURE}->{$signatureId}->{STUDENT_SIGNATURE} = $row[3];
        $self->{CERTIFICATE_SIGNATURE}->{$signatureId}->{X_OFFSET} = $row[4];
    }

	##### return the appropriate header
    return $self->{CERTIFICATE_SIGNATURE}->{$signatureId};
}


=head2 getCertificateField

Return the field information from the field id

=cut

sub getCertificateField
{
	my $self = shift;
	my ($fieldId) = @_;

	##### Let's see if we already have this definition.  
        my $rowData = $self->{CRM_CON}->selectrow_hashref("select * from printing_fields where field_id= ?", {}, $fieldId);
        
        $self->{CERTIFICATE_FIELD}->{$fieldId}->{DEFINITION} 	= $rowData->{definition};	
        $self->{CERTIFICATE_FIELD}->{$fieldId}->{DEFAULT} 	    = $rowData->{default};	
        $self->{CERTIFICATE_FIELD}->{$fieldId}->{XPOS} 		    = $rowData->{xpos};	
        $self->{CERTIFICATE_FIELD}->{$fieldId}->{DATA_MAP} 		= $rowData->{data_map};	
        $self->{CERTIFICATE_FIELD}->{$fieldId}->{CITATION} 		= $rowData->{citation};	

	##### return the appropriate field information based on the field id
	##### return the field data
	return $self->{CERTIFICATE_FIELD}->{$fieldId};
}

=head2 getCourseCertificateLayout

Return the certificate layout for the course id

=cut

sub getCourseCertificateLayout
{
	my $self = shift;
	my ($courseId,$productId) = @_;
        $productId=($productId)?$productId:1;

	###### get a list of all the fields for this particular course
	######
	###### Let's see if we already have it defined
#	if (exists $self->{COURSE_FIELDS}->{$courseId})
#	{
#		return $self->{COURSE_FIELDS}->{$courseId};
#	}

    ###### ok, it's not defined, but is it aliased?
    my $alias = $self->getCourseCertificateAlias($courseId,$productId);
    if ($alias)
    {
        #### this certificate is aliased.  let's get the alias layout and assign it to this course id 
        my $aliasLayout = $self->getCourseCertificateLayout($alias,$productId);
        %{$self->{COURSE_FIELDS}->{$courseId}} = %{$self->{COURSE_FIELDS}->{$alias}};
		
        return $self->{COURSE_FIELDS}->{$courseId};
    }

    ##### ASSERT:  We don't have the course layout already in storage and the course is not aliased.
    ##### Let's go ahead and set up the layout and return it

        ###### Checking For course is exists or not
        my $count=$self->{CRM_CON}->selectrow_array("select count(*) from printing_course_fields where course_id = ? and product_id=?",{},$courseId,$productId);
	my $productName=(exists $self->{SETTINGS}->{PRODUCT_NAME}->{$productId})?$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}:'DIP';
	$productName=(!$productName)?'DIP':$productName;
	$self->{PRODUCT}=$productName;
        if((!$count || $count == 0) && !(exists $self->{SETTINGS}->{TEXASPRINTING}->{$productName}->{$courseId} && $self->{SETTINGS}->{TEXASPRINTING}->{$productName}->{$courseId} eq 'TX')){
		my $cId = $self->{CRM_CON}->selectrow_array("select course_id from printing_course_templates  where product_id=? and default_course_id=?",{},$productId,1);
		$courseId = $cId;
	}

	##### let's get the fields from the database
	my $sql = $self->{CRM_CON}->prepare("select field_id, rank from printing_course_fields where course_id = ? and product_id=?");
	$sql->execute($courseId,$productId);
	undef $self->{COURSE_FIELDS}->{$courseId}->{FIELDS};
	while (my ($fieldId, $rank) = $sql->fetchrow)
	{
	    	$self->{COURSE_FIELDS}->{$courseId}->{FIELDS}->{$rank} = $fieldId;
	}
	
	
	my @header = $self->{CRM_CON}->selectrow_array("select header_id from printing_course_header where course_id = ?  and product_id=?", {}, $courseId,$productId);
	$self->{COURSE_FIELDS}->{$courseId}->{HEADER} = $header[0];
	
    my @disclaimer = $self->{CRM_CON}->selectrow_array("select disclaimer_id from printing_course_disclaimer where course_id = ?  and product_id=?", {}, $courseId,$productId);
	$self->{COURSE_FIELDS}->{$courseId}->{DISCLAIMER} = $disclaimer[0];
    
    my @signature = $self->{CRM_CON}->selectrow_array("select signature_id from printing_course_signature where course_id = ?  and product_id=?", {}, $courseId,$productId);
	$self->{COURSE_FIELDS}->{$courseId}->{SIGNATURE} = $signature[0];

	
	###### the values are in.  Return them
	return $self->{COURSE_FIELDS}->{$courseId};
}


=head2 getCourseCertificateAlias

Get an alias layout for a particular certificate

=cut

sub getCourseCertificateAlias
{
	my $self = shift;
	my ($courseId,$productId) = @_;

	##### return the appropriate field information based on the field id
	my $sql = $self->{CRM_CON}->selectrow_hashref("select alias_course_id from printing_course_alias where course_id = ? and product_id=?", 
                                                {}, $courseId,$productId);
	
	##### return the field data
	return ($sql->{alias_course_id}) ? $sql->{alias_course_id} : 0;
}

sub _printAddress
{
    my $self = shift;
    my ($yPos, $userData, $xPos) = @_;
    if (!$xPos) { 
	$xPos = 60;
    }
    my $xDiff=0;
    ###### define the line spacing, set the font, then print out the address
    my $LINESPACE = 14;
    $self->{PDF}->writeLine( $xPos-$xDiff, $yPos, $userData->{FIRST_NAME} . ' ' . $userData->{LAST_NAME} ); 
    $yPos       -= $LINESPACE;
    $self->{PDF}->writeLine( $xPos-$xDiff, $yPos, $userData->{ADDRESS_1} ); 
    $yPos       -= $LINESPACE;
    if ($userData->{ADDRESS_2})
    {
    $self->{PDF}->writeLine( $xPos-$xDiff, $yPos, $userData->{ADDRESS_2} ); 
    $yPos       -= $LINESPACE;
    }
    $self->{PDF}->writeLine( $xPos-$xDiff, $yPos, $userData->{CITY} . ', ' . $userData->{STATE} . '  ' . $userData->{ZIP} ); 

    return $yPos;
}

sub _printSignature
{
    my $self = shift;
    my ($yPos, $signatureId,$signature,$noByText) = @_;
    my $xDiff=0;
    my $certificateSig = $self->getCertificateSignature($signatureId);

    if ($certificateSig->{STUDENT_SIGNATURE})
    {
        $self->{PDF}->writeLine ( 350-$xDiff, $yPos,'Student Signature:_______________________________');
        $yPos -= 40;
    }

    if($noByText) {
	##No By Text, sometimes not required to display 'By:'
    } else {
    	##### put in a "by:"
	$self->{PDF}->writeLine( 350-$xDiff, $yPos, 'By:' );
    }

    if($signature && $signature eq '1'){
		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/CStokes-Signature.jpg",
                                360-$xDiff, $yPos-10, 68, 34,500,270);
    } elsif($signature && $signature eq '2') {
		$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/TonyGentile-Signature.jpg",
                                360-$xDiff, $yPos-10, 68, 34,500,270);
    }else{
	    	$self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/sig.jpg", 
                                360-$xDiff, $yPos-10, 105, 35,1050,305);
    }


    if ($certificateSig->{X_OFFSET})
    {
        $self->{PDF}->writeLine( $certificateSig->{X_OFFSET}-$xDiff, 
                                 $yPos, 
                                 $certificateSig->{INSTRUCTOR} );
    }
    else
    {
        $yPos -= 15;
        $self->{PDF}->writeLine( 350-$xDiff, 
                                $yPos, 
                                $certificateSig->{INSTRUCTOR} );
    }

}

sub _printCorporateAddress
{
    my $self = shift;
    my ($xPos,$yPos, $OFFICE,$domain, $phone) = @_;
    my $xDiff=0;
    my $helvetica       = 'HELVETICA';
    $self->{PDF}->setFont($helvetica, 8);
    $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{ADDRESS});
    if($OFFICE->{ADDRESS_2}){
    	$yPos -=10;
	$self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{ADDRESS_2});
    }
    $yPos -=10;
    $self->{PDF}->writeLine($xPos, $yPos, "$OFFICE->{CITY}, $OFFICE->{STATE} $OFFICE->{ZIP}");
    if($domain){
    	$yPos -=10;
	$self->{PDF}->writeLine($xPos, $yPos, $domain);
	$yPos -=11;
	if($phone) {
		$self->{PDF}->writeLine($xPos, $yPos, $phone);
	} else {
		$self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{PHONE});
	}
    }else{
	$yPos -=11;
	if($phone) {
		$self->{PDF}->writeLine($xPos, $yPos, $phone);
	} else {
		$self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{PHONE});
	}
    }

}

sub _printCorporateAddressReverse
{
    my $self = shift;
    my ($xPos,$yPos, $OFFICE,$domain) = @_;
    my $xDiff=0;
    my $helvetica       = 'HELVETICA';
    $self->{PDF}->setFont($helvetica, 8);
    $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{ADDRESS},180);
    $yPos +=10;
    $self->{PDF}->writeLine($xPos, $yPos, "$OFFICE->{CITY}, $OFFICE->{STATE} $OFFICE->{ZIP}",180);
    if($domain){
        $yPos +=10;
        $self->{PDF}->writeLine($xPos, $yPos, $domain,180);
        $yPos +=11;
        $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{PHONE},180);
    }else{
        $yPos +=11;
        $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{PHONE},180);
    }

}


sub _printCorporateAddress2
{
    my $self = shift;
    my ($xPos,$yPos, $OFFICE,$domain) = @_;
    my $xDiff=0;
    my $helvetica       = 'HELVETICABOLD';
    $self->{PDF}->writeLine($xPos, $yPos+10, $domain);
    $helvetica       = 'HELVETICA';
    $self->{PDF}->setFont($helvetica, 8);
    $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{ADDRESS});
    if($OFFICE->{ADDRESS_2}){
        $yPos -=10;
        $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{ADDRESS_2});
    }
    $yPos -=10;
    $self->{PDF}->writeLine($xPos, $yPos, "$OFFICE->{CITY}, $OFFICE->{STATE} $OFFICE->{ZIP}");
    $yPos -=11;
    $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{PHONE});

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

sub _generateFixedData {
        my ($userData) = @_;
        my %fixedData;
        my %fixedDataArr=(      drivers_license    => 'DRIVERS_LICENSE',
                                first_name         => 'FIRST_NAME',
                                last_name          => 'LAST_NAME',
                                dob                => 'DATE_OF_BIRTH',
                                address_1          => 'ADDRESS_1',
                                address_2          => 'ADDRESS_2',
                                city               => 'CITY',
                                state              => 'STATE',
                                zip                => 'ZIP',
                                phone              => 'PHONE',
                                certificate_number => 'CERTIFICATE_NUMBER',
                                completion_date    => 'COMPLETION_DATE',
                                delivery           => 'DELIVERY_DEF',
                                course_desc        => 'SHORT_DESC',
                                county             => 'COUNTY_DEF',
                                regulator          => 'REGULATOR_DEF',
                                state_id           => 'COURSE_STATE',
                                delivery_id        => 'DELIVERY_ID',
                                affiliate_id       => 'HOSTED_AFFILIATE',
                                da_name            => 'DA_NAME',
                                instructor_name    => 'INSTRUCTOR_NAME',
                                account_name       => 'ACCOUNT_NAME',
                        );
        foreach my $fieldId(keys %fixedDataArr){
                if($userData->{$fixedDataArr{$fieldId}}){
                        my $data=$userData->{$fixedDataArr{$fieldId}};
			if($fieldId eq 'delivery_id' && !$data){
				$data=1;
			}
                        $data =~ s/\'//g;
                        $fixedData{$fieldId}= $data ;
                }
        }
        return \%fixedData;
}

sub maxLineWidth
{
    my ($line) = @_;

    ###### maximum character length for the court row is 25 characters.  anymore
    ###### and we're going to split the line
    my $mainLine = "";
    my $rem = "";

    if (length($line) > 30)
    {
        my @regNameArray = split(/ /, $line);
        my $regField = 0;

        while (length($mainLine) <= 30)
        {
            my $tmp = $mainLine . $regNameArray[$regField] . " ";
            if (length($tmp) <= 30)
            {
                $mainLine .= $regNameArray[$regField] . " ";
                ++$regField;
            }
            else
            {
                last;
            }
        }
        while ($regField < @regNameArray)
        {
            $rem .= $regNameArray[$regField] . " ";
            ++$regField;
        }
    }
    else
    {
        $mainLine = $line;
    }


    my $retval = { MAINLINE => $mainLine, REM => $rem };
    return $retval;
}

sub getCourseCertificateTemplate
{
        my $self = shift;
        my ($courseId,$productId) = @_;
        $productId=($productId)?$productId:1;
        ###### ok, it's not defined, but is it aliased?
        my $alias = $self->getCourseCertificateAlias($courseId,$productId);
	if($alias){
		$courseId=$alias;
	}
        ###### get a all template/type  for this particular course
        ######
        ###### Let's see if we already have it defined
        if (exists $self->{COURSE_TEMPLATES}->{$productId}->{$courseId})
        {
                return $self->{COURSE_TEMPLATES}->{$productId}->{$courseId};
        }
	my $count=$self->{CRM_CON}->selectrow_array("select count(*) from printing_course_fields where course_id = ? and product_id=?",{},$courseId,$productId);
	my $productName=(exists $self->{SETTINGS}->{PRODUCT_NAME}->{$productId})?$self->{SETTINGS}->{PRODUCT_NAME}->{$productId}:'DIP';
        $productName=(!$productName)?'DIP':$productName;
        if((!$count || $count == 0) && !(exists $self->{SETTINGS}->{TEXASPRINTING}->{$productName}->{$courseId} && $self->{SETTINGS}->{TEXASPRINTING}->{$productName}->{$courseId} eq 'TX')){
                my $cId = $self->{CRM_CON}->selectrow_array("select course_id from printing_course_templates  where product_id=? and default_course_id=?",{},$productId,1);
                $courseId = $cId;
        }

        my $sql = $self->{CRM_CON}->prepare("select top_template,bottom_template,coversheet_template,template_type_id  from printing_course_templates where course_id = ? and product_id=?");         
        $sql->execute($courseId,$productId);
        while (my ($top,$bottom,$coverSheet,$type) = $sql->fetchrow)
        {
                $self->{COURSE_TEMPLATES}->{$productId}->{$courseId}->{TOP} = $top;
                $self->{COURSE_TEMPLATES}->{$productId}->{$courseId}->{BOTTOM} = $bottom;
                $self->{COURSE_TEMPLATES}->{$productId}->{$courseId}->{COVERSHEET}=$coverSheet;
                $self->{COURSE_TEMPLATES}->{$productId}->{$courseId}->{TEMPLATE_TYPE}=$type;
        }

	return $self->{COURSE_TEMPLATES}->{$productId}->{$courseId};

}



=head2 getCourseMiscellaneousData

Return the field information from the field id

=cut

sub getCourseMiscellaneousData
{
        my $self = shift;
        my ($fieldId,$courseId,$productId) = @_;

        ##### Let's see if we already have this definition.
        my $alias = $self->getCourseCertificateAlias($courseId,$productId);
        my $rowData = $self->{CRM_CON}->selectrow_hashref("select * from printing_course_miscellaneous_data where field_id= ?and course_id = ? and product_id = ?", {}, $fieldId,$courseId,$productId);
	if(!$rowData->{value}){
        	if($alias){
                	$courseId=$alias;
        	}
        	$rowData = $self->{CRM_CON}->selectrow_hashref("select * from printing_course_miscellaneous_data where field_id= ?and course_id = ? and product_id = ?", {}, $fieldId,$courseId,$productId);
	}
	if($rowData->{value}){
       		$self->{CERTIFICATE_FIELD}->{$fieldId}->{DEFAULT}           = $rowData->{value};
	}

        ##### return the appropriate field information based on the field id
        ##### return the field data
        return $self->{CERTIFICATE_FIELD}->{$fieldId};
}

sub getFile {
        my $self = shift;
	my ($file) = @_;
	my $fh   = IO::File->new( $file );
	my $content;
	while( <$fh> ) {
		$content .= $_;
	}
	return $content;
}

sub dbSendFax {
        my $self = shift;
        my ($faxNumber,@fileNames) =@_;

        if(length($faxNumber)>10 && substr($faxNumber,0,1) eq '1'){
                $faxNumber=substr($faxNumber,1);
        }
        $faxNumber =~ s/(\s+|\(|\)|\-|\.)//ig;
        my $to  = $faxNumber.'@rcfax.com';

        my $msg = MIME::Lite->new(
                From    => 'I Drive Safely <reports@idrivesafely.com>',
                To      => $to,
                Subject => "Fax to $faxNumber",
                Type    => 'multipart/mixed'
        );

        foreach my $filePath(@fileNames) {
                my $fileName = $filePath;
                $fileName =~ s/\/tmp\///ig;

                $msg->attach(Type => 'application/pdf',
                                Path     => $filePath,
                                Filename => $fileName,
                                Disposition => 'attachment'
                );
        }
        $msg->send('sendmail', '/usr/lib/sendmail -t -oi -oem -f reports@idrivesafely.com');
}

sub _printHorzCorporateAddress
{
    my $self = shift;
    my ($ref) = @_;
    my ($xPos,$yPos, $OFFICE,$domain, $separator, $phone);
    $xPos = $ref->{X};
    $yPos = $ref->{Y};
    $OFFICE = $ref->{OFFICE};
    $domain = $ref->{DOMAIN};
    $separator = $ref->{SEPARATOR};
    $phone = $ref->{PHONE};
    my $xDiff=0;
    my $helvetica       = 'HELVETICA';
    $self->{PDF}->setFont($helvetica, 10);
    my $data = $OFFICE->{NAME}." $separator ".$OFFICE->{ADDRESS}. " $separator "."$OFFICE->{CITY}, $OFFICE->{STATE} $OFFICE->{ZIP}";
    if ($domain)
    {
	$data .= " $separator ".$domain;
    }
    if ($phone)
    {
	$data .= " $separator ".$OFFICE->{PHONE};
    }
    $self->{PDF}->writeLine($xPos, $yPos, $data);
}

sub updateCertsStock
{
        my $self = shift;
        my ($itemId) = @_;

        if ($itemId)
        {       
                my @Stock = $self->{CRM_CON}->selectrow_array("SELECT CURRENT_STOCK,ITEMS_PER_PACKAGE FROM stock_items WHERE ITEM_ID = ?", {}, $itemId);
                my $currentStock = $Stock[0];
                my $Items = $Stock[1];
                my $temp=0; 
                if ($currentStock && ($Items == 0))
                {
                        $currentStock-=1;
                        $self->{CRM_CON}->do("UPDATE stock_items set CURRENT_STOCK = $currentStock WHERE ITEM_ID = $itemId");
                } else {
                        $temp = ($currentStock * $Items) - 1;
			if($Items>0){
                        	$currentStock = (($temp) / ($Items));
	                        $self->{CRM_CON}->do("UPDATE stock_items set CURRENT_STOCK = $currentStock WHERE ITEM_ID = $itemId");
			}
                }

        }
}

sub _printVertCorporateAddress
{
    my $self = shift;
    my ($xPos,$yPos, $OFFICE,$domain) = @_;
    my $xDiff=0;
    my $helvetica       = 'HELVETICA';
    $self->{PDF}->setFont($helvetica, 8);
    $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{ADDRESS});
    if ($OFFICE->{ADDRESS1}) {
	    $yPos -=10;
	    $self->{PDF}->writeLine($xPos, $yPos, $OFFICE->{ADDRESS1});
            $yPos -=11;
            $self->{PDF}->writeLine($xPos, $yPos, "$OFFICE->{CITY}, $OFFICE->{STATE} $OFFICE->{ZIP}");
            if($domain){
                $yPos -=11;
                $self->{PDF}->writeLine($xPos, $yPos, $domain);
                $yPos -=12;
                $self->{PDF}->writeLine($xPos, $yPos, "TOLL FREE: ".$OFFICE->{PHONE});
            }else{
                $yPos -=12;
                $self->{PDF}->writeLine($xPos, $yPos, "TOLL FREE: ".$OFFICE->{PHONE});
            }
    } else {
	    $yPos -=10;
	    $self->{PDF}->writeLine($xPos, $yPos, "$OFFICE->{CITY}, $OFFICE->{STATE} $OFFICE->{ZIP}");
	    if($domain){
        	$yPos -=10;
	        $self->{PDF}->writeLine($xPos, $yPos, $domain);
        	$yPos -=11;
	        $self->{PDF}->writeLine($xPos, $yPos, "TOLL FREE: ".$OFFICE->{PHONE});
	    }else{
        	$yPos -=11;
	        $self->{PDF}->writeLine($xPos, $yPos, "TOLL FREE: ".$OFFICE->{PHONE});
	    }
    }

}

sub _printIDSLogo
{
    my $self = shift;
    my ($xPos, $yPos) = @_;
    $self->{PDF}->genImage($self->{SETTINGS}->{TEMPLATESPATH}."/printing/images/idrivesafely_logo.jpg", $xPos, $yPos, 60, 62,80,82);
}

sub _printHorzCorporateAddressDisplay
{
    my $self = shift;
    my ($ref) = @_;
    my ($xPos,$yPos, $OFFICE,$domain, $separator, $phone, $phoneNumber);
    $xPos = $ref->{X};
    $yPos = $ref->{Y};
    $OFFICE = $ref->{OFFICE};
    $domain = $ref->{DOMAIN};
    $separator = $ref->{SEPARATOR};
    $phone = $ref->{PHONE};
    $phoneNumber = $ref->{PHONE_NUMBER};
    my $xDiff=0;
    my $helvetica       = 'HELVETICA';
    $self->{PDF}->setFont($helvetica, 9);
    my $data = $OFFICE->{NAME}." $separator ".$OFFICE->{ADDRESS}. " $separator "."$OFFICE->{CITY}, $OFFICE->{STATE} $OFFICE->{ZIP}";
    if ($domain)
    {
        $data .= " $separator ".$domain;
    }
    if ($phone)
    {
	if($phoneNumber) {
        	$data .= " $separator ".$phoneNumber;
	} else {
        	$data .= " $separator ".$OFFICE->{PHONE};
	}
    }
    $self->{PDF}->writeLine($xPos, $yPos, $data);
}



=pod

head1 AUTHOR

hari@ed-ventures-online.com

=head1 SVN INFO

=item $URL: http://galileo/svn/PRINTING/trunk/lib/Certificate.pm $

=item $Author: harib $

=item $Date: 2009-12-03 07:27:40 $

=item $Rev: 71 $

=cut

1;
