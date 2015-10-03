package Pet::Pet;

#use Pet::Tea::Tea;
use Pet::Recorder::TestRecorder;
use Pet::TestCase::XLS_TC;
use XML::Simple;
use Cwd 'abs_path';
use File::Spec;
use Data::Dumper;

#Pet.pm
#Pet.pm is the main part of Pet engine, which support Perl scripts test tasks execution
#with different options. It support all objects defined in TEA also, e.g. Node, Card, Trunk.
#
#PetFS.1 Pet is a Perl package provides support for test task execution and test results
#recording. Pet.pm supports the following subroutines:
#?  new(testParameters): to create the Pet environment for test task running
#?  runTestTask(): to run a test task
#?  createTestPlan(): to create a test plan with the indicated test suite directory
#?  checkTestBed(): just check test bed, instead of running a test task.
#?  runTeaStep(): (Phase II) run tea type test steps.
#?  runTeaTest(): (Phase II) run a tea test input file (test cases).
#
#PetFS.2 Pet package should support all objects defined in TEA, including objects defined
#for systems under test, and objects defined for test equipment and communications;


sub new {
	my($class, $args) = @_;
	bless $args, $class;
	return $args;
}

# create the Pet environment for test task running
sub RunTestTask {
	my ( $class, %args ) = @_;
   my $self = {
		_testname => undef,
		_testpurpose => undef,
		_testdesc => undef,
		_programname => undef,
		_buildnumber => undef,
		_setup => undef,
		_debugger   => undef,
		_output   => undef,
		_runctlflag    => undef,
		_outputdir   => undef,
		_username => undef,
		_testplan_file => undef, 
		_testplan_dir  => undef, 
		_phytestbed_file  => undef, 
		_testcase_files => undef,
		_tea_engine => undef,
		_suite_file => undef,
		_mailto => undef,
	};

   bless $self, $class;

   # print Dumper(%args);
	for ( keys %args ) {
		if (/^ReleaseName$/) {
			$self->{_programname} = $args{$_};
		}
		elsif (/^BuildNumber$/) {
			$self->{_buildnumber} = $args{$_};
		}
		elsif (/^Debugger$/) {
			$self->{_debugger} = $args{$_};
		}
		elsif (/^Output$/) {
			$self->{_output} = $args{$_};
		}
		elsif (/^RunCtlFlag$/) {
			$self->{_runctlflag} = $args{$_};
		}
		elsif (/^OutputDir$/) {
			$self->{_outputdir} = $args{$_};
		}
		elsif (/^Username$/) {
			$self->{_username} = $args{$_};
		}
		elsif (/^TaskID$/) {
			$self->{_taskid} = $args{$_};
		}
		elsif (/^Testplanfile$/) {
			$self->{_testplan_file} = $args{$_};
		}
		elsif (/^MailTo$/) {
			$self->{_mailto} = $args{$_};
		}		
	}
	$self->parse_testplan();
	$self->InitTestbed() if $self->{_phytestbed_file};
	if($self->{_suite_file}) {
		eval {
			package main;
			
			do $self->{_suite_file};
		};
		if ($@) {
			print $@;
			print "Config $self->{_suite_file} fail\n";
		}					
	}
	
	TestStart(name	=> $self->{_testname}, 
		purpose	=> $self->{_testpurpose},
		desc 	=> $self->{_testdesc}, 
		release	=> $self->{_programname},
		build	=> $self->{_buildnumber},
		mail	=> $self->{_mailto},
		FailOpt	=> $self->{_runctlflag},);
	SetTestRecPath($self->{_outputdir}) if $self->{_outputdir};
	my $testbed_ready = PASS;

	$testbed_ready = {main::TestBedSetup()} if exists(&main::TestBedSetup);
	if($testbed_ready) {
		foreach my $casefile (@{$self->{_testcase_files}}) {
			$self->RunCaseFile($casefile);
		}
	}

	main::TestBedClearup() if exists(&main::TestBedClearup);
	TestEnd();
	
	return $self;
}
sub parse_testplan {
	my ($self, $testplanfile) = @_;
	$self->{_testplan_file} = $testplanfile if $testplanfile;
	die "Can't read Testplan: ", $self->{_testplan_file}, "\n"
	  unless -r $self->{_testplan_file};	
	
	abs_path($self->{_testplan_file}) =~ /(.*[\\\/])/;
	$self->{_testplan_dir} = $1;
	
	local $_ = $self->{_testplan_file};
	if(/.pl$/) {
		eval {	package main; do $_;	};
		if ($@) {
			print $@;
			print "Exec $_ fail!\n";
		}	
		
	} elsif(/.xml$/) {
		# parse XML file
		my $xml  = XML::Simple->new();
		my $data = $xml->XMLin( $self->{_testplan_file}, ForceArray => 1 );
		
		# remove spaces
		foreach (qw(TestName Purpose Description Program Build Setup SuiteFile PhysicalTestBedFile)) {
			$data->{$_} =~ s/^[\s]+//;
			$data->{$_} =~ s/[\s]+$//;
		}
		
		# test name
		$self->{_testname} = $data->{'TestName'};
		$self->{_testname} = pop(@{File::Spec->splitpath($self->{_testplan_file})}) unless $self->{_testname};
		
		# test purpose
		$self->{_testpurpose} = $data->{'Purpose'};

		# test description
		$self->{_testdesc} = $data->{'Description'};

		# program under test
		$self->{_programname} = $data->{'Program'};
		
		# build under test
		$self->{_buildnumber} = $data->{'Build'};		
		
		# testbed setup requirement
		$self->{_setup} = $data->{'Setup'};			
		
		# test suite file
		$self->{_suite_file} = File::Spec->rel2abs($data->{'SuiteFile'}, $self->{_testplan_dir});
		
		# configure testbed
		$self->{_phytestbed_file} = File::Spec->rel2abs($data->{'PhysicalTestBedFile'}, $self->{_testplan_dir});

		# run test cases
		foreach my $testCase (@{$data->{'TestCases'}->[0]->{'File'}}) {
			$testCase =~ s/^[\s]+//;
			$testCase =~ s/[\s]+$//;
			push @{$self->{_testcase_files}}, File::Spec->rel2abs($testCase, $self->{_testplan_dir});
		}
	}
	return $self;
}
	

