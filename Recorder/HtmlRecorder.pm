package Pet::Recorder::HtmlRecorder;

use constant {
	### The template files for summary and detailed reports
	SUMMARY_TEMPLATE => 'Template/Test_Summary_Report_Template.htm' ,
	DETAILED_TEMPLATE=> 'Template/Test_Detail_Report_Template.htm' ,

	### Block signs for new reports
	TASKINFOBLOCK => '<!--TestTaskInfoBlock-->' ,
	FAILCASEBLOCK => '<!--FailCaseBlock-->' ,
	SUMMARYBLOCK => '<!--TestResultSummaryBlock-->' ,
	CASEBLOCK => '<!--TestCaseBlock-->',
	STEPBLOCK => '<!--TestStepBlock-->',

	### The labels defined to replace in the templates ###
	V_NAME => '\?name\?',
	V_USER => '\?user\?' ,
	V_RELEASE => '\?release\?' ,
	V_BUILD => '\?build\?', 
	V_PURPOSE => '\?purpose\?',
	V_SETUP => '\?setup\?',
	V_MORE => '\?more\?',

	V_CASENO => '\?caseno\?',
	V_CASEDESCRIPTION => '\?casedescription\?',
	V_CASESTATUS => '\?casestatus\?',
	V_CASENLABEL => '\?casen\?',

	V_TOTALCASES => '\?totalcases\?', 
	V_PASSED => '\?passed\?',
	V_PASSRATE => '\?passrate\?',
	V_FAILED => '\?failed\?',
	V_FAILRATE => '\?failrate\?',
	V_BLOCKED => '\?blocked\?',
	V_BLOCKRATE => '\?blockrate\?',

	V_STEPNO => '\?stepno\?',
	V_STEPSTATUS => '\?stepstatus\?',
	V_STEPDESCRIPTION => '\?stepdescription\?' ,
	
	V_STARTTIME => '\?starttime\?',
	V_ENDTIME => '\?endtime\?',
	V_TIMELAST => '\?timelast\?',

	V_SUMMARYREPORTFILE => '\?summaryreportfile\?',
	V_DETAILEDREPORTFILE => '\?detailedreportfile\?',
	V_LOGFILE => '\?logfile?\?',
	
};

my ($fh_sum_t, $fh_detail_t, $fh_sum, $fh_detail, $fh_log);

sub new {
	my ( $class, %args ) = @_;

	#define some var need save
	my $self = {
		_task_info => {
			_name => ' ',
			_user => ' ',
			_release => ' ',
			_build => ' ',
			_purpose => ' ',
			_desc => ' ', 
			_setup => ' ',
			_more => ' ',
			_output_path => ' ',
		},
		_summary => {
			_test_finished => 0, # 0: not finished yet
			_cases_all => 0,
			_cases_passed => 0,
			_cases_failed => 0,
			_pass_rate => 0.0,
			_cases_unrun => 'N/A',
			_fail_rate => 0.0,		
			_start_time =>' ',
			_end_time => ' ',
		},

		_files => {
			_summary => "SummaryReport",
			_detailed => "DetailedReport",
			_log => "TestLog",
		},

		_fail_case => ' ',
		_case_start => ' ',
		_step => ' ' ,
		_case_end => ' ' ,
		_case_desc => ' ',
	};
	
	bless( $self, $class );

	return $self;
}


