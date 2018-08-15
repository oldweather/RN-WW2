#!/usr/bin/perl 

# Make the ship-specific web pages

use strict;
use warnings;
use FindBin;
use File::Basename;

my @Ships = <$FindBin::Bin/../gridded_fields/ship_routes/*.pp>;

foreach my $Ship (@Ships) {
    $Ship = basename($Ship);
    $Ship =~ s/\.pp//;

    make_route_file($Ship);
}

# Make the index page
open( DOUT, ">$FindBin::Bin/../docs/by_ship/index.html" )
  or die "Can't open html file for index";
print DOUT "<html>\n";
print DOUT "<head>\n";
print DOUT "<title>Observations sorted by ship</title>\n";
print DOUT "</head>\n";
print DOUT "<body bgcolor=white>\n";
print DOUT
  "<small><a href=\"../index.html\">New observations page</a></small>\n";
print DOUT "<center><h1>Data sorted by ship</h1></center>\n";
print DOUT "<table cellpadding=3>\n";

foreach my $Ship (@Ships) {
    $Ship = basename($Ship);
    $Ship =~ s/\.pp//;
    print DOUT "<tr><td><strong>$Ship</strong></td>"
      . "<td><a href=\"$Ship.route.html\">Route image</a></td>";

    #      if ( -r "$FindBin::Bin/../docs/clive_directory/by_ship/$Ship.html" )
    #    {
    #        print DOUT "<td><a href=\"../clive_directory/by_ship/$Ship.html\">"
    #          . "Directory entry</a></td>";
    #    }
    print DOUT
      "<td><a href=\"../../imma_files/sorted_by_ship/$Ship.imma\">Observations</a></td>";
    print DOUT
      "<td><a href=\"../../imma_files/sorted_by_ship/summaries/$Ship.summary\">Obs. summary</a></td>";

#print DOUT
#  "<td><a href=\"../../imma_files/conversion_errors/$Ship.imma.errs\">Obs.conversion errors</a></td>";
    print DOUT "</tr>\n";
}
print DOUT "</table>\n";
print DOUT "<p><hr>\n";
print DOUT "Last updated: 2007-12-31<br>\n";
print DOUT
  "Maintained by: <a href=\"mailto:philip.brohan\@metoffice.com\">Philip Brohan</a>.\n";
print DOUT "</body>\n</html>\n";
close(DOUT);

sub make_route_file {

    my $Ship = shift;

    open( DOUT, ">$FindBin::Bin/../docs/by_ship/$Ship.route.html" )
      or die "Can't open route file for $Ship";

    print DOUT "<html>\n";
    print DOUT "<head>\n";
    print DOUT "<title>Route 1938-47 for $Ship</title>\n";
    print DOUT "</head>\n<body>\n";
    print DOUT "<small><a href=\"index.html\">Ship index</a></small>\n";
    print DOUT "<center><h1>Route of HMS $Ship</h1></center>\n";
    print DOUT
      "<center><img src=\"../ship_figures/$Ship.route.png\" height=500 width=900></center>\n";
    print DOUT
      "<center><img src=\"../ship_figures/$Ship.position_type.png\" height=500 width=900></center>\n";
    print DOUT "<p><hr>\n";
    print DOUT "Last updated: 2007-12-31<br>\n";
    print DOUT
      "Maintained by: <a href=\"mailto:philip.brohan\@metoffice.com\">Philip Brohan</a>.\n";
    print DOUT "</body></html>\n";
    close(DOUT);

}
