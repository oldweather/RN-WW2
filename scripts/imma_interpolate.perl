#!/usr/bin/perl

# Interpolate positions for all the new RN obs from the
#  subset with positions.

# Uses linear interpolation using 2 constraints
#  1) Don't interpolate over more than 48 hours
#  2) Don't interpolate over more than 5 degrees (lat or long)
# If adjacent good positions fail these checks, intermediate obs will
#  not have a position interpolated.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module/";
use IMMA;
use Time::Local;

# Read in the obs and sort into date order
my @a;
while ( my $ob = imma_read( \*STDIN ) ) {
    push @a, $ob;
}
@a = sort td_compare @a;

# Mark the obs with positions
my @WithP;
foreach (@a) {
    if ( defined( $_->{LAT} ) && defined( $_->{LON} ) ) {
        push @WithP, 1;
    }
    else {
        push @WithP, 0;
    }
}

# Interpolate the missing locations
for ( my $i = 0 ; $i < scalar(@a) ; $i++ ) {
    if ( defined( $a[$i]->{LAT} ) || defined( $a[$i]->{LON} ) ) {
        next;
    }
    my $Previous = find_previous($i);
    my $Next     = find_next($i);
    if (   defined($Previous)
        && defined($Next) )
    {
        my ( $Lat1, $Lon1 ) = interpolate( $Previous, $Next, $a[$i] );
        if (   defined($Lat1)
            && defined($Lon1) )
        {
            $a[$i]->{LAT} = $Lat1;
            $a[$i]->{LON} = $Lon1;
            $a[$i]->{LI}  = 3;       # Mark position as interpolated
        }
    }

}

# Output the new obs
foreach (@a) { $_->write( \*STDOUT ); }

# Find the last previous ob that has a date
sub find_previous {
    my $Point = shift;
    for ( my $j = $Point - 1 ; $j >= 0 ; $j-- ) {
        if ( $a[$j]->{ID} ne $a[$Point]->{ID} ) { return; }
        if ( $WithP[$j] == 1 ) { return $a[$j]; }
    }
    return;
}

# Find the first subsequent ob that has a date
sub find_next {
    my $Point = shift;
    for ( my $j = $Point + 1 ; $j < scalar(@a) ; $j++ ) {
        if ( $a[$j]->{ID} ne $a[$Point]->{ID} ) { return; }
        if ( $WithP[$j] == 1 ) { return $a[$j]; }
    }
    return;
}

