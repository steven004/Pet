our $Math = new Pet::MathForTest;

sub mysum {
    my $result = 0;
    foreach (@_) {
        if (/^\d+/) { $result += $_; }
        else {
            print STDERR "all digitals required\n";
            return -1;
        }
    }
    return $result;
}


sub onFailSub{
  print STDERR "Test Stopped on Case# $_[0] Step# $_[1]! \n";
}
