package Pet::Tea::Symbols;

use base qw(Exporter Pet::Tea::Base);

use strict;

## This module creates a table containing references
## to all the object types (symbols) specified in the test 
## configuration file.  It is intended for use only by
## Tea classes.  It also provides methods for executing
## methods of the symbols contained in the table. This
## module also creates a Tea::Extensions object which
## contains common user methods such as wait and also
## will load any user defined extensions in the config
## file.  Extensions are used to provide methods which
## must have knowledge of the table created by this module
## ie. the method must operate on more than one test object. 
## Extension are not intended for everyday use only special
## cases where its not a good idea to modify core modules 
##



## This routine is given an array ref where each element is 
## a hasref containing the line of name=value pairs from the
## test configuration file. It returns a hashref where the
## keys are the symbol names defined in the configuration file
## that are read from the input file during the actual test
## run and the values are a reference to the instantiated object.
## it also instantiates an extension methods class 

sub init {

   my ($self,$config_map) = @_;

   my (%table,@ext_list,$log_root);

   $log_root = $self->output_dir(); ## get the log root dir

   ## for every line of name=value pairs in the config file 
   ## ( of course its in hash form now but it was lines = )

   for my $element (@$config_map) {

       ## if the entry is an extension, do it last

       if(exists $element->{EXTENSION}) {

          push @ext_list, $element;

          next;

       }

       ## get the object type and the symbol name
       ## if present and remove them from this hash

       my $class = delete $element->{TYPE};

       # modified by Peng Wan 2010-02-08
       # change symbol to be case care
#       my $symbol = lc delete $element->{SYMBOL}; ## symbls are case folded
       my $symbol = delete $element->{SYMBOL}; 
	   
       ## add ::new to pkg type and we have the constructor name
       
       ###############################################################
       ##support multi format like SYMBOL=NodeSet1 TYPE::SpecialMultiObjects SUBSYMBOLS=Node1,Node2,Node3...
       ##Mar30,2009 by Nan Chen
       if($class eq 'Tea::SpecialMultiObjects'){
			my @symbolSet = split(',',$element->{SUBSYMBOLS});    
#			foreach my $symbolSetSymbol (@symbolSet)  {
#				foreach my $definedSymbol ($self->{_table}){
#					if ($symbolSetSymbol eq $definedSymbol){last;}
#				}
#			} 	
			$table{$symbol} = \@symbolSet;
#			last;
			next;
       }

       my $construct = $class . '::new';

       ## make sure we can call the constructor

       if( ! $self->can($construct) ) {

          return $self->error("Could not call '$construct' for symbol '$symbol'");
                  
       }

       ## call it, passing it the named args from the config map/file
       ## and the log root directory so it may place its log there

       #kangjian add for support sn9K mesh
       my $p;
       if($construct eq 'Tea::Objects::Mesh::new')
       {
       	$p = new $class (%$element,LOG_ROOT => $log_root,%table);
       }
       else
       {
       	$p = new $class (%$element,LOG_ROOT => $log_root);
       }

       ## add it to the table

       $table{$symbol} = $p;
         
   }

   ## keep ref to the table as an object variable

   $self->{_table} = \%table if %table;

   ## create the extension manager object

   my $extensions = new Pet::Tea::Extensions(Errmode => 'return');

   ## give it a reference to this object

   $extensions->symbols($self);

   for my $element (@ext_list) {

      ## load all desired extension packages

      delete $element->{EXTENSION};

      $extensions->load_extension(%$element)
          or return $self->error($extensions->errmsg());


      next;

   }

   ## keep a reference to the extensions, so user can access 

   $table{test} = $extensions;

   1;

}

## This method takes a symbol::method::args (step from input file)
## and returns a hashref containing the object ref, method name, and
## the arguments to pass, and of course makes sure its valid
##
## Example: symbol is Telnet::cmd::ls
##
## format is always <object>::<method>::<arg1>::<arg2>::..
##
## will return { 
##               object_ref => HASHREF, (to Net::Telnet obj)
##               method_name => 'cmd', (the method to call) 
##               args_array => ARRAYREF, (value 0 would be 'ls')
##             }            
##

