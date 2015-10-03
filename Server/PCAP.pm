package Pet::Server::PCAP;

use strict;

use base qw(Pet::Server::Server);

#################################################################################
sub new {
#################################################################################
# %args include : host, user, passwd, mode, path, filelist, intf1, [intf2].
#################################################################################
	my ($class, %args) = @_;
	my $this = Pet::Server::Server::new($class, %args);
	bless $this, $class;
	
	foreach(keys %args) {
		if(/^path$/i) {
			$this->{path} = $args{$_};
		} elsif(/^filelist$/i) {
			$this->{filelist} = $args{$_};
		} elsif(/^intf$/i) {
			$this->{intf} = $args{$_};
		}
	}
	
	if(defined $this->{filelist}) {
		my @files = split(/;/, $this->{filelist});
		$this->{filesRef} = \@files;
	}
	
	return $this;
}

#################################################################################
sub start {
#################################################################################
# input params support : 1. $this
#                        2. $this, $intf
#                        3. $this, $intf, $params
#################################################################################
	my ($this, $intf, $params) = @_;
	
	my $command;
	my @files = @{$this->{filesRef}};
	foreach(@files) {
		my $cmd;
		if(defined($intf)) {
			$cmd = "tcpreplay -i ".$intf." --timer=gtod $params ".$this->{path}.$_.";";
		} else {
			$cmd = "tcpreplay -i ".$this->{intf}." --timer=gtod ".$this->{path}.$_.";";
		}
		$command.= "date;".$cmd;
	}
	
	my $tmpCmdsFile = "/tmp/tmpPCAP.sh";
	my $tmpOutFile  = "/tmp/pcap.out";
	$this->{service}->expect(1, -re=>'#');
	$this->{service}->send("echo '$command' > $tmpCmdsFile\n");
	$this->{service}->expect(2);
	$this->{service}->send("chmod 777 $tmpCmdsFile\n");
	$this->{service}->expect(2);
	$this->{service}->send("nohup $tmpCmdsFile >> $tmpOutFile &\n");
	$this->{service}->expect(5);
}

#################################################################################
sub stop {
#################################################################################
	my ($this) = @_;
	
	my @files = @{$this->{filesRef}};
	foreach(@files) {
		my $file = $this->{path}.$_;
		$this->{service}->send("ps -ef |grep $file\n");
		$this->{service}->expect(5);
		my $result = $this->{service}->before();
		$result =~ /root(\s+)(\d+)/i;
		my $pid = $2;
		
		$this->{service}->send("kill -9 $pid\n");
		$this->{service}->expect(5);
	}
}

#################################################################################
sub isRunning {
#################################################################################
	my ($this) = @_;
	
	my $isRunning = 0;
	my @files = @{$this->{filesRef}};
	foreach(@files) {
		my $file = $this->{path}.$_;
		$this->{service}->send("ps -ef |grep $file\n");
		$this->{service}->expect(5, -re=>'$file');
		my $num = $this->{service}->match_number();
		if($num > 1) {
			$isRunning = 1;
			last;
		}
	}
	
	return $isRunning;
}

1;