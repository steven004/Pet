package Pet::Tea::Runtime;

use base qw(Exporter Pet::Tea::Base);

use vars qw($CURRENT_TC_STEP);
use strict;



## The invoke method runs all the procedures in the procedure list.
## It returns 1 on success undef on failure, error msg is available
## via the errmsg() object method

sub invoke {

   my $self = shift;

   ## is everything set ?

   if( ! $self->testcase() ) {
      return $self->error('The testcase module has not been set!');
   } elsif( ! $self->symbols() ) {
      return $self->error('The test configuration has not been set!');
   } elsif( ! $self->proc_list() ) {
      return $self->error('The procedure list has not been set!');
   }

   ## initializes breakpoint conditions/handlers

   $self->init_breakpoints($self->symbols()->table());

   ## grab the procedure list and go!

   my $proc_list = $self->proc_list();

   for my $proc (@$proc_list) {
      $self->do_proc($proc);
   } 

   1;

}

## The do_proc method executes all steps in a procedure,
## it takes an arrayref containing each step and hopefully
## a description then returns undef

sub do_proc {

   my($self,$proc) = @_;

   my($testcase,$desc,$tc_step,$in_step);

   ## get the testcase object, and a description of this step

   $testcase = $self->testcase();
   $desc = _get_proc_desc($proc);

   if (exists $Tea::Objects::Base::TEMP_STACKS{read_attr}) {
      delete $Tea::Objects::Base::TEMP_STACKS{read_attr};
   }

   ## begin a new testcase step unless one is already open

   if($tc_step = $self->current_tc_step()) {
      $in_step = 1; ## we are a recursive call of do_proc
   } else {
      $tc_step = $testcase->step(Description => $desc);
      $self->current_tc_step($tc_step);  ## set a ref to the current tc step
   }

   ## execute every step in this procedure

   for (my $i=0;$i<@$proc;$i++) {

      next if !$proc->[$i];
      my(@conditional_steps);

      ## if we come across a group of steps that use if/then logic
      ## read all of them and then execute them all together

      while($proc->[$i] =~ /^(IF|THEN|ELSE?)/) {
         push @conditional_steps, $proc->[$i++];
      }

      if(@conditional_steps > 0) { ## conditional steps to execute

         $i--;  ## come back one so we dont skip the next non-conditional step
         $self->do_conditional_steps(\@conditional_steps,$tc_step);

      } else { ## single step to execute

#         $self->do_step($proc->[$i],$tc_step);

	################################################################################
	##support multi format like SYMBOL=NodeSet1 TYPE::SpecialMultiObjects SUBSYMBOLS=Node1,Node2,Node3...
	##Mar30,2009 by Nan Chen
		$self->do_multi_steps($proc->[$i],$tc_step);

      }

   }

   ## end the step if we are instance that created it

   if($tc_step && ! $in_step) {
       $tc_step->end() if ($tc_step && ! $in_step);
       $self->current_tc_step(0);
   }

   return;

}

## The do_step method executes and logs the result
## for a single step.  It takes a step in text form and
## a reference to the testcase module step.  It will skip the
## step if any script error is encountered. It returns status 1/0.

sub do_step {

   my($self,$step,$tc_step,$conditional) = @_;
   my($master_result);

   ## if its an info record it right away, or if its
   ## an end, stop the test

   if($step =~ /test::info::(.+?)$/i) {
      $tc_step->info($1);
      if (exists $Tea::Objects::Base::TEMP_STACKS{read_attr}) {
          delete $Tea::Objects::Base::TEMP_STACKS{read_attr};
      }
      return 1;
   } elsif($step =~ /test::end$/i) {
      $tc_step->end();
      $self->testcase()->end();
      exit(1);
   }

   ## try to execute the step, handle multiple results if present

   for my $r (@{$self->execute_step($step)}) {
   	
#   for my $r (@{$self->execute_multi_step($step)}) {

      ## if multiple results are returned, the first is the master
      ## that represents pass/fail for the multiple results

      $master_result = $r if not defined $master_result;

      if($conditional) { ## log as conditional step if flag set
         my $msg = "CONDITIONAL STEP ($conditional): ";
         if(!$r) { $msg .= $self->errmsg(); }
         else { 
            $msg .= $r->{desc}; 
            $msg .=  ', ' . $r->{msg} if $r->{msg};
         }
         $tc_step->info($msg); print "\n$msg\n" if ! $tc_step;
      } elsif(!$r) { ## log error and skip if that failed
         my $msg = "*** Skipping Step: " . $self->errmsg();
         $tc_step->warning($msg) if $tc_step;
         print "\n$msg\n" if ! $tc_step;
      } elsif($r->{info}) {
         ## an info message
         $tc_step->info($r->{info});
      } else {
         ## otherwise form the pass/fail msg 
         my $msg = $r->{desc}; 
         $msg .= ', ' . $r->{msg} if $r->{msg};
         ## check and log the result
         $tc_step->check($r->{pass} == 1,$msg,$msg) if $tc_step;
      }

      if( my $bp_list = $self->at_breakpoint($step,$r) ) {
          for my $action (@$bp_list) {
             $self->do_step($action,$tc_step);
          }
      }

   }

   sleep 1; ## a small delay

   return $master_result ? $master_result->{pass} : 0;

}

