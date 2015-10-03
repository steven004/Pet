package Pet::TestBed::TestBedService;
use Spreadsheet::ParseExcel;
#use Tea::Objects;
use strict;
my $CardModeChangingTime  = 1 * 60;
my $CardModifyWaitingTime = 5;
my $PortModifyWaitingTime = 5;
my $J0UpdateWaitingTime   = $PortModifyWaitingTime;
my $TrunkCreateTime       = 5;
my $AccessCreateTime      = 5;
my $TunnelCreateTime      = 5;
my $CRGCreateTime         = 10;
my $CRGMemberCreateTime   = 5;
my $APSCreateTime         = 5;
my $PPGCreateTime         = 5;
my $RPGCreateTime         = 5;
my $LOXCCreateTime        = 5;
my $CktCreateTime         = 10;
my $CGCreateTime       	  = 5;
my $ESVCCreateTime       	  = 5;

sub new {
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
		"Setting_List" => '',
		"CurrentRow" => '',
		"CurrentCol" => '',
		"CreatedObjs" => [],
		"HandleObjNames" => [],
	};
	bless $self, $class;
	$self->init();
	return $self;
}
sub current_position {
	my $self = shift;
	if(@_ > 0) {
		my %args = @_;
		for(keys %args) {
			if(/-?CurrentRow$/i) {
				$self->{'CurrentRow'} = delete $args{$_};
			}elsif(/-?CurrentCol$/i) {
				$self->{'CurrentCol'} = delete $args{$_};
			}
		}
	}
	return '[ '.$self->{'XLSFile'}.':'.$self->{'WorksheetIndex'}.' ('.($self->{'CurrentRow'}+1).', '.($self->{'CurrentCol'}+1).') ]';
}

sub cfg_testbed {
	my $self = shift;
	@{$self->{"CreatedObjs"}} = ();
	@{$self->{"HandleObjNames"}} = ();	
	my %func_list = (
		CRG                  => \&cfg_CRG,
		Mesh                  => \&cfg_Mesh,
		APS                  => \&cfg_ApsProtectionGroup,
		PPG                  => \&cfg_PathProtectionGroup,
		RPG                  => \&cfg_RingProtectionGroup,
		Circuit              => \&cfg_Circuit,
		LOXC                 => \&cfg_LOXC,
		CG					=> \&cfg_ConcatenationGroup,
		ESVC				=> \&cfg_EthernetService,
	);	
	foreach my $setting (@{$self->{'Setting_List'}}) {
		my $name = $setting->{'name'};
		next unless exists $func_list{$name};
		for(my $i=0; $i<scalar(@{$setting->{'data'}}); $i++) {
			# update current position info
			$self->current_position('CurrentRow' => $setting->{'startRow'}, 'CurrentCol' => $setting->{'startCol'}+$i+1);		
			$func_list{$name}->($self, $setting->{'data'}->[$i]);
		}
	}
	print "\n\n************************************\n****\tService Create Success\t****\n************************************\n\n";
	return $self;
}

sub check_testbed {
	my $self = shift;
	my %func_list = (
		Card_SIM             => \&cfg_Cards_Sonet,
		Card_E1DS1           => \&cfg_Cards_E1DS1,
		Card_DS3          	 => \&cfg_Cards_DS3,
		Card_MRE			=> \&cfg_Cards_MRE,
		SonetLinePort        => \&cfg_Ports_Sonet,
		Connectivity         => \&verify_Connections_Sonet,
		E1DS1Port            => \&cfg_Ports_E1DS1,
		DS3Port          	 => \&cfg_Ports_DS3,
		EthernetPort		=> \&cfg_Ports_Ethernet,
	);	
	foreach my $setting (@{$self->{'Setting_List'}}) {
		my $name = $setting->{'name'};
		# debug
		# next unless $name =~ /SonetLinePort/;
		next unless exists $func_list{$name};
		for(my $i=0; $i<scalar(@{$setting->{'data'}}); $i++) {
			# update current position info
			$self->current_position('CurrentRow' => $setting->{'startRow'}, 'CurrentCol' => $setting->{'startCol'}+$i+1);		
			$func_list{$name}->($self, $setting->{'data'}->[$i]);
		}
	}	
	print "\n\n************************************\n****\tTestbed Check Success\t****\n************************************\n\n";
	return $self;
}
sub collect_TEAObj {
	my $self = shift;
	@{$self->{"CreatedObjs"}} = ();
	no strict 'refs';	
	while ( my $handleObjName = pop( @{ $self->{"HandleObjNames"} } ) ) {
		undef ${"main::$handleObjName"};
	}	

	my %func_list = (
		Card_SIM             => \&cfg_Cards_Sonet,
		Card_E1DS1           => \&cfg_Cards_E1DS1,
		Card_DS3          	 => \&cfg_Cards_DS3,
		Card_MRE			=> \&cfg_Cards_MRE,
		SonetLinePort        => \&cfg_Ports_Sonet,
		E1DS1Port            => \&cfg_Ports_E1DS1,
		DS3Port          	 => \&cfg_Ports_DS3,
		EthernetPort		=> \&cfg_Ports_Ethernet,	
		CRG                  => \&cfg_CRG,
		Mesh                  => \&cfg_Mesh,
		APS                  => \&cfg_ApsProtectionGroup,
		PPG                  => \&cfg_PathProtectionGroup,
		RPG                  => \&cfg_RingProtectionGroup,
		Circuit              => \&cfg_Circuit,
		LOXC                 => \&cfg_LOXC,
		CG					=> \&cfg_ConcatenationGroup,
		ESVC				=> \&cfg_EthernetService,		
	);	
	foreach my $setting (@{$self->{'Setting_List'}}) {
		my $name = $setting->{'name'};
		next unless exists $func_list{$name};
		for(my $i=0; $i<scalar(@{$setting->{'data'}}); $i++) {
			# update current position info
			$self->current_position('CurrentRow' => $setting->{'startRow'}, 'CurrentCol' => $setting->{'startCol'}+$i+1);		
			$func_list{$name}->($self, $setting->{'data'}->[$i], "onlyGet");
		}
	}
	return $self->{"CreatedObjs"};
}
sub clear {
	my $self = shift;
	$self->collect_TEAObj();
	while ( my $exsitingObj = pop( @{ $self->{"CreatedObjs"} } ) ) {
		$_ = ref($exsitingObj);
		if(/Tea::Objects::ConcatenationGroup/) {
			$exsitingObj->set('-ProvisionedConstituents', '');
		}elsif(/Tea::Objects::RingProtectionGroup/){
			$exsitingObj->set('-AdminStatus', 'down');
		}
		my $errorCode = $exsitingObj->delete() or next;
	}
	no strict 'refs';	
	while ( my $handleObjName = pop( @{ $self->{"HandleObjNames"} } ) ) {
		undef ${"main::$handleObjName"};
	}
	
	return $self;
}

sub del {
	my $self = shift;
	return $self;
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

    ( $xlsContent->{'startRow'}, $xlsContent->{'endRow'} ) = $worksheet->row_range();
    ( $xlsContent->{'startCol'}, $xlsContent->{'endCol'} ) = $worksheet->col_range();

	my @IF_Stack;
	for my $row ( $xlsContent->{'startRow'} .. $xlsContent->{'endRow'} ) {
		my $startCol = $xlsContent->{'startCol'};
		my $endCol = $xlsContent->{'endCol'};
		my $firstCell = $worksheet->get_cell( $row, $startCol ) or next;
		if($_ = $firstCell->value()) {
			if(/^IF$/i) {
				my $secondCell = $worksheet->get_cell( $row, $startCol+1 );
				my $condition = 0;
				if($secondCell) {
					$condition = $secondCell->value();
					no strict 'refs';
					while($condition =~ s/\$([[:word:]]+)/\"${"main::$1"}\"/) {};
					$condition = eval $condition;
				}
				push @IF_Stack, $condition ? 1 : 0;
			}elsif(/^EndIF$/i) {
				die "Unexpected $_" unless scalar(@IF_Stack);
				pop @IF_Stack;
			}
		}
		# if the condition is false, skip parsing the content
		next if(scalar(@IF_Stack) and grep(/0/, @IF_Stack));
		$xlsContent->{$row}->{'level'} = $worksheet->{OptionFlags}[$row]&0xF;
        for my $col ($startCol .. $endCol) {
            my $cell = $worksheet->get_cell( $row, $col ) or next;
            # next unless $cell;
			$xlsContent->{$row}->{$col}->{'content'} = $cell->value();
			$xlsContent->{$row}->{$col}->{'content'} =~ s/^\s*//;
			# $xlsContent->{$row}->{$col}->{'unformatted'} = $cell->unformatted();
        }
    }
	return $xlsContent;	
}

sub init {
	my $self = shift;
	my $content = $self->parseXLS() or die "Bad XLS file";

	my $is_in_block;
	my $base_level;
	my @settingSet;
	my $block_num = 0;
	# get the boundarys of each service block
	for(my $i=$content->{'startRow'}; $i <= $content->{'endRow'}; $i++) {
		next unless exists($content->{$i});
		# initia at the first row
		if($i == $content->{'startRow'}) {
			$is_in_block = 0;
			$base_level = $content->{$i}->{'level'};
		}
		# block start, get the start row
		if(not $is_in_block 
			and exists($content->{$i+1}) 
			and $content->{$i+1}->{'level'} > $content->{$i}->{'level'}) {
			$is_in_block = 1;
			$settingSet[$block_num]->{'startRow'} = $i;
		}
		$self->current_position('CurrentRow' => $i);
		## debug
		# print "current row = ", $i+1, "\n";
		# print "start level = ", $content->{$settingSet[$block_num]->{'startRow'}}->{'level'}, "\n";
		# print "next row level = ", $content->{$i+1}->{'level'}, "\n";
		# block end, get the last row
		if($is_in_block 
			and ( (not exists($content->{$i+1})) or (exists($content->{$i+1}) 
			and $content->{$i+1}->{'level'} == $content->{$settingSet[$block_num]->{'startRow'}}->{'level'})
			or ($i == $content->{'endRow'}))){
			$is_in_block = 0;
			$settingSet[$block_num]->{'endRow'} = $i;
			$settingSet[$block_num]->{'endCol'} = $content->{'endCol'}; # for default value
			for(my $j=$content->{'startCol'}; $j <= $content->{'endCol'}; $j++) {
				$self->current_position('CurrentCol' => $j);
				# first column should not be empty
				if($j==$content->{'startCol'}) {
					for(my $ii= $settingSet[$block_num]->{'startRow'}; $ii <= $settingSet[$block_num]->{'endRow'}; $ii++) {
						next unless exists($settingSet[$block_num]->{$ii});
						$self->current_position('CurrentRow' => $ii);
						if($content->{$ii}->{$j}->{'content'} eq '') {	
							die $self->current_position()." should not be empty!!";
						}
					}
					$settingSet[$block_num]->{'startCol'} = $j;
					next;
				}		
				my $is_col_empty = 1;
				for(my $ii= $settingSet[$block_num]->{'startRow'}; $ii <= $settingSet[$block_num]->{'endRow'}; $ii++) {
					next unless exists($content->{$ii});
					if(defined $content->{$ii}->{$j}->{'content'} and $content->{$ii}->{$j}->{'content'}) {
						$is_col_empty = 0;
						last;
					}
					# print $ii+1, "\t", $j+1, " is empty\n";
				}
				if($is_col_empty) {
					$settingSet[$block_num]->{'endCol'} = $j-1;
					last;
				}
			}
			# debug
			# print "----------- (", $settingSet[$block_num]->{'startRow'}, ", ", $settingSet[$block_num]->{'endRow'}, ") -----------\n\n\n";			
			# for next block
			$block_num++;
			next;			
		}
	}

	# parse each block's content
	for(my $blockIndex=0; $blockIndex<scalar(@settingSet); $blockIndex++) {
		my $startRow = $settingSet[$blockIndex]->{'startRow'};
		my $endRow = $settingSet[$blockIndex]->{'endRow'};
		my $startCol = $settingSet[$blockIndex]->{'startCol'};
		my $endCol = $settingSet[$blockIndex]->{'endCol'};
		$settingSet[$blockIndex]->{'name'} = $content->{$startRow}->{$startCol}->{'content'};
		## debug 
		# print "\n\n", $settingSet[$blockIndex]->{'name'}, "\n\n";
		# print "Row Range [", $startRow+1, ", ", $endRow +1, "];\tCol Range [", $startCol+1, ", ", $endCol +1, "].\n";
		my @data;
		for(my $j=$startCol+1; $j<=$endCol; $j++) {
			my %unit;
			$unit{'colTittle'} = Translate($content->{$startRow}->{$j}->{'content'});
			for(my $i=$startRow+1; $i<=$endRow; $i++) {
				next unless exists($content->{$i});
				my $name = Translate($content->{$i}->{$startCol}->{'content'});
				$unit{$name} = Translate($content->{$i}->{$j}->{'content'});
				# Enable users to define macros in "Define" block
				no strict 'refs';	
				if($settingSet[$blockIndex]->{'name'} =~ /Define/i) {
					${"main::$name"} = $unit{$name};
				}
				## debug
				# print $name, ":\t", $unit{$name}, "\n";
			}
			push @data, \%unit;
		}
		$settingSet[$blockIndex]->{'data'} = \@data;
	}
	$self->{'Setting_List'} = \@settingSet;
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

sub cfg_Cards_Sonet {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}
	my $hostIP = $content->{'Host'} or die "\"Host\" should not be empty at ".$self->current_position();
	$self->get_NE_list($hostIP);
	my $cardIndex = $content->{'Index'} or die "\"Index\" should not be empty at ".$self->current_position();
	for(my $i=0; $i<$objectNum; $i++) {
		my $Card = new Tea::Objects::Card(
			Host  => $hostIP,
			Index => _index_increase($cardIndex, $i),
		);
		die unless $Card;
		my $nmi = $Card->nm_if() or die "$hostIP $cardIndex not exist";
		my $ref = $nmi->get( $Card->nm_name() )
		  or die "$hostIP ", $Card->nm_name(), " not exist";
		my %actual_attribute = %{$ref};
		
		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $Card;	
				push @{ $self->{"HandleObjNames"} }, $parName;				
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $Card;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $Card;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}
		
		if(not $onlyGet) {
			if ($content->{"AdminStatus"}
				and $content->{"AdminStatus"} ne
				$actual_attribute{"-AdminStatus"} )
			{
				$Card->set( "-AdminStatus", $content->{"AdminStatus"} );
				sleep $CardModifyWaitingTime;
			}
			if($content->{"PortRateQuad1"} or $content->{"PortRateQuad2"}) {
				die "Unsupported quad rate modification, ".$self->current_position() unless $actual_attribute{"-CardType"} eq "SIM_3_12x8";
				if ($content->{"PortRateQuad1"}
					and $content->{"PortRateQuad1"} ne
					$actual_attribute{"-PortRateQuad1"} )
				{	# admin down all affected ports
					my @before_mod;
					for ( my $i = 1 ; $i <= 4 ; $i++ ) {
						my $Port = new Tea::Objects::Port(
							Host  => $Card->host(),
							Index => $cardIndex . "-$i"
						);
						next unless $Port;
						my $nmi = $Port->nm_if() or next;
						my $ref = $nmi->get( $Port->nm_name() ) or next;
						my %actual_attribute = %{$ref};
						next
						  if (
							$actual_attribute{"-AdministrativeStatus"} eq "adm_down" );
						my %modfied = (
							Object => $Port,
							AdministrativeStatus =>
							  $actual_attribute{"-AdministrativeStatus"}
						);
						push @before_mod, \%modfied;
						$Port->set( "-AdministrativeStatus", "adm_down" );
						sleep $PortModifyWaitingTime;
					}
					$Card->set( "-PortRateQuad1", $content->{"PortRateQuad1"} );
					sleep $CardModeChangingTime;

					# recover previous port status
					foreach my $portCfg (@before_mod) {
						my ( $obj, $status );
						for ( keys %{$portCfg} ) {
							if (/-?Object$/i) {
								$obj = delete $portCfg->{$_};
							}
							elsif (/-?AdministrativeStatus/i) {
								$status = delete $portCfg->{$_};
							}
						}
						next unless $obj;
						if ($status) {
							$obj->set( "-AdministrativeStatus", $status );
							sleep $PortModifyWaitingTime;
						}
					}
				}
				if ($content->{"PortRateQuad2"}
					and $content->{"PortRateQuad2"} ne
					$actual_attribute{"-PortRateQuad2"} )
				{

					# admin down all affected ports
					my @before_mod;
					for ( my $i = 5 ; $i <= 8 ; $i++ ) {
						my $Port = new Tea::Objects::Port(
							Host  => $Card->host(),
							Index => $cardIndex . "-$i"
						);
						next unless $Port;
						my $nmi = $Port->nm_if() or next;
						my $ref = $nmi->get( $Port->nm_name() ) or next;
						my %actual_attribute = %{$ref};
						next
						  if (
							$actual_attribute{"-AdministrativeStatus"} eq "adm_down" );
						my %modfied = (
							Object => $Port,
							AdministrativeStatus =>
							  $actual_attribute{"-AdministrativeStatus"}
						);
						push @before_mod, \%modfied;
						$Port->set( "-AdministrativeStatus", "adm_down" );
						sleep $PortModifyWaitingTime;
					}
					$Card->set( "-PortRateQuad2", $content->{"PortRateQuad2"} );
					sleep $CardModeChangingTime;

					# recover previous port status
					foreach my $portCfg (@before_mod) {
						my ( $obj, $status );
						for ( keys %{$portCfg} ) {
							if (/-?Object$/i) {
								$obj = delete $portCfg->{$_};
							}
							elsif (/-?AdministrativeStatus/i) {
								$status = delete $portCfg->{$_};
							}
						}
						next unless $obj;
						if ($status) {
							$obj->set( "-AdministrativeStatus", $status );
							sleep $PortModifyWaitingTime;
						}
					}
				}
			}
		}
	}
}

