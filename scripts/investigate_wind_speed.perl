#!/usr/bin/perl -w

# Count the number of observations with the ship in port

use strict;
use warnings;
use IMMA;

while ( my $ob = imma_read( \*ARGV ) ) {
    if ( substr( $ob->{SUPD}, 19, 20 ) =~ /\w/ ) {    # In port
        print "1 ";
    }
    else {
        print "0 ";
    }
    if ( defined( $ob->{ID} ) ) {
        printf "%9s ", $ob->{ID};
    }
    else {
        print "       NA ";
    }
    for my $Var (qw(LONG LAT W)) {
        if ( defined( $ob->{$Var} ) ) {
            printf "%6.1f ", $ob->{$Var};
        }
        else {
            print "    NA ";
        }
    }
    print "\n";
}