## The execute_step method executes and returns the result 
## for a single step.  It takes a step in text form. It will
## abort the step if any script error is encountered.
##
## Example step string: test_port::get::AdminStatus=~up
##
## exepect the result of 'get adminstatus' of 'test_port' to match 'up'
##

################################################################################
##support multi format like SYMBOL=NodeSet1 TYPE::SpecialMultiObjects SUBSYMBOLS=Node1,Node2,Node3...
##Mar30,2009 by Nan Chen
sub do_multi_steps {
	my($self,$cmd,$tc_step,$conditional) = @_;	
#   my ($self,$cmd) = @_;   
      
   ##check if it is a symbolSet or not
   my $cmd_symbols = $self->symbols();
   my $table = $cmd_symbols->{_table};
   my @cmd_symbol = split ('::',$cmd);
   my $symbol_name = shift @cmd_symbol; 
   my $remine_cmd = join('::',@cmd_symbol);
        
   if ( $symbol_name=~/set/i ){
   	my $arrAddress = $table->{lc $symbol_name};
   	my @symbolSet = @$arrAddress;
	  	
   	 for(my $j=0;$j<scalar(@symbolSet);$j++){   	 	 
   	 	my $newCmd = join('::',$symbolSet[$j],$remine_cmd);
#   	 	$self->execute_step($newCmd);
			$self->do_step($newCmd,$tc_step);
   	 }
   }
   else{
#   	  $self->execute_step($cmd);
		$self->do_step($cmd,$tc_step);
   }	
}
sub execute_step {

   my ($self,$cmd) = @_;

   my (@results,$step_data,$symbols,$response);

   ## break up elements of a step (symbol,method,args|operation,expectation)

   $step_data = _read_step($cmd);

   $symbols = $self->symbols(); ## get our symbol class ref 

   ## have the symbol class execute the symbol, trap the 
   ## error and return if one was raised 

   $response = $symbols->execute($step_data->{symbol});

   if(not defined $response) {
      $self->error($symbols->errmsg());
      push @results, undef;
   } elsif(exists $response->{multi_result}) {
      ## handle each result if there is more than one
      my $multi = delete $response->{multi_result};

      push @results, $self->interpet_step($response,$step_data);

      for my $r (@$multi) {
         my $sd = (exists $r->{step_data}) ? $r->{step_data} : $step_data;
         push @results, $self->interpet_step($r,$sd);
      }

   } else {

      push @results, $self->interpet_step($response,$step_data);

   }

   return \@results;

}

#########################################################################
## interpet_step(): determine pass/fail for each a result response

