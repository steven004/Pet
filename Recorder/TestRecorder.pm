package Pet::Recorder::TestRecorder;

## TestRecorder is to record test report in different levels via different channels

$VERSION = '1.7.0';

require Exporter;
our @ISA = qw(Exporter);

use strict;
use warnings;

use Pet::Recorder::ConsoleRecorder;
#use Pet::Recorder::TealogRecorder; # Remove this when using TmsRecorder
use Pet::Recorder::HtmlRecorder;
#use Recorder::EmailRecorder;
#use Pet::Recorder::TmsRecorder;
#use Pet::Recorder::GuiRecorder;

#export pub method and each Constants
our @EXPORT =  qw(
  	TestSuiteName  TestSuiteDes TestSuitePurpose TestPlanName TestSuiteEnv
  	TestStart TestEnd
  	CaseStart Step Pass Fail Is Isnt Like Unlike Steps CaseEnd
  	TestLog WarningMsg  InfoMsg  ErrorMsg DebugMsg
  	TestRecTo  SetTestRecPath  TestRecOpt
  	OptOnFail  SubOnFail
  	PASS  FAIL
  	ERROR  WARNING  INFO  DEBUG TRACE
  	TMS  HTML  CONSOLE  XML  TEALOG  EMAIL
  	KEEP_RUNNING  STOP_ON_STEP_FAIL  STOP_ON_CASE_FAIL  PROMPT_ON_FAIL
  	PROMPT_BY_STEP  PROMPT_BY_CASE  NO_RUNTIME_CONTROL
  	TESTSUMMARY  TESTDETAIL  TESTLOG  
);

use constant {
	# Boolean Constants for test case/step pass or fail
	PASS => 1,  FAIL => 0,
	# Numberical Constants for Message Levels
	ERROR => 4,  WARNING => 3,  INFO => 2,  TRACE=> 1,  DEBUG => 0,
	#Numberical Constants for Where to Record (for advanced usage)
	TMS => 1,  HTML => 2,  CONSOLE => 4,  XML => 8,  TEALOG => 16,  EMAIL => 32,
	#Numberical Constants for Runtime Controlling
	KEEP_RUNNING => 0,  STOP_ON_STEP_FAIL => 1,  STOP_ON_CASE_FAIL => 2, PROMPT_ON_FAIL => 3,
	PROMPT_BY_STEP=>4, PROMPT_BY_CASE=>5, TEST_QUIT=>6, NO_RUNTIME_CONTROL=>-1, 
	#Numberical Constants for What to Record (just for advanced usage)
	ERROR => 1,		#  Log for Error message
	WARNING=>2,	#  Log for Warning message
	INFO=>4,		#  Log for information/comments/notices 
	TRACE=>8,		#  Log for trace
	DEBUG=>16,		#  Log for Debug information
 	TESTSUMMARY => 128,	#  SummaryReport
 	TESTDETAIL => 256,	#  DetailedReport
 	TESTLOG => 384,		#  Log for test suite and test cases. Including information in SummaryReport and DetailedReport
};

my $self;
my $pause_test;
my %AllChannels = ('TMS'=>[TMS, 'TmsRecorder'], 'HTML'=>[HTML,  'HtmlRecorder'], 'CONSOLE'=>[CONSOLE, 'ConsoleRecorder'],
				'TEALOG'=>[TEALOG, 'TealogRecorder'], 'EMAIL'=>[EMAIL, 'EmailRecorder']);
my %AllRecordLevels = ('TESTSUMMARY' => TESTSUMMARY,  'TESTDETAIL' => TESTDETAIL,  'TESTLOG' => TESTLOG,
 	'ERROR' =>ERROR, 	'WARNING' => WARNING, 'INFO' =>INFO, 'TRACE'=>TRACE,	'DEBUG' =>DEBUG);