## A hash table passed to this subroutine to indicate the test information ##
sub TestStart {
	my($self, %TestAttr) = @_;
	
 	for (keys %TestAttr) {
 		if (/name/i) { $self->{_task_info}->{_name} = $TestAttr{$_} ;
 		} elsif (/desc/i) {
 			$self->{_task_info}->{_desc} = $TestAttr{$_};
 		} elsif (/purpose/i) {
 			$self->{_task_info}->{_purpose} = $TestAttr{$_};
 		} elsif (/setup/i) {
 			$self->{_task_info}->{_setup} = $TestAttr{$_};
 		} elsif (/release/i) {
 			$self->{_task_info}->{_release} = $TestAttr{$_};
 		} elsif (/build/i) {
 			$self->{_task_info}->{_build} .= '-'.$TestAttr{$_};
		} elsif (/host|ip/i) {
			$self->{_task_info}->{_host} = $TestAttr{$_};
		} elsif (/id/i) {
			$self->{_task_info}->{_taskid} = $TestAttr{$_};
		} elsif (/output|path|dir/i) {
			$self->{_task_info}->{_output_path} = $TestAttr{$_};
		} elsif (/user/i) {
			$self->{_task_info}->{_user} = $TestAttr{$_};
		} else { $self->{_task_info}->{more} .= $_ .':'. $TestAttr{$_} ."\t"; }
  	};

	$self->{_summary}->{_start_time} = time;
	
	$self->_open_file();	

	foreach (values %{$self->{_files}}) { s(.*/|\\)()g ;}
	###
	## write the summary report about the test task info. 
	my ($reportinfo, $taskinfo);
	$reportinfo = $self->_read_file($fh_sum_t, TASKINFOBLOCK);
	$self->_replace_and_write ($fh_sum, $reportinfo, 
				&V_NAME => $self->{_task_info}->{_name},
	                     &V_STARTTIME => _dateStr() ,
                            &V_DETAILEDREPORTFILE => $self->{_files}->{_detailed} ,
                            &V_LOGFILE => $self->{_files}->{_log}
                       );

	$taskinfo = $self->_read_file($fh_sum_t, TASKINFOBLOCK);
	$self->_replace_and_write ($fh_sum, $taskinfo, 
				&V_NAME => $self->{_task_info}->{_name},
	                     &V_USER => $self->{_task_info}->{_user} ,
                            &V_RELEASE => $self->{_task_info}->{_release} ,
                            &V_BUILD => $self->{_task_info}->{_build},
                            &V_PURPOSE => $self->{_task_info}->{_purpose},
                            &V_SETUP => $self->{_task_info}->{_setup},
                            &V_MORE => $self->{_task_info}->{_more}
                       );
       $self->_copy_file($fh_sum_t, $fh_sum, FAILCASEBLOCK);

	## get the fail case info template for the report
	$self->{_fail_case} = $self->_read_file($fh_sum_t, FAILCASEBLOCK);

	###
	## write the detailed report about the task info
	$reportinfo = $self->_read_file($fh_detail_t, TASKINFOBLOCK);
	$self->_replace_and_write ($fh_detail, $reportinfo, 
				&V_NAME => $self->{_task_info}->{_name},
	                     &V_STARTTIME => _dateStr() ,
                            &V_SUMMARYREPORTFILE => $self->{_files}->{_summary},
                            &V_LOGFILE => $self->{_files}->{_log}
                       );

	$taskinfo = $self->_read_file($fh_detail_t, TASKINFOBLOCK);

	
	$self->_replace_and_write ($fh_detail, $taskinfo, 
				&V_NAME => $self->{_task_info}->{_name},
	                     &V_USER => $self->{_task_info}->{_user} ,
                            &V_RELEASE => $self->{_task_info}->{_release} ,
                            &V_BUILD => $self->{_task_info}->{_build},
                            &V_PURPOSE => $self->{_task_info}->{_purpose},
                            &V_SETUP => $self->{_task_info}->{_setup},
                            &V_MORE => $self->{_task_info}->{_more}
                       );
       $self->_copy_file($fh_detail_t, $fh_detail, CASEBLOCK);

	## get the case & step info template for the report
	$self->{_case_start} = $self->_read_file($fh_detail_t, STEPBLOCK);
	$self->{_step} = $self->_read_file($fh_detail_t, STEPBLOCK);	
	$self->{_case_end} = $self->_read_file($fh_detail_t, CASEBLOCK);

	###
	## write the test log file
	foreach my $attr (keys %TestAttr) {
		$self->_write_log ("&nbsp;&nbsp; $attr:&nbsp;&nbsp;  $TestAttr{$attr} ");
	}
	$self->_write_log ("------------------Test Start -------------------------");
}