sub interpet_step {

   my($self,$response,$step_data) = @_;
   my(%result);

   ## get the description

   $result{desc} = $response->{desc};

   if( $response->{failed} ) {

       ## we had script failure, mark as skippped 

       $result{retval} = 0;
       $result{msg} = $response->{error};
       #$result{info} = '*** Skipping Step: '.$response->{error}.' ***';
       return \%result;

   } elsif($response->{info}) {

       ## this is an info message

       $result{pass} = 1;
       $result{info} = $response->{info};

   } elsif( $step_data->{op} eq 'bool' ) {

       ## expecting 1 for pass 0 for fail in retval
       ## figure out if it passed and the msg to return

       $result{pass} = $response->{retval} ? 1 : 0;    
       $result{msg} = $response->{retval} ? 'SUCCESS' : $response->{error};

       return \%result

   } else {
       
       ## we got a result back! now lets see if we expected it
       ## case fold the expected value and the actual value

       $step_data->{value} = lc $step_data->{value};
       my $retval = lc $response->{retval};
       #added by cn at July.09 2009, support detail message for every channel
       
       my $ontRetVal = $response->{retval};
       if (ref($ontRetVal) eq 'HASH'){
   		my %inhash = %$ontRetVal;
   		if (defined $inhash{'Ont512HitTimeDetails'}){
   			my $point_hitList = $inhash{'hitList'};
   			my @hitList = @$point_hitList;
   			my $hitItem;
   			my $notMatchMsg = "";
   			my $pass = 1;
   			my $op_desc = _get_op_desc($step_data->{op});
   			foreach $hitItem (@hitList){
   				my $hit_channel = $hitItem->{'channel'};
   				my $hit_duration = $hitItem->{'duration'};
   				print "Channel: $hit_channel, Duration: $hit_duration, criteria: $op_desc '$step_data->{value}'\n";
   				my $compare;
#   				if($step_data->{value} =~/[0-9]*[_a-zA-Z]+/){
#			       if($step_data->{op} eq '=='){
#			       	$compare = qq(q($hit_duration) eq q($step_data->{value})?1:0);
#			       }elsif($step_data->{op} eq '<='){
#			       		$compare = qq(q($hit_duration) le q($step_data->{value})?1:0);
#			       	}elsif($step_data->{op} eq '>='){
#			       		$compare = qq(q($hit_duration) ge q($step_data->{value})?1:0);
#			       	}elsif($step_data->{op} eq '!='){
#			       		$compare = qq(q($hit_duration) ne q($step_data->{value})?1:0);
#			       	}elsif($step_data->{op} eq '<=>'){
#			       		$compare = qq(q($hit_duration) cmp q($step_data->{value})?1:0);
#			       	}elsif($step_data->{op} eq '<'){
#			       		$compare = qq(q($hit_duration) lt q($step_data->{value})?1:0);
#			       	}elsif($step_data->{op} eq '>'){
#			       		$compare = qq(q($hit_duration) gt q($step_data->{value})?1:0);
#			       	}

					if($step_data->{op} eq '=='){
					$compare =(($hit_duration == $step_data->{value})?1:0);
			       }elsif($step_data->{op} eq '<='){
			       		$compare = (($hit_duration <= $step_data->{value})?1:0);
			       	}elsif($step_data->{op} eq '>='){
			       		$compare = (($hit_duration >= $step_data->{value})?1:0);
			       	}elsif($step_data->{op} eq '!='){
			       		$compare = (($hit_duration != $step_data->{value})?1:0);
			       	}elsif($step_data->{op} eq '<'){
			       		$compare = (($hit_duration < $step_data->{value})?1:0);
			       	}elsif($step_data->{op} eq '>'){
			       		$compare = (($hit_duration > $step_data->{value})?1:0);
			       	}

			       	if ($compare != 1){
			       		$notMatchMsg .= "Channel: $hit_channel with Duration: $hit_duration not match criteria!\n";
			       		print $notMatchMsg."\n";
			       		$pass = 0;
#			       		last;
			       	}
#				}
   			}
   			

   			if ($pass == 0){
   				$result{pass} = 0;
   				$result{msg} = "\nexpected $op_desc '$step_data->{value}'";
   				$result{msg} .= ", got: \n";
   				$result{msg} .= $notMatchMsg;
   			}
   			else {
   				$result{pass} = 1;
   				$result{msg} = "\nexpected $op_desc '$step_data->{value}'";
   				$result{msg} .= ", all match criteria! \n";
   			}
   			print "end for ont512 hit_time check\n";
   			return \%result;
   		}
       }
		
       ## eval the expression using the specified operation
       my ($comp1, $comp2);
       if($step_data->{value} =~/[0-9]*[_a-zA-Z]+/){
       
       if($step_data->{op} eq '=='){
       	$comp1 = qq(q($retval) eq q($step_data->{value})?1:0);
       }elsif($step_data->{op} eq '<='){
       		$comp1 = qq(q($retval) le q($step_data->{value})?1:0);
       	}elsif($step_data->{op} eq '>='){
       		$comp1 = qq(q($retval) ge q($step_data->{value})?1:0);
       	}elsif($step_data->{op} eq '!='){
       		$comp1 = qq(q($retval) ne q($step_data->{value})?1:0);
       	}elsif($step_data->{op} eq '<=>'){
       		$comp1 = qq(q($retval) cmp q($step_data->{value})?1:0);
       	}elsif($step_data->{op} eq '<'){
       		$comp1 = qq(q($retval) lt q($step_data->{value})?1:0);
       	}elsif($step_data->{op} eq '>'){
       		$comp1 = qq(q($retval) gt q($step_data->{value})?1:0);
       	}
       }
       
#       	$comp2 = qq(q($retval) $step_data->{op} q($step_data->{value})? 1:0);

		my $translateResponse = $retval;
		$translateResponse =~ s/\(/left/g;
		$translateResponse =~ s/\)/right/g;
		my $translateResult = $step_data->{value};
		$translateResult =~ s/\(/left/g;
		$translateResult =~ s/\)/right/g;
		
		my $responseString = q($translateResponse);
		my $resultString = q($translateResult);

		$comp2 = qq($responseString $step_data->{op} $resultString? 1:0);
#		print "comp2: $comp2\n";
#		my $res = eval $comp2;
#		print "result: $res\n";
		
	   if(defined $comp1){
	   		$result{pass} = eval $comp1 && eval $comp2;
	   }
	   else{
	   		$result{pass} = eval $comp2;
	   }
       
#       eval qq(q($retval) $step_data->{op} q($step_data->{value}));

   }

   ## build our message and pass it back to do_step

   if( ! $response->{retval} && $response->{error}) {

      ## if the command failed return the error as the msg

      $result{msg} = $response->{error};

   } else {

        ## grab a text description of the operation we did

        my $op_desc = _get_op_desc($step_data->{op});
        $result{msg} = "expected $op_desc '$step_data->{value}'";
        $result{msg} .= ", got '$response->{retval}'";

   }

   return \%result;

}