sub _report_init_ {
	$self = {	#define default values
		_record_channels=>{},
		_where_to_report => 0,
		_what_to_report => 0,
		_test_task_info => {
#			_test_plan_name => 'Undefined Test Plan',
#			_test_suite_desc => '',
#			_test_bed_desc => '',
#			_test_plan_file => 'Unknown',
#			_task_id => 0,
			_release => '',
			_build => '',
			_user => 'Xin',
			_host => '',
	  		_report_path => '',
		},

		_case_index => 0,
		_step_index => 0,
		_last_case_status => PASS,
		_last_case_desc => '',
		_run_time_ctl =>KEEP_RUNNING,
	  	_sub_on_fail => sub {return FAIL;},  		
	  	
		_test_statistics => {
			_test_finished => 0, # 0: not finished yet
			_cases_all => 0,
			_cases_passed => 0,
			_cases_failed => 0,
			_steps_all => 0,
			_steps_passed => 0, 
			_steps_failed => 0,
			case_pass_rate => 0.0,
			step_pass_rate => 0.0,
			starttime => time(),
			endtime => time(),
			_cases_unrun => 'N/A',
			_fail_rate => 0.0,
		},
		_test_sum => [],
	};

	if (defined ($ENV{'TESTRECPATH'} ) ) {
		$self->{_test_task_info}->{_report_path} = $ENV{'TESTRECPATH'} ;
	} else {
		#set the default report directory
		if ($^O =~ /MSWin32/)
			{ $self->{_test_task_info}->{_report_path} = 'C:/apps/pet_output/'.$ENV{'USERNAME'}.'/';}
		else
			{ $self->{_test_task_info}->{_report_path}  = '/tmp/pet_output/'.$ENV{'USER'}.'/'; }
	}

	if (defined ($ENV{'TESTRECTO'} ) ) {
		my $channel;
		my $TestRecChannel = $ENV{'TESTRECTO'};
		$self->{_where_to_report} = 0;
		foreach $channel (keys (%AllChannels)) {
			if ($TestRecChannel =~ $channel ) {
				$self->{_where_to_report} |= $AllChannels{$channel}[0];
			}
		}
	} else { # default report channels
		$self->{_where_to_report} = EMAIL | HTML | CONSOLE |TMS;
	}

	if (defined ($ENV{'TESTRECOPT'} ) ) {
		my $level;
		my $TestRecLevel = $ENV{'TESTRECTO'};
		$self->{_what_to_report} = 0;
		foreach $level (keys %AllRecordLevels) {
			if ($TestRecLevel =~ $level ) {
				$self->{_what_to_report} |= $AllRecordLevels{$level};
			}
		}
	} else { # record all stuff by default
		$self->{_what_to_report} = TESTSUMMARY | TESTDETAIL | TESTLOG
						| ERROR|WARNING | INFO| DEBUG |TRACE;
	}

	if ($^O =~ /MSWin32/)
		{ $self->{_test_task_info}->{_user} = $ENV{'USERNAME'};}
	else
		{ $self->{_test_task_info}->{_user}  = $ENV{'USER'}; }

	bless $self;

	$pause_test = 0;
 
  return $self;

}	

sub CaseStart {
	my $CaseDes = $self->{_last_case_desc} = shift;

	my $CaseNo = ++ $self->{_case_index} ;
	if ($self->{_step_index} != 0 ) {
		print STDERR "There is a CaseEnd missed before this case !!!\n";
		print STDERR "\t(Case No: $CaseNo\t $CaseDes)\n";
		CaseEnd();
		$self->{_step_index} = 0;
	}

	$self->{_last_case_status} = PASS;
	_record_("CaseStart", $CaseNo, $CaseDes);
}

