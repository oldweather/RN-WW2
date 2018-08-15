#!/usr/bin/perl 

# Make a web index page for the companion ship figures

use strict;
use warnings;
use FindBin;
use File::Basename;

chdir "$FindBin::Bin" or die;

my @Ships = glob("../figs/*.slp.sc.png");

print "<table cellpadding=3>\n";
print "<tr><th>Ship</th>"
  . "<th><Pressure</th>"
  . "<th>SST</th>"
  . "<th>Air temperature</th></tr>\n";
foreach my $Ship ( sort(@Ships) ) {
    $Ship = basename($Ship);
    $Ship =~ s/\.slp.sc.png//;
    print "<tr>";

    # Ship name
    my $Shn = $Ship;
    $Shn =~ s/_+$//;
    $Shn =~ s/_/ /g;
    print "<th>$Shn</th>\n";
    foreach my $Var (qw(slp sst at)) {
        print "  <td>";
        if ( -r "../figs/$Ship.$Var.ts.png" ) {
            print "<a href=\"../figs/$Ship.$Var.ts.png\">Time series</a>";
        }
        if ( -r "../figs/$Ship.$Var.sc.png" ) {
            print "<br><a href=\"../figs/$Ship.$Var.sc.png\">Scatter plot</a>";
        }
        print "</td>\n";
    }
    print "</tr>\n";
}
print "</table>\n";

