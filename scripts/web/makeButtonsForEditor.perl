#!/usr/bin/perl 

# Make load links for each ship - to be pasted into the IMMA editor.

use strict;
use warnings;
use FindBin;
use File::Basename;

my @Ships = <$FindBin::Bin/../imma_files/sorted_by_ship/*.imma>;

foreach my $Ship (@Ships) {
    my $Sp = sprintf "%s", basename($Ship);
    my @Fields = split /[\s_]+/, $Sp;
    my $Sp2 = ucfirst( lc( $Fields[0] ) );
    $Sp2 =~ s/\.imma//;
    for ( my $i = 1 ; $i < scalar(@Fields) ; $i++ ) {
        $Sp2 .= " " . ucfirst( lc( $Fields[$i] ) );
    }
    print "<li>$Sp2<br>&nbsp;&nbsp;";
    printf "<a href=\"javascript:loadData('../imma_files/sorted_by_ship/before_qc/"
      . "%s','%s - before QC')\">-QC &nbsp;</a>\n", $Sp, $Sp2;
    printf "<a href=\"javascript:loadData('../imma_files/sorted_by_ship/uninterpolated/"
      . "%s','%s - after QC')\">+QC &nbsp;</a>\n", $Sp, $Sp2;
    printf "<a href=\"javascript:loadData('../imma_files/sorted_by_ship/"
      . "%s','%s - after QC and interpolation')\">+Interp.</a></li>\n\n", $Sp, $Sp2;
}