## this sub takes a ref to the proc list and
## attempts to find the proc description, it 
## will return what it finds or a default desc

sub _get_proc_desc {

   my $proc = shift;

   for my $step (@$proc) {

      ## is this one the description?

      if($step =~ /testcase::procedure/i) {

         ## pull out just the description

         $step =~ s/(testcase::procedure)(=|::?)//i;
         my $desc = $step;
         $step = undef;
         return $desc; ## and return it

      }

   }
 
   ## return the default 

   return "N/A";

}

## this sub take the operation performed
## as an argument and return the text desc

sub _get_op_desc {

   local $_ = shift;

   my $op_desc;

   if( /</ ) {
      $op_desc = 'less than';
   } elsif( />/ ) {
      $op_desc = 'greater than';
   } elsif( /!=/ ) {
      $op_desc = 'not to be';
   } elsif( /==/ ) {
      $op_desc = 'to be';
   } elsif( /=~/ ) {
      $op_desc = 'to match';
   } elsif( /!~/ ) {
      $op_desc = 'not to match';
   }

   return $op_desc;

}

## this sub takes the step string and
## breaks out the elements of the step
##
## symbol::methods::args
## operation (if specified, if not its a bool)
## expectation
##
## this will return a hashref containing the
## above data as keys

sub _read_step {

   local $_ = shift;
   my $tmp = $_ ;
   my(%step,$op);
   
   

   ## find a two char op like == != etc

   if( /([<>=!])([<>=!~])/ ) {
       $op = $1 . $2;
   } elsif( /([<>=!~])/ ) {

      ## or a single char operation like >

      $op = $1;

   } else { $op = '='; }

   ## split up our symbol::method::args 
   ## and op|expected value

   my($symbol,@val)=split($op);

   my $value = join("$op",@val);
   $value =~ s/^\s+//;

   ## clean up any user inconsistancy
   ## with the colons seperating symbol::method::args

   $symbol =~ s/::+/::/g;
   $symbol =~ s/\s+::/::/g;
   $symbol =~ s/::\s+/::/g;



   ## if we got a single =, count that
   ## as an argument to be set not an
   ## evaluation operation, so it is bool
   ## expect pass or fail

   if($op eq '=') {
      $symbol .= "::$value";
      $op = 'bool';
      $value = '';
   }

   ## return the symbol to be passed to the Tea::Symbol class
   ## for execution, and the operation and expected value
   ## for execute_step() to evaluate

   $step{symbol} = $symbol;
   $step{value} = $value;
   $step{op} = $op || 'bool';
   
#   if(index($tmp,"shell_cmd")>0)
#   {
#    $step{symbol} = $tmp;
#    $step{value} = "";
#    $step{op} = 'bool';
#   }
   \%step;

}