sub CaseEnd {
	if (@_) { 	Step(@_); }
	my $stop = 0;

	if ($self->{_step_index} == 0 ) {
	# No any checkpoint for this case. 
		print STDERR "Warning: There is no any check point in this case !!!\n";
		print STDERR "\t(Case No: $self->{_case_index}\t $self->{_last_case_desc})\n";
	}

	# set the _step_index to 0 for the next case. 
	$self->{_step_index} = 0; 
	
	_record_("CaseEnd", $self->{_case_index}, $self->{_last_case_status});
	if ($self->{_last_case_status} ) {
		$self->{_test_statistics}->{_cases_passed} ++;
	} else { 
		$self->{_test_statistics}->{_cases_failed} ++; 
		if ($self->{_run_time_ctl} == STOP_ON_CASE_FAIL ) { $stop = 1; }
	}
	
	## Runtime Controlling
	unless ($stop) {
		if ($pause_test ) {
			$self->{_run_time_ctl} = $self->_pause_test("by Ctrl-C");
			if ($self->{_run_time_ctl} == TEST_QUIT) {$stop = 1;}			
			$pause_test = 0;
		} elsif ($self->{_run_time_ctl} == PROMPT_BY_CASE ) {
			$self->{_run_time_ctl} = $self->_pause_test("due to pause set by case");
			if ($self->{_run_time_ctl} == TEST_QUIT) { $stop = 1; }
		}
	}

	if ($stop)	{
		&{$self->{_sub_on_fail}}($self->{_case_index});
		TraceMsg("Runtime Control: The Test stopped here due to a case failure!");
		$self->_test_end_();
		die "Test Stopped on Case#$self->{_case_index}  due to case failure!";
	}

	return $self->{_last_case_status};		
		
}

sub Step {
	my ($condition, $desc1, $desc2) = @_;
	$self->{_step_index} ++;
	my $stop = 0;

	if (!defined $desc1) { $desc1 = ' '; }
	if (!defined $desc2) { $desc2 = $desc1; }

	## Record the step result
	if ($condition) {
		$self->{_test_statistics}->{_steps_passed} ++;
		_record_("Step", $self->{_step_index}, PASS, $desc1);
	} else {
		$self->{_last_case_status} = FAIL; 
		$self->{_test_statistics}->{_steps_failed} ++;
		_record_("Step", $self->{_step_index}, FAIL, $desc2); 
	}

	## Runtime Controlling
	unless ($condition) {
		if ($self->{_run_time_ctl} == STOP_ON_STEP_FAIL ) {$stop = 1;}
		if ( $self->{_run_time_ctl} == PROMPT_ON_FAIL   ) {
			$self->{_run_time_ctl} = $self->_pause_test("due to step failure");
			if ($self->{_run_time_ctl} == TEST_QUIT) {$stop = 1;}
		} 
	}

	unless ($stop) {
		if ($pause_test ) {
			$self->{_run_time_ctl} = $self->_pause_test("by Ctrl-C");
			if ($self->{_run_time_ctl} == TEST_QUIT) {$stop = 1;}			
			$pause_test = 0;
		} elsif ($self->{_run_time_ctl} == PROMPT_BY_STEP ) {
			$self->{_run_time_ctl} = $self->_pause_test("due to pause set by step");
			if ($self->{_run_time_ctl} == TEST_QUIT) { $stop = 1; }
		}
	}
	
	if ($stop)  {
		&{$self->{_sub_on_fail}}($self->{_case_index}, $self->{_step_index});
		TraceMsg("Runtime Control: The test stopped here due to a step failure!");
		CaseEnd();
		$self->_test_end_();
		die "Test Stopped on Case#$self->{_case_index} - Step#$self->{_step_index} due to step failure!";
	} else {	return $condition ? PASS : FAIL; }
}

