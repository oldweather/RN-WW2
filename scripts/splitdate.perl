#!/usr/bin/perl

# Put a break in the Portsmouth pressure graph whenever there is more
#  than 1 day between observations.

use strict;
use warnings;

my $Last;
while (<>) {
    unless ( $_ =~ /^\d/ ) {
        print $_;
        next;
    }
    my $Date = (split)[0];
    if ( defined($Last) && $Date - $Last > 100 ) {
        print "\n$_";
    }
    else {
        print $_;
    }
    $Last = $Date;
}
