package Pet::Tea::Extensions;

use base qw(Exporter Pet::Tea::Base);

use strict;

## This file contains:
## A.  Global common user methods (wait)
## B.  A method to load extension packages
##
## Extension packages can be two flavors
## A.  Add routines to the namespace to add/change behaviors
## B.  New Objects (that are to complex to be in Tea/Objects/*
##
## NOTE: new objects must place a named reference to
## themselves in the symbol table $self->symbols->table()
## in order to be called from the test input files
## the key is the name to call them, the value their ref
##

## load an extension package

sub load_extension {

   my($self,%args) = @_;

   ## get the package name

   my $extension_package = delete $args{TYPE};

   ## use it in an eval loop

   eval "use $extension_package;";

   ## raise an error if the eval failed
 
   return $self->error($@) if $@;

   ## call the constructor if there is one

   if( $self->can($extension_package . '::new')) {

      ## the class we are loading is responsible
      ## for giving its self an entry in the symbol table
      ## just call the construct, dont save the reference
      ## but be sure to pass the symbol object along

      new $extension_package(Symbols => $self->symbols(),%args);

   }

   return 1; ## success!

}

## Golbal Methods

#######################################################################################
#######################################################################################
## The methods below can be called within the input file to do generic ops like wait ##
#######################################################################################
#######################################################################################

## this method waits for specified time

sub wait {

   my($self,$time,$unit) = @_;

   ## was the time and unit together

   if( !$unit && $time =~ /(\w+?$)/ ) {

      $unit = $1;

   } elsif( !$ unit ) {

      ## if not default unit is seconds

      $unit = 'seconds';

   }

   ## factor the correct time based on the unit

   if(    $unit =~ /m/i) { ##minutes

       $time *= 60;

   } elsif($unit =~ /h/i) { ##hours

       $time *= 3600;

   } elsif($unit =~ /d/i) { ##days

       $time *= 86400;

   } else { $time = int($time); }

   ## ok wait now, exciting!

   print "\nWaiting $time second(s)...";

   for(my $i=0;$i<$time;$i++) {

      print "."; sleep 1;

   }

   print "DONE\n\n";

   ## return the properly formated hashref

   return { success => 1, retval => 1, desc => "Wait $time second(s)" }

}
############################################################################
##created by cn at Jun23,2009 to suppport ifdef endif in config_file, if defined 
##excuted, let it to change the method be test::do_nothing
sub do_nothing{
	my $self = @_;
	print "Do not need to excuted according to config_file\n";
	my $thisRes = { 
		success => 1, 
		retval => 1, 
		desc => "Do not need to excuted according to config_file" 
	};
	return $thisRes;
}

############################################################################
## halt(): stop this test now

sub halt {

   my($self,$reason) = @_;

   print "\n ****** Test Halted";

   print ": $reason" if $reason;

   print " ******\n\n"; 

   exit(0);

}

############################################################################
## info(): log an informational message

sub info {

   my($self,$msg) = @_;

   my %result;

   $result{info} = $msg;

   return \%result;

}

############################################################################
## pause(): pause and wait for a control C from the user

sub pause {

   my($self,$reason) = @_;

   my (%result,$paused);

   $reason ||= 'Paused';

   $result{info} = $reason;
   $paused = 1;

   ## setup signal handler

   $SIG{'INT'} = sub { $paused = 0; };

   print "\n$reason (CTRL-C to resume)...";

   ## wait for signal

   while($paused) {

      sleep 5;
      print ".";

   }
   
   print "RESUMED\n\n";

   ## restore the default handler

   $SIG{'INT'} = 'DEFAULT';

   return \%result;

}

############################################################################
## shell_cmd(): executes the given external script, returns the output

sub shell_cmd {

   my($self,$cmd) = @_;
   my(@output,%result);

   $result{desc} = "Executing external command: $cmd";

   @output = `$cmd`;

   $result{retval} = join("\n",@output);

   return \%result;

}

############################################################################
## verify_attr():  Verify attributes place on a stack by read_attr

sub verify_attr {

   my($self, $val) = @_;

   my($stack,$baseline,%result);

   $result{desc} = 'Verifying attribute values';

   if(not exists $Tea::Objects::Base::TEMP_STACKS{read_attr}) {
      return { failed => 1, error => 'no attributes on stack, from read_attr()' };
   }

   $stack = delete $Tea::Objects::Base::TEMP_STACKS{read_attr};

   $baseline = shift @$stack;

   for(my $i=0;$i<scalar(@$stack);$i++) {
      if ($val) {
         if($baseline =~ /^\d+?$/) {
            if (!($baseline <= $stack->[$i] + $val)) { 
               $result{retval} = 0;
               $result{error} = 'found inconsistent value';
               return \%result;
            }
          } else {
            if (not($baseline le $stack->[$i] + $val)) { 
               $result{retval} = 0;
               $result{error} = 'found inconsistent value';
               return \%result;
            }
         }
      } else {
        if($baseline =~ /^\d+?$/) {
           if($baseline != $stack->[$i]) { 
               $result{retval} = 0;
               $result{error} = 'found inconsistent value';
               return \%result;
            }
          } else {
            if($baseline ne $stack->[$i]) {
               $result{retval} = 0;
               $result{error} = 'found inconsistent value';
               return \%result;
            }
         }
      }
   }
   $result{retval} = 1;
   return \%result;

}
   
1;