sub TestStart {
	if (@_) {
       	 my %TestAttr = @_;
    	
 		for (keys %TestAttr) {
 			if (/name/i) { $self->{_test_task_info}->{_name} = $TestAttr{$_} ; 
 			} elsif (/purpose/i) {
 				$self->{_test_task_info}->{_purpose} = $TestAttr{$_}; 
 			} elsif (/desc|setup/i) {
 				$self->{_test_task_info}->{_desc} = $TestAttr{$_};
	 		} elsif (/release/i) {
 				$self->{_test_task_info}->{_release} = $TestAttr{$_} . $self->{_test_task_info}->{_build};
 			} elsif (/build/i) {
 				$self->{_test_task_info}->{_build} .= '-'.$TestAttr{$_};
			} elsif (/host|ip/i) {
				$self->{_test_task_info}->{_host} = $self->{_test_task_info}->{Parameter}[1] = $TestAttr{$_};
			} elsif (/id/i) {
				$self->{_test_task_info}->{_task_id} = $TestAttr{$_};
			} elsif (/output|path|dir/i) {
				$self->{_test_task_info}->{_output_path} = $TestAttr{$_};
			} elsif (/user/i) {
				$self->{_test_task_info}->{_user} = $TestAttr{$_};
			} elsif (/(Opt.*Fail)|(Fail.*Option)|(Fail.*Opt)/i) {
				$self->{_run_time_ctl} = $TestAttr{$_};
			} elsif (/(Sub.*Fail)|(Fail.*Sub)/i) {
				$self->{_sub_on_fail} = $TestAttr{$_};
			} else { $self->{_test_task_info}->{$_} = $TestAttr{$_}; }
  		};
	}
	
	_init_Channels_();

	_record_("TestStart", %{$self->{_test_task_info}});
}

sub TestEnd {
	$self->{_test_statistics}->{_test_finished} = "Finished"; # Indicate test finished
	$self->_test_end_(@_);
}

#### Aliases of Step(...) ##############
#The alias of  Step(PASS, Desc)
sub Pass { 	Step( PASS, @_ ); }

#  Fail alias of  Step(Fail, Desc)
sub Fail { Step(FAIL, @_ ); }

## __result__ is a special variable to record the actual result for a test 
sub Is {
	my ( $Cond1, $Cond2, @des ) = @_;
	foreach (@des) { s/__result__/$Cond1/;};
	Step ($Cond1 eq $Cond2, @des );
}

sub Isnt {
	my ( $Cond1, $Cond2, @des ) = @_;
	foreach (@des) { s/__result__/$Cond1/;};
	Step ($Cond1 ne $Cond2, @des );
}
#change to support multi lines
sub Like {
	my ( $Cond1, $Cond2, @des ) = @_;
	foreach (@des) { s/__result__/$Cond1/;};
	Step(scalar($Cond1 =~ /$Cond2/ims ), @des);
}
#change to support multi lines
sub Unlike {
	my ( $Cond1, $Cond2, @des ) = @_;
	foreach (@des) { s/__result__/$Cond1/;};
	Step(scalar($Cond1 !~ /$Cond2/ims), @des);
}

sub Steps {
    my @steps = split("\n", $_[0]);

    foreach (@steps) {
        chomp;
        s/^(\s|\t)+//;
        s/\r|\t+$//;
        s/^"//;
        s/"$//;
    }

    my @ps;  ## parsed steps.
    $self->_parse_steps (\@ps, @steps);

    $self->_run_steps(@ps);	

}

sub _test_end_ {
  my $self = shift;
  my $cp = $self->{_test_statistics}->{_cases_passed};
  my $cf = $self->{_test_statistics}->{_cases_failed};
	my $ca = $self->{_test_statistics}->{_cases_all} = $cp + $cf;

  my $sp = $self->{_test_statistics}->{_steps_passed};
  my $sf = $self->{_test_statistics}->{_steps_failed};
	my $sa = $self->{_test_statistics}->{_steps_all} = $sp + $sf;
 	
	if ($ca) {
		$self->{_test_statistics}->{case_pass_rate} = $cp / $ca;
		$self->{_test_statistics}->{case_fail_rate} = $cf / $ca;
		$self->{_test_statistics}->{step_pass_rate} = $sp / $sa;
		$self->{_test_statistics}->{step_fail_rate} = $sf / $sa;		
	}

	$self->{_test_statistics}->{endtime} = time();
	
	_record_("TestEnd", %{$self->{_test_statistics}}, @_);
}