sub cfg_Ports_Sonet {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}
	my $hostIP = $content->{'Host'} or die "\"Host\" should not be empty at ".$self->current_position();
	$self->get_NE_list($hostIP);
	my $portIndex = $content->{'Index'} or die "\"Index\" should not be empty at ".$self->current_position();
	for(my $i=0; $i<$objectNum; $i++) {
		my $Port      = new Tea::Objects::Port(
			Host  => $hostIP,
			Index => _index_increase($portIndex, $i),
			Type  => "SonetLinePortPic"
		);	
		die unless $Port;
		my $nmi = $Port->nm_if()
		  or die "$hostIP ", $Port->nm_name(), " not exist";
		my $ref = $nmi->get( $Port->nm_name() )
		  or die "$hostIP ", $Port->nm_name(), " not exist";
		my %actual_attribute = %{$ref};
		
		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $Port;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $Port;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $Port;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}
		
		if(not $onlyGet) {
			my @modified_attrs;
			foreach my $attr (qw(AdministrativeStatus FramingMode)) {
				push @modified_attrs, "-$attr", $content->{"$attr"}
				  if (  $content->{"$attr"}
					and $content->{"$attr"} ne
					$actual_attribute{"-$attr"} );
			}
			if ( scalar(@modified_attrs) ) {
				$Port->set(@modified_attrs);
				sleep $PortModifyWaitingTime;
			}		
		}
	}
}

sub verify_Connections_Sonet {
	my $self         = shift;
	my $content = shift;
	my $peerNodeIP = $content->{'colTittle'} or die "peerNodeIP should not be empty at ".$self->current_position();
	my @ports2Verify;
	foreach my $localNodeIP (keys(%$content)) {
		next if $localNodeIP eq 'colTittle'; # only process related parameters
		next if ($content->{$localNodeIP} =~ /^NA$/i);
		foreach my $ports_pair (split(/\n/, $content->{$localNodeIP})) {
			my ($localPortIndex, $peerPortIndex) = split(/[\s:]/, $ports_pair);
			die "Incorrect $localNodeIP $ports_pair LocalPort:PeerPort format at ".$self->current_position() unless($localNodeIP and $peerNodeIP);
			my $localPort = new Tea::Objects::Port(
				Host  => $localNodeIP,
				Index => $localPortIndex,
				Type  => "SonetLinePortPic"
			);
			{
				my ( $nmi, $ref );
				die $localPort->host(),
				  " ", $localPort->nm_name(), " not exist"
				  unless ( ( $nmi = $localPort->nm_if() )
					and ( $ref = $nmi->get( $localPort->nm_name() ) ) );
				$localPort->{'previousSendJ0'} = $ref->{"-TransmitSectionTrace"};
			}
			my $peerPort = new Tea::Objects::Port(
				Host  => $peerNodeIP,
				Index => $peerPortIndex,
				Type  => "SonetLinePortPic"
			);
			{
				my ( $nmi, $ref );
				die $peerPort->host(),
				  " ", $peerPort->nm_name(), " not exist"
				  unless ( ( $nmi = $peerPort->nm_if() )
					and ( $ref = $nmi->get( $peerPort->nm_name() ) ) );
				$peerPort->{'previousSendJ0'} = $ref->{"-TransmitSectionTrace"};
			}
			$localPort->{'peerPortRef'} = $peerPort;
			$peerPort->{'peerPortRef'}  = $localPort;
			push @ports2Verify, $localPort, $peerPort;
		}
	}
	
	# step1. check J0
	{
		# set J0 with a random string, length <= 15
		my $maxLenth=15;
		my @charSet = (0..9, '$','a'..'z','A'..'Z','-','+','_'); # '%' has been excluded from the set because it has special meaning in http requests
		foreach my $port (@ports2Verify) {
			srand;
			my $randStr = join '', map { $charSet[int rand @charSet] } 0..($maxLenth-1);
			$port->set( "-TransmitSectionTrace", $randStr );		
		}
		sleep $PortModifyWaitingTime;
		
		# check J0 trace
		foreach my $port (@ports2Verify) {
			my $peer = $port->{'peerPortRef'};
			my $sendJ0 =
			  $port->nm_if()->get( $port->nm_name() )->{"-TransmitSectionTrace"};
			my $recvJ0 =
			  $peer->nm_if()->get( $peer->nm_name() )->{"-ReceiveSectionTrace"};
			my $expire = 2;
			while ( $sendJ0 ne $recvJ0 ) {
				if ( $expire-- ) {
					sleep $J0UpdateWaitingTime;
					$recvJ0 =
					  $peer->nm_if()->get($peer->nm_name())->{"-ReceiveSectionTrace"};
					next;
				}
				die $port->host(), " ", $port->nm_name(), " (send $sendJ0)",
				  " is not connected with ", $peer->host(), " ", $peer->nm_name(),
				  " (received $recvJ0)";
			}
		}	
		# recover previous J0
		foreach my $port (@ports2Verify) {
			$port->set( "-TransmitSectionTrace", $port->{'previousSendJ0'} );
		}
		sleep $PortModifyWaitingTime;		
	}
	# step2. check port PM
	{
		# reset port PM
		my $peerNE = new Tea::Objects::SN9K(Host  => $peerNodeIP);
		foreach my $port (@ports2Verify) {
			if($port->host() eq $peerNodeIP) {
				my $portIndex = $port->nm_name();
				$portIndex =~ s/[^-]+-//;
				$peerNE->shell_cmd("hdb initreg port $portIndex layer all interval current");
			}
		}
		
		foreach my $localNodeIP (keys(%$content)) {
			my $localNE = new Tea::Objects::SN9K(Host  => $localNodeIP);
			foreach my $port (@ports2Verify) {
				if($port->host() eq $localNodeIP) {
					my $portIndex = $port->nm_name();
					$portIndex =~ s/[^-]+-//;
					$localNE->shell_cmd("hdb initreg port $portIndex layer all interval current");
				}
			}
		}
		# wait for pm count
		sleep $PortModifyWaitingTime;
		# check pm
		my @PM_Line = qw(CV_L ESA_L ESB_L ES_L SES_L UAS_L AISS_L FC_L);
		my @PM_LineFE = qw(CV_LFE ESA_LFE ESB_LFE ES_LFE SES_LFE UAS_LFE AISS_LFE FC_LFE);
		my @PM_Section = qw(CVs ESA ESB ESs SESs LOSS SEFSs);		
		foreach my $port (@ports2Verify) {
			my $port_name = $port->nm_name() or die;
			my $nmi = $port->nm_if() or die;
			my $ref = $nmi->get($port_name) or die;
			foreach (@PM_Section, @PM_Line, @PM_LineFE) {
				die $port->host()." $port_name $_ is increasing" if($ref->{"-$_"}); 
			}
		}
	}
}

sub cfg_Cards_E1DS1 {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}
	my $hostIP = $content->{'Host'} or die "\"Host\" should not be empty at ".$self->current_position();
	$self->get_NE_list($hostIP);
	my $cardIndex = $content->{'Index'} or die "\"Index\" should not be empty at ".$self->current_position();
	for(my $i=0; $i<$objectNum; $i++) {
		my $Card = new Tea::Objects::Card(
			Host  => $hostIP,
			Index => _index_increase($cardIndex, $i),
		);
		die unless $cardIndex and $Card;
		my $nmi = $Card->nm_if() or die;
		my $ref = $nmi->get( $Card->nm_name() )
		  or die "$hostIP ", $Card->nm_name(), " not exist";
		my %actual_attribute = %{$ref};
		my %obj_attribute;

		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $Card;	
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $Card;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $Card;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}
		
		if(not $onlyGet) {
			{
				my $PdhType = $content->{"PdhType"} or $actual_attribute{"-PdhType"} ;
				my $LineCoding = $content->{"LineCoding"} or $actual_attribute{"-LineCoding"};
				if($PdhType =~ /ds1/i) {
					die "Wrong line coding for $hostIP $cardIndex under ds1 mode, should be b8zs or ami at ".$self->current_position() 
						unless($LineCoding =~ /b8zs|ami/);
				}elsif($PdhType =~ /e1/i) {
					die "Wrong line coding for $hostIP $cardIndex under e1 mode, should be hdb3 or ami at ".$self->current_position() 
						unless($LineCoding =~ /hdb3|ami/);
				}
			}
			my @modified_attrs;
			foreach my $attr (qw(AdminStatus Mode PdhType LineCoding)) {
				push @modified_attrs, "-$attr", $content->{"$attr"}
				  if (  $content->{"$attr"}
					and $content->{"$attr"} ne $actual_attribute{"-$attr"} );
			}
			if ( $content->{"Island"} ) {
				my ( $IslandChassis, $IslandSlot ) =
				  split( "-", $content->{"Island"} );
				push @modified_attrs, "-IslandChassis", $IslandChassis,
				  "-IslandSlot", $IslandSlot
				  if ( $IslandChassis ne $actual_attribute{"-IslandChassis"}
					or $IslandSlot ne $actual_attribute{"-IslandSlot"} );
			}
			if ( scalar(@modified_attrs) ) {
				$Card->set(@modified_attrs);
				sleep $CardModifyWaitingTime;
			}
		}
	}
}

sub cfg_Ports_E1DS1 {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}
	my $hostIP = $content->{'Host'} or die "\"Host\" should not be empty at ".$self->current_position();
	$self->get_NE_list($hostIP);
	my $portIndex = $content->{'Index'} or die "\"Index\" should not be empty at ".$self->current_position();
	
	# get parent information
	my $cardIndex = $1 if($portIndex =~ /^(\d+-\d+)/);
	my $Card = new Tea::Objects::Card(
		Host  => $hostIP,
		Index => $cardIndex,
	);	
	die unless $cardIndex and $Card;
	my $nmi = $Card->nm_if() or die;
	my $ref = $nmi->get( $Card->nm_name() )
	  or die "$hostIP ", $Card->nm_name(), " not exist";
	my $portType;
	if($ref->{'-PdhType'} =~ /ds1/i) {
		$portType = "Port_DS1";
	}elsif($ref->{'-PdhType'} =~ /e1/i) {
		$portType = "Port_E1";
	}else {die "Unsupported card pdhtype $ref->{'-PdhType'}";}
		
	for(my $i=0; $i<$objectNum; $i++) {
		my $Port      = new Tea::Objects::Port(
			Host  => $hostIP,
			Index => _index_increase($portIndex, $i),
			Type  => $portType,
		);	
		die unless $Port;
		my $nmi = $Port->nm_if()
		  or die "$hostIP ", $Port->nm_name(), " not exist";
		my $ref = $nmi->get( $Port->nm_name() )
		  or die "$hostIP ", $Port->nm_name(), " not exist";
		my %actual_attribute = %{$ref};

		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $Port;
				push @{ $self->{"HandleObjNames"} }, $parName;				
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $Port;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $Port;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}	

		if(not $onlyGet) {
			# check FramingFormat
			{
				my $PortType = $content->{"Type"} or $actual_attribute{"-Type"} ;
				my $FramingFormat = $content->{"FramingFormat"} or $actual_attribute{"-FramingFormat"};
				if($PortType =~ /ds1/i) {
					die "Wrong Framing Format for $hostIP ,", $Port->nm_name(), ", should be unframed, sf or esf at ".$self->current_position()
						unless($FramingFormat =~ /unframed|sf|esf/);
				}elsif($PortType =~ /e1/i) {
					die "Wrong Framing Format for $hostIP ,", $Port->nm_name(), ", should be pcm32unframed, pcm31 or pcm31crc at ".$self->current_position()
						unless($FramingFormat =~ /pcm32unframed|pcm31|pcm31crc/);
				}
			}		
			# calculate AlarmReporting
			{
				my ($actual_ais, $actual_rdi);
				$actual_rdi = int($actual_attribute{'-AlarmReporting'}/4);
				$actual_ais = ($actual_attribute{'-AlarmReporting'} - 4*$actual_rdi)/1;
				my $ais = $content->{'AlarmReporting_AIS'} or $actual_ais;
				my $rdi = $content->{'AlarmReporting_RDI'} or $actual_rdi;
				$content->{'AlarmReporting'} = 1*$ais+4*$rdi;
			}
			my @modified_attrs;
			$content->{'AlarmReporting'} = 1*$content->{'AlarmReporting_AIS'} + 4*1*$content->{'AlarmReporting_RDI'};
			foreach my $attr (qw(AdminState FramingFormat LowOrderMapping PortLineCoding IngressPathPerformance EgressPathPerformance AisDownstreamGenerationOnLOF AlarmReporting)) {
				push @modified_attrs, "-$attr", $content->{"$attr"}
				  if (  $content->{"$attr"}
					and $content->{"$attr"} ne
					$actual_attribute{"-$attr"} );
			}

			if ( scalar(@modified_attrs) ) {
				$Port->set(@modified_attrs);
				sleep $PortModifyWaitingTime;
			}
		}
	}
}

sub cfg_Cards_DS3 {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}
	my $hostIP = $content->{'Host'} or die "\"Host\" should not be empty at ".$self->current_position();
	$self->get_NE_list($hostIP);
	my $cardIndex = $content->{'Index'} or die "\"Index\" should not be empty at ".$self->current_position();
	for(my $i=0; $i<$objectNum; $i++) {
		my $Card = new Tea::Objects::Card(
			Host  => $hostIP,
			Index => _index_increase($cardIndex, $i),
		);
		die unless $cardIndex and $Card;
		my $nmi = $Card->nm_if() or die;
		my $ref = $nmi->get( $Card->nm_name() )
		  or die "$hostIP ", $Card->nm_name(), " not exist";
		my %actual_attribute = %{$ref};
		my %obj_attribute;

		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $Card;	
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $Card;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $Card;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}
		
		if(not $onlyGet) {
			my @modified_attrs;
			foreach my $attr (qw(AdminStatus Mode PdhType LineCoding)) {
				push @modified_attrs, "-$attr", $content->{"$attr"}
				  if (  $content->{"$attr"}
					and $content->{"$attr"} ne $actual_attribute{"-$attr"} );
			}
			# if ( $content->{"Island"} ) {
				# my ( $IslandChassis, $IslandSlot ) =
				  # split( "-", $content->{"Island"} );
				# push @modified_attrs, "-IslandChassis", $IslandChassis,
				  # "-IslandSlot", $IslandSlot
				  # if ( $IslandChassis ne $actual_attribute{"-IslandChassis"}
					# or $IslandSlot ne $actual_attribute{"-IslandSlot"} );
			# }
			if ( scalar(@modified_attrs) ) {
				$Card->set(@modified_attrs);
				sleep $CardModifyWaitingTime;
			}
		}
	}
}

