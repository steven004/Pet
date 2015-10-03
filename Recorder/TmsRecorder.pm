## This Tms recorder is just to write test results into the Libra Database. 
## This version is to eliminate DBTestcase&Testcase package. i.e. it writes to the database directly. 
## The side effect is that all TEA log files will be writen. And also it is not write to TMS database directly
## Next, the following changes can be done:
##		1. ----none (Remove any file logs, i.e. just write the Database. )
##		2. Directly write to TMS database.
##		3. Enhance TMS to import test plan from the test report database. 
## Known limitations or problems: 1) The Warning function doesnot implemented in this version; 2) No any TestLog functions. 

##################################################################################
## Database Info:
## 	Database: sqa_logs; there are 3 tables: tests, procedures, steps.
## 	Structures (fields) -- 
##		Tests: timestamp, version_num, test_name, engineer, engineer_id, buildid, purpose, setup, comments, percent_pass, del_queue, approved, tc_percent_pass, elapsed_time
##		procedures: id, testid, timestamp, description, proc_num, result
##		steps: id, timestamp, description, testid, proc_id, result, step_num
##################################################################################

package Pet::Recorder::TmsRecorder;

use strict;

## Module/file import
use DBI;

my $teatestcase;		  
my $teastep;			
local *pettesttask = *teatestcase;
local *petteststep = *teastep;

sub new {
	my ( $class, %args ) = @_;

	#define some var need save
	my $self = { 
		_case_index => 0,
		_step_index => 0,
	};
	
	bless ($self, $class);
	return $self;
}

## A hash table passed to this subroutine to indicate the test information ##
sub TestStart {
	my($self, %TestAttr) = @_;

    ## Read our config
    my $config_obj = "";
    my $ats_config = $config_obj->read_config();

	my %params = ( Purpose => 'N/A', 
					Version => 'N/A', 
					Setup => 'N/A', 
					Name => 'N/A',
				);

 	for (keys %TestAttr) {
 		if (/version/i) { $params{Version} = $TestAttr{$_} ; 
 	} elsif (/test/i) {
 		$params{Name} = $TestAttr{$_}; 
 	} elsif (/engineer/i) {
 		$params{Engineer} = $TestAttr{$_};
 	} elsif (/release/i) {
 		$params{Build} = $TestAttr{$_}.$params{Build}; 
 	} elsif (/build/i) {
 		$params{Build} = '-' . $TestAttr{$_};
	} elsif (/purpose/i) {
		$params{Purpose} = $TestAttr{$_};
	} elsif (/setup/i) {
		$params{Setup} = $TestAttr{$_};
	} elsif (/user/i) {
		$params{Username} = $TestAttr{$_};
	} else { $params{$_} = $TestAttr{$_}; }
  };

    ## We need a 'Version' tag to insert into the database
    unless (defined $params{Version}) {
	if (defined $params{Host}) {

	    ## They didn't tell us the Version, but they did tell us a Host
	    ## Let's go figure out the version ourselves
	    my $version = $self->_get_version();

	    ## Set the version to what we found
	    $params{Version} = $version if $version;
	}

	## If we couldn't figure out the version, default to 'Undefined'
	$params{Version} = $params{Version} || 'Undefined';
    }

    ## If they don't pass an engineer id, default to the 'Automation' userid 999
    $params{Engineer} = ( $params{Engineer} =~ /^\d+$/ ) ? $params{Engineer} : 999;

    ## insert the new test into the database, die on any errors

    my($dbh,$values,$sql,$rows);

    $dbh = DBI->connect("DBI:$ats_config->{DBDriver}:database=sqa_logs;host=$ats_config->{DBHost}", $ats_config->{DBUser}, $ats_config->{DBPasswd}, { PrintError => 1});

    die "Could not connect to database: $DBI::errstr" if ! $dbh;

    $self->{DB_if} = $dbh;

    $values = join(',',$dbh->quote($params{Version}),$dbh->quote($params{Name}),$dbh->quote($params{Engineer}),
                       $dbh->quote($params{Build}),$dbh->quote($params{Purpose}),$dbh->quote($params{Setup}));

    $sql = "INSERT INTO tests (version_num,test_name,engineer_id,buildid,purpose,setup) VALUES ($values)";

    $rows = $dbh->do($sql);
	 
    die "Failed to INSERT test setup into database: $sql : $DBI::errstr" if $rows <= 0;

    ## store the test id, then call base startTestCase()

    $self->{DB_testid} = $dbh->{mysql_insertid};

}

