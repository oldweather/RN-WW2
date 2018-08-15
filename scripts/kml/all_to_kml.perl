#!/usr/bin/perl

# Convert each ship IMMA file to a KML file

use strict;
use warnings;
use IMMA;
use FindBin;
use File::Basename;

my $Colour = 1;
foreach my $InFile ( glob("$FindBin::Bin/../imma_files/sorted_by_ship/*.imma") )
{
    my $Ship = basename($InFile);
    $Ship =~ s/\.imma//;
    if(-r "$FindBin::Bin/../kml_files/$Ship.kml") { next; }
    `imma_to_kml.perl --firstcolour=$Colour --title=\"$Ship\" < \"$InFile\" > \"$FindBin::Bin/../kml_files/$Ship.kml\"`;
    $Colour++;
    if ( $Colour > 28 ) { $Colour = 1; }
}
