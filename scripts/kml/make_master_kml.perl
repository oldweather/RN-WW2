#!/usr/bin/perl 

# Make a master KML file for all the WW2 RN ships

use strict;
use warnings;
use FindBin;
use File::Basename;

print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<kml xmlns=\"http://earth.google.com/kml/2.2\">\n";
print "  <Document>\n";
print "    <name>New RN WW2 obs.</name>\n";
print "    <description>\n";
print
  "     This file contains 3 million placemarks - don't load all the ships at once.\n";
print "    </description>\n";
print "    <open>0</open>\n";

my $Colour=1;
foreach my $InFile ( glob("$FindBin::Bin/../imma_files/sorted_by_ship/*.imma") ) {
    my $Ship = basename($InFile);
    $Ship =~ s/\.imma//;

    print "    <NetworkLink>\n";
    print "      <name>$Ship</name>\n";
    print "      <open>0</open>\n";
    print "      <visibility>0</visibility>\n";
    print "      <Link>\n";
    print "      <href>\n";
    print
      "        http://brohan.org/cgi-bin/imma/imma_to_kml.cgi?".
      "title=$Ship;firstcolour=$Colour;file=".
      "/home/philip/public_html/job/digitisation/rn_ww2_data/imma_files/sorted_by_ship/$Ship.imma\n";
    print "      </href>\n";
    print "      <refreshMode>onChange</refreshMode> \n";
    print "      <viewRefreshMode>never</viewRefreshMode> \n";
    print "      </Link>\n";
    print "    </NetworkLink>\n";
    $Colour++;
    if($Colour>28) { $Colour=1; }
}
print " </Document>\n";
print "</kml>\n";