## A hash table passed to this subroutine to indicate test runtime info, and test statistics information ##
#		_test_statistics => {
#			_test_finished => 0, # 0: not finished yet
#			_cases_all => 0,
#			_cases_passed => 0,
#			_cases_failed => 0,
#			_pass_rate => 0.0,
#			_cases_unrun => 'N/A',
#			_fail_rate => 0.0,
#		},
		
sub TestEnd {
   my($self, %statistics) = @_;

       my($dbh,$sql, $rows, $runtime);

       $dbh = $self->{DB_if};

       $runtime = $statistics{endtime} - $statistics{starttime};

       $sql = "UPDATE tests SET elapsed_time='$runtime' WHERE id='$self->{DB_testid}'";

       $dbh->do($sql);

       warn "Failed to UPDATE test elapsed time: $sql : $DBI::errstr"
          if $DBI::errstr;

## update the tc_percent_pass. We can update this when the whole test complete.
	my ($percent_pass, $tc_percent_pass) = (100 * $statistics{step_pass_rate}, 100 * $statistics{case_pass_rate} );
 	
       $sql = "UPDATE tests SET tc_percent_pass='$tc_percent_pass' WHERE id='$self->{DB_testid}'";
       $rows = $dbh->do($sql);

       warn "Failed to UPDATE last testcase percent pass: $sql : $DBI::errstr" 
          if $DBI::errstr;

    ## Update table tests with $percent_pass
    $sql = "UPDATE tests SET percent_pass='$percent_pass' WHERE id='$self->{DB_testid}'";

    $rows = $dbh->do($sql);

    warn "Failed to UPDATE percent_pass in database: $sql : $DBI::errstr"
       if $DBI::errstr;


	$self->{DB_if}->disconnect() if $self->{DB_if};
	$self->{DB_if} = undef;
	return;
}

## Parameters: (CaseNo, CaseDescription) ###
sub CaseStart {
    my ( $self, $case_id, $case_des) = @_;

    my($dbh,$sql,$exist_id,$desc,$rows,$step);

    $dbh = $self->{DB_if};

    ## Insert our new procedure

    $desc = $dbh->quote($case_des);

    $sql = "INSERT INTO procedures (testid,description,proc_num) VALUES ($self->{DB_testid},$desc, $case_id)";

    $rows = $dbh->do($sql);

    warn "Failed to INSERT new procedure into database: $sql : $DBI::errstr" if $rows <= 0;

    $self->{DB_procid} = $dbh->{mysql_insertid};
}

## Parameters: (CaseNo, CaseStatus: PASS or FAIL) ###
sub CaseEnd {
    my ( $self, $case_id, $case_status  ) = @_;

       my($dbh,$sql,$rows,$tc_percent_pass);

       $dbh = $self->{DB_if};

       ## update the last procedure pass/fail field

       $sql = "UPDATE procedures SET result=$case_status WHERE id='$self->{DB_procid}'";
       $rows = $dbh->do($sql);

       warn "Failed to UPDATE last procedure result: $sql : $DBI::errstr" if $rows <= 0;

       return 1;

}


##Parameters: (StepNo, StepStatus: PASS or FAIL, Desc) ###
sub Step {

	my ($self, $StepNo, $StepStatus, $desc) = @_;

	$StepStatus = 2 if ($StepStatus == 0);   # in the steps table in database sqalog, 2 means fail. 
	
  my ($dbh, $sql, $rows);
    $dbh = $self->{DB_if};

    $sql = "INSERT INTO steps (description,testid,proc_id,result,step_num) VALUES ("; 
    $sql .= $dbh->quote($desc) . ",'$self->{DB_testid}','$self->{DB_procid}','$StepStatus','$StepNo' )";

    $rows = $dbh->do($sql);

    warn "Failed to INSERT new step into database: $sql : $DBI::errstr"
       if $rows <= 0;

    return; 
}


sub _get_version {
    my $self = shift;

    return unless defined $self->{Host};

    my $timeout = 120;

    my $path="/NMSRequest/GetObjects?NoHTML=true&Objects=System";

    my $page = $self->_get_page($path, $timeout) or return;
    my @sysVer = split /,/,$page;
    my @versionNum = split / /,$sysVer[3];
    return $versionNum[2];
}


sub DESTROY {

   my $self = shift;

   $self->{DB_if}->disconnect() if $self->{DB_if};

}

## end of module
1;
=pod
## Parameter: (Level, Message) ###
sub TestLog {
	my ($self, $level, $levellog, $note) = @_;

	my $logfunc = lc $levellog;	
	if ($teatestcase->can($logfunc) ) {
		$teatestcase->$logfunc($note);
	}
}


=cut

1;

