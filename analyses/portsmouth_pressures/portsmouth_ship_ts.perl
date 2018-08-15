#!/usr/bin/perl 

# Look at the SD v. no. of simultanious obs for ships in Portsmouth

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;

my @Dim = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

# Get the pressure, ship and date for obs in Portsmouth
my ( %Pressure, %Ships );
while ( my $ob = imma_read( \*STDIN ) ) {
    unless (
           defined( $ob->{LON} )
        && abs( $ob->{LON} - -1.1 ) < 0.1
        && defined( $ob->{LAT} )
        && abs( $ob->{LAT} - 50.8 ) < 0.1
        && defined( $ob->{YR} )
        && $ob->{YR} == 1938
        && defined( $ob->{MO} )
        && ( $ob->{MO} == 8 || $ob->{MO} == 9 )
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
    $Ships{ $ob->{ID} } = 1;
}

foreach my $Ship ( sort keys(%Ships) ) {
    print "'-' using 1:2 title '$Ship',\\\n";
}
foreach my $Ship ( sort keys(%Ships) ) {
    foreach my $Date ( sort( keys(%Pressure) ) ) {
        if ( defined( $Pressure{$Date}{$Ship} ) ) {
            printf "%s %d\n", $Date, $Pressure{$Date}{$Ship};
        }
    }
    print "e\n";
}
