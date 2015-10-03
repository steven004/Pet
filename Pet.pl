#!/usr/bin/perl
######################################################################################
#
# Usage: Usage: Pet [-cnhv] [testplanfile] [switches] [arguments]
#-b BuildNumber indicate the build number of the system/software under test.
#-c Pet will just check test bed availability, instead running all cases in the test case list.
#-d [:debugger] run program under debugger (future).
#-o [tms/console/html/xml/txt] indicate the environment of the Pet. Local run by default.
#-f [con/stop] continue the program or stop it when there is a case fail.
#-h print Usage hints.
#-n new a test plan file in current directory based on the existing test bed and test case files.
#-l OutputDir indicate the output directory of log. \tmp\pet\username\ will is the default output directory.
#-r ReleaseName indicate the release name/number of the system/software under test.
#-t TaskID indicate the test task ID for TMS. This option is just required by TMS to run the Pet.
#-u UserName indicate the who is running the test scripts. Pet will get the user name from OS if no this option.
#-v print version, subversion <includes VERY IMPORTANT Pet functionality info>.
#
######################################################################################


use Pet::Pet;
use Data::Dumper;
#use TestBed::TestBed;
use Pet::Recorder::TestRecorder;

die "$0 requires arguments.\n", if $#ARGV < 0;
our $EnableDebug = 1;

our $SWVersion = "1.0";
#my $opDir ="\\tmp\\pet\\username\\";
my $opDir ="C:/apps/";
my $args = {
	ReleaseName => "",         
	BuildNumber => "",     
	Debugger    => "",     
	Output      => "console",  
	TaskID     =>  "",     # Test Task ID, this option just is defined for TMS.
	Username     => "",    # need pet.pl input
	Testplanfile => "",	
	RunCtlFlag =>  "NO_RUNTIME_CONTROL",  
	OutputDir => $opDir,
};

$args->{'Username'} = ( "MSWin32" eq $^O ) ? $ENV{USERNAME} : $ENV{LOGNAME};

if ( 0 == $#ARGV ) {
	if ( "-h" eq $ARGV[0] ) {
		print_help();
	}
	elsif ( "-v" eq $ARGV[0] ) {
		print_version();
	}
	else {
		print_usage();
	}
}
elsif ( 1 == $#ARGV ) {
	$args->{'Testplanfile'} = $ARGV[1];
	
	my $myPet = new Pet::Pet($args);
	if ( "-c" eq $ARGV[0] ) {
		$myPet->checkTestBed();
	}
	elsif ( "-n" eq $ARGV[0] ) {
		$myPet->createTestPlan();
	}
	else {
		print_usage();
	}
}
else {
	$args->{'Testplanfile'} = shift;
	my $followArgument = "";
	while ( $_ = shift ) {
		# make sure one switch tag follows one argument
		if ( (/^-[bdoflrum]$/) xor( "" eq $followArgument ) ) {
			print_usage();
			exit;
		}
		if    (/^-b$/) { $followArgument = \( $args->{'BuildNumber'} ); }
		elsif (/^-d$/) { $followArgument = \( $args->{'Debugger'} ); }
		elsif (/^-o$/) { $followArgument = \( $args->{'Output'} ); }
		elsif (/^-f$/) { $followArgument = \( $args->{'RunCtlFlag'} ); }
		elsif (/^-l$/) { $followArgument = \( $args->{'OutputDir'} ); }
		elsif (/^-r$/) { $followArgument = \( $args->{'ReleaseName'} ); }
		elsif (/^-u$/) { $followArgument = \( $args->{'Username'} ); }
		elsif (/^-t$/) { $followArgument = \( $args->{'TaskID'} ); }
		elsif (/^-m$/) { $followArgument = \( $args->{'MailTo'} ); }
		else {
			$$followArgument = $_;
			$followArgument = "";
		}
	}

	# make sure the last argument is not missing
	if ( "" ne $followArgument ) {
		print_usage();
		exit;
	}
	# check arguments
	check_argument(%$args);
	RunTestTask Pet::Pet(%$args);
}

sub print_version {
	print "Version: $SWVersion\n";
}