sub cfg_Ports_DS3 {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}
	my $hostIP = $content->{'Host'} or die "\"Host\" should not be empty at ".$self->current_position();
	$self->get_NE_list($hostIP);
	my $portIndex = $content->{'Index'} or die "\"Index\" should not be empty at ".$self->current_position();
	
	# get parent information
	my $cardIndex = $1 if($portIndex =~ /^(\d+-\d+)/);
	my $Card = new Tea::Objects::Card(
		Host  => $hostIP,
		Index => $cardIndex,
	);	
	die unless $cardIndex and $Card;
	my $nmi = $Card->nm_if() or die;
	my $cardAttr = $nmi->get( $Card->nm_name() )
	  or die "$hostIP ", $Card->nm_name(), " not exist";
	if($content->{'LowOrderMapping'} eq '1' and $cardAttr->{'-Mode'} ne 'bundled_au4') {
		die "LowOrderMapping can't be enabled when card is under ", $cardAttr->{'-Mode'}, " Mode at ".$self->current_position(); 
	}		
		
	for(my $i=0; $i<$objectNum; $i++) {
		my $portIndex = _index_increase( $portIndex, $i );
		my $Port      = new Tea::Objects::Port(
			Host  => $hostIP,
			Index => $portIndex,
			Type  => 'Port_DS3',
		);	
		die unless $Port;
		my $nmi = $Port->nm_if()
		  or die "$hostIP ", $Port->nm_name(), " not exist";
		my $ref = $nmi->get( $Port->nm_name() )
		  or die "$hostIP ", $Port->nm_name(), " not exist";
		my %actual_attribute = %{$ref};
		
		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $Port;
				push @{ $self->{"HandleObjNames"} }, $parName;				
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $Port;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $Port;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}

		if(not $onlyGet) {
			my @modified_attrs;
			foreach my $attr (qw(AdminState FramingFormat LowOrderMapping LineBuildOut TransmuxMode TransmuxType ResultTreatment)) {
				push @modified_attrs, "-$attr", $content->{"$attr"}
				  if (  $content->{"$attr"}
					and $content->{"$attr"} ne
					$actual_attribute{"-$attr"} );
			}
			# if transmux changed, will forcefully disable all e1/ds1 channels first 
			if($actual_attribute{'-TransmuxMode'} eq "port_based" 
				and $actual_attribute{'-ResultTreatment'} eq "bundled"
				and grep(/TransmuxMode|TransmuxType|ResultTreatment/, @modified_attrs)) {
				my %channelAttr = ('LowOrderMapping' => '0');
				cfg_DS3_E1DS1Channels($hostIP, $portIndex, 1, -1, \%channelAttr);
			}
			if ( scalar(@modified_attrs) ) {
				$Port->set(@modified_attrs);
				sleep $PortModifyWaitingTime;
			}
			# continue to configure E1/DS1 channels attributes
			if(($content->{'ResultTreatment'} eq "bundled") or (not $content->{'ResultTreatment'} and ($actual_attribute{'-ResultTreatment'} eq "bundled"))) {
				if($content->{"E1DS1Channels"}) {
					my $startCh;
					my $channelNum;
					my @digs = split('-', $content->{"E1DS1Channels"});				
					if(defined($digs[0]) and defined($digs[1])) { 
					# multi channels
						$startCh = $digs[0];
						$channelNum = $digs[1]-$digs[0]+1;
					}elsif(not defined($digs[0])) {
					# negative number, all channels
						$startCh = 1;
						$channelNum = -1;
					}else{ 
					# sigle number, one channel
						$startCh = $digs[0];
						$channelNum = 1;
					}
					die "Incorrect E1DS1 channels: ", $content->{"E1DS1Channels"}," at ".$self->current_position() unless($startCh and $channelNum);
					my %channelAttr = ('LowOrderMapping' => '1');
					$channelAttr{'FramingFormat'} = $content->{"E1DS1ChannelFramingFormat"} if $content->{"E1DS1ChannelFramingFormat"};
					cfg_DS3_E1DS1Channels($hostIP, $portIndex, $startCh, $channelNum, \%channelAttr);
				}	
			}
		}
	}
}

# cfg all channels if number<0
sub cfg_DS3_E1DS1Channels {
	my $hostIP = shift or die;
	my $portIndex = shift or die;
	my $channelStart = shift or die;
	my $channelNum = shift or die;
	my $channelAttr = shift or die;
	my $Port = new Tea::Objects::Port(
		Host  => $hostIP,
		Index => $portIndex,
		Type  => 'Port_DS3'
	);
	my $nmi = $Port->nm_if()
	  or die "$hostIP ", $Port->nm_name(), " not exist";
	my $ref = $nmi->get( $Port->nm_name() )
	  or die "$hostIP ", $Port->nm_name(), " not exist";
	my $ChannelType = $ref->{"-TransmuxType"} ;
	my $TotalChannelNum;
	if($ChannelType =~ /ds1/i) {
		$ChannelType = 'Channel_DS1';
		$TotalChannelNum = 28;
	}elsif($ChannelType =~ /e1/i) {
		$ChannelType = 'Channel_E1';
		$TotalChannelNum = 21;
	}else{
		die "Unsupported ChannelType [$ChannelType] on $hostIP $portIndex";
	}
	$channelNum = $TotalChannelNum-$channelStart+1 if($channelNum<0);
	die "Unsupport so many $ChannelType channels" if($channelStart+$channelNum-1 > $TotalChannelNum);
	for(my $i=0; $i<$channelNum; $i++) {
		my $channelIndex = $channelStart+$i;
		my $E1DS1Channel = new Tea::Objects::Base(
			Host  => $hostIP,
			Index => $channelIndex,
		);	
		$E1DS1Channel->nm_name(join('-', $ChannelType, $portIndex, $channelIndex));
		my $actual_attribute_ref = $nmi->get( $E1DS1Channel->nm_name() )
			  or die "$hostIP ", $E1DS1Channel->nm_name(), " not exist";
		my @modified_attrs;
		foreach my $attr (qw(FramingFormat LowOrderMapping)) {
			push @modified_attrs, "-$attr", $channelAttr->{"$attr"}
			  if (  defined($channelAttr->{"$attr"})
					and $channelAttr->{"$attr"} ne
					$actual_attribute_ref->{"-$attr"} );
		}
		if ( scalar(@modified_attrs) ) {
			$E1DS1Channel->set(@modified_attrs);
		}
	}
}


sub cfg_Cards_MRE {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}
	my $hostIP = $content->{'Host'} or die "\"Host\" should not be empty at ".$self->current_position();
	$self->get_NE_list($hostIP);
	my $cardIndex = $content->{'Index'} or die "\"Index\" should not be empty at ".$self->current_position();
	for(my $i=0; $i<$objectNum; $i++) {
		my $Card = new Tea::Objects::Card(
			Host  => $hostIP,
			Index => _index_increase($cardIndex, $i),
		);
		die unless $Card;
		my $nmi = $Card->nm_if() or die "$hostIP $cardIndex not exist";
		my $ref = $nmi->get( $Card->nm_name() )
		  or die "$hostIP ", $Card->nm_name(), " not exist";
		my %actual_attribute = %{$ref};
		
		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $Card;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $Card;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $Card;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}
		
		if(not $onlyGet) {
			my @modified_attrs;
			foreach my $attr (qw(AdminStatus LoPathSize)) {
				push @modified_attrs, "-$attr", $content->{"$attr"}
				  if (  $content->{"$attr"}
					and $content->{"$attr"} ne $actual_attribute{"-$attr"} );
			}

			if ( scalar(@modified_attrs) ) {
				$Card->set(@modified_attrs);
				sleep $CardModifyWaitingTime;
			}
		}
	}
}

sub cfg_Ports_Ethernet {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}
	my $hostIP = $content->{'Host'} or die "\"Host\" should not be empty at ".$self->current_position();
	$self->get_NE_list($hostIP);
	my $portIndex = $content->{'Index'} or die "\"Index\" should not be empty at ".$self->current_position();
	for(my $i=0; $i<$objectNum; $i++) {
		my $Port      = new Tea::Objects::Port(
			Host  => $hostIP,
			Index => _index_increase($portIndex, $i),
			Type  => "EthernetPort"
		);	
		die unless $Port;
		my $nmi = $Port->nm_if()
		  or die "$hostIP ", $Port->nm_name(), " not exist";
		my $ref = $nmi->get( $Port->nm_name() )
		  or die "$hostIP ", $Port->nm_name(), " not exist";
		my %actual_attribute = %{$ref};
		
		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $Port;
				push @{ $self->{"HandleObjNames"} }, $parName;				
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $Port;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $Port;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}
		
		if(not $onlyGet) {
			my @modified_attrs;
			foreach my $attr (qw(AdministrativeStatus AutoNeg LocalAbility)) {
				push @modified_attrs, "-$attr", $content->{"$attr"}
				  if (  $content->{"$attr"}
					and $content->{"$attr"} ne
					$actual_attribute{"-$attr"} );
			}
			if ( scalar(@modified_attrs) ) {
				$Port->set(@modified_attrs);
				sleep $PortModifyWaitingTime;
			}		
		}
	}
}


sub cfg_Mesh {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;
	my $peerNodeIP = $content->{'colTittle'} or die "peerNodeIP should not be empty at ".$self->current_position();
	$self->get_NE_list($peerNodeIP);
	foreach my $localNodeIP (keys(%$content)) {
		next if $localNodeIP eq 'colTittle';  # only process related parameters
		next if(not $content->{$localNodeIP} or $content->{$localNodeIP} =~ /NA/i);
		$self->get_NE_list($content->{$localNodeIP});
		foreach my $mesh_service (split(/\n/, $content->{$localNodeIP})) {
			my ($service_name, $obj_name, @par_list) = split(/:/, $mesh_service);
			die "service_name should not be empty at ".$self->current_position() unless($service_name);
			my @handleObjectName;
			@handleObjectName = split(/[\s,]/, $obj_name) if $obj_name;	

			my %service_attr = ('localNodeIP' => $localNodeIP,
								'peerNodeIP'  => $peerNodeIP);
			$_ = $service_name;
			
			if(/SwitchTrunk/){
				die "At most one $service_name object names for $service_name at ".$self->current_position() if(scalar(@handleObjectName)>1);
				$service_attr{'localPortIndex'} = shift @par_list;
				$service_attr{'peerPortIndex'} = shift @par_list;
				$service_attr{'Conduits'} = shift @par_list;
				$service_attr{'AdminCost'} = shift @par_list;
				$service_attr{'DCCNum'} = shift @par_list;
				$service_attr{'VPN'} = shift @par_list;	
				$service_attr{'OspfAreaId'} = shift @par_list;
				my $Obj = $self->cfg_Mesh_SwitchTrunk(\%service_attr, $onlyGet);
				# mapping to object handle(s)
				my $parName;
				# allow only one object name
				if(scalar(@handleObjectName) == 1) {
					$parName = $handleObjectName[0];
					no strict 'refs';	
					${"main::$parName"} = $Obj;
					push @{ $self->{"HandleObjNames"} }, $parName;
				}
			} else {
				die "At most two $service_name object names for $service_name at ".$self->current_position() if(scalar(@handleObjectName)>2);
				my ($localObj, $remoteObj);
				if(/Tunnel/i) {
					$service_attr{'Area'} = shift @par_list;
					$service_attr{'Cost'} = shift @par_list;
					($localObj, $remoteObj) = $self->cfg_Mesh_Tunnel(\%service_attr, $onlyGet);
				}elsif(/SwitchAccess/i){
					die "At most two $service_name object names for $service_name at ".$self->current_position() if(scalar(@handleObjectName)>2);
					$service_attr{'localPortIndex'} = shift @par_list;
					$service_attr{'peerPortIndex'} = shift @par_list;
					$service_attr{'Area'} = shift @par_list;
					$service_attr{'Cost'} = shift @par_list;
					$service_attr{'DCCNum'} = shift @par_list;
					$service_attr{'FCS'} = shift @par_list;
					($localObj, $remoteObj) = $self->cfg_Mesh_SwitchAccesses(\%service_attr, $onlyGet);
				}else{
					die "Incorrect service_name $service_name at ".$self->current_position();
				}
				# mapping to object handle(s)
				my $parName;
				# given only one object name
				if(scalar(@handleObjectName) == 1) {
					$parName = $handleObjectName[0]."_1"; 
					no strict 'refs';	
					${"main::$parName"} = $localObj;
					push @{ $self->{"HandleObjNames"} }, $parName;
					$parName = $handleObjectName[0]."_2"; 
					no strict 'refs';	
					${"main::$parName"} = $remoteObj;
					push @{ $self->{"HandleObjNames"} }, $parName;
				}else{
					$parName = $handleObjectName[0];
					no strict 'refs';	
					${"main::$parName"} = $localObj;
					push @{ $self->{"HandleObjNames"} }, $parName;
					$parName = $handleObjectName[1];
					no strict 'refs';	
					${"main::$parName"} = $remoteObj;				
					push @{ $self->{"HandleObjNames"} }, $parName;
				}	
			}
		}
	}
}

sub cfg_Mesh_Tunnel {
	my $self         = shift;
	my $content = shift or die "Abnormal occurs";
	my $onlyGet      = shift;

	my $localEnd_IP = $content->{'localNodeIP'} or die "Abnormal occurs";
	$self->get_NE_list($localEnd_IP);
	my $peerEnd_IP = $content->{'peerNodeIP'} or die "Abnormal occurs";
	$self->get_NE_list($peerEnd_IP);

	my $tunnel_local = new Tea::Objects::Tunnel(
		Host  => $localEnd_IP,
		Index => $localEnd_IP . '-' . $peerEnd_IP
	);
	my $tunnel_peer = new Tea::Objects::Tunnel(
		Host  => $peerEnd_IP,
		Index => $peerEnd_IP . '-' . $localEnd_IP
	);
	if ( not $onlyGet ) {
		$tunnel_local->{tunnelFromIpAddress} =
		  $tunnel_peer->{tunnelToIpAddress} = $localEnd_IP;
		$tunnel_local->{tunnelToIpAddress} =
		  $tunnel_peer->{tunnelFromIpAddress} = $peerEnd_IP;
		$tunnel_local->{tunnelArea} = $tunnel_peer->{tunnelArea} =
		  $content->{'Area'};
		$tunnel_local->{tunnelCost} = $tunnel_peer->{tunnelCost} =
		  $content->{'Cost'};
		if ( my $errorCode =
			( _create_tunnel($tunnel_local) || _create_tunnel($tunnel_peer) ) )
		{
			die $errorCode, " during creat tunnel at ".$self->current_position();
		}		
	}
	if ( exists $self->{"CreatedObjs"} ) {
		push @{ $self->{"CreatedObjs"} }, $tunnel_local;
		push @{ $self->{"CreatedObjs"} }, $tunnel_peer;
	}
	else {
		my @tmp = ( $tunnel_local, $tunnel_peer );
		$self->{"CreatedObjs"} = \@tmp;
	}
	return ($tunnel_local, $tunnel_peer);
}

sub _create_tunnel {
	my $tunnel = shift or return;
	my %tunnel_template = (
		Name                 => $tunnel->nm_name(),
		-tunnelFromIpAddress => $tunnel->{tunnelFromIpAddress},
		-tunnelToIpAddress   => $tunnel->{tunnelToIpAddress},
		-tunnelCost          => "1",
		-tunnelArea          => "0.0.0.1",
	);

	$tunnel_template{-tunnelCost} = $tunnel->{tunnelCost}
	  if defined $tunnel->{tunnelCost};
	$tunnel_template{-tunnelArea} = $tunnel->{tunnelArea}
	  if defined $tunnel->{tunnelArea};

	$tunnel->_obj_template( \%tunnel_template );
	my $create = $tunnel->create();
	return $create->{error} if ( $create->{error} );
	sleep $TunnelCreateTime;
	return;
}

sub cfg_Mesh_SwitchAccesses {
	my $self         = shift;
	my $content = shift or die "Abnormal occurs";
	my $onlyGet      = shift;

	my $localEnd_IP = $content->{'localNodeIP'} or die "Abnormal occurs";
	$self->get_NE_list($localEnd_IP);
	my $peerEnd_IP = $content->{'peerNodeIP'} or die "Abnormal occurs";
	$self->get_NE_list($peerEnd_IP);
	my $localPortIndex = $content->{'localPortIndex'} or die "localPortIndex should not be empty at ".$self->current_position();
	my $peerPortIndex = $content->{'peerPortIndex'} or die "peerPortIndex should not be empty at ".$self->current_position();

	my $access_local = new Tea::Objects::SwitchAccess(
		Host  => $localEnd_IP,
		Index => $localPortIndex
	);
	my $access_peer = new Tea::Objects::SwitchAccess(
		Host  => $peerEnd_IP,
		Index => $peerPortIndex
	);
	if ( not $onlyGet ) {
		if($content->{'DCCNum'}) {
			die "Invalid DCCNum ", $content->{'DCCNum'}, " at ".$self->current_position() unless($content->{'DCCNum'} =~ /0|3|4|9|11|12|15/);
		}				
		$access_local->{Index} = $localPortIndex;
		$access_peer->{Index}  = $peerPortIndex;
		$access_local->{SwitchAccessArea} =
		  $access_peer->{SwitchAccessArea} = $content->{'Area'};
		$access_local->{SwitchAccessCost} =
		  $access_peer->{SwitchAccessCost} = $content->{'Cost'};
		$access_local->{SwitchAccessSonetOverheadBytes} =
		  $access_peer->{SwitchAccessSonetOverheadBytes} =
		  2**$content->{'DCCNum'} - 1;
		$access_local->{SwitchAccessFCS} =
		  $access_peer->{SwitchAccessFCS} = $content->{'FCS'};
		if ( my $errorCode = ( _create_access($access_local) || _create_access($access_peer) ) ) {
			die $errorCode, " during creat switchaccess at ".$self->current_position();
		}							
	}
	if ( exists $self->{"CreatedObjs"} ) {
		push @{ $self->{"CreatedObjs"} }, $access_local;
		push @{ $self->{"CreatedObjs"} }, $access_peer;
	}
	else {
		my @tmp = ( $access_local, $access_peer );
		$self->{"CreatedObjs"} = \@tmp;
	}
	return ($access_local, $access_peer);
}

