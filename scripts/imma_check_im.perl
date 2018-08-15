#!/usr/bin/perl

# Check that each IMMA file has IM set correctly

#use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module/";
use IMMA;
use FindBin;
use File::Basename;

my @Ships = <$FindBin::Bin/../imma_files/sorted_by_ship/*>;

foreach my $Ship (@Ships) {
    my $Sp = sprintf "%s", basename($Ship);
    print "$Sp\n";
    open( DIN, "$Ship" ) or die "Can't open $Sp";
    my $Count = 0;
    while ( my $ob = imma_read( \*DIN ) ) {
        unless ( defined( $ob->{IM} ) && $ob->{IM} == 0 ) { $Count++; }
    }
    close(DIN);
    print "$Count\n";
}
