#!/usr/bin/perl
package Pet::TestCase::XLS_TC;

use Pet::common::CLI;
use Pet::TestCase::WorkSheet;
use Data::Dumper;
use strict;

sub new {
	my($class, %args) = @_;
	my $self = {
		_case => '',
		_cli_handle => '',
	};	
	for ( keys %args ) {
		if (/^CliHandle$/) {
			$self->{_cli_handle} = $args{$_};
		}
	}
	bless $self, $class;
	return $self;
}

sub RunCaseFile {
	my $self = shift;
	my $xlsFilename = shift;
	my $worksheetIndex = 0;
	while(my $case_content = new TestCase::WorkSheet( xlsfile => $xlsFilename, worksheetindex => $worksheetIndex++)) {
		# $case_content->dump_test_cases();
		local $_ = $case_content->{'CaseInfo'}->{'_template_type'};
		if(/OSS TL1/) {
			my $cli_if = new Pet::Common::CLI($self->{_cli_handle});
			$cli_if->run($case_content);
		# }elsif{
		}
	}
}
1;