#########################################################################
## init_breakpoints(): setup a list of breakpoints for this test

sub init_breakpoints {

   my($self,$symbols) = @_;

   my(@breakpoints);

   for my $sym (keys %$symbols) {
      if(ref($symbols->{$sym}) eq 'Tea::BreakPoint') {
         push @breakpoints, $symbols->{$sym};
      }
   }

   $self->breakpoints(\@breakpoints);

   return;

}

#########################################################################
## breakpoints(): get/set the list of breakpoints defined

sub breakpoints {

   my($self) = shift;

   my $prev = $self->{_breakpoints};

   if(@_ > 0) {

       $self->{_breakpoints} = shift;

   }

   return $prev;

}

#########################################################################
## at_breakpoint(): returns true if we hit a breakpoint condition

sub at_breakpoint {

   my($self,$step,$result) = @_;

   my $breakpoints = $self->breakpoints() or return;

   my (@bp_list);

   for my $bp (@$breakpoints) {
      if($bp->condition_met($step,$result)) {
         push @bp_list, $bp->action();
      }
   }

   return \@bp_list if @bp_list > 0;

}
   
#########################################################################
## do_conditional_steps(): execute multiple steps that contain if/thens

sub do_conditional_steps {

   my($self,$steps,$tc_step) = @_;

   my $tree = build_logic_tree($steps);

   $tc_step->info('CONDITIONAL STEPS ENCOUNTERED (IF/THEN/ELSE)');

   while($tree) {

      my $conditional = ($tree->{true}||$tree->{false}) ? 'IF' : 0;

      my $expr = $tree->{expr};

      if($expr =~ /\s+?(AND|OR)\s+?/) {

         $tree = $self->do_andor_logic($expr,$tc_step)
                 ? $tree->{true} : $tree->{false};

      } else {

         $tree = $self->do_step($expr,$tc_step,$conditional) 
                 ? $tree->{true} : $tree->{false};

      }

    }
  
    $tc_step->info('CONDITIONAL STEPS COMPLETED (IF/THEN/ELSE)');

    return;

}

#########################################################################
## do_andor_logic(): do if statements that have logical and/or statements

sub do_andor_logic {

   my($self,$expr,$tc_step) = @_;

   my(@list) = split(/\s+?AND\s+?|\s+?OR\s+?/,$expr);

   if($expr =~ /\sAND\s/) {

      for(@list) { return if ! $self->do_step($_,$tc_step,'IF expr AND expr ...'); }          

   } else {

      for(@list) { last if $self->do_step($_,$tc_step,'IF expr OR expr ...'); }

   }

   return 1;

}

#########################################################################
## build_logic_tree(): build logic tree from a list of if/then/else steps 

sub build_logic_tree {

   my($lines) = shift;

   my ($last_node,$top_node,$current_top_node);

   for (@$lines) {

      my %tree_node = (expr => '', true => '', false => '');

      if(/^\s*IF\s+?(.+?)$/) {

         $top_node = \%tree_node if ! $top_node;
         $current_top_node = \%tree_node;

      } elsif(/^\s*THEN\s+?(.+?)$/) {

         $last_node->{true} = \%tree_node;

      } elsif(/^\s*ELSE?\s*IF\s+?(.+?)$/) {

         $current_top_node->{false} = \%tree_node;
         $current_top_node = \%tree_node;

      } elsif(/^\s*ELSE\s+?(.+?)$/i) {

         $current_top_node->{false} = \%tree_node;

      }

      $tree_node{expr} = $1;
      $last_node = \%tree_node;

   }

   return $top_node;

}

#########################################################################
## current_tc_step(): get/set reference to current testcase step object

sub current_tc_step {

   my($self) = shift;

   my $prev = $CURRENT_TC_STEP;

   if(@_ > 0) {

       $CURRENT_TC_STEP = shift;

   }

   return $prev;

}

1;

