#!/usr/bin/perl

# Check the effect of differences in coverage on the time-series plot

use strict;
use warnings;
use FindBin;
use lib "$ENV{PP_PERL}";
use PP;
use PP::average;

my $OldF = "$FindBin::Bin/../gridded_fields/sst/5x5/old.pp";
my $NewF = "$FindBin::Bin/../gridded_fields/sst/5x5/new.pp";

my ( $dinO, $dinN );
open( $dinO, "$OldF" ) or die "Can't open $OldF";
open( $dinN, "$NewF" ) or die "Can't open $NewF";

while ( my $ppO = pp_read($dinO) ) {
    my $ppN = pp_read($dinN);
    unless ( $ppO->{lbyr} == $ppN->{lbyr}
        && $ppO->{lbmon} == $ppN->{lbmon} )
    {
        die "Date mismatch";
    }
    my (@Results);
    $Results[0] = area_average($ppO);
    $Results[1] = area_average($ppN);
    for ( my $i = 0 ; $i < $ppO->{lbrow} ; $i++ ) {
        for ( my $j = 0 ; $j < $ppO->{lbnpt} ; $j++ ) {
            if ( $ppO->{data}->[$i][$j] == $ppO->{bmdi} ) {
                $ppN->{data}->[$i][$j] = $ppN->{bmdi};
                next;
            }
            if ( $ppN->{data}->[$i][$j] == $ppN->{bmdi} ) {
                $ppO->{data}->[$i][$j] = $ppO->{bmdi};
            }
        }
    }
    $Results[2] = area_average($ppO);
    $Results[3] = area_average($ppN);

    printf "%04d%02d %g %g %g %g\n", $ppN->{lbyr}, $ppN->{lbmon}, $Results[0], $Results[1], $Results[2], $Results[3] ;
}

