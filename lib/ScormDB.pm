#/usr/local/bin/perl
package ScormDB;
use strict;
use DBI;
use Symbol;
use DBD::mysql qw(:ora_types);
use Data::Dumper;
use printerSite;
sub new
{
        my $pkg         = shift;
        my $class       = ref($pkg) || $pkg;

    my $self = {
                    SCORM_CON =>   { DB => $printerSite::SCORM_DATABASE, HOST=>$printerSite::SCORM_DATABASE_HOST, USERNAME => $printerSite::SCORM_DATABASE_USER, PASSWORD => $printerSite::SCORM_DATABASE_PASSWORD },
                    @_,
               };

        bless ($self, $class);

        my $dbConnects = $self->_dbConnect();
        if (! $dbConnects)
        {
                die();
        }

        ####### ASSERT:  The db connections were successful.  Assign
        $self->{SCORM_CON}      = $dbConnects->{SCORM_CON};
	$self->{SCORM_CON}->do("SET SESSION wait_timeout = 50800");
        ##### let's get some settings
        return $self;
}


sub _dbConnect
{
        my $self = shift;
        ####### ok, we just connected to oracle, now let's connect to the mysql db for the CRM
        my $mysqlDBH = DBI->connect("dbi:mysql:$self->{SCORM_CON}->{DB}:$self->{SCORM_CON}->{HOST}",
                                                $self->{SCORM_CON}->{USERNAME},
                                                $self->{SCORM_CON}->{PASSWORD});
        if(!$mysqlDBH)
        {
                ####### Error.  Print out the error and return
                print STDERR "Error Connecting to the database: $self->{SCORM_CON}->{DB} - $DBI::errstr\n";
                return 0;
        }

        ###### ASSERT:  We connected to both databases.  Return the connections
        my $retval = { 'SCORM_CON' => $mysqlDBH };

        return $retval;
}

sub DESTROY
{
    #### um...yeah, pretty worthless @ this point  :-)
    my $self = shift;
}

sub dbGetInstructorDetails{
	my $self = shift;
	my ($userId,$printDate)=@_;
	my ($instructorId,$instructorFirstName,$instructorLastName,$digitalSignaturePath,$digitalInitialPath,$teaNumber,$classId)=$self->{SCORM_CON}->selectrow_array("select i.instructor_id, i.first_name, i.last_name, i.digital_signature_path, i.digital_initial_path, i.tea_number,sc.class_id from ami_student_class_assignment sca inner join ami_scheduled_class sc on (sc.class_id = sca.class_id) inner join ami_instructor i on (i.instructor_id = sc.instructor_id) where  sca.user_id = ?",{}, $userId);
	my %tmpHash;
	$tmpHash{INSTRUCTORID}=$instructorId;
	$tmpHash{INSTRUCTORFIRSTNAME}=$instructorFirstName;
	$tmpHash{INSTRUCTORLASTNAME}=$instructorLastName;
	$tmpHash{DIGITALSIGNATUREPATH}=$digitalSignaturePath;
	$tmpHash{DIGITALINITIALPATH}=$digitalInitialPath;
	$tmpHash{TEANUMBER}=$teaNumber;
	if(!$printDate){
		$printDate = $self->{SCORM_CON}->selectrow_array("select now()");
	}
	my ($overrideInstructorId,$classOverrideDate) = $self->{SCORM_CON}->selectrow_array("select new_instructor_id,start_datetime from ami_instructor_class_override where class_id=? and '$printDate' between start_datetime and end_datetime and active>0",{},$classId);
	if(!$overrideInstructorId){
		($overrideInstructorId,$classOverrideDate) = $self->{SCORM_CON}->selectrow_array("select instructor_id,start_datetime from ami_instructor_class_override where class_id=? and '$printDate' < start_datetime and active>0",{},$classId);
	}
	if($overrideInstructorId){
		($instructorId,$instructorFirstName,$instructorLastName,$digitalSignaturePath,$digitalInitialPath,$teaNumber)=$self->{SCORM_CON}->selectrow_array("select i.instructor_id, i.first_name, i.last_name, i.digital_signature_path, i.digital_initial_path, i.tea_number from ami_instructor i where i.instructor_id = ?",{}, $overrideInstructorId);
		$tmpHash{INSTRUCTORID}=$instructorId;
	        $tmpHash{INSTRUCTORFIRSTNAME}=$instructorFirstName;
        	$tmpHash{INSTRUCTORLASTNAME}=$instructorLastName;
	        $tmpHash{DIGITALSIGNATUREPATH}=$digitalSignaturePath;
        	$tmpHash{DIGITALINITIALPATH}=$digitalInitialPath;
	        $tmpHash{TEANUMBER}=$teaNumber;
                if($classOverrideDate gt $printDate){
                        $tmpHash{OLD_INSTRUCTOR_DATA}=1;
                }
	}
	return \%tmpHash;
}

sub dbGetInstructorDetails2{
        my $self = shift;
        my ($userId,$printDate)=@_;
        my ($instructorId,$instructorFirstName,$instructorLastName,$digitalSignaturePath,$digitalInitialPath,$teaNumber,$classId)=$self->{SCORM_CON}->selectrow_array("select i.instructor_id, i.first_name, i.last_name, i.digital_signature_path, i.digital_initial_path, i.tea_number,sc.class_id from ami_student_class_assignment sca inner join ami_scheduled_class sc on (sc.class_id = sca.class_id) inner join ami_instructor i on (i.instructor_id = sc.instructor_id) where  sca.user_id = ?",{}, $userId);
        my %tmpHash;
        $tmpHash{INSTRUCTORID}=$instructorId;
        $tmpHash{INSTRUCTORFIRSTNAME}=$instructorFirstName;
        $tmpHash{INSTRUCTORLASTNAME}=$instructorLastName;
        $tmpHash{DIGITALSIGNATUREPATH}=$digitalSignaturePath;
        $tmpHash{DIGITALINITIALPATH}=$digitalInitialPath;
        $tmpHash{TEANUMBER}=$teaNumber;
        if(!$printDate){
                $printDate = $self->{SCORM_CON}->selectrow_array("select now()");
        }
        my ($overrideInstructorId,$classOverrideDate) = $self->{SCORM_CON}->selectrow_array("select new_instructor_id,start_datetime from ami_instructor_class_override where class_id=? and '$printDate' between start_datetime and end_datetime and active>0",{},$classId);
        if($overrideInstructorId){
                ($instructorId,$instructorFirstName,$instructorLastName,$digitalSignaturePath,$digitalInitialPath,$teaNumber)=$self->{SCORM_CON}->selectrow_array("select i.instructor_id, i.first_name, i.last_name, i.digital_signature_path, i.digital_initial_path, i.tea_number from ami_instructor i where i.instructor_id = ?",{}, $overrideInstructorId);
                $tmpHash{INSTRUCTORID}=$instructorId;
                $tmpHash{INSTRUCTORFIRSTNAME}=$instructorFirstName;
                $tmpHash{INSTRUCTORLASTNAME}=$instructorLastName;
                $tmpHash{DIGITALSIGNATUREPATH}=$digitalSignaturePath;
                $tmpHash{DIGITALINITIALPATH}=$digitalInitialPath;
                $tmpHash{TEANUMBER}=$teaNumber;
                if($classOverrideDate gt $printDate){
                        $tmpHash{OLD_INSTRUCTOR_DATA}=1;
                }
        }
        return \%tmpHash;
}

1;
