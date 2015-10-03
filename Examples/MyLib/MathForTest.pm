package MyLib::MathForTest;

use strict;
require Exporter;
our $VERSION = 1.00;

sub new {
    my $self = {
        ErrMsg => 'Oops, Error!',
        Error => 0,
    };
    
    bless $self;
    return $self;
}

sub add {
    my $self = shift;
    my $result = 0;
    foreach (@_) {
        if (/^\d+/) { $result += $_; }
        else { $self->{Error} = 1;
            $self->{ErrMsg} = 'Must be digitals!';
            return -1;
        }
    }
    return $result;
}

my $m_result = 0;
sub m_add {
    my $self = shift;
    foreach (@_) {
        if (/^\d+/) { $m_result += $_; }
        else { $self->{Error} = 1;
            $self->{ErrMsg} = 'Must be digitals!';
            return -1;
        }
    }
    return $m_result;
}

1;

