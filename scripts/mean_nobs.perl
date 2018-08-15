#!/usr/bin/perl -w

# Make mean fields of the number of observations on the 2x2 grid
#  Over the periofd 1941-6.

use strict;
use warnings;
use lib "$ENV{PP_PERL}";
use PP;

my $Mean;
my $Count;

while ( my $pp = pp_read( \*STDIN ) ) {
    if ( $pp->{lbyr} < 1941 || $pp->{lbyr} > 1946 ) { next; }
    $Count++;
    if ( defined($Mean) ) {
        for ( my $i = 0 ; $i < $pp->{lbrow} ; $i++ ) {
            for ( my $j = 0 ; $j < $pp->{lbnpt} ; $j++ ) {
                if ( $pp->{data}->[$i][$j] == $pp->{bmdi} ) {
                    next;
                }
                elsif ( $Mean->{data}->[$i][$j] == $Mean->{bmdi} ) {
                    $Mean->{data}->[$i][$j] = $pp->{data}->[$i][$j];
                }
                else {
                    $Mean->{data}->[$i][$j] += $pp->{data}->[$i][$j];
                }
            }
        }
    }
    else {
        $Mean = pp_copy($pp);
    }
}

for ( my $i = 0 ; $i < $Mean->{lbrow} ; $i++ ) {
    for ( my $j = 0 ; $j < $Mean->{lbnpt} ; $j++ ) {
        if ( $Mean->{data}->[$i][$j] == $Mean->{bmdi} ) {
            next;
        }
        else {
            $Mean->{data}->[$i][$j] /= $Count;
        }
    }
}

$Mean->write_to_file( \*STDOUT );

