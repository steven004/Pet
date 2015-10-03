package Pet::Recorder::ConsoleRecorder;

sub new {
	my ( $class, %args ) = @_;

	#define some var need save
	my $self = { 
		_case_index => 0,
		_step_index => 0,
	};
	
	bless( $self, $class );

	return $self;
}

## A hash table passed to this subroutine to indicate the test information ##
sub TestStart {
	my($self, %TestAttr) = @_;
	foreach my $attr (keys %TestAttr) {
		print "$attr:\t $TestAttr{$attr} \n";
	}
	print "\n------------------Test Start -------------------------\n";
}

## A hash table passed to this subroutine to indicate test runtime info, and test statistics information ##
sub TestEnd {
	my($self, %TestAttr) = @_;

	print "\n-----------------Test End ---------------------------\n";
	foreach my $attr (keys %TestAttr) {
		print "$attr:\t $TestAttr{$attr} \n";
	}
}

## Parameters: (CaseNo, CaseDescription) ###
sub CaseStart {
	print "\nCase $_[1] Start: $_[2] \n";
}

## Parameters: (CaseNo, CaseStatus: PASS or FAIL) ###
sub CaseEnd {
  my $result = $_[2]?'PASS':'FAIL';
	print "Case $_[1] ----------- $result ----------- \n";
}

##Parameters: (StepNo, StepStatus: PASS or FAIL, Desc) ###
sub Step {
	print "\tStep $_[1]: \t";
	print $_[2]?'PASS':'FAIL';
	print "\t$_[3]\n";
}

## Parameter: (Level, Message) ###
sub TestLog {
	my ($self, $level, $levellog, $note) = @_;

	print "\t  Log (-$levellog-)\t$note\n";
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

