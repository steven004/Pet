package Pet::Recorder::EmailRecorder;

use Mail::Sender;

# The configuration of Mail server and account should be modified as per the real case
# Here they are just fake name
use constant {
	MAILFROM => 'pet@gmail.com',
	SMTPSERVER => 'smtp.gmail.com',
};

my ($sender, $FH);

sub new {
	my ( $class, %args ) = @_;

	#define some var need save
	my $self = { 
		_task_info => {}, 
		_summary => {},
	};
	
	bless( $self, $class );

	return $self;
}

## A hash table passed to this subroutine to indicate the test information ##
sub TestStart {
	my($self, %TestAttr) = @_;
	my ($mailto, $mailsub);

	foreach (keys %TestAttr) {
		if (/mail/i) {
			$mailto = $TestAttr{$_};
		} elsif (/name/i) {
			$mailsub = $TestAttr{$_};
		}
		$self->{_task_info}->{$_} = $TestAttr{$_};
	}

	ref ($sender = new Mail::Sender { from => MAILFROM(),
       	smtp => SMTPSERVER()})
		or die "Error($sender) : $Mail::Sender::Error\n";
		
	ref $sender->Open({to => $mailto,
            subject => $mailsub})
        	or die "Error: $Mail::Sender::Error\n";

	$FH = $sender->GetHandle();
	print $FH "Test Task Information:\n";

	foreach (keys %{$self->{_task_info}}){
		print $FH "\t$_:\t$self->{_task_info}->{$_}\n";
	}
        
}

## A hash table passed to this subroutine to indicate test runtime info, and test statistics information ##
sub TestEnd {
	my($self, %TestAttr) = @_;

	foreach my $attr (keys %TestAttr) {
		$self->{_summary}->{$attr} = $TestAttr{$attr};
	}

	print $FH "\n\n ------------------ TEST END ----------------\n\n";
	print $FH "Test Summary Information:\n";
	foreach (keys %{$self->{_summary}}){
		print $FH "\t $_:\t$self->{_summary}->{$_}\n";
	}
 
  $sender->Close;
}

=pod
## Parameters: (CaseNo, CaseDescription) ###
sub CaseStart {
}

## Parameters: (CaseNo, CaseStatus: PASS or FAIL) ###
sub CaseEnd {
}

##Parameters: (StepNo, StepStatus: PASS or FAIL, Desc) ###
sub Step {
}

## Parameter: (Level, Message) ###
sub TestLog {

}
=cut

1;

