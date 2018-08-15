#!/usr/bin/perl -w

# Count the number of observations with the ship at sea

use strict;
use warnings;

use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;

my ( $Sea_d, $Sea_i, $Sea_m );
while ( my $ob = imma_read( \*STDIN ) ) {
    if ( substr( $ob->{SUPD}, 19, 20 ) =~ /\w/ ) { next; }    # In port
    if ( defined( $ob->{LAT} ) && defined( $ob->{LON} ) ) {
        if ( $ob->{LI} == 3 ) { $Sea_i++; }
        else { $Sea_d++; }
    }
    else { $Sea_m++; }
}

print "$Sea_d $Sea_i $Sea_m\n";

