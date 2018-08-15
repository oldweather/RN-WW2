#!/usr/bin/perl -w

# Extract a list of all the ports given as locations in the
#  new digitised marine obs.

use strict;
use warnings;

my @Files = <../ncdc_txt/as_received/*.txt>;
my %Ports;
foreach my $File (@Files) {
    open( DIN, $File ) or die "Can't open $File";

    while (<DIN>) {

        if ( $_ =~ /^2/ ) {    # Data line
            my $Port = substr( $_, 19, 20 );
            if ( $Port =~ /\w/ ) {
                $Ports{$Port}++;
            }
        }

    }
    close(DIN);

}

foreach ( sort( { $Ports{$b} <=> $Ports{$a} } keys(%Ports) ) ) {
    print "$_ $Ports{$_}\n";
}