sub _create_access {
	my $access = shift or return;
	my %access_template = (
		Name                            => $access->nm_name(),
		-SwitchAccessFCS                => "bit32",
		-SwitchAccessSonetOverheadBytes => "7",
		-SwitchAccessCost               => "1",
		-SwitchAccessArea               => "0.0.0.1",
	);

	my @Chassis_Slot_Port = split( '-', $access->{Index} );
	$access_template{-SwitchAccessChassis} = shift @Chassis_Slot_Port;
	$access_template{-SwitchAccessSlot}    = shift @Chassis_Slot_Port;
	$access_template{-SwitchAccessPort}    = shift @Chassis_Slot_Port;

	$access_template{-SwitchAccessFCS} = $access->{SwitchAccessFCS}
	  if(defined $access->{SwitchAccessFCS} and $access->{SwitchAccessFCS});
	$access_template{-SwitchAccessSonetOverheadBytes} =
	  $access->{SwitchAccessSonetOverheadBytes}
	  if(defined $access->{SwitchAccessSonetOverheadBytes} and $access->{SwitchAccessSonetOverheadBytes});
	$access_template{-SwitchAccessCost} = $access->{SwitchAccessCost}
	  if defined $access->{SwitchAccessCost};
	$access_template{-SwitchAccessArea} = $access->{SwitchAccessArea}
	  if defined $access->{SwitchAccessArea};

	$access->_obj_template( \%access_template );
	my $create = $access->create();
	return $create->{error} if ( $create->{error} );
	sleep $AccessCreateTime;
	return;
}

sub cfg_Mesh_SwitchTrunk {
	my $self         = shift;
	my $content = shift or die "Abnormal occurs";
	my $onlyGet      = shift;

	my $localEnd_IP = $content->{'localNodeIP'} or die "Abnormal occurs";
	$self->get_NE_list($localEnd_IP);
	my $peerEnd_IP = $content->{'peerNodeIP'} or die "Abnormal occurs";
	$self->get_NE_list($peerEnd_IP);
	my $localPortIndex = $content->{'localPortIndex'} or die "localPortIndex should not be empty at ".$self->current_position();
	my $peerPortIndex = $content->{'peerPortIndex'} or die "peerPortIndex should not be empty at ".$self->current_position();
	
	my $trunk = new Tea::Objects::Trunk(
		From => $localEnd_IP . '-' . $localPortIndex,
		To   => $peerEnd_IP . '-' . $peerPortIndex
	);
	if ( not $onlyGet ) {
		if($content->{'DCCNum'}) {
			die "Invalid DCCNum ", $content->{'DCCNum'}, " at ".$self->current_position() unless($content->{'DCCNum'} =~ /0|3|4|9|11|12|15/);
		}
		$trunk->{Conduits}        = $content->{'Conduits'};
		$trunk->{AdminCost}       = $content->{'AdminCost'};
		$trunk->{IPoverSonetPhys} = 2**$content->{'DCCNum'} - 1;
		$trunk->{VPN}             = $content->{'VPN'};
		$trunk->{OspfAreaId}      = $content->{'OspfAreaId'};
		if ( my $errorCode = _create_trunk($trunk) ) {
			die $errorCode, " during creat switchtrunk at ".$self->current_position();
		}
	}
	if ( exists $self->{"CreatedObjs"} ) {
		push @{ $self->{"CreatedObjs"} }, $trunk;
	}
	else {
		my @tmp = ($trunk);
		$self->{"CreatedObjs"} = \@tmp;
	}
	return $trunk;
}

sub get_NE_list {
	my $self = shift;
	my $ip   = shift;
	if ( $self->{"NEList"} and scalar( @{ $self->{"NEList"} } ) ) {
		my $found = 0;
		foreach my $NE ( @{ $self->{"NEList"} } ) {
			if ( $NE->host() eq $ip ) {
				$found = 1;
				last;
			}
		}
		if ( not $found ) {
			my $NE = new Tea::Objects::SN9K( Host => $ip );
			push @{ $self->{"NEList"} }, $NE;
		}
	}
	else {
		my $NE = new Tea::Objects::SN9K( Host => $ip );
		my @NEList = ($NE);
		$self->{"NEList"} = \@NEList;
	}
	return @{ $self->{"NEList"} };
}

sub _create_trunk {
	my $trunk = shift or return;
	my %trunk_template = (
		-OspfAreaId                  => "0.0.0.1",
		-VPN                         => "0",
		-MgtChanCost                 => "1",
		-AdminCost                   => "100",
		-IPoverSonetPhys             => "32767",
		-PeerDiscovery               => "1",
		-OpaqueNMCookieEndPtType     => "PicSonetLogPort",
		-OpaqueNMCookieEndPtInst     => "1",
		-OpaqueNMCookiePeerEndPtType => "PicSonetLogPort",
		-OpaqueNMCookiePeerEndPtInst => "1",
	);
	my (
		%new_trunk_template_a, $trunk_end_a,          $trunk_name_a,
		$routerid_a,           %new_trunk_template_b, $trunk_end_b,
		$trunk_name_b,         $routerid_b,           @tmp
	);
	$trunk_end_a = $trunk->end_point_a();
	$trunk_end_b = $trunk->end_point_b();

	# end_a
	%new_trunk_template_a = %trunk_template;
	$trunk_name_a = $trunk_end_a->line_port_name();    # SonetLinePortPic-1-32-4
	$trunk_name_a =~ s/SonetLinePortPic/SwitchTrunk/;
	$new_trunk_template_a{Name} = $trunk_name_a;

	@tmp = split( '-', $trunk_name_a );
	shift @tmp;
	$new_trunk_template_a{-Chassis} = shift @tmp;
	$new_trunk_template_a{-Slot}    = shift @tmp;
	$new_trunk_template_a{-Port}    = shift @tmp;

	# end_b
	%new_trunk_template_b = %trunk_template;
	$trunk_name_b = $trunk_end_b->line_port_name();    # SonetLinePortPic-1-32-4
	$trunk_name_b =~ s/SonetLinePortPic/SwitchTrunk/;
	$new_trunk_template_b{Name} = $trunk_name_b;

	@tmp = split( '-', $trunk_name_b );
	shift @tmp;
	$new_trunk_template_b{-Chassis} = shift @tmp;
	$new_trunk_template_b{-Slot}    = shift @tmp;
	$new_trunk_template_b{-Port}    = shift @tmp;

	# both
	$new_trunk_template_a{-PeerChassis} = $new_trunk_template_b{-Chassis};
	$new_trunk_template_a{-PeerSlot}    = $new_trunk_template_b{-Slot};
	$new_trunk_template_a{-PeerPort}    = $new_trunk_template_b{-Port};

	$new_trunk_template_b{-PeerChassis} = $new_trunk_template_a{-Chassis};
	$new_trunk_template_b{-PeerSlot}    = $new_trunk_template_a{-Slot};
	$new_trunk_template_b{-PeerPort}    = $new_trunk_template_a{-Port};

	$new_trunk_template_a{-AdminCost} = $new_trunk_template_b{-AdminCost} =
	  $trunk->{AdminCost}
	  if defined $trunk->{AdminCost};
	$new_trunk_template_a{-Conduits} = $new_trunk_template_b{-Conduits} =
	  $trunk->{Conduits}
	  if defined $trunk->{Conduits};
	$new_trunk_template_a{-PeerRouterId} =
	  $trunk_end_b->nm_if()->get('System-1')->{-RouterID}
	  or die "get routerID error at ", $trunk_end_b->host();
	$new_trunk_template_b{-PeerRouterId} =
	  $trunk_end_a->nm_if()->get('System-1')->{-RouterID}
	  or die "get routerID error at ", $trunk_end_a->host();

	$new_trunk_template_b{-TrunkName} = $new_trunk_template_a{-TrunkName} =
"$new_trunk_template_b{-PeerRouterId} -- $new_trunk_template_a{-PeerRouterId}";

	$new_trunk_template_b{-OspfAreaId} = $new_trunk_template_a{-OspfAreaId}
	  if defined $trunk->{OspfAreaId};
	$new_trunk_template_b{-VPN} = $new_trunk_template_a{-VPN}
	  if defined $trunk->{VPN};
	$new_trunk_template_b{-MgtChanCost} = $new_trunk_template_a{-MgtChanCost}
	  if defined $trunk->{MgtChanCost};
	$new_trunk_template_b{-IPoverSonetPhys} =
	  $new_trunk_template_a{-IPoverSonetPhys}
	  if defined $trunk->{IPoverSonetPhys};
	$new_trunk_template_b{-PeerDiscovery} =
	  $new_trunk_template_a{-PeerDiscovery}
	  if defined $trunk->{PeerDiscovery};

	$trunk_end_a->_obj_template( \%new_trunk_template_a );
	$trunk_end_b->_obj_template( \%new_trunk_template_b );

	my $create = $trunk->create();
	return $create->{error} if ( $create->{error} );
	sleep $TrunkCreateTime;
	return;
}

sub cfg_ApsProtectionGroup {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;

	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	die "At most two APS objects can be created at ".$self->current_position() if(scalar(@handleObjectName)>2);
	# mandatory parameters
	foreach (qw(Node1_IP Node1_WorkingPort Node1_ProtectPort)) {
		die "\"$_\" should not be empty at ".$self->current_position() unless $content->{$_};
	}	
	# support create sigle-side APS
	my $doubleSides;
	if($content->{'Node2_IP'} and $content->{'Node2_WorkingPort'} and $content->{'Node2_ProtectPort'}) {
		$doubleSides = 1;
	}elsif($content->{'Node2_IP'} or $content->{'Node2_WorkingPort'} or $content->{'Node2_ProtectPort'}) {
		die "Incorrect info on Node2 side at ".$self->current_position();
	}else{
		$doubleSides = 0;
		die "Only one APS object name can be given for one-side APS at ".$self->current_position() if(scalar(@handleObjectName)==2);
	}

	my ($APS_1, $APS_2);
	$self->get_NE_list($content->{'Node1_IP'});
	$APS_1 = new Tea::Objects::APS(
		Host  => $content->{'Node1_IP'},
		Index => $content->{"Node1_ProtectPort"},
	);
	if($doubleSides) {
		$self->get_NE_list($content->{'Node2_IP'});
		$APS_2 = new Tea::Objects::APS(
			Host  => $content->{"Node2_IP"},
			Index => $content->{"Node2_ProtectPort"},
		);
	}

	if ( not $onlyGet ) {
		$APS_1->{ProtectedPort} = $content->{"Node1_WorkingPort"};
		$APS_2->{ProtectedPort} = $content->{"Node2_WorkingPort"};
		$APS_1->{ApsAdminMode}  = $APS_2->{ApsAdminMode} =
		  $content->{"ApsAdminMode"}
		  if defined( $content->{"ApsAdminMode"} );
		$APS_1->{ApsAdminReversionMode} = $APS_2->{ApsAdminReversionMode} =
		  $content->{"ApsAdminReversionMode"}
		  if defined( $content->{"ApsAdminReversionMode"} );
		$APS_1->{ApsWtrTimeout} = $APS_2->{ApsWtrTimeout} =
		  $content->{"ApsWtrTimeout"}
		  if defined( $content->{"ApsWtrTimeout"} );

		my $errorCode;
		if ( $errorCode = _create_aps($APS_1))
		{
			die $errorCode, " at ".$self->current_position();
		}
		if ( $doubleSides and ($errorCode = _create_aps($APS_2)))
		{
			die $errorCode, " at ".$self->current_position();
		}		
	}
	if ( exists $self->{"CreatedObjs"} ) {
		push @{ $self->{"CreatedObjs"} }, $APS_1;
		push @{ $self->{"CreatedObjs"} }, $APS_2 if $doubleSides;
	}
	else {
		my @tmp = ( $APS_1);
		push @tmp, $APS_2 if $doubleSides;
		$self->{"CreatedObjs"} = \@tmp;
	}
	# mapping to object handle(s)
	my $parName;
	# given only one object name
	if(scalar(@handleObjectName) == 1) {
		if($doubleSides) {
			$parName = $handleObjectName[0]."_1"; 
			no strict 'refs';	
			${"main::$parName"} = $APS_1;
			push @{ $self->{"HandleObjNames"} }, $parName;
			$parName = $handleObjectName[0]."_2"; 
			no strict 'refs';	
			${"main::$parName"} = $APS_2;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}else{
			$parName = $handleObjectName[0];
			no strict 'refs';	
			${"main::$parName"} = $APS_1;	
			push @{ $self->{"HandleObjNames"} }, $parName;			
		}
	}else{
		$parName = $handleObjectName[0];
		no strict 'refs';	
		${"main::$parName"} = $APS_1;
		push @{ $self->{"HandleObjNames"} }, $parName;
		$parName = $handleObjectName[1];
		no strict 'refs';	
		${"main::$parName"} = $APS_2;		
		push @{ $self->{"HandleObjNames"} }, $parName;
	}		
}


sub _create_aps {
	my $APS = shift or return;
	my ( $protectIndex, @protect_C_S_P, @protected_C_S_P );
	$protectIndex = $APS->nm_name();
	$protectIndex =~ s/[^-]+-//;
	@protect_C_S_P   = split( '-', $protectIndex );
	@protected_C_S_P = split( '-', $APS->{ProtectedPort} );

	my %aps_template = (
		Name                     => $APS->nm_name(),
		-ApsProtectionGroupName  => $APS->nm_name(),
		-ApsProtectionGroupIndex => $protectIndex,
		-ProtectChassis          => shift(@protect_C_S_P),
		-ProtectSlot             => shift(@protect_C_S_P),
		-ProtectPort             => shift(@protect_C_S_P),
		-WorkingChassis          => shift(@protected_C_S_P),
		-WorkingSlot             => shift(@protected_C_S_P),
		-WorkingPort             => shift(@protected_C_S_P),
		-ApsAdminMode            => "admin_bidirectional",
		-ApsAdminReversionMode   => "admin_nonrevertive",
		-ApsWtrTimeout           => "5",
	);
	$aps_template{"-ApsAdminMode"} = $APS->{ApsAdminMode}
	  if defined( $APS->{ApsAdminMode} );
	$aps_template{"-ApsAdminReversionMode"} = $APS->{ApsWtrTimeout}
	  if defined( $APS->{ApsWtrTimeout} );
	$aps_template{"-ApsWtrTimeout"} = $APS->{ApsWtrTimeout}
	  if defined( $APS->{ApsWtrTimeout} );

	$APS->_obj_template( \%aps_template );

	my $create = $APS->create();
	return $create->{error} if ( $create->{error} );
	sleep $APSCreateTime;
	return;
}

