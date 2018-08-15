#!/usr/bin/perl

# Estimate spatial correlation of gridded SLP with Darwin data.

use strict;
use warnings;
use lib "$ENV{PP_PERL}";
use PP;

my @pp;
while ( my $pp = pp_read( \*STDIN ) ) {
    unless($pp->{lbmon}>=6 && $pp->{lbmon}<=8) { next; }
    push @pp, $pp;
}

my $D_lat =
  int( ( -12.47 - ( $pp[0]->{bzy} + $pp[0]->{bdy} / 2 ) ) / $pp[0]->{bdy} );
my $D_long =
  int( ( 130.83 - ( $pp[0]->{bzx} + $pp[0]->{bdx} / 2 ) ) / $pp[0]->{bdx} );

# Calculate means
my @Mean;
my @Count;
for ( my $m = 0 ; $m < scalar(@pp) ; $m++ ) {
    for ( my $i = 0 ; $i < $pp[$m]->{lbrow} ; $i++ ) {
        for ( my $j = 0 ; $j < $pp[$m]->{lbnpt} ; $j++ ) {
            if ( $pp[$m]->{data}->[$i][$j] == $pp[$m]->{bmdi} ) { next; }
            $Mean[$i][$j] += $pp[$m]->{data}->[$i][$j];
            $Count[$i][$j]++;
        }
    }
}
for ( my $i = 0 ; $i < $pp[0]->{lbrow} ; $i++ ) {
    for ( my $j = 0 ; $j < $pp[0]->{lbnpt} ; $j++ ) {
        if ( defined( $Count[$i][$j] ) ) { $Mean[$i][$j] /= $Count[$i][$j]; }
    }
}

# Calculate SD
my @Sd;
for ( my $m = 0 ; $m < scalar(@pp) ; $m++ ) {
    for ( my $i = 0 ; $i < $pp[$m]->{lbrow} ; $i++ ) {
        for ( my $j = 0 ; $j < $pp[$m]->{lbnpt} ; $j++ ) {
            if ( $pp[$m]->{data}->[$i][$j] == $pp[$m]->{bmdi} ) { next; }
            $Sd[$i][$j] += ( $pp[$m]->{data}->[$i][$j] - $Mean[$i][$j] )**2;
        }
    }
}
for ( my $i = 0 ; $i < $pp[0]->{lbrow} ; $i++ ) {
    for ( my $j = 0 ; $j < $pp[0]->{lbnpt} ; $j++ ) {
        if ( defined( $Count[$i][$j] ) && $Count[$i][$j] > 1 ) {
            $Sd[$i][$j] /= $Count[$i][$j];
            $Sd[$i][$j] = sqrt( $Sd[$i][$j] );
        }
        else {
            $Sd[$i][$j] = undef();
        }
    }
}

# Calculate corelations
my @Correlation;
for ( my $m = 0 ; $m < scalar(@pp) ; $m++ ) {
    for ( my $i = 0 ; $i < $pp[$m]->{lbrow} ; $i++ ) {
        for ( my $j = 0 ; $j < $pp[$m]->{lbnpt} ; $j++ ) {
            if ( $pp[$m]->{data}->[$i][$j] == $pp[$m]->{bmdi} ) { next; }
            if ( $pp[$m]->{data}->[$D_lat][$D_long] == $pp[$m]->{bmdi} ) {
                next;
            }
            $Correlation[$i][$j] +=
              ( $pp[$m]->{data}->[$i][$j] - $Mean[$i][$j] ) *
              ( $pp[$m]->{data}->[$D_lat][$D_long] - $Mean[$D_lat][$D_long] );
        }
    }
}
for ( my $i = 0 ; $i < $pp[0]->{lbrow} ; $i++ ) {
    for ( my $j = 0 ; $j < $pp[0]->{lbnpt} ; $j++ ) {
        if ( defined( $Correlation[$i][$j] ) && defined( $Sd[$i][$j] ) ) {
            $Correlation[$i][$j] /= $Count[$i][$j];
            $Correlation[$i][$j] /= sqrt($Sd[$i][$j]**2 * $Sd[$D_lat][$D_long]**2);
        }
        else {
            $Correlation[$i][$j] = undef();
        }
    }
}

# Convert to PP and output
for ( my $i = 0 ; $i < $pp[0]->{lbrow} ; $i++ ) {
    for ( my $j = 0 ; $j < $pp[0]->{lbnpt} ; $j++ ) {
        if ( defined( $Correlation[$i][$j] ) ) {
            $pp[0]->{data}->[$i][$j] = $Correlation[$i][$j];
        }
        else {
            $pp[0]->{data}->[$i][$j] = $pp[0]->{bmdi};
        }
    }
}
$pp[0]->write_to_file( \*STDOUT );
