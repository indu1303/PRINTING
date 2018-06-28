#!/usr/bin/perl

use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Cookies;
use Encode qw(encode);
use CGI qw(:cgi);
use CGI qw(-compile :cgi);
use warnings;

my $dir=param('DIR');
my $uploadUrl = param('UPLOADURL');
my $statusUrl = param('STATUSURL');
my $file = param('FILE');
my $keyField = param('KEYFIELD');
# Make Unix style path
$dir=~s|\\|/|gi;

# Remove trailing slashes
$sep=$/; $/="/"; chomp($dir); $/=$sep;

# Now try to get the list of files
#

my $browser=LWP::UserAgent->new();

my @ns_headers = (

   'User-Agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7) Gecko/20041107 Firefox/1.0',

   'Accept' => 'image/gif, image/x-xbitmap, image/jpeg,

        image/pjpeg, image/png, */*',

   'Accept-Charset' => 'iso-8859-1,*,utf-8',

   'Accept-Language' => 'en-US',

  );

$browser->cookie_jar( {} );

uploadfile:
$eckey=encode('utf8',$file);
if($eckey ne $file) {
	symlink($file,"$dir/$file");
}
$response=$browser->post("$uploadUrl",
@ns_headers,Content_Type=>'form-data',Content=>
        [
               file1=>["$dir/$eckey"],
	       key => "$keyField"

        ]);

push @responses,$response->as_string;
if($response->code!=302 && $response->code!=200) {
        #print $response->as_string;
        goto uploadfile;
} else {
	#print "Uploaded successfully.\n";
}             

#open(DEBUG,">$dir/debug.txt") or die "Could not write file.\n";

#print DEBUG @responses;

#close DEBUG;
print "CONTENT-TYPE:TEXT/HTML\nLOCATION:$statusUrl\n";
print "\n\n";


 

