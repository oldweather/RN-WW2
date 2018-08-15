#!/usr/bin/perl -w

# Count the number of observations with the ship in port

use strict;
use warnings;

use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;

my ( $Port_p, $Port_t );
while ( my $ob = imma_read( \*STDIN ) ) {
    if ( substr( $ob->{SUPD}, 19, 20 ) =~ /\w/ ) {    # In port
        $Port_t++;
        if ( defined( $ob->{LAT} ) && defined( $ob->{LON} ) ) {
            $Port_p++;
        }
    }
}

print "$Port_t $Port_p\n";