sub get_reference {

   my($self,$symbol) = @_;

   my (@args,$tries,%ref);

   my $it = $symbol;

   my $table = $self->{_table};
   

   ## keep removing the right most ::xxx until the we
   ## have found an symbol defined in the table
   ## only try this 10 times, then assume its a bad symbol

  # modified by Peng Wan 2010-02-08
  # change symbol to be case care
#   while( ! $table->{lc $symbol} && $tries < 10) {
   while( ! $table->{$symbol} && $tries < 10) {      

      my(@t)=split(/::/,$symbol);

      my $arg = pop @t;

      push @args, $arg;

      $symbol = join('::',@t);

      $tries++;

   }

   if($tries == 10) {

      return $self->error("Can not execute '$it', symbol not initialized");

   }

   ## we got here, the object must be defined in the table, grab the ref 

   # modified by Peng Wan 2010-02-08
  # change symbol to be case care
#   my $p = $table->{lc $symbol};
   my $p = $table->{$symbol};

   @args = reverse @args; ## the args must be flipped
                          ## we went backwards above

   # modified by Peng Wan 2010-02-08
  # change symbol to be case care						  
#   my $method = lc shift @args; ## case fold the method
   my $method = shift @args; ## case fold the method

   ## make sure the object can call the method

   if( ! $p->can($method) ) {
   # modified by Peng Wan 2010-02-08
  # change symbol to be case care	
#      return $self->error("Symbol '" . (uc $symbol) . "' has no method named '$method'");
	  my $method_lc = lc $method; # try low case
	  return $self->error("Symbol '" . ($symbol) . "' has no method named '$method' or 'method_lc'") unless($p->can($method_lc));
	  $method = $method_lc;

   }

   ## return the hashref

   $ref{method_name} = $method;
   $ref{object_ref} = $p;
   $ref{arg_array} = \@args;

   \%ref;

}

## This method takes a symbol::method::args string and executes
## it if possible, it returns a hashref containing possible keys 
## (depending what happened) desc, retval, failed, and error.
## It is expected that the method we execute will return this
## hash to us already, but since we want to support all modules,
## if we dont get a hash, feel out the response and return our own.

sub execute {

   my($self,$symbol) = @_;

   my ($ref,@r,%result,$p,$method,$args);

   ## get the correct refs or quit

   $ref = $self->get_reference($symbol) or return;

   ## shorten up our variables

   ($p,$method,$args) = ($ref->{object_ref},$ref->{method_name},$ref->{arg_array});

   ## ok execute it, expect the result in list context
   ## to make it easy to tell what we are getting back

   @r = $p->$method(@$args);
 
   if(@r > 1) {

       ## an array, concat the elements
       ## and we will pass that back as retval

       $result{retval} = join("",@r);

   } elsif(ref($r[0]) eq 'HASH') {
   	
   	#added by cn at July.09 2009, support detail message for every channel
   	my $tmp = $r[0];
   	my %inhash = %$tmp;
   	if (defined $inhash{'Ont512HitTimeDetails'}){
   		$result{retval} = \%inhash;
   	}
   	else {

       $p->error_reason($r[0]->{error})
          if(exists $r[0]->{error} && $p->can('error_reason'));  ## save the error message
 
       return $r[0]; ## perfect a hash! send it back now
       
    #added by cn at July.09 2009, support detail message for every channel
   	}

   } elsif(ref($r[0]) eq 'ARRAY') {

       ## an arrayref, concat the elements
       ## and we will pass that back as retval

       $result{retval} = join("",@{$r[0]});

   } elsif(ref($r[0]) eq 'SCALAR') {

       ## a scalarref, pass that back as retval 

       $result{retval} = ${$r[0]};

   } elsif( !@r && $p->can('errmsg') ) {

       ## if there was no return value and
       ## we can call the errmsg() method
       ## lets do that and return it

       my $error_msg = $p->errmsg();

       $result{failed} = 1 if $error_msg;
       $result{error} = $error_msg if $error_msg;

       if($error_msg && $p->can('error_reason')) {
          $p->error_reason($error_msg);
       }

       return \%result if $error_msg;
 
   } else {

       ## a scalar, pass that back as retval

       $result{retval} = $r[0]

   }

   ## if we get this far we did not get a hash
   ## so we need to mark it failed if there was
   ## no retval, and make up a desc, then return 
   ## our own hash

   if( ! $result{retval}) { $result{failed} = 1; }

   $symbol =~ s/::$//;

   $result{desc} = "Execute $symbol";

   \%result;

}

## object method to get/set the symbol table reference

sub table {

   my $self = shift;

   my $old = $self->{_table};

   if(@_ > 0) {

      $self->{_table} = shift;

   }

   return $old;

}

1;