sub _init_Channels_ {
  my $channel;
  delete $self->{_record_channels} ;

	foreach $channel (keys %AllChannels) {
		if ( ($self->{_where_to_report}) & ($AllChannels{$channel}[0]) ) {
			my $Pkg = $AllChannels{$channel}[1];
		       my $class = 'Pet::Recorder::'.$Pkg;
			my $construct = $class.'::new';
			if ( $self->can($construct) )
				{ $self->{_record_channels}->{$AllChannels{$channel}[0]} = $class->new() ; }
		}
	}

	return $self->{_record_channels};
}


sub TestRecTo {
	$self->{_where_to_report} = shift;
	if ($self->{_where_to_report} == 0) {
		print STDERR "Nothing will be recorded for the test !!! \n";
	}
}

sub SetTestRecPath {
	$self->{_test_task_info}->{_report_path} = shift;
}

sub TestRecOpt {
	$self->{_what_to_report} = shift;
	if ($self->{_what_to_report} == 0) {
		print STDERR "Nothing will be recorded for the test !!! \n";
	}
}

sub _record_ {
	my($method, @_args) = @_;

	my $channels = $self->{_record_channels};
	foreach my $channel (values (%$channels) ) {
		if ($channel->can($method)) {
			$channel->$method (@_args);
		}
	}		
}



sub TestSuiteName {
	$self->{_test_task_info}->{_name} = shift;
}

sub 	TestSuiteDes {
	$self->{_test_task_info}->{_desc} = shift;
}

sub TestSuitePurpose {
	$self->{_test_task_info}->{_purpose} = shift;
}

sub TestPlanName {
	$self->{_test_task_info}->{_test_plan_name} = shift;
}

sub TestSuiteEnv {
	$self->{_test_task_info}->{_set_up} = shift;
}

sub OptOnFail {
	$self->{_run_time_ctl} = shift;
}

sub SubOnFail {
	$self->{_sub_on_fail} = shift;	
}


###################################################################
### TestLog related subroutines
sub TestLog {
  my $level = shift;
	my $levellog = ($level == ERROR)? "ERROR" :
                ($level == WARNING) ? "WARNING" :
                ($level == INFO) ? "INFO" :
                ($level == DEBUG) ? "DEBUG" :
                ($level == TRACE) ? "TRACE" :
		            "N/A";

	_record_ ("TestLog", $level, $levellog, @_);
}

### Aliases of TestLog
sub WarningMsg { TestLog (WARNING, @_); }
sub InfoMsg { TestLog (INFO, @_); }
sub ErrorMsg { TestLog (ERROR, @_); }
sub DebugMsg { TestLog (DEBUG, @_); }
sub TraceMsg { TestLog (TRACE, @_); }


