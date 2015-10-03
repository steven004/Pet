package Pet::TestBed::PhysicalTestBed;
use Spreadsheet::ParseExcel;
use strict;

sub load {
	my($class, %args) = @_;
	my($xlsFilename, $worksheetIndex);
	for(keys %args) {
		if(/-?xlsfile$/i) {
			$xlsFilename = delete $args{$_};
		}elsif(/-?worksheetindex/i) {
			$worksheetIndex = delete $args{$_};
		}
	}
	
	if (!defined($xlsFilename) or !defined($worksheetIndex))
	{
	   die ("usage: XLSFile, WorksheetIndex\n");
	}
	my $self = {"XLSFile" => $xlsFilename, 
		"WorksheetIndex" => $worksheetIndex, 
	};
	bless $self, $class;

	my $xlsContent = $self->parseXLS();
	no strict 'refs';	
	for(my $i=0; defined($xlsContent->{$i}); $i++) {
		my $par_name = $xlsContent->{$i}->{0}->{'content'};
		last unless $par_name;
		my $par_value = $xlsContent->{$i}->{1}->{'content'};
		${"main::$par_name"} = Translate($par_value);
	}	
	return $self;
}

sub Translate {
	my $value          = shift;
	return undef unless defined $value;
	return $value unless ( $value =~ /\$/ );
	my @sections = split( /\$/, $value );
	my $resultValue = $sections[0];
	for ( my $i = 1 ; $i < scalar(@sections) ; $i++ ) {
		my $const_part = $sections[$i];
		$const_part =~ s/^[[:word:]]+//;
		my $var_part = $sections[$i];
		$var_part =~ s/$const_part$//;
		no strict 'refs';
		if ( defined ${"main::$var_part"} ) {
			$resultValue .= ${"main::$var_part"} . $const_part;
		}
		else {
			$resultValue .= $sections[$i];
		}
	}

	#	print "before: ", $value, "\tafter: ", $resultValue, "\n";
	return $resultValue;
}

sub parseXLS {
	my $self = shift;
	my $xlsFilename = $self->{"XLSFile"};
	my $worksheetIndex = $self->{"WorksheetIndex"};
	my $xlsContent = { };

	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse( $xlsFilename );
	if ( !defined $workbook ) {
		die "Parsing error: ", $parser->error(), ".\n";
	}
	my @worksheets = $workbook->worksheets();
	unless ( exists $worksheets[$worksheetIndex]) {
		die "$xlsFilename worksheet $worksheetIndex not exists .\n";
	}
	my $worksheet = $worksheets[$worksheetIndex];

    print "Worksheet name: ", $worksheet->get_name(), "\n\n";

    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

	for my $row ( $row_min .. $row_max ) {
		$xlsContent->{$row-$row_min}->{'level'} = $worksheet->{OptionFlags}[$row]&0xF;
        for my $col ( $col_min .. $col_max ) {
            my $cell = $worksheet->get_cell( $row, $col );
            next unless $cell;
			$xlsContent->{$row-$row_min}->{$col-$col_min}->{'content'} = $cell->value();
			$xlsContent->{$row-$row_min}->{$col-$col_min}->{'unformatted'} = $cell->unformatted();
        }
    }
	return $xlsContent;	
}


1;