sub cfg_PathProtectionGroup {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;

	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}	
	# mandatory parameters
	foreach (qw(Host Working Protect Size)) {
		die "\"$_\" should not be empty at ".$self->current_position() unless $content->{$_};
	}
	$self->get_NE_list($content->{'Host'});
	
	my $BW;
	$_ = $content->{'Size'};
	if(/STS1_AU3/) {$BW = 1;}
	elsif(/STS3c_AU4/){$BW = 3;}
	elsif(/STS12c_AU4_4c/){$BW = 12;}
	elsif(/STS24c_AU4_8c/){$BW = 24;}
	elsif(/STS48c_AU4_16c/){$BW = 48;}
	elsif(/STS192c_AU4_64c/){$BW = 192;}

	for(my $i=0; $i<$objectNum; $i++) {
		my $PPG = new Tea::Objects::PPG(
			Host  => $content->{"Host"},
			Index => _index_increase($content->{"Protect"}, $i*$BW),
		);
		if ( not $onlyGet ) {
			$PPG->{ProtectedTS}    = _index_increase($content->{"Working"}, $i*$BW);
			$PPG->{Size}           = $content->{"Size"};
			$PPG->{ProtectionType} = $content->{"ProtectionType"}
			  if defined( $content->{"ProtectionType"} );
			$PPG->{RevMode} = $content->{"RevMode"}
			  if defined( $content->{"RevMode"} );
			$PPG->{RepCtrl} = $content->{"RepCtrl"}
			  if defined( $content->{"RepCtrl"} );
			$PPG->{RepMode} = $content->{"RepMode"}
			  if defined( $content->{"RepMode"} );
			$PPG->{WtrTimeout} = $content->{"WtrTimeout"}
			  if defined( $content->{"WtrTimeout"} );
			if ( my $errorCode = _create_ppg($PPG) ) {
				die $errorCode;
			}
		}
		if ( exists $self->{"CreatedObjs"} ) {
			push @{ $self->{"CreatedObjs"} }, $PPG;
		}
		else {
			my @tmp = ($PPG);
			$self->{"CreatedObjs"} = \@tmp;
		}
		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $PPG;	
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $PPG;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $PPG;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}
	}		
}

sub _create_ppg {
	my $PPG = shift or return;
	my ( $protectIndex, @protectTS, @protectedTS, @newPPG_template_list );
	$protectIndex = $PPG->nm_name();
	$protectIndex =~ s/[^-]+-//;
	my ( $protectTS, $protectedTS, @protectTS_array, @protectedTS_array );
	$protectTS = $protectIndex;
	@protectTS_array = split( '-', $protectTS );

	$protectedTS = $PPG->{ProtectedTS};
	@protectedTS_array = split( '-', $protectedTS );

	my %ppg_template = (
		Name         => $PPG->nm_name(),
		-Name        => "(P) $protectTS, (W) $protectedTS",
		-Bw          => "STS1_AU3",
		-PChassis    => shift(@protectTS_array),
		-PSlot       => shift(@protectTS_array),
		-PPort       => shift(@protectTS_array),
		-PStartingTS => shift(@protectTS_array),

		-WChassis       => shift(@protectedTS_array),
		-WSlot          => shift(@protectedTS_array),
		-WPort          => shift(@protectedTS_array),
		-WStartingTS    => shift(@protectedTS_array),
		-ProtectionType => "upsr",
		-RevMode        => "0",
		-RepCtrl        => "0",
		-RepMode        => "ps_rep_event",
		-WtrTimeout     => "5"
	);

	$ppg_template{"-Bw"} = $PPG->{Size} if defined( $PPG->{Size} );
	$ppg_template{"-ProtectionType"} = $PPG->{ProtectionType}
	  if defined( $PPG->{ProtectionType} );
	$ppg_template{"-RevMode"} = $PPG->{RevMode} if defined( $PPG->{RevMode} );
	$ppg_template{"-RepCtrl"} = $PPG->{RepCtrl} if defined( $PPG->{RepCtrl} );
	$ppg_template{"-RepMode"} = $PPG->{RepMode} if defined( $PPG->{RepMode} );
	$ppg_template{"-WtrTimeout"} = $PPG->{WtrTimeout}
	  if defined( $PPG->{WtrTimeout} );

	$PPG->_obj_template( \%ppg_template );
	my $create = $PPG->create();
	return $create->{error} if ( $create->{error} );
	sleep $PPGCreateTime;
	return;
}

sub cfg_LOXC {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;

	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}	
	# mandatory parameters
	foreach (qw(Host Ingress Egress Size)) {
		die "\"$_\" should not be empty at ".$self->current_position() unless $content->{$_};
	}
	$self->get_NE_list($content->{'Host'});
	my $hostIP = $content->{"Host"}; 
	my $LOXCSize = $content->{"Size"};
	my $IngressInfo =
	  _get_channelInfo( $hostIP, $content->{"Ingress"} );
	die "Incorrect formate of LOXC Ingress"
	  unless ( $IngressInfo and $IngressInfo->{'ChannelType'} );
	my $EgressInfo =
	  _get_channelInfo( $hostIP, $content->{"Egress"} );
	die "Incorrect formate of LOXC Egress"
	  unless ( $EgressInfo and $EgressInfo->{'ChannelType'} );
	{		  
		my %matchedBW = (
			'TU11_VT1' => 0,
			'TU12_VT2'  => 0,
			'DS1'       => 0,
			'E1'        => 0,
			'TU3'      => 0,
			'DS3'       => 0
		);
		foreach ( $IngressInfo->{'ChannelType'},
			$EgressInfo->{'ChannelType'} )
		{
			if (/SONETSDH|VLPORT/) {
				$matchedBW{'TU11_VT1'}++;
				$matchedBW{'TU12_VT2'}++;
				$matchedBW{'DS1'}++;
				$matchedBW{'E1'}++;
				$matchedBW{'TU3'}++;
				$matchedBW{'DS3'}++;
			}
			elsif (/E1|Channel_E1/) {
				$matchedBW{'E1'}++;
			}
			elsif (/DS1|Channel_DS1/) {
				$matchedBW{'DS1'}++;
			}
			elsif (/DS3/) {
				$matchedBW{'DS3'}++;
			}
		}
		my @allowedBWs;
		foreach my $bw ( keys(%matchedBW) ) {
			if ( $matchedBW{$bw} == 2 ) {
				push @allowedBWs, $bw;
			}
		}

		# no sutible BW
		if ( scalar(@allowedBWs) < 1 ) {
			die "$hostIP: LOXC between ", $content->{"Ingress"},
			  " and ", $content->{"Egress"}, " is not supported";
		}
		else {

			# has input BW
			if ($LOXCSize) {

				# input BW doesn't match
				if ( $matchedBW{$LOXCSize} != 2 ) {
					die "$hostIP: BW $LOXCSize LOXC not supported between ",
					  $content->{"Ingress"}, " and ",
					  $content->{"Egress"},  ": ",
					  join( "\/", @allowedBWs )
					  if scalar(@allowedBWs);
				}
			}
			else {

				# match ONLY ONE
				if ( scalar(@allowedBWs) == 1 ) {
					$LOXCSize = $allowedBWs[0];
				}
				elsif ( !$LOXCSize ) {

					# match two or more
					die "$hostIP: should specify the BW of LOXC between ",
					  $content->{"Ingress"}, " and ",
					  $content->{"Egress"},  "\n\t",
					  join( "\/", @allowedBWs );
				}
			}
		}
	}
	
	for(my $i=0; $i<$objectNum; $i++) {
		my ($IngressChassis, $IngressSlot, $IngressPort, $IngressTimeslot, $IngressTug3, $IngressTug2,
			$IngressVcNumber, $IngressM13Channel) = split( '-', $$content->{"Ingress"} );
		$IngressTimeslot = 0 unless defined $IngressTimeslot;
		$IngressTug3 = 0 unless defined $IngressTug3;
		$IngressTug2 = 0 unless defined $IngressTug2;
		$IngressVcNumber = 0 unless defined $IngressVcNumber;
		$IngressM13Channel = 0 unless defined $IngressM13Channel;
		
		my ($EgressChassis, $EgressSlot, $EgressPort, $EgressTimeslot, $EgressTug3, $EgressTug2,
			$EgressVcNumber, $EgressM13Channel) = split( '-', $$content->{"Egress"} );
		$EgressTimeslot = 0 unless defined $EgressTimeslot;
		$EgressTug3 = 0 unless defined $EgressTug3;
		$EgressTug2 = 0 unless defined $EgressTug2;
		$EgressVcNumber = 0 unless defined $EgressVcNumber;
		$EgressM13Channel = 0 unless defined $EgressM13Channel;
		
		if ( $LOXCSize =~ /DS1/ ) {
			if($IngressInfo->{'ChannelType'} =~ /DS1/) {
				$IngressPort += $i;
				die "Can't support so many LOXCs in this version" unless((($IngressPort>=1)and($IngressPort<=24))or(($IngressPort>=29)and($IngressPort<=52))or(($IngressPort>=57)and($IngressPort<=80)));
			}elsif ($IngressInfo->{'ChannelType'} =~ /Channel_DS1/) {
				$IngressTimeslot += $i;
				die "Can't support so many LOXCs in this version" if($IngressTimeslot>7*4);
			}else {
				$IngressVcNumber += $i;
				$IngressTug2 +=
				  int( ($IngressVcNumber-1) / 4 );
				$IngressVcNumber = ($IngressVcNumber-1)%4+1;
				die "Can't support so many LOXCs in this version" if ( $IngressTug2 > 7);
			}
			if($EgressInfo->{'ChannelType'} =~ /DS1/) {
				$EgressPort += $i;
				die "Can't support so many LOXCs in this version" unless((($IngressPort>=1)and($IngressPort<=24))or(($IngressPort>=29)and($IngressPort<=52))or(($IngressPort>=57)and($IngressPort<=80)));
			}elsif ($EgressInfo->{'ChannelType'} =~ /Channel_DS1/) {
				$EgressTimeslot += $i;
				die "Can't support so many LOXCs in this version" if($EgressTimeslot>7*4);
			}else {
				$EgressVcNumber += $i;
				$EgressTug2 +=
				  int( ($EgressVcNumber-1) / 4 );
				$EgressVcNumber = ($EgressVcNumber-1)%4+1;
				die "Can't support so many LOXCs in this version" if ( $EgressTug2 > 7);
			}
		}elsif( $LOXCSize =~ /TU11_VT1/ ) {
			$IngressVcNumber += $i;
			$IngressTug2 +=
			  int( ($IngressVcNumber-1) / 4 );
			$IngressVcNumber = ($IngressVcNumber-1)%4+1;
			
			$EgressVcNumber += $i;
			$EgressTug2 += int( ($EgressVcNumber-1) / 4 );
			$EgressVcNumber = ($EgressVcNumber-1)%4+1;
			die "Can't support so many LOXCs in this version"
			  if ( $IngressTug2 > 7
				or $EgressTug2 > 7 );
		}elsif( $LOXCSize =~ /E1/ ) {
			if($IngressInfo->{'ChannelType'} =~ /E1/) {
				$IngressPort += $i;
				die "Can't support so many LOXCs in this version" if($IngressPort>3*7*3);
			}elsif ($IngressInfo->{'ChannelType'} =~ /Channel_E1/) {
				$IngressTimeslot += $i;
				die "Can't support so many LOXCs in this version" if($IngressTimeslot>7*3);
			}else {
				$IngressVcNumber += $i;
				$IngressTug2 +=
				  int( ($IngressVcNumber-1) / 3 );
				$IngressVcNumber = ($IngressVcNumber-1)%3+1;
				die "Can't support so many LOXCs in this version" if ( $IngressTug2 > 7);
			}
			if($EgressInfo->{'ChannelType'} =~ /E1/) {
				$EgressPort += $i;
				die "Can't support so many LOXCs in this version" if($EgressPort>3*7*3);
			}elsif ($EgressInfo->{'ChannelType'} =~ /Channel_E1/) {
				$EgressTimeslot += $i;
				die "Can't support so many LOXCs in this version" if($EgressTimeslot>7*3);
			}else {
				$EgressVcNumber += $i;
				$EgressTug2 +=
				  int( ($EgressVcNumber-1) / 3 );
				$EgressVcNumber = ($EgressVcNumber-1)%3+1;
				die "Can't support so many LOXCs in this version" if ( $EgressTug2 > 7);
			}
		}elsif( $LOXCSize =~ /TU12_VT2/ ) {
			$IngressVcNumber += $i;
			$IngressTug2 +=
			  int( ($IngressVcNumber-1) / 3 );
			$IngressVcNumber = ($IngressVcNumber-1)%3+1;
			$EgressVcNumber += $i;
			$EgressTug2 += int( ($EgressVcNumber-1) / 3 );
			$EgressVcNumber = ($EgressVcNumber-1)%3+1;
			die "Can't support so many LOXCs in this version"
			  if ( $IngressTug2 > 7
				or $EgressTug2 > 7 );
		}
		elsif ( $LOXCSize =~ /DS3|TU3/ ) {
			$IngressTug3++;
			$EgressTug3++;
			die "Can't support so many LOXCs in this version"
			  if ( $IngressTug3 > 1
				or $EgressTug3 > 1 );
		}
		my $LOXC = new Tea::Objects::LoXC(
			Host  => $hostIP,
			Index => join( '-',	$IngressChassis, $IngressSlot, $IngressPort, $IngressTimeslot, 
				$IngressTug3, $IngressTug2,	$IngressVcNumber, $IngressM13Channel, $EgressChassis, 
				$EgressSlot, $EgressPort, $EgressTimeslot, $EgressTug3, $EgressTug2, 
				$EgressVcNumber, $EgressM13Channel),
		);	
		if(not $onlyGet) {
			$LOXC->{Size} = $LOXCSize;
			$LOXC->{IngressChassis} = $IngressChassis;
			$LOXC->{IngressSlot} = $IngressSlot;
			$LOXC->{IngressPort} = $IngressPort;
			$LOXC->{IngressTimeslot} = $IngressTimeslot;
			$LOXC->{IngressTug3} = $IngressTug3;
			$LOXC->{IngressTug2} = $IngressTug2;
			$LOXC->{IngressVcNumber} = $IngressVcNumber;
			$LOXC->{IngressM13Channel} = $IngressM13Channel;
			
			$LOXC->{EgressChassis} = $EgressChassis;
			$LOXC->{EgressSlot} = $EgressSlot;
			$LOXC->{EgressPort} = $EgressPort;
			$LOXC->{EgressTimeslot} = $EgressTimeslot;
			$LOXC->{EgressTug3} = $EgressTug3;
			$LOXC->{EgressTug2} = $EgressTug2;					
			$LOXC->{EgressVcNumber} = $EgressVcNumber;
			$LOXC->{EgressM13Channel} = $EgressM13Channel;	

			if ( my $errorCode = _create_loxc($LOXC) ) {
				die $errorCode;
			}				
		}
		if ( exists $self->{"CreatedObjs"} ) {
			push @{ $self->{"CreatedObjs"} }, $LOXC;
		}
		else {
			my @tmp = ( $LOXC);
			$self->{"CreatedObjs"} = \@tmp;
		}
		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $LOXC;	
				push @{ $self->{"HandleObjNames"} }, $parName;				
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $LOXC;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $LOXC;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}	
	}
}

sub _create_loxc {
	my $LOXC = shift or return;		
	my $Host = new Tea::Objects::SN9K( Host => $LOXC->host() );
	my $SwitchIP = $Host->getObjects("System-1")->{'-SwitchIP'};	
	my $Name = join( '-',"LOXC",  $SwitchIP,
		$LOXC->{IngressChassis},  $LOXC->{IngressSlot},
		$LOXC->{IngressPort},     $LOXC->{IngressTimeslot},
		$LOXC->{IngressTug3},     $LOXC->{IngressTug2},
		$LOXC->{IngressVcNumber}, $LOXC->{IngressM13Channel},
		$LOXC->{EgressChassis},   $LOXC->{EgressSlot},
		$LOXC->{EgressPort},      $LOXC->{EgressTimeslot},
		$LOXC->{EgressTug3},      $LOXC->{EgressTug2},
		$LOXC->{EgressVcNumber},  $LOXC->{EgressM13Channel} );	
	my %loxc_template = (
		Name => $Name,
		-LoXcName => $Name,
		-LocalSwitchIP	=> $SwitchIP,
		-BandwidthForward => $LOXC->{Size},
		-BandwidthReverse => $LOXC->{Size},
		-IngressChassis   => $LOXC->{IngressChassis},
		-IngressSlot		=> $LOXC->{IngressSlot},		  
		-IngressPort		=> $LOXC->{IngressPort},
		-IngressTimeslot	=> $LOXC->{IngressTimeslot},
		-IngressTug3		=> $LOXC->{IngressTug3},
		-IngressTug2		=> $LOXC->{IngressTug2},
		-IngressVcNumber	=> $LOXC->{IngressVcNumber},
		-IngressM13Channel => $LOXC->{IngressM13Channel},
		-EgressChassis	=> $LOXC->{EgressPort},
		-EgressSlot		=> $LOXC->{EgressSlot},		  
		-EgressPort		=> $LOXC->{EgressPort},
		-EgressTimeslot	=> $LOXC->{EgressTimeslot},
		-EgressTug3		=> $LOXC->{EgressTug3},
		-EgressTug2		=> $LOXC->{EgressTug2},
		-EgressVcNumber	=> $LOXC->{EgressVcNumber},
		-EgressM13Channel => $LOXC->{EgressM13Channel},
	);
	$LOXC->_obj_template( \%loxc_template );
	my $create = $LOXC->create();
	return $create->{error} if ( $create->{error} );
	sleep $LOXCCreateTime;
	return;
}

