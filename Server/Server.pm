package Pet::Server::Server;

use strict;

use Expect;
use Net::Telnet;

#################################################################################
sub new {
#################################################################################
# %args include : host, [user], [passwd], [mode]
#################################################################################
	my ($class, %args) = @_;
	my $this = {
		service	=> undef,
		errMsg	=> undef,
		
		host	=> undef,
		user	=> undef,
		passwd	=> undef,
		mode	=> undef, #Telnet/SSH/FTP/SFTP
	};
	bless $this, $class;
	
	if(! exists($args{'host'})) {
		print "Please input service host.\n";
		exit;
	}
	
	foreach(keys %args) {
		if(/^host$/i) {
			$this->{host} = $args{$_};
		} elsif(/^user$/i) {
			$this->{user} = $args{$_};
		} elsif(/^passw(or)?d$/i) {
			$this->{passwd} = $args{$_};
		} elsif(/^mode$/i) {
			$this->{mode} = $args{$_};
		}
	}
	
	return $this;
}

#################################################################################
sub open {
#################################################################################
	my ($this) = @_;
	
	if($this->{mode} =~ /^Telnet$/i) {
		$this->{service} = Net::Telnet->new(Timeout=>10);
		$this->{service}->open(Host=>$this->{host});
		$this->{service}->login($this->{user}, $this->{passwd});
		
	} elsif($this->{mode} =~ /^SSH$/i) {
		$this->_open("ssh");
		
	} elsif($this->{mode} =~ /^FTP$/i) {
		$this->_open("ftp");
		
	} elsif($this->{mode} =~ /^SFTP$/i) {
		$this->_open("sftp");
	}
}

sub _open {
	my ($this, $mode) = @_;
	
	my $str = $this->{user}."@".$this->{host};
	$this->{service} = Expect->spawn($mode, $str);
	$this->{service}->expect(5,
			[qr/password/i => sub { 
					my $exp = shift;
					$exp->send($this->{passwd}."\n");}],
			[qr/yes\/no/ => sub {
					my $exp = shift;
					$exp->send("yes\n");
					sleep 2;
					$exp->send($this->{passwd}."\n");}]);
	$this->{service}->expect(5);
}

#################################################################################
sub get{
#################################################################################
	my ($this, $key) = @_;
	
	return $this->{$key};
}

#################################################################################
sub set{
#################################################################################
	my ($this, $key, $value) = @_;
	
	$this->{$key} = $value;
}

#################################################################################
sub cd {
#################################################################################
	my ($this, $path) = @_;
	
	if($this->{mode} =~ /^(Telnet)$/i) {
		$this->{service}->cmd("cd $path");
	} elsif($this->{mode} =~ /^(SSH|FTP|SFTP)$/i) {
		$this->{service}->send("cd $path");
		$this->{service}->expect(2);
	}
}

#################################################################################
sub cmd {
#################################################################################
	my ($this, $cmd, $timeout) = @_;
	
	my $result;
	if($this->{mode} =~ /^(Telnet)$/i) {
		$result = $this->{service}->cmd("$cmd");
		
	} elsif($this->{mode} =~ /^(SSH|FTP|SFTP)$/i) {
		$this->{service}->send("$cmd");
		$this->{service}->expect($timeout);
		$result = $this->{service}->before();
	}
	
	return $result;
}

#################################################################################
sub errmsg {
#################################################################################
}

#################################################################################
sub close {
#################################################################################
	my ($this) = @_;
	
	$this->{service}->close;
}

1;