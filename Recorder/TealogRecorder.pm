package Pet::Recorder::TealogRecorder;


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

	my %teaargs = (
		Name => 'Undefined',
		Purpose => 'Undefined',
		Setup => 'Undefined',
		Build => '',
		Host => 'Unknown IP',
		Testid => '',
		LogFile => '/tmp/pet_output/',
		Parameters=> [ 
			'ip' => ' ',
			'user' => 'N/A',
			'pass' => '',
		],
	);

 	for (keys %TestAttr) {
 		if (/name/i) { $teaargs{Name} = $TestAttr{$_} ; 
 	} elsif (/desc/i) {
 		$teaargs{Purpose} = $TestAttr{$_}; 
 	} elsif (/setup/i) {
 		$teaargs{Setup} = $TestAttr{$_};
 	} elsif (/release/i) {
 		$teaargs{Build} = $TestAttr{$_} . $teaargs{Build}; 
 	} elsif (/build/i) {
 		$teaargs{Build} .= '-'.$TestAttr{$_};
	} elsif (/host|ip/i) {
		$teaargs{Host} = $teaargs{Parameter}[1] = $TestAttr{$_};
	} elsif (/id/i) {
		$teaargs{Testid} = $TestAttr{$_};
	} elsif (/output|path|dir/i) {
		$teaargs{LogFile} = $TestAttr{$_};
	} elsif (/user/i) {
		$teaargs{Parameters}[3] = $TestAttr{$_};
	} else { $teaargs{$_} = $TestAttr{$_}; }
  };

  if ( $teaargs{Parameter}[3] == 'N/A' ){
    $teaargs{Parameters}[3] = ($^O =~ /MSWin32/) ? $ENV{'USERNAME'}:$ENV{'USER'};
  }

 	$teatestcase = new Pet::Testcase (%teaargs);
}

## A hash table passed to this subroutine to indicate test runtime info, and test statistics information ##
sub TestEnd {
	$teatestcase->end;
}

## Parameters: (CaseNo, CaseDescription) ###
sub CaseStart {
	$teastep = $teatestcase->step(Description => $_[2]);
}

## Parameters: (CaseNo, CaseStatus: PASS or FAIL) ###
sub CaseEnd {
	$teastep->end;
}

##Parameters: (StepNo, StepStatus: PASS or FAIL, Desc) ###
sub Step {
	my ($self, $index, $condition, $desc) = @_;
	my $desc1 = ' ' ;
	my $desc2 = ' ' ; 

	if ($condition) { $desc1 = $desc; } 
	else { $desc2 = $desc; }
	$teastep->check($condition, $desc1, $desc2); 
}

## Parameter: (Level, Message) ###
sub TestLog {
	my ($self, $level, $levellog, $note) = @_;

	my $logfunc = lc $levellog;	
	if ($teatestcase->can($logfunc) ) {
		$teatestcase->$logfunc($note);
	}
}

=pod
  	CaseStart   Step
  	Pass  Is  Like  Isnt  Fail
  	TestLog WarningMsg  InfoMsg  ErrorMsg  CaseEnd
  	TestRecTo  SetTestRecPath  TestRecOpt

sub step() {
	my $self = shift;
	my %args = @_;
	$self->_output_console(
		'TestStep ' . %args->{stepname} . ' result = ' . %args->{result} );
	$self->_output_console(
		'                  Expect Result=' . %args->{expect} );
	$self->_output_console(
		'                  ActualRestult=' . %args->{actual} );

}

sub case() {
	my $self = shift;
	my %args = @_;
	$self->_output_console(
		'TestCase ' . %args->{casename} . ' result = ' . %args->{result} );
	$self->_output_console(
		'                  Expect Result=' . %args->{expect} );
	$self->_output_console(
		'                  ActualRestult=' . %args->{actual} );

}

sub _init_output() {
	my $self = shift;

	$self->_output_console( 'TestPlanName=' . $self->{args}->{Testplanfile} );
	$self->_output_console( 'User=' . $self->{args}->{Username} );
	$self->_output_console( 'BuildNumber=' . $self->{args}->{BuildNumber} );
	$self->_output_console( 'ReleaseNumber=' . $self->{args}->{ReleaseName} );

}

sub _output_console() {

	#output to a file
	my ( $self, $output_string ) = @_;
	print $output_string;
	print "\n";

}

#close the file handle
sub end() {

}
=cut

1;