sub _get_channelInfo {
	my $hostIP  = shift;
	my $channel = shift;
	my ( $chassis, $slot, $port, $ts, $tug3, $tug2, $vc, $m13 ) =
	  split( '-', $channel );
	my %info = (
		CardType    => undef,
		CardMode    => undef,
		PortType    => undef,
		ChannelType => undef,
	);
	my $cardIndex = join( '-', $chassis, $slot );
	my $Card = new Tea::Objects::Card(
		Host  => $hostIP,
		Index => join( '-', $chassis, $slot ),
	);
	die unless $cardIndex and $Card;
	my ( $nmi, $ref );
	die $Card->host(), " ", $Card->nm_name(), " not exist"
	  unless ( ( $nmi = $Card->nm_if() )
		and ( $ref = $nmi->get( $Card->nm_name() ) ) );

	# for e1ds1 -PdhType = ds1/e1
	# for ds3 -InterfaceType = ds3
	$info{CardType} =
	     $ref->{'-PdhType'}
	  || $ref->{'-InterfaceType'}
	  || $ref->{'-CardType'};
	$info{CardMode} = $ref->{'-Mode'};
	return \%info unless ( defined $port and $port > 0 );
	local $_ = $info{CardType};
	if (/e1/) {
		$info{PortType}    = "Port_E1";
		$info{ChannelType} = "E1"
		  unless ( $ts || $tug3 || $tug2 || $vc || $m13 );
	}
	elsif (/ds1/) {
		$info{PortType}    = "Port_DS1";
		$info{ChannelType} = "DS1"
		  unless ( $ts || $tug3 || $tug2 || $vc || $m13 );
	}
	elsif (/ds3/) {
		$info{PortType} = "Port_DS3";
		my $Port = new Tea::Objects::Port(
			Host  => $hostIP,
			Index => join( '-', $chassis, $slot, $port ),
			Type  => "Port_DS3"
		);
		die $Port->host(), " ", $Port->nm_name(), " not exist"
		  unless ( ( $nmi = $Port->nm_if() )
			and ( $ref = $nmi->get( $Port->nm_name() ) ) );
		if (    $info{CardMode} eq "dist_tu3"
			and $ref->{'-TransmuxMode'} =~ /none|portless/ )
		{
			$info{ChannelType} = "DS3"
			  unless ( $ts || $tug3 || $tug2 || $vc || $m13 );
		}
		elsif ( $ref->{'-TransmuxMode'} =~ /port_based|portless/
			and $ref->{'-ResultTreatment'} =~ /distributed/ )
		{
			if ( $ref->{'-TransmuxType'} =~ /ds1/ ) {
				$info{ChannelType} = "Channel_DS1"
				  unless ( $tug3 || $tug2 || $vc || $m13 );
			}
			elsif ( $ref->{'-TransmuxType'} =~ /e1/ ) {
				$info{ChannelType} = "Channel_E1"
				  unless ( $tug3 || $tug2 || $vc || $m13 );
			}
		}
	}
	elsif (/VXC_10/) {
		$info{ChannelType} = "VLPORT" if ( $ts > 0 );
	}
	else {
		$info{ChannelType} = "SONETSDH" if ( $ts > 0 );
	}
	return \%info;
}



sub cfg_CRG {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;

	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	die "Only one CRG objects can be created at ".$self->current_position() if(scalar(@handleObjectName)>1);
	# mandatory parameters
	foreach (qw(Host ProtectCard ProtectedCardList)) {
		die "\"$_\" should not be empty at ".$self->current_position() unless $content->{$_};
	}
	$self->get_NE_list($content->{'Host'});
	my $CRG = new Tea::Objects::CRG(
		Host  => $content->{"Host"},
		Index => $content->{"ProtectCard"},
	);
	if ( not $onlyGet ) {
		$CRG->{ProtectedCardList} = $content->{"ProtectedCardList"};
		$CRG->{Revertive}         = $content->{"Revertive"}
		  if defined( $content->{"Revertive"} );
		$CRG->{WaitToRestore} = $content->{"WaitToRestore"}
		  if defined( $content->{"WaitToRestore"} );
		$CRG->{ReportControl} = $content->{"ReportControl"}
		  if defined( $content->{"ReportControl"} );
		$CRG->{ReportMode} = $content->{"ReportMode"}
		  if defined( $content->{"ReportMode"} );
		if ( my $errorCode = _create_crg($CRG) ) {
			die $errorCode, " at ".$self->current_position() unless($errorCode =~ /already/);
		}
	}
	if ( exists $self->{"CreatedObjs"} ) {
		push @{ $self->{"CreatedObjs"} }, $CRG;
	}
	else {
		my @tmp = ($CRG);
		$self->{"CreatedObjs"} = \@tmp;
	}
	# mapping to object handle(s)
	my $parName;
	# given only one object name
	if(scalar(@handleObjectName) == 1) {
		$parName = $handleObjectName[0];
		no strict 'refs';	
		${"main::$parName"} = $CRG;	
		push @{ $self->{"HandleObjNames"} }, $parName;		
	}
}

sub _create_crg {
	my $CRG = shift or return;
	my $ProtectCardIndex = $CRG->nm_name();
	$ProtectCardIndex =~ s/[^-]+-//;
	my @ProtectedCardList = split(":", $CRG->{ProtectedCardList});
	# special check for DS3 CRG
	{
		my $errorCode = $CRG->host()." Card $ProtectCardIndex not exist"; # init
		my $Card = new Tea::Objects::Card(
			Host  => $CRG->host(),
			Index => $ProtectCardIndex,
		);
		my ( $nmi, $ref );
		return $errorCode unless ($Card and ($nmi = $Card->nm_if()) and ($ref = $nmi->get($Card->nm_name())));

		# for e1ds1 -PdhType = ds1/e1
		# for ds3 -InterfaceType = ds3
		my $cardType =
			 $ref->{'-PdhType'}
		  || $ref->{'-InterfaceType'}
		  || $ref->{'-CardType'};
		if($cardType =~ /ds3/) {
			my $current_c_s = $ProtectCardIndex;
			for(my $i=0; $i<scalar(@ProtectedCardList); $i++) {
				$errorCode = "DS3 protect card slots should be continuous";
				return $errorCode if($ProtectedCardList[$i] ne _index_increase($ProtectCardIndex, $i+1));
				$errorCode = "DS3 protect and working cards should reside on the same quard";
				return $errorCode if($ProtectedCardList[$i] =~ /-8$/);
			}
		}
	}
	
	my %crg_template = (
		Name           => $CRG->nm_name(),
		-Name          => $CRG->nm_name(),
		-Revertive     => "0",
		-WaitToRestore => "Global",
		-ReportControl => "NotReported",
		-ReportMode    => "Event",
	);

	$crg_template{"-Revertive"} = $CRG->{Revertive}
	  if defined( $CRG->{Revertive} );
	$crg_template{"-WaitToRestore"} = $CRG->{WaitToRestore}
	  if defined( $CRG->{WaitToRestore} );
	$crg_template{"-ReportControl"} = $CRG->{ReportControl}
	  if defined( $CRG->{ReportControl} );
	$crg_template{"-ReportMode"} = $CRG->{ReportMode}
	  if defined( $CRG->{ReportMode} );

	$CRG->_obj_template( \%crg_template, "no_filter" );
	my $create = $CRG->create();

# sometimes, it will cost long time for NE to response,
# then "problem reading from HTTP port: read timed-out" alarm will generated by TEA
# here ignore this exception
	die $create->{error}
	  if (  $create->{error}
		and $create->{error} !~ /(problem reading from HTTP port)|(already)/ );
	sleep $CRGCreateTime;


	my $MemberIndex = 0;
	foreach my $ProtectedCard (@ProtectedCardList) {
		$MemberIndex++;
		my $CRGMember = new Tea::Objects::CRGMember(
			Host  => $CRG->host(),
			Index => $ProtectCardIndex . "-" . $MemberIndex,
		);
		my @protectedChassisCard_array = split( '-', $ProtectedCard );
		$CRGMember->_obj_template(
			{
				Name               => $CRGMember->nm_name(),
				-CardChassisNumber => shift(@protectedChassisCard_array),
				-CardSlotNumber    => shift(@protectedChassisCard_array)
			},
			"no_filter"
		);
		my $create = $CRGMember->create();
		die $create->{error} if ( $create->{error} and $create->{error} !~ /already/ );
		sleep $CRGMemberCreateTime;
	}
	my $set = $CRG->set( "AdminState", "InService" );
	return $set->{error};
}

sub cfg_Circuit {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;

	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}	
	# mandatory parameters
	foreach (qw(SourceIP SourceChannel Size)) {
		die "\"$_\" should not be empty at ".$self->current_position() unless $content->{$_};
	}
	$self->get_NE_list( $content->{"SourceIP"} );
	
	for(my $i=0; $i<$objectNum; $i++) {
		my $Ckt = new Tea::Objects::Circuit(
			Host  => $content->{"SourceIP"},
			Index => _index_increase(
				$content->{"SourceChannel"},
				$i * $content->{"Size"}
			),
		);
		my $IsPresent = 0;
		my %actual_attribute;
		{
			my $nmi = $Ckt->nm_if()
			  or die $Ckt->host(), " ", $Ckt->nm_name(), " not exist";
			my $ref = $nmi->get( $Ckt->nm_name() );
			if(defined $ref) {
				$IsPresent = 1;
				%actual_attribute = %{$ref};
			}
		}
		
		if ( not $onlyGet ) {
			$content->{"DestinationIP"} = $content->{"SourceIP"}
			  unless defined( $content->{"DestinationIP"} );
			die unless defined( $content->{"DestinationChannel"} );
			$content->{"ProtectDestinationIP"} =
			  $content->{"SourceIP"}
			  if ( defined( $content->{"ProtectDestinationChannel"} )
				and
				( not defined( $content->{"ProtectDestinationIP"} ) ) );
			die
			  if (
				defined( $content->{"ProtectDestinationIP"} )
				and (
					not
					defined( $content->{"ProtectDestinationChannel"} ) )
			  );

			# Mandatory
			$Ckt->{SourceIP}      = $content->{"SourceIP"};
			$Ckt->{SourceChannel} = _index_increase(
				$content->{"SourceChannel"},
				$i * $content->{"Size"}
			);
			$Ckt->{DestinationIP}      = $content->{"DestinationIP"};
			$Ckt->{DestinationChannel} = _index_increase(
				$content->{"DestinationChannel"},
				$i * $content->{"Size"}
			);
			$Ckt->{Size} = $content->{"Size"};

			# Optional
			$Ckt->{CircuitServiceType} =
			  $content->{"CircuitServiceType"}
			  if defined( $content->{"CircuitServiceType"} );
			$Ckt->{CircuitVpnId} = $content->{"CircuitVpnId"}
			  if defined( $content->{"CircuitVpnId"} );
			$Ckt->{CircuitConcatenation} =
			  $content->{"CircuitConcatenation"}
			  if defined( $content->{"CircuitConcatenation"} );
			$Ckt->{CircuitProtection} = $content->{"CircuitProtection"}
			  if defined( $content->{"CircuitProtection"} );
			$Ckt->{CircuitPathProtectionDirectionalMode} =
			  $content->{"CircuitPathProtectionDirectionalMode"}
			  if defined(
					  $content->{"CircuitPathProtectionDirectionalMode"}
			  );
			$Ckt->{CircuitTrunkRestoration} =
			  $content->{"CircuitTrunkRestoration"}
			  if defined( $content->{"CircuitTrunkRestoration"} );
			if ( defined( $content->{"CircuitReversion"} ) ) {
				$Ckt->{CircuitReversion} =
				  $content->{"CircuitReversion"};
				if ( $Ckt->{CircuitReversion} eq
					"circuitAutomaticReversionEnabled" )
				{
					if (
						defined(
							$content->{
								"CircuitAutomaticReversionDelayTimer"}
						)
					  )
					{
						if (
							defined(
								$content->{
									"CircuitAutomaticReversionScheduledDay"}
							)
							or defined(
								$content->{
"CircuitAutomaticReversionScheduledHour_Min"
								  }
							)
						  )
						{
							die
"only one of \"CircuitAutomaticReversionDelayTimer\" and \"CircuitAutomaticReversionScheduledDay/Hour_Min\" can be configured at ".$self->current_position();
						}
						else {
							$Ckt->{CircuitAutomaticReversionDelayTimer} =
							  $content->{
								"CircuitAutomaticReversionDelayTimer"};
						}
					}
					elsif (
						(
							defined(
								$content->{
									"CircuitAutomaticReversionScheduledDay"}
							)
						)
						and (
							defined(
								$content->{
"CircuitAutomaticReversionScheduledHour_Min"
								  }
							)
						)
					  )
					{
						$Ckt->{CircuitAutomaticReversionScheduledDay} =
						  $content->{
							"CircuitAutomaticReversionScheduledDay"};
						my ( $hour, $minute ) = split(
							":",
							$content->{
"CircuitAutomaticReversionScheduledDay_Hour_Min"
							  }
						);
						$Ckt->{CircuitAutomaticReversionScheduledHour} =
						  $hour;
						$Ckt->{CircuitAutomaticReversionScheduledMinute} =
						  $minute;
					}
					else {
						die
"you should configure either \"CircuitAutomaticReversionDelayTimer\" or \"CircuitAutomaticReversionScheduledDay+Hour_Min\" at ".$self->current_position();
					}
				}
				elsif ( $Ckt->{CircuitReversion} eq
					"circuitManualReversionEnabled" )
				{
					$Ckt->{CircuitManualReversionScheduledTimer} =
					  $content->{"CircuitManualReversionScheduledTimer"}
					  if defined(
							  $content->{
								  "CircuitManualReversionScheduledTimer"}
					  );
				}
			}
			$Ckt->{CircuitIppmControl} =
			  $content->{"CircuitIppmControl"}
			  if defined( $content->{"CircuitIppmControl"} );
			$Ckt->{CircuitPathAlarmControl} =
			  $content->{"CircuitPathAlarmControl"}
			  if defined( $content->{"CircuitPathAlarmControl"} );
			$Ckt->{CircuitPathAlarmReporting} = 0;
			$Ckt->{CircuitPathAlarmReporting} += 4
			  if (
				$content->{"CircuitPathAlarmReporting_AIS-P"} eq "On" );
			$Ckt->{CircuitPathAlarmReporting} += 2
			  if ( $content->{"CircuitPathAlarmReporting_UNEQ-P"} eq
				"On" );
			$Ckt->{CircuitPathAlarmReporting} += 1
			  if (
				$content->{"CircuitPathAlarmReporting_RFI-P"} eq "On" );

			# working
			$Ckt->{CircuitSourceRerouted} =
			  $content->{"CircuitSourceRerouted"}
			  if defined( $content->{"CircuitSourceRerouted"} );
			if ( defined( $content->{"CircuitRouteMode"} ) ) {
				$Ckt->{CircuitRouteMode} =
				  $content->{"CircuitRouteMode"};
				if ( $Ckt->{CircuitRouteMode} eq "circuitStitchedMode" ) {
					my @nodeID_list;
					my @conduitID_list;				
					if(defined $content->{"CircuitStitchedRoute"}) {
						foreach my $item (split(/\s/, $content->{"CircuitStitchedRoute"})){
							if ( $item =~ /\./ ) {
								# convert node ip to node id
								my $NEObj =
								  new Tea::Objects::SN9K( Host => $item );
								push @nodeID_list,
								  $NEObj->nm_if()->get('System-1')->{-RouterID};
							}
							else {
								push @conduitID_list, $item;
							}
						}
						$Ckt->{CircuitStitchedRoute} =
						  ( scalar(@conduitID_list) and $Ckt->{CircuitProtection} ne 'circuitNoProtection')
						  ? join( " ",
							@nodeID_list, "ConduitList%3D", @conduitID_list )
						  : join( " ", @nodeID_list );								
					}else{
						die '"CircuitRouteMode" should not be empty for creating stitched circuit at '.$self->current_position()  unless $IsPresent;
						my $stitchType = ($Ckt->{CircuitProtection} eq 'circuitNoProtection') ? 'node' : 'conduit';
						$Ckt->{CircuitStitchedRoute} = $Ckt->get_path('working', $stitchType) or die "Circuit working path is down";
					}			
				}
			}
			# protection
			$Ckt->{ProtectDestinationIP} =
			  $content->{"ProtectDestinationIP"}
			  if defined( $content->{"ProtectDestinationIP"} );
			$Ckt->{ProtectDestinationChannel} =
			  _index_increase( $content->{"ProtectDestinationChannel"},
				$i * $content->{"Size"} )
			  if defined( $content->{"ProtectDestinationChannel"} );
			$Ckt->{CircuitProtectSourceRerouted} =
			  $content->{"CircuitProtectSourceRerouted"}
			  if defined( $content->{"CircuitProtectSourceRerouted"} );
			if ( defined( $content->{"CircuitProtectRouteMode"} ) ) {
				$Ckt->{CircuitProtectRouteMode} =
				  $content->{"CircuitProtectRouteMode"};
			}	  
				  
			if (( $Ckt->{CircuitProtectRouteMode} eq "circuitProtectStitchedMode" ) 
				or ((($Ckt->{CircuitProtection} eq "circuitConduitIdDiverse") or ($Ckt->{CircuitProtection} eq "circuitDiverselyRouted"))
					and ($Ckt->{CircuitRouteMode} eq "circuitStitchedMode"))) {
				my @nodeID_list;
				my @conduitID_list;
				if(defined $content->{"CircuitProtectStitchedRoute"}) {
					foreach my $item (split(/\s/, $content->{"CircuitProtectStitchedRoute"})){
						if ( $item =~ /\./ ) {
							# convert node ip to node id
							my $NEObj =
							  new Tea::Objects::SN9K( Host => $item );
							push @nodeID_list,
							  $NEObj->nm_if()->get('System-1')->{-RouterID};
						}
						else {
							push @conduitID_list, $item;
						}
					}
					$Ckt->{CircuitProtectStitchedRoute} =
					  ( scalar(@conduitID_list) )
					  ? join( " ",
						@nodeID_list, "ConduitList%3D", @conduitID_list )
					  : join( " ", @nodeID_list );					
				}else {
					die '"CircuitProtectRouteMode" should not be empty for creating stitched circuit at '.$self->current_position()  unless $IsPresent;
					$Ckt->{CircuitStitchedRoute} = $Ckt->get_path('protect', 'conduit') or die "Circuit protect path is down";
				}

			}
			if(! $IsPresent) {
				if ( my $errorCode = _create_circuit($Ckt) ) {
					die $errorCode, " at ".$self->current_position();
				}
			}else{
				if ( my $errorCode = _create_circuit($Ckt, \%actual_attribute) ) {
					die $errorCode, " at ".$self->current_position();
				}			
			}
		}	
		
		# mapping to object handle(s)	
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			$parName = $handleObjectName[0];
			if($i == 0 and not defined ${"main::$parName"}) { # by default, pointing to the first object
				no strict 'refs';	
				${"main::$parName"} = $Ckt;			
				push @{ $self->{"HandleObjNames"} }, $parName;
				# print "Push A: $parName\n";
			}
			# expand the object name for multi-objects
			{
				my $index = $i+1;
				while(defined ${"main::$parName"."_".$index}) { $index++; }
				$parName = $parName."_".$index;
			}			
			no strict 'refs';	
			${"main::$parName"} = $Ckt;
			push @{ $self->{"HandleObjNames"} }, $parName;
			# print "Push B: $parName\n";
		}else{
			if($parName = $handleObjectName[$i]) {
				no strict 'refs';	
				${"main::$parName"} = $Ckt;
				push @{ $self->{"HandleObjNames"} }, $parName;
				# print "Push C: $parName\n";
			}
		}
		
		if ( exists $self->{"CreatedObjs"} ) {
			push @{ $self->{"CreatedObjs"} }, $Ckt;
		}
		else {
			my @tmp = ($Ckt);
			$self->{"CreatedObjs"} = \@tmp;
		}
	}
	sleep $CktCreateTime if($objectNum and not $onlyGet);
}

