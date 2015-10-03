package Pet::Tea::BreakPoint;

use base qw(Pet::Tea::Base);

use strict;

#############################################################################
## new(): constructor

sub new {

   my($class,%args) = @_;

   my($self,$action,%cond,$range);

   $self = {
            _cond => '',
            _range => '',
            _action => '',
           };

   bless $self, $class;

   ## parse user args

   for(keys %args) {

      if(/-?action/i) {

         $self->action($args{$_});

      } elsif(/cond/i) {

         $cond{$args{$_}} = 0;

      } elsif(/-?range/i) {

         ## range not yet implemented

         $self->range($args{$_});

      }

   }

   $self->conditions(\%cond);

   return $self;

}

#############################################################################
## condition_met(): returns true if the conditions has been met

sub condition_met {

    my($self,$step,$result) = @_;

    $self->update_status($step,$result);

    my $checks = $self->conditions() or return;
 
    my $met_conditions = 0;

    for(keys %$checks) { $met_conditions++ if $checks->{$_} > 0; }   

    if(scalar(keys %$checks) == $met_conditions) {

       $self->clear_status();
       return 1;

    }

    return;

}

#############################################################################
## update_status(): updates the status of which conditions have been met

sub update_status {

    my($self,$step,$result) = @_;

    my $checks = $self->conditions() or return;

    ## currently only failed steps can be breaked on
    ## be sure to make sure $result is not null
    ## before checking for the pass condition

    return if $result && $result->{pass};

    ## update the current conditions met status

    for my $check (keys %$checks) {          

       if(eval { $step =~ /$check/i }) {

           $checks->{$check}++;

       }

    }

   $self->conditions($checks);

   return;

}   

#############################################################################
## clear_status(): clears the status of which conditions have been met

sub clear_status {

    my $self = shift;

    my $checks = $self->conditions() or return;

    ## update the current conditions met status

    for my $check (keys %$checks) {

       $checks->{$check} = 0;

    }

   $self->conditions($checks);

   return;

}  

#############################################################################
## action(): get/set the breakpoint action

sub action {

   my $self = shift;

   my $prev = $self->{_action};

   if(@_ > 0) {

      $self->{_action} = shift;

   }

   return $prev;

}      

#############################################################################
## conditions(): get/set the conditions hash

sub conditions {

   my $self = shift;

   my $prev = $self->{_cond};

   if(@_ > 0) {

      $self->{_cond} = shift;

   }

   return $prev;

}

#############################################################################
## range(): get/set the breakpoint step range 

sub range {

   my $self = shift;

   my $prev = $self->{_range};

   if(@_ > 0) {

      $self->{_range} = shift;

   }

   return $prev;

}

1;

