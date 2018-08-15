#!/usr/bin/perl -w

# Convert all the obs to IMMA format - ship by ship

use strict;
use warnings;
use FindBin;
use File::Basename;

my @Ships = <$FindBin::Bin/../ncdc_txt/sorted_by_ship/*>;

foreach my $Ship (@Ships) {
    my $Sp = sprintf "%s", basename($Ship);
    unless ( $Sp =~ /\w/ ) { next; }
    print "$Sp\n";
    #`$FindBin::Bin/text_to_imma.perl --name=\"$Sp\" < \"$Ship\" 1> \"$FindBin::Bin/../imma_files/sorted_by_ship/$Sp.imma\" 2> \"$FindBin::Bin/../imma_files/conversion_errors/$Sp.imma.errs\"`;
    #`$FindBin::Bin/imma_interpolate.perl < \"$FindBin::Bin/../imma_files/sorted_by_ship/uninterpolated/$Sp.imma\" > \"$FindBin::Bin/../imma_files/sorted_by_ship/$Sp.imma\"`;
    #`$FindBin::Bin/../../imma/rdimma0/rdimma < \"$FindBin::Bin/../imma_files/sorted_by_ship/$Sp.imma\" > /dev/null`;
    #`mv fort.10 \"$FindBin::Bin/../imma_files/sorted_by_ship/summaries/$Sp.summary\"`;
    `$FindBin::Bin/grid_voyage_from_imma.perl \"$Sp\"`;
    `pp_map --range=[1938:1947] --term=\"png size 900,500\" \"$FindBin::Bin/../gridded_fields/ship_routes/$Sp.pp\" > \"$FindBin::Bin/../docs/ship_figures/$Sp.route.png\"`;
    `$FindBin::Bin/plot_position_type.perl --term=\"png size 900,500\" < \"$FindBin::Bin/../imma_files/sorted_by_ship/$Sp.imma\" > \"$FindBin::Bin/../docs/ship_figures/$Sp.position_type.png\"`;
}
