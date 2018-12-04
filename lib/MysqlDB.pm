#/usr/local/bin/perl
package MysqlDB;
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
        $self->{CRM_CON}      = $dbConnects->{CRM_CON};
	$self->{CRM_CON}->do("SET SESSION wait_timeout = 50800");
        ##### let's get some settings
        return $self;
}

sub dbInsertAlerts{
    my $self =shift;
    my ($alertId) = @_;
    my $alertTransId=$self->getNextId('contact_id');
    $self->{CRM_CON}->do("insert into alert_details (alert_trans_id,alert_id,open_time,status_id) values ('$alertTransId','$alertId',sysdate(),'1')");
}

sub dbInsertPrintManifest{
   my $self = shift;
   my ($printId,$printType,$printMode,$jobPrintDate,$productId,$manifestId,$userId,$certificateCategory,$officeId,$errorId)=@_;
   if(!$errorId){
	$errorId=0;
   }
   $self->{CRM_CON}->do("insert into manifest_print_details (print_id,print_date,print_type,print_mode,job_print_date,product_id,manifest_id,user_id,certificate_category,office_id,error_id) values('$printId',sysdate(),'$printType','$printMode','$jobPrintDate','$productId','$manifestId','$userId','$certificateCategory','$officeId',$errorId)");
}


sub dbGetManifestUserByErrorId {
	my $self=shift;
	my ($printType,$errorId,$productId)=@_;
	print "$printType,$errorId,$productId";
	my $sql = $self->{CRM_CON}->prepare("select user_id,date_format(print_date,'%m-%d-%Y') as print_date,print_id from manifest_print_details where print_type=? and error_id=? and product_id=?");
	$sql->execute($printType,$errorId,$productId);
	my %tmpHash;
	my ($v1,$v2,$v3);
	while(($v1,$v2,$v3) = $sql->fetchrow)
        {
                $tmpHash{$v1}->{PRINT_DATE}=$v2;
                $tmpHash{$v1}->{PRINT_ID}=$v3;
        }
        $sql->finish;
        return \%tmpHash;

}                                                                                                                                               
sub dbUpdateManifestErrorCode {
	my $self=shift;
	my ($printId,$errorId)=@_;
	$self->{CRM_CON}->do("update manifest_print_details set error_id=? where print_id=?",{},$errorId,$printId);
}
sub dbInsertPrintManifestStudentInfo{
   my $self = shift;
   my ($printId,$fixedData,$variableData)=@_;
   my $count=$self->{CRM_CON}->selectrow_array("select count(print_id) from manifest_student_info where print_id=$printId");
   my $textData=$variableData;
   my $nottoupdatefields={drivers_license=>1,first_name=>1,last_name=>1,dob=>1,address_1=>1,address_2=>1,city=>1,state=>1,zip=>1};
   my $query='';
   $fixedData->{print_text_data}= $textData ;
   if(!$count || $count==0){
	my $fieldName='';
        my $fieldValue='';
	my $j=1;
        $fixedData->{print_id} = $printId;
	foreach my $key(keys %$fixedData){
		my $k1=lc $key;
		if(exists $nottoupdatefields->{$k1}){
			next;
		}
		if($j>1){
			$fieldName  .= ',';
			$fieldValue .= ',';
		}
		$fieldName  .= $key;
		$fixedData->{$key} =~ s/\'/\'\'/g;
		$fieldValue .= "'" . $fixedData->{$key} . "'";
		$j++;
	}
        $query="insert into manifest_student_info($fieldName) values($fieldValue)";
   }else{
        my @updateData;
        foreach my $key(keys %$fixedData){
		my $k1=lc $key;
		if(exists $nottoupdatefields->{$k1}){
			next;
		}
		$fixedData->{$key} =~ s/\'/\'\'/g;
                push  @updateData,"$key='$fixedData->{$key}'";
        }
        my $updateStr=join ',',@updateData;
        $query="update manifest_student_info set $updateStr where print_id=$printId";
  }
        $self->{CRM_CON}->do($query);
}
                                                                                                                                               
sub getNextId {
   my $self = shift;
   my ($seq) = @_;
   my $tableName=lc($seq ."_seq");
   my $query="update $tableName set id=id+1";
   $self->{CRM_CON}->do($query);
   my $id=$self->{CRM_CON}->selectrow_array("select id from $tableName");
   return $id;
}