# Interpolate from the positions of a previous and a subsequent ob
sub interpolate {
    my $Previous = shift;
    my $Next     = shift;
    my $Target   = shift;

    # Get the epoch time of each ob
    if (   !defined( $Previous->{HR} )
        || $Previous->{HR} < 0
        || $Previous->{HR} > 24
        || !defined( $Previous->{DY} )
        || $Previous->{DY} < 1
        || !defined( $Previous->{MO} )
        || $Previous->{MO} < 1
        || $Previous->{MO} > 12
        || $Previous->{DY} > month_lengths( $Previous->{MO}, $Previous->{YR} )
        || !defined( $Previous->{YR} )
        || $Previous->{YR} > 3000 )
    {
        return ( undef, undef );
    }
    my $Time_prev;
    if ( $Previous->{HR} == 24 ) {
        $Time_prev = timegm( 0, 59, 23, $Previous->{DY}, $Previous->{MO} - 1,
            $Previous->{YR} );
    }
    else {
        $Time_prev =
          timegm( 0, 0, $Previous->{HR}, $Previous->{DY}, $Previous->{MO} - 1,
            $Previous->{YR} );
    }
    if (   !defined( $Next->{HR} )
        || $Next->{HR} < 0
        || $Next->{HR} > 24
        || !defined( $Next->{DY} )
        || $Next->{DY} < 1
        || !defined( $Next->{MO} )
        || $Next->{MO} < 1
        || $Next->{MO} > 12
        || $Next->{DY} > month_lengths( $Next->{MO}, $Next->{YR} )
        || !defined( $Next->{YR} )
        || $Next->{YR} > 3000 )
    {
        return ( undef, undef );
    }
    my $Time_next;
    if ( $Next->{HR} == 24 ) {
        $Time_next =
          timegm( 0, 59, 23, $Next->{DY}, $Next->{MO} - 1, $Next->{YR} );
    }
    else {
        $Time_next =
          timegm( 0, 0, $Next->{HR}, $Next->{DY}, $Next->{MO} - 1,
            $Next->{YR} );
    }
    if (   !defined( $Target->{HR} )
        || $Target->{HR} < 0
        || $Target->{HR} > 24
        || !defined( $Target->{DY} )
        || $Target->{DY} < 1
        || !defined( $Target->{MO} )
        || $Target->{MO} < 1
        || $Target->{MO} > 12
        || $Target->{DY} > month_lengths( $Target->{MO}, $Target->{YR} )
        || !defined( $Target->{YR} )
        || $Target->{YR} > 3000 )
    {
        return ( undef, undef );
    }
    my $Time_target;
    if ( $Target->{HR} == 24 ) {
        $Time_target =
          timegm( 0, 59, 23, $Target->{DY}, $Target->{MO} - 1, $Target->{YR} );
    }
    else {
        $Time_target =
          timegm( 0, 0, $Target->{HR}, $Target->{DY}, $Target->{MO} - 1,
            $Target->{YR} );
    }

    # Give up if the gap is longer than 48 hours
    if ( $Time_next - $Time_prev > 172800 ) {
        return ( undef, undef );
    }

    # Deal with any logitude wrap-arounds
    my $Next_long = $Next->{LON};
    if ( $Next_long - $Previous->{LON} > 180 ) { $Next_long -= 360; }
    if ( $Next_long - $Previous->{LON} < -180 ) { $Next_long += 360; }

    # Give up if the separation is greater than 5 degrees
    if (   abs( $Next_long - $Previous->{LON} ) > 5
        || abs( $Next->{LAT} - $Previous->{LAT} ) > 5 )
    {
        return ( undef, undef );
    }

    # Do the interpolation
    if($Time_next<=$Time_prev) { return ( undef, undef ); }
    my $Weight = ( $Time_next - $Time_target ) / ( $Time_next - $Time_prev );
    my $Target_long = $Next_long * ( 1 - $Weight ) + $Previous->{LON} * $Weight;
    if ( $Target_long < -180 ) { $Target_long += 360; }
    if ( $Target_long > 180 ) { $Target_long -= 360; }
    my $Target_lat =
      $Next->{LAT} * ( 1 - $Weight ) + $Previous->{LAT} * $Weight;
    return ( $Target_lat, $Target_long );
}

# Compare two records, sort by callsign then date
sub td_compare {
    my ( $Idb, $Yrb, $Mob, $Dyb, $Hrb ) =
      ( $a->{ID}, $a->{YR}, $a->{MO}, $a->{DY}, $a->{HR} );
    unless ( defined($Idb) ) { $Idb = 'SHIP     '; }
    unless ( defined($Yrb) ) { $Yrb = 3000; }
    unless ( defined($Mob) ) { $Mob = 12; }
    unless ( defined($Dyb) ) { $Dyb = 31; }
    unless ( defined($Hrb) ) { $Hrb = 24; }
    my ( $Ida, $Yra, $Moa, $Dya, $Hra ) =
      ( $a->{ID}, $a->{YR}, $a->{MO}, $a->{DY}, $a->{HR} );
    unless ( defined($Ida) ) { $Ida = 'SHIP     '; }
    unless ( defined($Yra) ) { $Yra = 3000; }
    unless ( defined($Moa) ) { $Moa = 12; }
    unless ( defined($Dya) ) { $Dya = 31; }
    unless ( defined($Hra) ) { $Hra = 24; }
    return $Ida cmp $Idb ||    # Compare callsign
      $Yra <=> $Yrb      ||    # Compare Year
      $Moa <=> $Mob      ||    # Compare Month
      $Dya <=> $Dyb      ||    # Compare Day
      $Hra <=> $Hrb;           # Compare Hour
}

sub month_lengths {
    my $Month = shift;
    my $Year  = shift;
    unless ( defined($Month) && defined($Year) ) { return; }
    my @Lengths = qw(31 28 31 30 31 30 31 31 30 31 30 31);
    if ( $Year % 400 == 0 || ( $Year % 4 == 0 && $Year % 100 != 0 ) ) {
        $Lengths[1] = 29;
    }
    return $Lengths[ $Month - 1 ];
}
