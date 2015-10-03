package Pet::Tea::Parser;

use base qw(Exporter Pet::Tea::Base);

use strict;

## This module is the parser for Tea, it
## parses the input and config files. It
## is intended for use only by Tea classes
## for more information perldoc Tea 
##

## This method takes the filename and path
## of a Tea input file and returns a reference
## to the parsed data

sub input_file {

   my ($self,$file) = @_;

   open(FILE,$file) or return $self->error("$file: $!");
   my @lines = <FILE>;
   close(FILE);

   ## need to do some special cleaning of input file
   ## that where generated with ms xl

   foreach(@lines) { chomp; s/\r$//; s/\t$//; s/^"//; s/"$//; }

   my (@procs,%test,$test_start);
   my @currentStepArr;

   for(my $i=0;$i<scalar(@lines);$i++) {
   		my $currentLine = $lines[$i];
   		
   		next if $currentLine =~ /^\s+?$/;
#   		next if $currentLine =~ /^#/;

		if ($currentLine =~ /^#/){
			if ($i==(scalar(@lines)-1)){
				next if (!$test_start); 
				if (@currentStepArr){
	   				my @inArr = @currentStepArr;
	   				push @procs, \@inArr;
	   				my @emptyArr;
	   				@currentStepArr = @emptyArr;
				}
   			}
			next;
		}
   		
   		
   		if ($currentLine =~ /test_start/i){
   			$test_start = 1;
   		}
   		elsif (!$test_start){
			my($key,@rest)=split(/\s/,$currentLine);
			my $desc = join (' ',@rest);
			$test{lc $key} = $desc;
   		}
   		else{
   			if ($currentLine){			
	   			push @currentStepArr, $currentLine;
   			}
   		}
   		
   		if ( !$currentLine || $i==(scalar(@lines)-1)){
   			next if (!$test_start); 
   			if (@currentStepArr){
   				my @inArr = @currentStepArr;
   				push @procs, \@inArr;
   				my @emptyArr;
   				@currentStepArr = @emptyArr;
   			}
   		}
#
#      local $_ = $lines[$i];
#      
#      my $currentLine = $lines[$i];
#
#      ## ignore blank lines and comments
#      next if !$_ || /^\s+?$/ || /^#/;
#
#      s/#.+$//; next if !$_; 
#
#      if(/test_start/i) {
#
#         ## we have reached the test start
#         $test_start = 1;
#
#      } elsif(!$test_start) {
#
#         ## must be a test parameter
#         ## like Name, Purpose, etc
#         ## store it in the hash
#         my($key,@rest)=split(/\s/);
#         my $desc = join (' ',@rest);
#         $test{lc $key} = $desc;
#
#      } elsif(scalar(split(/\t/)) == 1) {
#
#          ## if our procs are running down instead
#          ## of across handle it one step per line
#          ## until reach a blank or >1 step per line
#          my @steps;
#
#          while(scalar(split(/\t/,$lines[$i])) == 1) {
#              my ($step,undef) = split(/\t/,$lines[$i]);
#              push @steps, $step if $step !~ /#/;
#              $i++; last if ! $lines[$i];
#
#              last if $i > scalar(@lines);
#          }
#
#          push @procs, \@steps;
#    
#      } else {
#
#        ## a proc running across, add to the proc list 
#        
#        ##mod Jun.12 2009 by cn , requirement by Leilei, do not need split \t in one line
#
##        my(@steps) = split(/\t/);
##        push @procs, \@steps;
#		my @stepArr;
#		push @stepArr, $_;
#		push @procs, \@stepArr;
#
#      }
   
   
   
   }

   $test{PROCS} = \@procs;
   return \%test;

}

## This method takes the filename and path
## of a Tea config file and returns a reference
## to the parsed data

sub config_file {

   my ($self,$file) = @_;

   open(FILE,$file) or return $self->error("$file: $!");
   my @lines = <FILE>;
   close(FILE);

   my($config_start,%hash,%macro_map,@config_map,%config_template);

   foreach(@lines) { chomp; s/\r$//; s/\s+?$//; s/^"//; s/"$//; }

   ## the beggining of a config file defines the config
   ## macros, read all config variables (if any) until
   ## we get to the config_map

   for(my $i=0;$lines[$i]!~/config_map/i&&$i<@lines;$i++) {

      $config_start = $i;
      local $_ = $lines[$i];
      
      ## ignore blanks and comments

      next if !$_ || /^\s+$/ || /^#/;

      my($name,$val) = /^(.+?)\s+?(.+?)$/; 
      $macro_map{$name} = $val;

   }

   ## we have reached the config map, now each
   ## config_map line will be tab delim name=value pairs
   ## create a hash for each line of the config map
   ## and create a list of config_map elements
   
   ##added by cn at Jun23, 2009 to support ifdef and endif
   my $needExcuted=1;

   for(my $i=$config_start+2;($lines[$i]!~/config_template$/i&&$i<@lines);$i++) {
   	##added by cn at Jun23, 2009 to support ifdef and endif
   	$config_start = $i;
   	my $currentLine = $lines[$i];
   	chomp $currentLine;
   	next if !$currentLine || ($currentLine =~ /^#/)|| ($currentLine =~ /^\s+?$/);
   	if ($currentLine =~ /ifdef/i){
   		$needExcuted = 0;
   		next;
   	}
   	elsif ($currentLine =~ /endif/i){
   		$needExcuted = 1;
   		next;
   	}
   	my @eList = split(/\t/,$currentLine);
   	my %config_single;

	for my $eItem (@eList){
		next if !$eItem;	
		$eItem =~ s/^\s+//; #left trim
		$eItem =~ s/\s+$//; #right trim
		my($attr,$value) = split(/=/,$eItem,2);
		$config_single{$attr} = $value;
	}
	if ($needExcuted == 0){
		$config_single{'TYPE'} = 'Tea::Extensions';
		$config_single{'NOTEXECUTE'} = 'yes';
	}
	else {
#		$config_single{'NEEDEXECUTED'} = 'yes';
	}

	push @config_map, \%config_single;
   	
#      $config_start = $i;
#      local $_ = $lines[$i]; chomp;
#      next if !$_ || /^#/ || /^\s+?$/;
#
#      my(@e) = split(/\t/);
#
#      my %config_line;
#
#      for my $element (@e) {
#
#          next if ! $element;
#          $element =~ s/^\s+//; #left trim
#          $element =~ s/\s+$//; #right trim
#          my($attr,$value) = split(/=/,$element,2);
#          $config_line{$attr} = $value
#
#      }
# 
#      push @config_map, \%config_line;

   }

   ## now read in the config template, if it exists

   for(my $i=$config_start+2;$i<@lines;$i++) {
	if($lines[$i]!~/^template/i){
	}else{
		local $_ = $lines[$i]; chomp;
      next if !$_ || /^#/ || /^\s+?$/;

      my(%template,$label);
      my(@e) = split(/\t/,$_);

      $label = shift @e;
      $label =~ /^TEMPLATE=(.+?)$/i;
      $label = $1;
      for(my $j=0;$j<@e;$j+=2) {
      	 $template{$e[$j]} = $e[$j+1]; 
      }

      $config_template{$label} = \%template;

   }
	}
      

   $hash{CONFIG_TEMPLATE} = \%config_template;
   $hash{MACRO_MAP} = \%macro_map;
   $hash{CONFIG_MAP} = \@config_map;

   return \%hash;

}

######################################################################
## config_template_subs():  replace template names referenced in
##                          the config map entries with template data

sub config_template_subs {

   my($self,$templates,$config_map) = @_;

   for my $entry (@$config_map) {
      for my $arg (keys %$entry) {
         if($arg =~ /^template$/i) {
            if(exists $templates->{$entry->{$arg}}) {
               $entry->{$arg} = $templates->{$entry->{$arg}};
            } else {
               return $self->error('no config template defined: '.$entry->{$arg});
            }
         }
      }
   }

   return;

}

######################################################################
## config_template_exp(): expand macros in the config template

sub config_template_exp {

   my($self,$macros,$templates) = @_;

   for my $entry (keys %$templates) {
      for my $attr (keys %{$templates->{$entry}}) {
         for my $macro (keys %$macros) {
            my $mval = $macros->{$macro};
            $templates->{$entry}->{$attr} =~ s/$macro/$mval/g;
         }
      }
   }
   for my $entry (keys %$templates) {
      for my $attr (keys %{$templates->{$entry}}) {
      }
   }

   return;

}

######################################################################
## config_macro_exp(): expand macros in the config map

sub config_macro_exp {

   my($self,$macros,$config_map) = @_;
   
   ##parse macro on macros
   ##mod by cn May.6 2009 
   ##requirement by Fang, Shuai
   for my $marco_item_key (keys %$macros){
   		my $marco_item_value = $macros->{$marco_item_key};
   		for my $macro_key (keys %$macros){
   			$marco_item_value =~ s/$macro_key/$macros->{$macro_key}/g;
   		} 
   		$macros->{$marco_item_key} = $marco_item_value;
   }
   ##parse end

   for my $entry (@$config_map) {
      for my $attr (keys %$entry) {
         for my $macro (keys %$macros) {
            my $mval = $macros->{$macro};
            $entry->{$attr} =~ s/$macro/$mval/g;
         }
      }
   }

   return;

}

######################################################################
## input_macro_exp(): expand macros in the input file

sub input_macro_exp {

   my($self,$macros,$test_data) = @_;

   my $input = delete $test_data->{PROCS};
 
   for(my $i=0;$i<@$input;$i++) {
      for(my $j=0;$j<@{$input->[$i]};$j++) {
         for my $macro (keys %$macros) {
            my $mval = $macros->{$macro};
            $input->[$i]->[$j] =~ s/$macro/$mval/g;
         }
      }
   }

   for my $header (keys %$test_data) {
      for my $macro (keys %$macros) {
         my $mval = $macros->{$macro};
         $test_data->{$header} =~ s/$macro/$mval/g;
      }
   }

   $test_data->{PROCS} = $input;

   return;

}

1;