sub _index_increase {
	my $indexStr    = shift;
	my $increase = shift;
	my @indexList  = split( '-', $indexStr );
	my $lastIndex       = pop @indexList;
	$lastIndex += $increase;
	push @indexList, $lastIndex;
	return join( '-', @indexList );
}

sub _create_circuit {
	my $Ckt = shift or return;
	my $actual_attribute_ref = shift;
	my $S_Node = new Tea::Objects::SN9K( Host => $Ckt->host() );
	my $SwitchIP = $S_Node->getObjects("System-1")->{'-SwitchIP'};
	my ( $Chassis, $Slot, $Port, $Channel ) =
	  split( "-", $Ckt->{SourceChannel} );
	my $D_Node = new Tea::Objects::SN9K( Host => $Ckt->{DestinationIP} );
	my $PeerSwitchIP = $D_Node->getObjects("System-1")->{'-SwitchIP'};
	my ( $PeerChassis, $PeerSlot, $PeerPort, $PeerChannel ) =
	  split( "-", $Ckt->{DestinationChannel} );

	# circuit templete with default value
	my $CKTObjName  = "Circuit-$SwitchIP-$Chassis-$Slot-$Port-$Channel";
	my $confirm     = '&Confirm';
	my %new_circuit = (
		Name                  => "$CKTObjName",
		-CircuitName          => "$CKTObjName",
		-CircuitSourceIp      => "$SwitchIP",
		-CircuitSourceChassis => "$Chassis",
		-CircuitSourceSlot    => "$Slot",
		-CircuitSourcePort    => "$Port",
		-CircuitSourceChannel => "$Channel",

		-CircuitDestinationIp      => "$PeerSwitchIP",
		-CircuitDestinationChassis => "$PeerChassis",
		-CircuitDestinationSlot    => "$PeerSlot",
		-CircuitDestinationPort    => "$PeerPort",
		-CircuitDestinationChannel => "$PeerChannel",

		-CircuitServiceType      => "1",
		-CircuitBandwidthForward => $Ckt->{Size},
		-CircuitBandwidthReverse => $Ckt->{Size},
		-CircuitLinkTransparency => "circuitSonetPath",
		$confirm                 => "Yes",

		-CircuitProtection                    => "circuitNoProtection",
		-CircuitPathProtectionDirectionalMode => "pathProtectionBidirectional",
		-CircuitTrunkRestoration              => "circuitTrunkRestDisabled",
		-CircuitIppmControl                   => "ippmNone",
		-CircuitPathAlarmControl              => "parNone",
		-CircuitPathAlarmReporting            => "0",
		-CircuitSourceRerouted                => "circuitSourceReroutedEnabled",
		-CircuitRouteMode                     => "circuitAutoMode",

		-CircuitProtectSourceRerouted => "circuitProtectSourceReroutedUnknown",
		-CircuitProtectRouteMode      => "circuitProtectRouteUnknownMode",
		-CircuitReversion             => "circuitReversionDisabled",
		-CircuitConcatenation         => "circuitFixedConcat",
	);
	$new_circuit{"-CircuitServiceType"} = $Ckt->{CircuitServiceType}
	  if defined( $Ckt->{CircuitServiceType} );
	$new_circuit{"-CircuitConcatenation"} = $Ckt->{CircuitConcatenation}
	  if defined( $Ckt->{CircuitConcatenation} );
	$new_circuit{"-CircuitVpnId"} = $Ckt->{CircuitVpnId}
	  if defined( $Ckt->{CircuitVpnId} );
	$new_circuit{"-CircuitProtection"} = $Ckt->{CircuitProtection}
	  if defined( $Ckt->{CircuitProtection} );
	$new_circuit{"-CircuitPathProtectionDirectionalMode"} =
	  $Ckt->{CircuitPathProtectionDirectionalMode}
	  if defined( $Ckt->{CircuitPathProtectionDirectionalMode} );
	$new_circuit{"-CircuitTrunkRestoration"} = $Ckt->{CircuitTrunkRestoration}
	  if defined( $Ckt->{CircuitTrunkRestoration} );

	$new_circuit{"-CircuitReversion"} = $Ckt->{CircuitReversion}
	  if defined( $Ckt->{CircuitReversion} );
	$new_circuit{"-CircuitAutomaticReversionDelayTimer"} =
	  $Ckt->{CircuitAutomaticReversionDelayTimer}
	  if defined( $Ckt->{CircuitAutomaticReversionDelayTimer} );
	$new_circuit{"-CircuitAutomaticReversionScheduledDay"} =
	  $Ckt->{CircuitAutomaticReversionScheduledDay}
	  if defined( $Ckt->{CircuitAutomaticReversionScheduledDay} );
	$new_circuit{"-CircuitAutomaticReversionScheduledHour"} =
	  $Ckt->{CircuitAutomaticReversionScheduledHour}
	  if defined( $Ckt->{CircuitAutomaticReversionScheduledHour} );
	$new_circuit{"-CircuitAutomaticReversionScheduledMinute"} =
	  $Ckt->{CircuitAutomaticReversionScheduledMinute}
	  if defined( $Ckt->{CircuitAutomaticReversionScheduledMinute} );
	$new_circuit{"-CircuitManualReversionScheduledTimer"} =
	  $Ckt->{CircuitManualReversionScheduledTimer}
	  if defined( $Ckt->{CircuitManualReversionScheduledTimer} );

	$new_circuit{"-CircuitIppmControl"} = $Ckt->{CircuitIppmControl}
	  if defined( $Ckt->{CircuitIppmControl} );
	$new_circuit{"-CircuitPathAlarmControl"} = $Ckt->{CircuitPathAlarmControl}
	  if defined( $Ckt->{CircuitPathAlarmControl} );
	$new_circuit{"-CircuitPathAlarmReporting"} =
	  $Ckt->{CircuitPathAlarmReporting}
	  if defined( $Ckt->{CircuitPathAlarmReporting} );

	$new_circuit{"-CircuitSourceRerouted"} = $Ckt->{CircuitSourceRerouted}
	  if defined( $Ckt->{CircuitSourceRerouted} );
	if ( defined( $Ckt->{CircuitRouteMode} ) ) {
		$new_circuit{"-CircuitRouteMode"}     = $Ckt->{CircuitRouteMode};
		$new_circuit{"-CircuitStitchedRoute"} = $Ckt->{CircuitStitchedRoute}
		  if ( $new_circuit{"-CircuitRouteMode"} eq "circuitStitchedMode" );
	}

	if ( defined( $Ckt->{ProtectDestinationIP} ) ) {
		my $D_Node =
		  new Tea::Objects::SN9K( Host => $Ckt->{ProtectDestinationIP} );
		$new_circuit{"-CircuitProtectDestinationIp"} =
		  $D_Node->getObjects("System-1")->{'-SwitchIP'};
	}

	if ( defined( $Ckt->{ProtectDestinationChannel} ) ) {
		my (
			$ProtectionChassis, $ProtectionSlot,
			$ProtectionPort,    $ProtectionChannel
		) = split( "-", $Ckt->{ProtectDestinationChannel} );
		$new_circuit{"-CircuitProtectDestinationChassis"} = $ProtectionChassis;
		$new_circuit{"-CircuitProtectDestinationSlot"}    = $ProtectionSlot;
		$new_circuit{"-CircuitProtectDestinationPort"}    = $ProtectionPort;
		$new_circuit{"-CircuitProtectDestinationChannel"} = $ProtectionChannel;
	}
	$new_circuit{"-CircuitProtectSourceRerouted"} =
	  $Ckt->{CircuitProtectSourceRerouted}
	  if defined( $Ckt->{CircuitProtectSourceRerouted} );
	$new_circuit{"-CircuitProtectRouteMode"} =
		  $Ckt->{CircuitProtectRouteMode} 
		  if ( defined( $Ckt->{CircuitProtectRouteMode} ) );

	if (( $Ckt->{CircuitProtectRouteMode} eq "circuitProtectStitchedMode" ) 
		or ((($Ckt->{CircuitProtection} eq "circuitConduitIdDiverse") or ($Ckt->{CircuitProtection} eq "circuitDiverselyRouted"))
			and ($Ckt->{CircuitRouteMode} eq "circuitStitchedMode"))) {
		$new_circuit{"-CircuitProtectStitchedRoute"} = $Ckt->{CircuitProtectStitchedRoute};
	}

#in NMS Functional Specification for Open Jaw Circuit Support
#4.7	General Constraints
#If a path is local, the destination endpoint type of that path must be unprotected endpoint types.
#The corresponding Source Reroute, Route Mode and Defined Path must be hidden from user and the Source Reroute must set to OFF.
	if ( $new_circuit{"-CircuitProtection"} =~ /OpenJaw$/ ) {
		if ( $new_circuit{"-CircuitDestinationIp"} eq
			$new_circuit{"-CircuitSourceIp"} )
		{
			$new_circuit{"-CircuitSourceRerouted"} =
			  "circuitSourceReroutedDisabled";
		}
		if ( $new_circuit{"-CircuitProtectDestinationIp"} eq
			$new_circuit{"-CircuitSourceIp"} )
		{
			$new_circuit{"-CircuitProtectSourceRerouted"} =
			  "circuitProtectSourceReroutedDisabled";
		}
	}
	# if modify circuit
	if(defined $actual_attribute_ref) {
		foreach (keys %new_circuit) {
			# filter
			delete $new_circuit{$_} unless (/^-/);
			# exlude consist parameters
			delete $new_circuit{$_} if($new_circuit{$_} eq $actual_attribute_ref->{$_});
		}
		# block illegal modifications
		foreach (qw(CircuitSourceIp CircuitSourceChassis CircuitSourceSlot CircuitSourcePort CircuitSourceChannel 
					CircuitDestinationIp CircuitDestinationSlot CircuitDestinationPort CircuitDestinationChannel 
					CircuitServiceType CircuitBandwidthForward CircuitBandwidthReverse)) {
			return "$_ can't be modfied" if exists $new_circuit{"-$_"};
		}
		# CircuitConcatenation
		if($actual_attribute_ref->{'-CircuitServiceType'} ne '1') {
			return "CircuitConcatenation can't be modfied" if exists $new_circuit{'-CircuitConcatenation'};
		}
		# Protection Destination
		unless(($actual_attribute_ref->{'-CircuitProtection'} eq 'circuitNoProtection' and $new_circuit{'-CircuitProtection'} =~ /OpenJaw$/i)
			or ($actual_attribute_ref->{'-CircuitProtection'} =~ /OpenJaw$/i and $new_circuit{'-CircuitProtection'} eq 'circuitNoProtection')) {
			foreach (qw(CircuitProtectDestinationChassis CircuitProtectDestinationSlot CircuitProtectDestinationPort CircuitProtectDestinationChannel
						CircuitProtectSourceRerouted CircuitProtectRouteMode)) {
				return "$_ can't be modfied" if exists $new_circuit{"-$_"};
			}
		}
		# CircuitLinkTransparency (TBD)		
		# CircuitPathProtectionDirectionalMode (TBD)		
		# CircuitTrunkRestoration (TBD)		
		# CircuitSourceRerouted (TBD)		
		# CircuitRouteMode (TBD)		
		# CircuitReversion (TBD)
		# IPPM & PAR
		my %IPPM_PAR;
		foreach (qw(CircuitIppmControl CircuitPathAlarmControl CircuitPathAlarmReporting)) {
			$IPPM_PAR{"-$_"} = delete $new_circuit{"-$_"} if exists $new_circuit{"-$_"};
		}
		$Ckt->set(%new_circuit) if scalar(keys %new_circuit);
		$Ckt->set(%IPPM_PAR) if scalar(keys %IPPM_PAR);
	}else {	
		$Ckt->nm_name( $new_circuit{Name} );
		$Ckt->_obj_template( \%new_circuit, "no_filter" );
		my $create = $Ckt->create();
		return $create->{error} if ( $create->{error} );
	}
	return;
}


