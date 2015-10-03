package Pet::TestBed::TestBed;

## TestBed is to setup testbed according to configuration file

$VERSION = '1.0.0';
use Pet::TestBed::TestBedService;

require Exporter;
our @ISA = qw(Exporter);

use strict;
#use warnings;

#export pub method and each Constants
our @EXPORT =  qw(
  	LoadTestBedCfg  CheckTestBedHealth CreateTestBed CleanTestBed LoadObjsOnly GetServiceObjects
);

use constant {
};

# the default testbed handle
my $self;

sub LoadTestBedCfg {
	if (@_) {
       	 my %CfgFile = @_;
    	my ($_phy_testbed_file_name, $_phy_testbed_sheet_index, $_log_testbed_file_name, $_log_testbed_sheet_index);
 		for (keys %CfgFile) {
 			if (/PhyTestBedFileName/i) { 
				$_phy_testbed_file_name = $CfgFile{$_} ; 
 			} elsif (/PhyTestBedSheetIndex/i) {
 				$_phy_testbed_sheet_index = $CfgFile{$_} ; 
	 		} elsif (/LogTestBedFileName/i) {
 				$_log_testbed_file_name = $CfgFile{$_} ; 
 			} elsif (/LogTestBedSheetIndex/i) {
 				$_log_testbed_sheet_index = $CfgFile{$_} ; 
			} 
  		};

		if(defined $_phy_testbed_file_name and defined $_phy_testbed_sheet_index) {
			# load Pet::TestBed::PhysicalTestBed (XLSFile => $_phy_testbed_file_name,	
									# WorksheetIndex => $_phy_testbed_sheet_index);
			$self = new Pet::TestBed::TestBedService (XLSFile => $_phy_testbed_file_name,	
									WorksheetIndex => $_phy_testbed_sheet_index);									
		}
		
		if(defined $_log_testbed_file_name and defined $_log_testbed_sheet_index) {
			$self = new Pet::TestBed::TestBedService (XLSFile => $_log_testbed_file_name,	
									WorksheetIndex => $_log_testbed_sheet_index);
		}
		return $self;
	}	
}

sub CheckTestBedHealth {
	my $testbed;
	if(@_ > 0) {
		$testbed = shift;
	} else {
		$testbed = $self;
	}
	$testbed->check_testbed();
}
sub CreateTestBed {
	my $testbed;
	if(@_ > 0) {
		$testbed = shift;
	} else {
		$testbed = $self;
	}
	$testbed->cfg_testbed();
}
sub CleanTestBed {
	my $testbed;
	if(@_ > 0) {
		$testbed = shift;
	} else {
		$testbed = $self;
	}
	$testbed->clear();
}
sub LoadObjsOnly {
	my $testbed;
	if(@_ > 0) {
		$testbed = shift;
	} else {
		$testbed = $self;
	}
	$testbed->collect_TEAObj();
}
sub GetServiceObjects {
	my ($testbed, $serviceType);
	if(@_ > 0) {
		$testbed = shift;
		$serviceType = shift;
	} else {
		$testbed = $self;
	}
	my $allService = $testbed->collect_TEAObj();
	if(defined $serviceType) {
		my @result;
		foreach (@{$allService}) {
			push @result, $_ if($_->nm_name() =~ /\Q$serviceType\E/);
		}
		return @result;
	}else {
		return @{$allService};
	}
}

1;