sub InitTestbed {
	my ($self, $phytestbedfile) = @_;
	$self->{_phytestbed_file} = $phytestbedfile if $phytestbedfile;
	die "Can't read Physical Testbed file: ", $self->{_phytestbed_file}, "\n"
	  unless -r $self->{_phytestbed_file};		

	local $_ = $self->{_phytestbed_file};
	if(/\.pl$/) {
		eval {
			print("do test bed");
			package main;
			print($self->{_phytestbed_file});
			do $self->{_phytestbed_file};
		};
		if ($@) {
			print $@;
			print "Config $self->{_phytestbed_file} fail\n";
		}				
	} elsif(/\.(txt|ttb|bed)$/i) {
		$self->{_tea_engine} = InitTestbed Pet::Tea::Tea(Output => $self->{_output}, 
									Version => $self->{_programname}, 
									Build => $self->{_buildnumber}, 
									Config => $self->{_phytestbed_file},
									MailTo => $self->{_mailto});
	} else {
		die "Failed! Unsupported TestBed Format $self->{_phytestbed_file}\n";
	}	 
	return $self;
}


sub RunCaseFile {
	my $self = shift;
	my $casefile = shift;

	die "Can't read case file: ", $casefile, "\n"  unless -r $casefile;	

	local $_ = $casefile;
	if(/\.pl$/) {
		eval {	
			package main; 
			our $MailTo = $self->{_mailto};
			print("do casefile...\n");
			print("$casefile\n");
			do $casefile;	
		};
		if ($@) {
			print $@;
			print "Exec $casefile fail!\n";
		}				
	} elsif(/\.(txt|ttc)$/) {
		die "No TEA configure file found!\n" unless $self->{_tea_engine};
		$self->{_tea_engine}->RunCaseFile($casefile);
	} elsif(/\.xls$/) {
		my $xls_tc = new Pet::TestCase::XLS_TC(CliHandle => ${main::exp});
		$xls_tc->RunCaseFile($casefile);
	}
}
1;

__END__

# run a test task
sub runTestTask {

	my $self = shift;
	print "runTestTask...\n";

	package main;

	$report = new Pet::TestRecorder(
		Testplanname => "",
		ReleaseName  => $self->{_programname},
		BuildNumber  => $self->{_buildnumber},
		Output       => $self->{_output},
		OutputDir    => $self->{_outputdir},
		TaskID       => $self->{_taskid},
		Username     => $self->{_username},
		Testplanfile => $self->{_testplan_file},
	);

	#run TestSuite.pl file to get the test suite information
	eval {
		do $self->{_testsuitfile};

#run TestBedSetup() subroutine to provision the common environment for test cases;
		TestBedSetup();
	};
	if ($@) {
		print $@;
		print '\r\n';
		print 'test bed setup failure,check your script and environment \r\n';
	}

#run test case files listed in the test plan file one by one; test results will be recorded;
	foreach my $testcase ( @{ $self->{_testcases} } ) {		
		do $testcase;
		if ($@) {
			print $@;
			print '\r\n';
			print 'please check this exception \r\n';
		}
	}

	#run TestBedClearup() to de-provision the test environment;
	eval { TestBedClearup(); };
	if ($@) {
		print $@;
		print '\r\n';
		print
		  'test bed clear up failure,check your script and environment \r\n';
	}

#run test bed destroy subroutine to delete the test bed, recover the clean system.
	$self->{_testbed}->destory();

}

# create a test plan with the indicated test suite directory
sub createTestPlan {
	my $self = shift;
	print "createTestPlan...\n";
	return "Success";

}

# just check test bed, instead of running a test task.
sub checkTestBed {
	my $self  = shift;
	my $level = shift;

	#Arguments: level       # to be defined.
	print "checkTestBed...\n";
	return $self->{_testbed}->Verify();

}

# (Phase II) run tea type test steps
sub runTeaStep {

	package main;
	my $self      = shift;
	my @TestSteps = @_;
	print "runTeaStep...\n";
	foreach my $step (@TestSteps) {
		eval {

			#run by tea engine
			my $ret = $runtime->do_step($step);
			if ($ret) {
				return "Success";
			}
			else {
				return "Failed";
			}
		};
		if ($@) {
			print $@;
			print '\r\n';
			print
'make sure you are use tea config file and all object is defined\r\n';
		}

	}
}

# (Phase II) run tea test input file (test cases)
sub runTeaTest {

	package main;
	my $self     = shift;
	my $filename = shift;
	print "runTeaTest...\n";
	eval {
		$tea->init_input($filename);

		$tea->invoke();
	};
	if ($@) {
		print $@;
		print '\r\n';
		print
		  'make sure you are use tea config file and all object is defined\r\n';
	}

	return;    # return the last case's result
}

1;