sub _parse_steps{
    my ($self, $parsed, @steps) = @_;

    my $i = 0;
    foreach (@steps) {
    	## do nothing for blank step or comment line
        if (/^(\t|\s)*(#.*)?$/) {next; }
        if (/^(\t|\s)*;(\t|\s)*$/) {next; }

        my ($obj, $method, @args, $op, $value, $passdes, $faildes, $origin);
        $origin = $_;
	 ## To see if there are any description for this step.
        ## Get $passdes and $faildes and remove other comments
        ## format ...; #passdes#faildes# other comments
		if (s/;(\s|\t)*#(.*)//) {
			$passdes = $2;
			if ($passdes =~ s/#(.*)// ){
  			   	$faildes = $1;
              		$faildes =~ s/#.*//;
            		}else {$faildes = $passdes; }
		} else { $passdes = $faildes = ''; }

        ## Remove the simicolon at the end of the step if one.
        s/(\t|\s)*;(\t|\s)*$//;

        ## Get $op and $value
        if (m/<=|>=|==|!=|=~|!~|<|>/) {
            ($_, $op, $value) = ($`, $&, $') ;
            $value =~ s/(\s|\t)+//;
        } else { $op = $value = ''; }

        if (m/::/) { ## a tea-like step
            ($obj, $method, @args) = split /::/;
        }else { ## a pure Perl statement, just like ::::$arg $op $value
            $obj = $method = '';
            push @args, $_;
        }

        push @$parsed, {
                obj => $obj,
                method => $method,
                args => \@args,
                op => $op,
                value => $value,
                passdes => $passdes,
                faildes => $faildes,
                origin => $origin,
            };
        $i++;
 #       print "$i: obj:$obj method:$method args:@args op:$op value:$value pass:$passdes fail:$faildes *E*\n";
	}

    return $i;  ## return the number of steps
}

## To calculate an exp in main name space
## Return the expr itself as a string if can not work out it.
sub _eval_main {
    my ($self, @exp) = @_;
    my @result;
    
    foreach (@exp) {
        s/^(\s|\t)+//; s/(\s|\t)+$//;
        my $exp = $_;
        if ($exp =~ s/(^|[^\\])(\$|@|%)/$1$2main::/g ) {
            $exp = eval $exp;
            push @result, ($@)? $_ : $exp ;
        } else { push @result, $_; }
    }
    return @result;
}

## To run all steps in the Steps() function.
## There is an assumption:
## All variables, including the objects defined, are in the main name space.
## This is strictly required to invoke the Steps() function.
## the return value of all functions used in Steps() should be SCALAR or a REF. 
sub _run_steps {
    my ($self, @ps) = @_;
    my $porf = PASS;
	
    foreach my $step (@ps) {
        my ($obj, $method, $value, $passdes, $faildes) = $self->_eval_main(
                $step->{obj}, $step->{method}, $step->{value}, $step->{passdes}, $step->{faildes});
        $passdes = ' ' unless (defined $passdes);
        $faildes = ' ' unless (defined $faildes);
        my @args = $self->_eval_main(@{$step->{args}});
        my $op = $step->{op};

	my ($retval, $result); 

        if (!($method)){
            if (!($obj)) { #No obj and method, Perl Statement.
                eval { $retval = pop @args; };
            } else { #Error step
                $@ = "Runtime Error: No method indicated for the object $obj";
            }
        }  else { # There is a method
            package main;
            no strict "refs";
            if ($obj) {
                eval { $retval = ${$obj}->$method(@args); };
            } else { eval { $retval = &{$method}(@args); };  }
        }

        if ($@ or ! defined($retval) ) {
            ErrorMsg("Error in the next step: $@!");
            $result = FAIL;
            $op = '';
            $faildes = 'Runtime Error: '. $step->{origin};
        }

	if (ref ($retval) eq 'HASH') { #A Tea object method return value
		if ($retval->{failed}) {
			$result = FAIL;
			if ($faildes =~ /^\s*$/) {
				$faildes = $retval->{error};
			}
		} elsif ($retval->{multi_result}) {
			# added by pwan 2010-07-28 to support xm->hit_time() return value structure
			# get the max retval of multi results
			$result = 0.00;
			foreach ( @{ $retval->{multi_result} } ) {
				$result = ( $_->{'retval'} > $result ) ? $_->{'retval'} : $result;
			}
		} elsif ($retval->{info}) {
			$result = PASS;
			if ($passdes =~ /^\s*$/) {
				$passdes = $retval->{info}; 
			}
		} elsif ( $op =~ /^\s*$/ ) {
			$result = $retval->{retval}?PASS:FAIL;
			if ($faildes =~ /^\s*$/) {
				$faildes = $retval->{error};
			}
		} else { 
			$result = $retval->{retval}; 
		}
	} elsif (ref($retval) eq 'ARRAY') {
		$result = join ('', @$retval);
	} else { $result = $retval; }

        $passdes =~ s/__result__/$result/ ;
        $faildes =~ s/__result__/$result/ ;

	my $cond; 
	if ( $value =~ /^[+\-]?([1-9]\d*|0)(\.\d+)?([eE][+\-]?([1-9]\d*))?$/ ) { # Just test decimal numbers
		for ($op) {
			$cond =
				/^==$/? ($result == $value) : 
				/^!=$/? ($result != $value) :
				/^=~$/? scalar($result =~ $value) :
				/^!~$/? scalar($result !~ $value) :
				/^>=$/? ($result >= $value) :
				/^<=$/? ($result <= $value) :
				/^>$/ ? ($result > $value) :
				/^<$/ ? ($result < $value) :
				$result;
		}
	} else {
		for ($op) {
			$cond =
				/^==$/? ($result eq $value) : 
				/^!=$/? ($result ne $value) :
				/^=~$/? scalar($result =~ $value) :
				/^!~$/? scalar($result !~ $value) :
				/^>=$/? ($result ge $value) :
				/^<=$/? ($result le $value) :
				/^>$/ ? ($result gt $value) :
				/^<$/ ? ($result lt $value) :
				$result;
		}
	}

	Step($cond, $passdes, $faildes) or $porf = FAIL; 
    }
    return $porf;
}

sub _runtime_ctl {
	$pause_test = 1;
}

sub _pause_test {
	my $self = shift;
	my $reason = shift;
	TraceMsg ("Runtime Control: Test paused $reason");
	print "Press RETURN to continue with option $self->{_run_time_ctl}, or select a new runtime option:";
	print "\n(0)KeepRunning; (1)StopOnStepFail; (2)StopOnCaseFail; (3)PromptOnFail; \n(4)PromptByStep; (5)PromptByCase; (6)Quit; (D)Debug ";

	my $opt;
	while ($opt = <>) {
		chomp $opt;
		if ($opt =~ /^\s*$/) { 
			TraceMsg ("Runtime Control: continue with option $self->{_run_time_ctl}... ");
			$opt = $self->{_run_time_ctl};
			last;
		}
		if ($opt=~/^[0-6]$/) { 
			TraceMsg ("Runtime Control: the runtime option changed by tester from $self->{_run_time_ctl} to $opt. Continue... ");
			last; 
		}	
		if ($opt =~ /d/i) { _debug_test (); }
		print "\n(0)KeepRunning; (1)StopOnStepFail; (2)StopOnCaseFail; (3)PromptOnFail; \n(4)PromptByStep; (5)PromptByCase; (6)Quit; (D)Debug ";
		print "\nPlease input the number from 1 to 6, or D for debug: "; 
	}
	
	# $self->{_run_time_ctl} = $opt;	
	return $opt;
}

sub _debug_test {
	DebugMsg ("Start Debug......");
	print "\nInput commands to run, or Quit the debug by press Q. Use \\ at the end of a line to input multi-line command.\n"; 

	while (1) {
		my $comm = <>;
		if ($comm =~ /Q/i) { last; }
		while ( $comm =~ s/\\$//) {
			my $ext = <>;
			$comm .= $ext;
		}

		DebugMsg( "Run command: $comm");
		my @ret = $self->_eval_main ( $comm );
		if ($@) {
			DebugMsg ("Execute the command above failed");
			ErrorMsg ($@);
		} else { 
			DebugMsg ("Executed the command, the return value: @ret");
		}
	}
	DebugMsg ("End of Debug.....");
}

sub DESTROY {
  my $self = shift;
	if ( !($self->{_test_statistics}->{_test_finished} ) ) {
		$self->_test_end_();
	}
}

#### Initiate the TestRecorder 
my $_report_initiated;
_report_init_() unless (defined $_report_initiated);
local $SIG{TERM}=$SIG{INT}=\&_runtime_ctl;
$_report_initiated = 1;

1;