## A hash table passed to this subroutine to indicate test runtime info, and test statistics information ##
sub TestEnd {
	my($self, %TestSum) = @_;

  foreach (keys %TestSum) {
    $self->{_summary}->{$_} = $TestSum{$_};
  }

	$self->{_summary}->{_end_time} = time;

	###
	## write the summary report about the summary. 
	$self->_copy_file($fh_sum_t, $fh_sum, SUMMARYBLOCK);

	my $suminfo;
	$suminfo = $self->_read_file($fh_sum_t, SUMMARYBLOCK);
	$self->_replace_and_write ($fh_sum, $suminfo, 
				&V_TOTALCASES => $self->{_summary}->{_cases_all}, 
				&V_PASSED => $self->{_summary}->{_cases_passed},
				&V_PASSRATE => $self->{_summary}->{_pass_rate},
				&V_FAILED => $self->{_summary}->{_cases_failed},
				&V_FAILRATE => $self->{_summary}->{_fail_rate},
				&V_BLOCKED => $self->{_summary}->{_cases_unrun},
				&V_BLOCKRATE => 'n/a',
				
				&V_STARTTIME => $self->_dateStr($self->{_summary}->{_start_time}),
				&V_ENDTIME => $self->_dateStr ($self->{_summary}->{_end_time}),
				&V_TIMELAST => ($self->{_summary}->{_end_time}-$self->{_summary}->{_start_time}).'  Seconds'
    );
    $self->_copy_file($fh_sum_t, $fh_sum, "ENDENDEND");

	## write the detailed report about the statistics
	$self->_copy_file($fh_detail_t, $fh_detail, SUMMARYBLOCK);
	$suminfo = $self->_read_file($fh_detail_t, SUMMARYBLOCK);
	
	$self->_replace_and_write ($fh_detail, $suminfo,
				&V_TOTALCASES => $self->{_summary}->{_cases_all}, 
				&V_PASSED => $self->{_summary}->{_cases_passed},
				&V_PASSRATE => $self->{_summary}->{_pass_rate},
				&V_FAILED => $self->{_summary}->{_cases_failed},
				&V_FAILRATE => $self->{_summary}->{_fail_rate},
				&V_BLOCKED => $self->{_summary}->{_cases_unrun},
				&V_BLOCKRATE => 'n/a',
				
				&V_STARTTIME => $self->_dateStr($self->{_summary}->{_start_time}),
				&V_ENDTIME => $self->_dateStr ($self->{_summary}->{_end_time}),
				&V_TIMELAST => ($self->{_summary}->{_end_time} - $self->{_summary}->{_start_time}) . 'Seconds'
                       );
       $self->_copy_file($fh_detail_t, $fh_detail, "ENDENDEND");


	## write the test log file.	
	$self->_write_log ("-----------------Test End ---------------------------<br>");
	foreach my $attr (keys %{$self->{_summary}}) {
		$self->_write_log ("&nbsp;&nbsp; $attr:&nbsp;&nbsp; $self->{_summary}->{$attr} ");
	}

	$self->_close_file;
}

## Parameters: (CaseNo, CaseDescription) ###
sub CaseStart {
	my ($self, $caseno, $desc) = @_;

	$self->{_case_desc} = $desc;

	###
	## write the case start info in detailed report
	$self->_replace_and_write($fh_detail, $self->{_case_start},
					&V_CASENO => $caseno,
					&V_CASENLABEL => 'Case'.$caseno,
					&V_CASEDESCRIPTION => $desc
				);
		
	###
	## write the test log file
	$self->_write_log ("Case $caseno Start: $desc ");
}

## Parameters: (CaseNo, CaseStatus: PASS or FAIL) ###
sub CaseEnd {
	my ($self, $caseno, $result) = @_;
	$result = $result?'<font color="green">PASS</font>':'<font color="red">FAIL</font>';
	
	###
	## write the case end info in detailed report
	$self->_replace_and_write ($fh_detail, $self->{_case_end}, 
					&V_CASENO => $caseno,
					&V_CASESTATUS => $result 
				);
	
	## write the case info in summary report if failed
	if ($result =~ 'FAIL') {
		$self->_replace_and_write ($fh_sum, $self->{_fail_case},
						&V_CASENO => $caseno,
						&V_CASEDESCRIPTION => $self->{_case_desc},
						&V_CASESTATUS => $result ,
						&V_DETAILEDREPORTFILE => $self->{_files}->{_detailed},
						&V_CASENLABEL => 'Case'.$caseno
					);
	}

	###
	## write the test log file
	$self->_write_log ("Case $caseno ----------- $result ----------- <br>");
}

