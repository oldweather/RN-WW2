#!/usr/bin/perl 

# Clean any blank lines out of the IMMA files

use strict;
use warnings;
use FindBin;

chdir "$FindBin::Bin/../imma_files/sorted_by_ship" or die;
my @Files = glob("*_(*).imma");
foreach my $File (@Files) {
    open( DIN,  $File )      or die "Can't open $File";
    open( DOUT, ">tmp.out" ) or die;
    while (<DIN>) {
        unless ( $_ =~ /\d/ ) { next; }
        print DOUT "$_";
    }
    close DOUT;
    close DIN;
    `mv tmp.out "$File"`;
}