sub cfg_RingProtectionGroup {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;

	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	die "Only one CRG objects can be created at ".$self->current_position() if(scalar(@handleObjectName)>1);
	# mandatory parameters
	foreach (qw(Host RingID RingNodeId PeerEastNode EastEndPoint PeerWestNode WestEndPoint)) {
		die "\"$_\" should not be empty at ".$self->current_position() unless $content->{$_};
	}
	$self->get_NE_list($content->{'Host'});
	my $RPG = new Tea::Objects::RPG(
		Host       => $content->{'Host'},
		ObjectName => "RingProtectionGroup-" . $content->{'RingID'},
	);
	if ( not $onlyGet ) {
		$RPG->{RingID}   = $content->{'RingID'};
		$RPG->{RingArch} = $content->{'RingArch'}
		  if defined( $content->{'RingArch'} );
		$RPG->{RingMode} = $content->{'RingMode'}
		  if defined( $content->{'RingMode'} );
		$RPG->{Bandwidth} = $content->{'Bandwidth'}
		  if defined( $content->{'Bandwidth'} );
		$RPG->{RingNodeId} = $content->{'RingNodeId'};
		my $East_Node =
		  new Tea::Objects::SN9K( Host => $content->{'PeerEastNode'} );
		$RPG->{PeerEastIPAddress} =
		  $East_Node->getObjects("System-1")->{'-SwitchIP'};
		$RPG->{EastEndPoint}        = $content->{'EastEndPoint'};
		$RPG->{EastProtectEndPoint} = $content->{'EastProtectEndPoint'}
		  if defined( $content->{'EastProtectEndPoint'} );
		my $West_Node =
		  new Tea::Objects::SN9K( Host => $content->{'PeerWestNode'} );
		$RPG->{PeerWestIPAddress} =
		  $West_Node->getObjects("System-1")->{'-SwitchIP'};
		$RPG->{WestEndPoint}        = $content->{'WestEndPoint'};
		$RPG->{WestProtectEndPoint} = $content->{'WestProtectEndPoint'}
		  if defined( $content->{'WestProtectEndPoint'} );
		$RPG->{RingWTRTime} = $content->{'RingWTRTime'}
		  if defined( $content->{'RingWTRTime'} );
		$RPG->{SpanWTRTime} = $content->{'SpanWTRTime'}
		  if defined( $content->{'SpanWTRTime'} );
		$RPG->{AutoSquelchDiscovery} =
		  $content->{'AutoSquelchDiscovery'}
		  if defined( $content->{'AutoSquelchDiscovery'} );
		$RPG->{AutoRingDiscovery} = $content->{'AutoRingDiscovery'}
		  if defined( $content->{'AutoRingDiscovery'} );

		if ( my $errorCode = _create_rpg($RPG) ) {
			die $errorCode, " at ".$self->current_position();
		}
	}
	# mapping to object handle(s)
	my $parName;
	# given only one object name
	if(scalar(@handleObjectName) == 1) {
		$parName = $handleObjectName[0];
		no strict 'refs';	
		${"main::$parName"} = $RPG;			
		push @{ $self->{"HandleObjNames"} }, $parName;
	}	
	if ( exists $self->{'CreatedObjs'} ) {
		push @{ $self->{'CreatedObjs'} }, $RPG;
	}
	else {
		my @tmp = ($RPG);
		$self->{'CreatedObjs'} = \@tmp;
	}
}

sub _create_rpg {
	my $RPG = shift or return;
	my %rpg_template = (
		Name                   => $RPG->nm_name(),
		-Name                  => $RPG->nm_name(),
		-RingID                => $RPG->{RingID},
		-RingArch              => "ring_2f",
		-RingMode              => "BLSR",
		-Bandwidth             => "48",
		-RingNodeId            => $RPG->{RingNodeId},
		-PeerEastIPAddress     => $RPG->{PeerEastIPAddress},
		-EastEndPoint          => $RPG->{EastEndPoint},
		-EastProtectEndPoint   => "0-0-0",
		-PeerWestIPAddress     => $RPG->{PeerWestIPAddress},
		-WestEndPoint          => $RPG->{WestEndPoint},
		-WestProtectEndPoint   => "0-0-0",
		-RingWTRTime           => "5",
		-SpanWTRTime           => "5",
		-AutoEastPeerDiscovery => "false",
		-AutoWestPeerDiscovery => "false",
		-AutoRingDiscovery     => "false",
		-AutoSquelchDiscovery  => "false",
	);
	$rpg_template{'-RingArch'} = $RPG->{RingArch}
	  if defined( $RPG->{RingArch} );
	$rpg_template{'-RingMode'} = $RPG->{RingMode}
	  if defined( $RPG->{RingMode} );
	$rpg_template{'-Bandwidth'} = $RPG->{Bandwidth}
	  if defined( $RPG->{Bandwidth} );
	$rpg_template{'-EastProtectEndPoint'} = $RPG->{EastProtectEndPoint}
	  if defined( $RPG->{EastProtectEndPoint} );
	$rpg_template{'-WestProtectEndPoint'} = $RPG->{WestProtectEndPoint}
	  if defined( $RPG->{WestProtectEndPoint} );
	$rpg_template{'-RingWTRTime'} = $RPG->{RingWTRTime}
	  if defined( $RPG->{RingWTRTime} );
	$rpg_template{'-SpanWTRTime'} = $RPG->{SpanWTRTime}
	  if defined( $RPG->{SpanWTRTime} );
	$rpg_template{'-AutoSquelchDiscovery'} = $RPG->{AutoSquelchDiscovery}
	  if defined( $RPG->{AutoSquelchDiscovery} );
	$rpg_template{'-AutoRingDiscovery'} = $RPG->{AutoRingDiscovery}
	  if defined( $RPG->{AutoRingDiscovery} );

	$RPG->_obj_template( \%rpg_template, "no_filter" );
	my $create = $RPG->create();
	return $create->{error} if ( $create->{error} );
	sleep $RPGCreateTime;
	return;
}


sub cfg_ConcatenationGroup {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;

	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	die "At most two CG objects can be created at ".$self->current_position() if(scalar(@handleObjectName)>2);
	# mandatory parameters
	foreach (qw(LocalNodeIpAddress LocalIndex LocalCGId)) {
		die "\"$_\" should not be empty at ".$self->current_position() unless $content->{$_};
	}	
	
	# support create sigle-side CG
	my $doubleSides;
	if($content->{'RemoteNodeIpAddress'} and $content->{'RemoteIndex'}) {
		$doubleSides = 1;
	}elsif($content->{'RemoteNodeIpAddress'} and $content->{'RemoteIndex'}) {
		die "Incorrect info on RemoteNode side at ".$self->current_position();
	}else{
		$doubleSides = 0;
		die "Only one CG object name can be given for one-side CG at ".$self->current_position() if(scalar(@handleObjectName)==2);
	}
	
	$self->get_NE_list($content->{'LocalNodeIpAddress'});
	my ($CG_1, $CG_2);
	$CG_1 = new Tea::Objects::ConcatenationGroup(
		Host  => $content->{'LocalNodeIpAddress'},
		Index => $content->{"LocalIndex"}.'-1-'.$content->{'LocalCGId'},
	);
	if($doubleSides) {
		$self->get_NE_list($content->{'RemoteNodeIpAddress'});
		$CG_2 = new Tea::Objects::ConcatenationGroup(
			Host  => $content->{"RemoteNodeIpAddress"},
			Index => $content->{"RemoteIndex"}.'-1-'.$content->{'RemoteCGId'},
		);
	}

	if ( not $onlyGet ) {
		my $localHost = new Tea::Objects::SN9K( Host => $content->{"LocalNodeIpAddress"} );
		my $localSwitchIP = $localHost->getObjects("System-1")->{'-SwitchIP'};	
		$CG_1->{LocalNodeIpAddress} = $localSwitchIP;
		($CG_1->{LocalChassis}, $CG_1->{LocalSlot}) = split('-', $content->{"LocalIndex"});
		$CG_1->{LocalCGId} = $content->{'LocalCGId'};
				
		$CG_1->{LCAS}  = $content->{"LCAS"} if defined( $content->{"LCAS"} );
		$CG_1->{GFP_F_PFI} = $content->{"GFP_F_PFI"} if defined( $content->{"GFP_F_PFI"} );
		$CG_1->{Granularity} = $content->{"Granularity"} if defined( $content->{"Granularity"} );
		
		if($doubleSides) {
			my $remoteHost = new Tea::Objects::SN9K( Host => $content->{"RemoteNodeIpAddress"} );
			my $remoteSwitchIP = $remoteHost->getObjects("System-1")->{'-SwitchIP'};	
			
			$CG_2->{LocalNodeIpAddress} = $CG_1->{RemoteNodeIpAddress} = $remoteSwitchIP;
			($CG_2->{LocalChassis}, $CG_2->{LocalSlot}) = ($CG_1->{RemoteChassis}, $CG_1->{RemoteSlot}) = split('-', $content->{"RemoteIndex"});
			$CG_2->{LocalCGId} = $CG_1->{RemoteCGId} = $content->{'RemoteCGId'};
			
			$CG_2->{RemoteNodeIpAddress} = $CG_1->{LocalNodeIpAddress}; 
			($CG_2->{RemoteChassis}, $CG_2->{RemoteSlot}) = ($CG_1->{LocalChassis}, $CG_1->{LocalSlot});
			$CG_2->{RemoteCGId} = $CG_1->{LocalCGId};
			
			$CG_2->{LCAS} = $CG_1->{LCAS};
			$CG_2->{GFP_F_PFI} = $CG_1->{GFP_F_PFI};
			$CG_2->{Granularity} = $CG_1->{Granularity};
		}
		if(defined( $content->{"ProvisionedConstituents"} ) and $content->{"ProvisionedConstituents"}) {
			my @constituents = split(/[\s,]/, $content->{"ProvisionedConstituents"});
			my @final;
			foreach (@constituents) {
				if(/-/) {
					my ($start, $end) = split(/-/, $_);
					for(my $i=$start; $i<=$end; $i++) {
						push @final, $i;
					}
				}else{
					push @final, $_;
				}
			}
			$CG_1->{ProvisionedConstituents} = $CG_2->{ProvisionedConstituents} =  join(',', @final) ;
		}
		my $errorCode;
		if ( $errorCode = _create_cg($CG_1))
		{
			die $errorCode, " at ".$self->current_position();
		}
		if ( $doubleSides and ($errorCode = _create_cg($CG_2)))
		{
			die $errorCode, " at ".$self->current_position();
		}		
	}
	if ( exists $self->{"CreatedObjs"} ) {
		push @{ $self->{"CreatedObjs"} }, $CG_1;
		push @{ $self->{"CreatedObjs"} }, $CG_2 if $doubleSides;
	}
	else {
		my @tmp = ( $CG_1);
		push @tmp, $CG_2 if $doubleSides;
		$self->{"CreatedObjs"} = \@tmp;
	}
	# mapping to object handle(s)
	my $parName;
	# given only one object name
	if(scalar(@handleObjectName) == 1) {
		if($doubleSides) {
			$parName = $handleObjectName[0]."_1"; 
			no strict 'refs';	
			${"main::$parName"} = $CG_1;
			push @{ $self->{"HandleObjNames"} }, $parName;
			$parName = $handleObjectName[0]."_2"; 
			no strict 'refs';	
			${"main::$parName"} = $CG_2;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}else{
			$parName = $handleObjectName[0];
			no strict 'refs';	
			${"main::$parName"} = $CG_1;	
			push @{ $self->{"HandleObjNames"} }, $parName;			
		}
	}else{
		$parName = $handleObjectName[0];
		no strict 'refs';	
		${"main::$parName"} = $CG_1;
		push @{ $self->{"HandleObjNames"} }, $parName;
		$parName = $handleObjectName[1];
		no strict 'refs';	
		${"main::$parName"} = $CG_2;
		push @{ $self->{"HandleObjNames"} }, $parName;		
	}		
}

sub _create_cg {
	my $CG = shift or return;
	my %cg_template = (
		Name                     => $CG->nm_name(),
		-LocalNodeIpAddress  	=> $CG->{LocalNodeIpAddress},
		-LocalChassis  			=> $CG->{LocalChassis},
		-LocalSlot 				=> $CG->{LocalSlot},
		-LocalCGId         		=> $CG->{LocalCGId},
		-LCAS           		=> $CG->{LCAS},
		-GFP_F_PFI         		=> $CG->{GFP_F_PFI},
		-Granularity 			=> $CG->{Granularity},
	);
	$cg_template{'-RemoteNodeIpAddress'} = $CG->{RemoteNodeIpAddress} if defined( $CG->{RemoteNodeIpAddress} );
	$cg_template{'-RemoteChassis'} = $CG->{RemoteChassis} if defined( $CG->{RemoteChassis} );
	$cg_template{'-RemoteSlot'} = $CG->{RemoteSlot} if defined( $CG->{RemoteSlot} );
	$cg_template{'-RemoteCGId'} = $CG->{RemoteCGId} if defined( $CG->{RemoteCGId} );
	$cg_template{'-ProvisionedConstituents'} = $CG->{ProvisionedConstituents} if defined( $CG->{ProvisionedConstituents} );

	$CG->_obj_template( \%cg_template );

	my $create = $CG->create();
	return $create->{error} if ( $create->{error} );
	sleep $CGCreateTime;
	return;
}



sub cfg_EthernetService {
	my $self         = shift;
	my $content = shift;
	my $onlyGet      = shift;

	my @handleObjectName;
	@handleObjectName = split(/[\s,]/, $content->{'colTittle'}) if(defined $content->{'colTittle'} and $content->{'colTittle'});
	my $objectNum = (defined($content->{'Num'}) and $content->{'Num'} ne '') ? $content->{'Num'} : 1;
	if(scalar(@handleObjectName)>1 and scalar(@handleObjectName) != $objectNum) {
		die "Object names are not consist with the number at ".$self->current_position();
	}	
	# mandatory parameters
	foreach (qw(LocalNodeIpAddress LocalIndex LocalCGId)) {
		die "\"$_\" should not be empty at ".$self->current_position() unless $content->{$_};
	}
	$self->get_NE_list($content->{'LocalNodeIpAddress'});
	for(my $i=0; $i<$objectNum; $i++) {
		my $EthernetService = new Tea::Objects::EthernetService(
			Host  => $content->{'LocalNodeIpAddress'},
			Index => _index_increase($content->{'LocalIndex'}, $i).'-1',
		);
		if ( not $onlyGet ) {
			my $Host = new Tea::Objects::SN9K( Host => $content->{"LocalNodeIpAddress"} );
			my $SwitchIP = $Host->getObjects("System-1")->{'-SwitchIP'};			
			$EthernetService->{LocalNodeIpAddress}           = $SwitchIP;
			($EthernetService->{LocalChassis}, $EthernetService->{LocalSlot}, $EthernetService->{LocalPort}) 
			= split('-', $content->{"LocalIndex"});
			$EthernetService->{LocalCGId}           = $content->{"LocalCGId"};
			$EthernetService->{CLFNotification}           = $content->{"CLFNotification"};
			$EthernetService->{CLFNotificationSoakInterval}           = $content->{"CLFNotificationSoakInterval"};
			$EthernetService->{CGFNotification}           = $content->{"CGFNotification"};
			$EthernetService->{CGFNotificationThreshold}           = $content->{"CGFNotificationThreshold"};
			$EthernetService->{CGFNotificationSoakInterval}           = $content->{"CGFNotificationSoakInterval"};
			if ( my $errorCode = _create_esvc($EthernetService) ) {
				die $errorCode;
			}
		}
		if ( exists $self->{"CreatedObjs"} ) {
			push @{ $self->{"CreatedObjs"} }, $EthernetService;
		}
		else {
			my @tmp = ($EthernetService);
			$self->{"CreatedObjs"} = \@tmp;
		}
		# mapping to object handle(s)
		my $parName;
		# given only one object name
		if(scalar(@handleObjectName) == 1) {
			if($i == 0) { # by default, pointing to the first object
				$parName = $handleObjectName[0];
				no strict 'refs';	
				${"main::$parName"} = $EthernetService;	
				push @{ $self->{"HandleObjNames"} }, $parName;				
			}
			# expand the object name for multi-objects
			if($objectNum > 1) {
				$parName = $handleObjectName[0]."_".($i+1); 
				no strict 'refs';	
				${"main::$parName"} = $EthernetService;
				push @{ $self->{"HandleObjNames"} }, $parName;
			}
		}else{
			$parName = $handleObjectName[$i];
			no strict 'refs';	
			${"main::$parName"} = $EthernetService;
			push @{ $self->{"HandleObjNames"} }, $parName;
		}	
	}			
}

sub _create_esvc {
	my $ESVC = shift or return;
	my %esvc_template = (
		Name                     => $ESVC->nm_name(),
		-LocalNodeIpAddress  	=> $ESVC->{LocalNodeIpAddress},
		-LocalChassis  			=> $ESVC->{LocalChassis},
		-LocalSlot 				=> $ESVC->{LocalSlot},
		-LocalPort         		=> $ESVC->{LocalPort},
		-FlowId					=> '1',
		-LocalCGId         		=> $ESVC->{LocalCGId},
		-CLFNotification    => $ESVC->{CLFNotification},
		-CLFNotificationSoakInterval          => $ESVC->{CLFNotificationSoakInterval},
		-CGFNotification          	=> $ESVC->{CGFNotification},
		-CGFNotificationThreshold             => $ESVC->{CGFNotificationThreshold},
		-CGFNotificationSoakInterval           		=> $ESVC->{CGFNotificationSoakInterval},
	);

	$ESVC->_obj_template( \%esvc_template );

	my $create = $ESVC->create();
	return $create->{error} if ( $create->{error} );
	sleep $ESVCCreateTime;
	return;
}

1;
