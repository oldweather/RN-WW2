#!/usr/bin/perl

# Make a PP field showing the route of a selected ship over
#  1938-47

use strict;
use warnings;
use lib "$ENV{PP_PERL}";
use PP;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module";
use IMMA;
use FindBin;
use Time::Local;

my $Ship_name = $ARGV[0];

# Make an empty 1x1 degree grid to put the positions on
my $pp_grid = pp_create(
    lbyr   => 1938,
    lbmon  => 1,
    lbdat  => 1,
    lbyrd  => 1947,
    lbmond => 12,
    lbdatd => 31,
    lbnpt  => 360,
    lbrow  => 180,
    lbcode => 2,
    lbrel  => 2,
    lbfc   => 0,
    bgor   => 0,
    bplat  => 90.0,
    bplon  => 0.0,
    lbtim  => 21,
    bzy    => -90.5,
    bdy    => 1.0,
    bzx    => -180.0,
    bdx    => 1,
    bmdi   => -1.0e30,
    lblrec => 360 * 180,
    bmks   => 1,
    lbfc   => 0,
    lbhem  => 0
);
for ( my $i = 0 ; $i < 180 ; $i++ ) {
    for ( my $j = 0 ; $j < 360 ; $j++ ) {
        ${ $pp_grid->{data} }[$i][$j] = $pp_grid->{bmdi};
    }
}

# Grid all the obs for this ship
my $Start_date = timelocal( 0,  0,  0,  1,  0,  1938 );
my $End_date   = timelocal( 59, 59, 23, 31, 11, 1947 );
open( DIN, "$FindBin::Bin/../imma_files/sorted_by_ship/$Ship_name.imma" )
  or die "No obs for ship $Ship_name";
lo_ob: while ( my $ob = imma_read( \*DIN ) ) {

    foreach (qw(YR MO DY HR LAT LON)) {
        unless ( defined( $ob->{$_} ) ) { next lo_ob; }
    }
    unless ( checkday( $ob->{YR}, $ob->{MO}, $ob->{DY} ) ) { next; }

    if ( $ob->{YR} < 1938 || $ob->{YR} > 1947 ) { next; }
    my $Date =
      ( timelocal( 0, 0, $ob->{HR}, $ob->{DY}, $ob->{MO} - 1, $ob->{YR} ) -
          $Start_date ) / ( $End_date - $Start_date );
    my $Xloc = int( ( $ob->{LON} + 180 ) );
    my $Yloc = int( ( $ob->{LAT} + 90 ) );
    $Date = 1938 + $Date * 10;
    ${ $pp_grid->{data} }[$Yloc][$Xloc] = $Date;
}
close(DIN);

open( DOUT, ">$FindBin::Bin/../gridded_fields/ship_routes/$Ship_name.pp" )
  or die "Can't open route PP file for $Ship_name";
$pp_grid->write_to_file( \*DOUT );
close(DOUT);

sub checkday {
    my $year  = shift;
    my $month = shift;
    my $day   = shift;
    if ( $day > month_lengths( $month, $year ) ) {
        return;
    }
    return 1;
}

sub month_lengths {
    my $Month   = shift;
    my $Year    = shift;
    my @Lengths = qw(31 28 31 30 31 30 31 31 30 31 30 31);
    if ( $Year % 400 == 0 || ( $Year % 4 == 0 && $Year % 100 != 0 ) ) {
        $Lengths[1] = 29;
    }
    return $Lengths[ $Month - 1 ];
}

