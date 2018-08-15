#!/usr/bin/perl 

# Find sets of ships travelling in company
# (within 0.2 degrees in lat and long)

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;

my %Company;
my %Slp;
my %Sst;
my %At;
while ( my $ob = imma_read( \*STDIN ) ) {
    unless (
           defined( $ob->{LON} )
        && defined( $ob->{LAT} )
        && defined( $ob->{YR} )
        && defined( $ob->{MO} )
        && defined( $ob->{DY} )
        && defined( $ob->{HR} )
        && defined( $ob->{ID} )
        && defined( $ob->{LI} )
        && $ob->{LI} != 6    # Not in port
      )
    {
        next;
    }
    my $Date = sprintf "%04d%02d%02d%02d", $ob->{YR}, $ob->{MO}, $ob->{DY},
      int( $ob->{HR} );
    my $Lat = int($ob->{LAT} * 10);
    if ( $Lat % 2 == 1 ) { $Lat += 1; }
    my $Lon = int($ob->{LON} * 10);
    if ( $Lon % 2 == 1 ) { $Lon += 1; }

    #    for ( my $i = -1 ; $i <= 1 ; $i++ ) {
    #        for ( my $j = -1 ; $j <= 1 ; $j++ ) {
    $Company{$Date}{$Lat}{$Lon}{ $ob->{ID} } = 1;
    if ( defined( $ob->{SLP} ) ) {
        $Slp{$Date}{$Lat}{$Lon}{ $ob->{ID} } = $ob->{SLP};
    }

    if ( defined( $ob->{SST} ) ) {
        $Sst{$Date}{$Lat}{$Lon}{ $ob->{ID} } = $ob->{SST};
    }
    if ( defined( $ob->{AT} ) ) {
        $At{$Date}{$Lat}{$Lon}{ $ob->{ID} } = $ob->{AT};
    }

    #        }
    #    }
}

foreach my $Date ( sort keys(%Company) ) {
    foreach my $Lat ( sort keys( %{ $Company{$Date} } ) ) {
        foreach my $Lon ( sort keys( %{ $Company{$Date}{$Lat} } ) ) {
            if ( scalar( keys( %{ $Company{$Date}{$Lat}{$Lon} } ) ) > 1 ) {
                print "$Date: $Lat $Lon ";
                foreach my $Ship ( keys( %{ $Company{$Date}{$Lat}{$Lon} } ) ) {
                    $Ship =~ s/ /_/g;
                    print "$Ship ";
                }
                foreach my $Ship ( keys( %{ $Company{$Date}{$Lat}{$Lon} } ) ) {
                    if ( defined( $Slp{$Date}{$Lat}{$Lon}{$Ship} ) ) {
                        printf "%7.1f ", $Slp{$Date}{$Lat}{$Lon}{$Ship};
                    }
                    else {
                        print "      _ ";
                    }
                }
                foreach my $Ship ( keys( %{ $Company{$Date}{$Lat}{$Lon} } ) ) {
                    if ( defined( $Sst{$Date}{$Lat}{$Lon}{$Ship} ) ) {
                        printf "%5.1f ", $Sst{$Date}{$Lat}{$Lon}{$Ship};
                    }
                    else {
                        print "    _ ";
                    }
                }
                foreach my $Ship ( keys( %{ $Company{$Date}{$Lat}{$Lon} } ) ) {
                    if ( defined( $At{$Date}{$Lat}{$Lon}{$Ship} ) ) {
                        printf "%5.1f ", $At{$Date}{$Lat}{$Lon}{$Ship};
                    }
                    else {
                        print "    _ ";
                    }
                }
                print "\n";
            }
        }
    }
}