sub check_argument {
	my %args = @_;
	# print Dumper(%args);
	# check Output
	foreach my $output (split(/\|/, $args->{'Output'})) {
		die "Invalid argument $output followed by -o" 
		unless grep( /$output$/i, qw(tms console html xml txt) );
	}

	# check RunCtlFlag
	my %RunCtlFlag = (
		KEEP_RUNNING => 0,  
		STOP_ON_STEP_FAIL => 1,  
		STOP_ON_CASE_FAIL => 2, 
		PROMPT_ON_FAIL => 3,
		PROMPT_BY_STEP=>4, 
		PROMPT_BY_CASE=>5, 
		TEST_QUIT=>6, 
		NO_RUNTIME_CONTROL=>-1,
	);
	die "Invalid argument $args->{'RunCtlFlag'} followed by -f" 
	unless exists($RunCtlFlag{$args->{'RunCtlFlag'}});
	$args->{'RunCtlFlag'} = $RunCtlFlag{$args->{'RunCtlFlag'}};
}

sub print_help {
	print_usage();
	print_options();
}

sub print_usage {
	print "\nUsage: Pet [-cnhv] [testplanfile] [switches] [arguments]\n";
}

sub print_options {
	my %options = (
		'-b' => 'BuildNumber indicate the build number of the system/software under test',
		'-c' => 'Pet will just check test bed availability, instead running all cases in the test case list',
		'-d' => '[:debugger] run program under debugger (future)',
		'-o' => '[tms/console/html/xml/txt] indicate the environment of the Pet. Local run by default',
		'-f' => '[KEEP_RUNNING/STOP_ON_STEP_FAIL/STOP_ON_CASE_FAIL/PROMPT_ON_FAIL/PROMPT_BY_STEP/PROMPT_BY_CASE/TEST_QUIT] continue the program or stop it when there is a case fail',
		'-h' => 'print Usage hints',
		'-n' => 'new a test plan file in current directory based on the existing test bed and test case files',
		'-l' => 'OutputDir indicate the output directory of log. \tmp\pet\username\ will be used for the default output directory',
		'-r' => 'ReleaseName indicate the release name/number of the system/software under test',
		'-u' => 'UserName indicate the who is running the test scripts. Pet will get the user name from OS if no this option',
		'-t' => 'TaskID indicate the test task ID for TMS. This option is just required by TMS to run the Pet',
		'-v' => 'print version, subversion <includes VERY IMPORTANT Pet functionality info>',
		'-m' => 'the mail address for test result reports',
	);
	
	foreach (keys %options) {
		print "\t", $_, "\t", $options{$_}, "\n";
	}

}


__END__

perl Pet.pl ..\Testplan_Example.txt -b 1.1 -r 2.7.0


[correct]
perl Pet.pl -v
perl Pet.pl -h
perl Pet.pl -c ../Testplan_Example.xml
perl Pet.pl -n ../Testplan_Example.xml
perl Pet.pl ../Testplan_Example.xml -b 1.1 -e tms -f con -o /shard1/sqa/ -r 2.7.0 -u Steven
perl Pet.pl ../Testplan_Example.xml -b 1.1 -r 2.7.0


[invalid]
perl Pet.pl -v ../Testplan_Example.xml
perl Pet.pl -h -b 1.1
perl Pet.pl -c 
perl Pet.pl -n ../Testplan_Example.xml -b 1.1 -e tms -f
perl Pet.pl ../Testplan_Example.xml -b 1.1 -e tmss -f con -o /shard1/sqa/ -r 2.7.0 -u Steven
perl Pet.pl ../Testplan_Example.xml -b 1.1 -e tms -f conn -o /shard1/sqa/ -r 2.7.0 -u Steven
perl Pet.pl ../Testplan_Example.xml -b 1.1 -r 2.7.0 -x nothing
perl Pet.pl ../Testplan_Example.xml -b 1.1 -r 2.7.0 -o
Pet /home/steven/script/Private_Lib/TL1_Example/TestPlans/tl1_auto_eg.xml -m steven004@gmail.com -f PROMPT_ON_FAIL
