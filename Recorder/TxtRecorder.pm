package Pet::Recorder::TxtRecorder;
require Exporter;
use Time::Local;
use POSIX qw(strftime);


sub new() {
	my ( $class, %args ) = @_;

	#save the args
	my $self = {
		args=>\%args,
	};



	bless( $self, $class );

	#init the output dir and log/result html file
	$self->_init_output();

	return $self;
}

sub step() {
	my $self  = shift;
	my %args=@_;

	$self->_output_txt( 'TestStep ' . %args->{stepname}.' result = '.%args->{result} );
	$self->_output_txt( '                  Expect Result='.%args->{expect});
    $self->_output_txt( '                  ActualRestult='.%args->{actual});

}

sub case() {
	my $self  = shift;
    my %args=@_;

    $self->_output_txt( 'TestCase ' . %args->{casename}.' result = '.%args->{result} );
    $self->_output_txt( '                  Expect Result='.%args->{expect});
    $self->_output_txt( '                  ActualRestult='.%args->{actual});


}



#create out put files
sub _init_output() {
	my  $self  = shift;
	my $now_string = strftime( "%Y-%m-%d-%H-%M-%S", localtime );

	my $filname = $self->{args}->{OutputDir} . '\\' . $self->{args}->{Testplanname} . '-' . $now_string;

	#init the test report file
	my $report = '>' . $filname . '_report' .'.txt';
	open( REPORT, $report ) or die $!;
	$self->_output_txt('TestPlanName='.$self->{args}->{Testplanname});
	$self->_output_txt('User='.$self->{args}->{Username});
	$self->_output_txt('BuildNumber='.$self->{args}->{BuildNumber});
	$self->_output_txt('ReleaseNumber='.$self->{args}->{ReleaseName});

}

sub _output_txt()
{
	#output to a file
	my ( $self, $output_string ) = @_;
	
	print REPORT $output_string;	
	print REPORT "\n";
	
}
#close the file handle
sub end()
{
	close(REPORT);
}
1;