sub createFollowUp{
    my $self = shift;
    my($userId,$notes,$errorCode,$flStateUser) = @_;
#   Check whether a followup exists with the same Error Code
    my $followupExists = 0;
    if($errorCode){
        $notes = "$errorCode:$notes";
        my $arr_ref  = $self->{CRM_CON}->selectall_arrayref("select ct.transcript from contact_user cu, contact_follow_up cf, contact_transcripts ct where cu.user_id=$userId and cu.contact_id = cf.contact_id and cf.followup_type=5 and cf.contact_follow_id=ct.contact_follow_id");
        foreach(@$arr_ref){
            my @tempArr = split(/:/,$_->[0]);
            if($errorCode eq $tempArr[0]){
                $followupExists = 1;
                last;
            }
        }
    }
#   if followup with this errorCode does'nt exists then create followup
    unless($followupExists){
	    my $contactId = $self->getNextId('contact_id');
	    my $contactFollowId = $self->getNextId('contact_follow_id');
	    my $groupId = ($flStateUser) ?  4 : 1;
	    my $operatorId = 0;
	    my $contactStatusId = 1;
	    my ($sec,$min,$hour,$mday,$mon,$year) = (localtime(time()))[0,1,2,3,4,5];
	    $year = $year+1900;
	    $mon = $mon+1;
	    my $currentTime = "$year-$mon-$mday $hour:$min:$sec";
	    my $priority = 1;
	    my $followupType = 5;      # Fedex or FLWebService Followup
	    my $productId = 1;         # This followup is for DIP product
	#   Transcript data
	    my $transcriptId = $self->getNextId('transcript_id');
                                                                                                                                                                                                                                                           
	    my $query1 = "insert into contact_follow_up(contact_follow_id,group_id,operator_id,contact_status_id,contact_id,open_time,priority_id,followup_type,product_id) values($contactFollowId,$groupId,$operatorId,$contactStatusId,$contactId,'$currentTime',$priority,$followupType,$productId)";
	    my $query2 = "insert into contact_transcripts(transcript_id,transcript_date,contact_id,contact_follow_id,transcript) values ($transcriptId,'$currentTime',0,$contactFollowId,'$notes')";
	    my $query3 = "insert into contact_user(contact_id,user_id) values($contactId,$userId)";
                                                                                                                                                                                                                                                           
	    $self->{CRM_CON}->begin_work;
	    my $flag1 = $self->{CRM_CON}->do($query1);
	    my $flag2 = $self->{CRM_CON}->do($query2);
	    my $flag3 = $self->{CRM_CON}->do($query3);
	    if($flag1 && $flag2 && $flag3){
        	$self->{CRM_CON}->commit;    # Successful execution commit changes
	    }else{
        	$self->{CRM_CON}->rollback;  # Error rollback changes
    	    }
    }
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

sub dbInsertLabelPageNumber {
        my $self = shift;
        my ($userId,$manifestId,$pageNo) = @_;
        $self->{CRM_CON}->do("update manifest_print_details set page_no=$pageNo where manifest_id=$manifestId and user_id=$userId");

}

sub dbInsertFedexDesktopDetails {
        my $self = shift;
        my ($jobId,$manifestId,$certName,$label,$status,$state) = @_;
        $self->{CRM_CON}->do("insert into fedex_desktop_details(job_id,manifest_id,job_date,certificate_filename,label,state,status) values('$jobId','$manifestId',now(),'$certName','$label','$state','$status')");
}

sub getManifestUsers{
	my $self = shift;
	my ($manifestId) = @_;
	my $sql = $self->{CRM_CON}->prepare("select pd.user_id from manifest_print_details pd where pd.manifest_date is not null and (pd.status is null or pd.status !=-99) and pd.manifest_id=$manifestId order by pd.print_id");
	$sql->execute;
	
	my %tmpHash;
    	my $v1;

    	$sql->execute;
    	while(($v1) = $sql->fetchrow)
    	{
       		$tmpHash{$v1}=$v1;
    	}
    	$sql->finish;
    	return \%tmpHash;

}

sub dbUpdateTrackingInfo{
	my $self = shift;
	my ($printId,$trackingNumber) = @_;
	$self->{CRM_CON}->do("update manifest_student_info set delivery=? where print_id=?",{},$trackingNumber,$printId);
}

sub dbUpdateReturnMailStatus{
    my $self =shift;
    my ($transId) = @_;
    $self->{CRM_CON}->do("update return_mail_transactions set status ='1' where return_mail_request_id =?",{},$transId);
}

1;
