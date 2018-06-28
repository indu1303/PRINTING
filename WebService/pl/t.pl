#!/usr/bin/perl -w 


use lib qw(/ids/tools/PRINTING/lib);
use PDF::Reuse;
use printerSite;

use strict;
no strict "refs";
	my $date = 't';
	my $manifestId = 't';
	my $pageNumber = 79;
	my $dir = "$printerSite::SITE_PNG_PATH/FEDEXKINKOS/$date/$manifestId";
	my $pdf = "Cert_Label_".$date."_$manifestId".".pdf";
	system("/bin/cp $dir/$pdf /tmp/");
	prFile("/tmp/pagecount.pdf");
	my $count = prSinglePage("/tmp/$pdf");
	prEnd();
	$count++;
	if($count == 2){## If only One label and One Certificate exists then delete the folder
        	chdir("$printerSite::SITE_PNG_PATH/FEDEXKINKOS/$date");
        	rmdir("$manifestId");
	}else{
		## Now Delete the Certificate and Label Page
        	prFile("/tmp/Cert_Label.pdf");
	        for(my $i = 1;$i<=$count;$i++){
        	        if($i != $pageNumber && $i != $pageNumber+1){
                	        prDoc( { file  => "/tmp/$pdf",
                        	         first => $i,
                                	 last  => $i });
                	}
	        }
        	prEnd();

		if(-e "/tmp/$pdf"){
			unlink("/tmp/$pdf");
		}
		## Copy the new pdf to the same place
		if(-e "/tmp/Cert_Label.pdf"){
		        system("/bin/cp /tmp/Cert_Label.pdf /tmp/$pdf");
	        	system("/bin/cp /tmp/$pdf $dir/");
			unlink("/tmp/Cert_Label.pdf");
		}
	}
