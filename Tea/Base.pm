package Pet::Tea::Base;
$VERSION = '1.2';
#use base qw(Exporter Common::Base1);

## This class is derived from Common::Base1 for more
## info run perldoc Common::Base1

use strict;

## This module provides common object methods for accessing
## variables inside Tea classes, it is intended to be used
## only for Tea classes.  All methods in this module will
## behave the same way, if given an argument they will set
## the object variable to that argument and return the old 
## setting, if given no argument they will return the current
## value the variable is set to. For more doc see Tea.pm.
##


####################### Public Methods ###############################
## Constructor
sub new {
    my ($class, @args) = @_;
    
    my $self = bless {}, ref($class) || $class;
    
    $self->_init(@args);
        
    return $self;
}

###############################################################
sub errmode {
    my ($self, $mode) = @_;
    my $prev = $self->{_errmode};

    if (@_ >= 2) {
        ## Set the error mode.
        defined $mode or $mode = '';
        if (ref($mode) eq "CODE") {
            $self->{_errmode} = $mode;
        } elsif (ref($mode) eq "ARRAY") {
            unless (ref($mode->[0]) eq "CODE") {
                $self->_carp("bad errmode: first item in list must " .
                                "be a code ref");
                $mode = "die";
                }
            $self->{_errmode} = $mode;
        } elsif ($mode =~ /^return$/i) {
            $self->{_errmode} = "return";
        } else {
            $self->{_errmode} = "die";
        }
    }

    $prev;
}


###############################################################
sub _init {
    my ($self) = @_;
    
    # default errmode is return
    my $errmode = 'die';
    my $debug_log = '';
    
    if (@_ == 2) {  # one positional arg given
        $errmode = $_[1];
    } elsif (@_ > 2) {  # named arguments
        my %args;
        
        (undef, %args) = @_;
        foreach (keys %args) {
            if (/^-?Errmode/i) {
                $errmode = $args{$_};
            }
            elsif(/^-?Debug_log/i) {
                $debug_log = $args{$_};
            }
            ##added by cn at Jun23, 2009 to support ifdef and endif
            elsif(/^-?NOTEXECUTE/i){
            	$self->{'NOTEXECUTE'} = $args{$_};
            }
        }
    }
    
    $self->errmode($errmode);
    $self->errmsg('');
    $self->debug_log($debug_log);
    $self->print_debug_log("*DEBUG* ran _init from Base1");
    
    1;
}


###############################################################
## debug_log: set or get the debug_log file

sub debug_log {
    my ($self, $debug_log) = @_;

    my $fh = $self->{_debug_log};

    if ( @_ >= 2 ) {
        defined $debug_log or $debug_log = '';

        if ( length $debug_log ) {
            $fh = new FileHandle(">$debug_log") or return
                $self->error("ERROR: Could not get debug_log file: $debug_log $!");

            $self->{_debug_log} = $fh;
        }

    }

    $fh;

} #End sub debug_log


###############################################################
## print_debug_log: method to print debug log

sub print_debug_log {
    my ($self, $string) = @_;

    if ( $self->debug_log() ||
         $self->{_debug_mode} ) {
        my $pstring = $string . "\n";
        my $fh = $self->debug_log();
        if ( ref($fh) ) {
            print $fh $pstring;
        } else {
            print $pstring;
            $| = 1;
        }
        
    }

    1;
} #end print debug log


###############################################################
sub error {
    my ($self, @errmsg) = @_;

    if (@_ >= 2) {
        ## Put error message in the object.
        my $errmsg = join '', @errmsg;
        $self->{_errmsg} = $errmsg;

        ## Do the error action as described by error mode.
        my $mode = $self->{_errmode};
        if (ref($mode) eq "CODE") {
            &$mode($self, $errmsg);
            return;
        } elsif (ref($mode) eq "ARRAY") {
            my ($func, @args) = @$mode;
            &$func(@args);
            return;
        } elsif ($mode =~ /^return$/i) {
            return;
        } else {  # die
            if ($errmsg =~ /\n$/) {
                die $errmsg;
            } else {
                ## Die and append caller's line number to message.
                $self->_croak($errmsg);
            }
        }
    } else {
        return $self->{_errmsg} ne '';
    }
}


## set or get ref to the current procedure list

sub proc_list {

   my $self = shift;

   my $old = $self->{_proclist};

   if(@_ > 0) {

      $self->{_proclist} = shift;

   }

   return $old;

}


sub testcase {

   my $self = shift;

   my $old = $self->{_testcase};

   if(@_ > 0) {

      $self->{_testcase} = shift;

   }

   return $old;

}

## set or get ref to the Tea symbol table (Tea::Symbols)

sub symbols {

   my $self = shift;

   my $old = $self->{_symbols};

   if(@_ > 0) {

      $self->{_symbols} = shift;

   }

   return $old;

}

## set or get ref to the test config map 

sub config {

   my $self = shift;

   my $old = $self->{_config};

   if(@_ > 0) {

      $self->{_config} = shift;

   }

   return $old;

}

## set or get ref to the test input 

sub input {

   my $self = shift;

   my $old = $self->{_input};

   if(@_ > 0) {

      $self->{_input} = shift;

   }

   return $old;

}

sub output_dir {

   my $self = shift;

   my $old = $self->{_outputdir};

   if(@_ > 0) {

      $self->{_outputdir} = shift;

   }

   return $old;

}



###############################################################
sub errmsg1 {
    my ($self, @errmsgs) = @_;
    my $prev = $self->{_errmsg};

    if (@_ >= 2) {
        $self->{_errmsg} = join '', @errmsgs;
    }

    $prev;
}

## return the current object error message (if present)
## and clear it, this is derived from Common::Base but
## extended to clear the message also;

sub errmsg {

   my $self = shift;

   my $msg = $self->errmsg1();

   $self->{_errmsg} = '';

   return $msg;

}

1;

