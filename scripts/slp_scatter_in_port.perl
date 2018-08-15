#!/usr/bin/perl 

# Look at the SD v. no. of simultanious obs for ships in Portsmouth

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;

my @Dim = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

# Get the pressure, ship and date for obs in Portsmouth
my (%Pressure);
while ( my $ob = imma_read( \*STDIN ) ) {
    unless (
           defined( $ob->{LON} )
        && abs( $ob->{LON} - -1.1 ) < 0.1
        && defined( $ob->{LAT} )
        && abs( $ob->{LAT} - 50.8 ) < 0.1
        && defined( $ob->{YR} )
        && defined( $ob->{MO} )
        && defined( $ob->{DY} )
        && defined( $ob->{HR} )
        && defined( $ob->{ID} )
        && defined( $ob->{LI} )
        && $ob->{LI} == 6    # Position from metadata
        && defined( $ob->{SLP} )
      )
    {
        next;
    }
    my $Date = sprintf "%04d%02d%02d%02d", $ob->{YR}, $ob->{MO}, $ob->{DY},
      int( $ob->{HR} );
    $Pressure{$Date}{ $ob->{ID} } = $ob->{SLP};
#    print "$Date $ob->{LAT} $ob->{LON}\n";
}

for ( my $Year = 1938 ; $Year <= 1947 ; $Year++ ) {
    for ( my $Month = 1 ; $Month <= 12 ; $Month++ ) {
        for ( my $Day = 1 ; $Day <= $Dim[ $Month - 1 ] ; $Day++ ) {
            for ( my $Hour = 0 ; $Hour < 24 ; $Hour++ ) {
                my $Date = sprintf "%04d%02d%02d%02d", $Year, $Month, $Day,
                  $Hour;
                my $Count = scalar( keys( %{ $Pressure{$Date} } ) );
                unless ( defined($Count) ) { $Count = 0; }
                printf "%s %d\n", $Date, $Count;
            }
        }
    }
}