##Parameters: (StepNo, StepStatus: PASS or FAIL, Desc) ###
sub Step {
	my ($self, $stepno, $cond, $desc) = @_;
	my $result = $cond?'<font color="green">PASS</font>':'<font color="red">FAIL</font>';
 
	$self->_replace_and_write ($fh_detail, $self->{_step}, 
					&V_STEPNO => $stepno,
					&V_STEPSTATUS => $result,
					&V_STEPDESCRIPTION => $desc
				);
	
	## write the test log file
	$self->_write_log ("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Step $stepno: \t", $result, "\t$desc") ;
}

## Parameter: (Level, Message) ###
sub TestLog {
	my ($self, $level, $levellog, $note) = @_;

	$self->_write_log ('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font style="BACKGROUND-COLOR: #cccccc">' .
                      "<em>Log (-$levellog-)&nbsp;&nbsp;$note</em></font>");
}



#------------------------------
# _dateStr
#
# return the string rendition of a time. If time
# not supplied, it returns the current time
#
sub _dateStr {
    my $self = shift;
    my $time = shift;
    $time = time if (! defined $time);

    ## Build timestamp.
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime $time;
    my $month = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
    $year %= 100;
    my $str = sprintf("%02d%s%02d_%02d%02d%02d",
		      $mday, $month, $year, $hour, $min, $sec);

    return $str;
}

sub _open_file {
  my $self = shift;
	my $curtime = _dateStr();

	if ($self->{_task_info}->{_output_path} !~ m[/|\\$] ) {
		$self->{_task_info}->{output_path} .= '/';
	}
	
	$self->{_files}->{_summary} = $self->{_task_info}->{_output_path} . $curtime. $self->{_task_info}->{_name}. '-sum.htm';
	$self->{_files}->{_detailed} = $self->{_task_info}->{_output_path} . $curtime. $self->{_task_info}->{_name}. '-detail.htm';
	$self->{_files}->{_log} = $self->{_task_info}->{_output_path} . $curtime . $self->{_task_info}->{_name}. '-log.htm' ;

	my($f_sum_t, $f_detail_t);
	my $thisdir = $INC{"Pet/Recorder/HtmlRecorder.pm"};
	$thisdir =~ s/HtmlRecorder\.pm//;
	$f_sum_t = $thisdir . SUMMARY_TEMPLATE;
	$f_detail_t = $thisdir . DETAILED_TEMPLATE;	
	open ($fh_sum_t, '<', $f_sum_t) or 
		die ("Can not open the summary report template file\n");
	open ($fh_detail_t, '<', $f_detail_t) or 
		die ( "Can not open the detailed report template file\n");

	open ($fh_sum, '>', $self->{_files}->{_summary}) or 
		die ( "Can not open the summary report file to write\n" );
	open ($fh_detail, '>', $self->{_files}->{_detailed}) or 
		die ( "Can not open the detail report file to write\n" );
	open ($fh_log, '>', $self->{_files}->{_log}) or
		die ( "Can not open the detail report file to write\n" );

}

sub _close_file {
  my $self = shift;
	close ($fh_sum_t);
	close ($fh_detail_t);

	close ($fh_sum  );
	close ($fh_detail );
	close ($fh_log );
}


sub _write_log {
	my $self = shift;

	print {$fh_log} _dateStr(), ":",  @_, '<br>';
}

sub _copy_file {
	my $self = shift;
	my ($fs, $fd, $stop) = @_;
	my $lines = 0;
	
	while (<$fs>) {
		print $fd $_;
		$lines ++;
		if ($_ =~ $stop) { last; }
	}
	return $line;
}

sub _read_file {
	my $self = shift;
	my ($fs, $stop) = @_;
	my $msg='';
	
	while (<$fs>) {
		$msg .= $_;
		if ($_ =~ $stop) { last; }
	}
	
	return $msg;
}

sub _replace_and_write {
	my ($self, $fh, $msg, %replace) = @_;

	foreach (keys %replace) {
   		 $msg =~ s/$_/$replace{$_}/
  	}
  	print $fh $msg;
}

1;

