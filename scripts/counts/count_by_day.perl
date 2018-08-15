#!/usr/bin/perl

# Count the number of observations in each calendar month

#use strict;
use warnings;
use IMMA;
use FindBin;
use File::Basename;

my @Ships = <$FindBin::Bin/../imma_files/sorted_by_ship/*>;

my %Counts;
foreach my $Ship (@Ships) {
    my $Sp = sprintf "%s", basename($Ship);
    open( DIN, "$Ship" ) or die "Can't open $Sp";
    my $Count = 0;
    while ( my $ob = imma_read( \*DIN ) ) {
        unless ( defined( $ob->{YR} )
            && defined( $ob->{MO} )
            && defined( $ob->{DY} ) )
        {
            next;
        }
        $Counts{ sprintf "%04d/%02d/%02d", $ob->{YR}, $ob->{MO}, $ob->{DY} }++;
    }
    close(DIN);
}

foreach my $Day ( sort( keys(%Counts) ) ) {
    printf "%s %d\n", $Day, $Counts{$Day};
}
