#!/usr/bin/perl 

# Convert an IMMA file into an XML file to be used with google maps.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use FindBin;
use Time::Local;

my $Ship_name = $ARGV[0];

# Make an XML entity for all the obs from this ship
my $Start_date = timelocal( 0,  0,  0,  1,  0,  1938 );
my $End_date   = timelocal( 59, 59, 23, 31, 11, 1947 );
open( DIN, "$FindBin::Bin/../imma_files/sorted_by_ship/$Ship_name.imma" )
  or die "No obs for ship $Ship_name";
print "<markers>\n";
my $First_at;
#my $Count=0;
lo_ob: while ( my $ob = imma_read( \*DIN ) ) {

    foreach (qw(YR MO DY HR LAT LON)) {
        unless ( defined( $ob->{$_} ) ) { next lo_ob; }
    }

    if ( defined($First_at) ) {
        if (   $ob->{LAT} == $First_at->{LAT}
            && $ob->{LON} == $First_at->{LON} )
        {
            $First_at->{End_date} = sprintf "%04d/%02d/%02d:%02d", $ob->{YR},
              $ob->{MO}, $ob->{DY}, $ob->{HR};
            next;
        }
        else {
#            if($Count++%100==0) {
                print_ob($First_at);
#            }
            $First_at = $ob;
        }
    }
    else {
        $First_at = $ob;
    }

}
if ( defined($First_at) ) {
    print_ob($First_at);
}
close(DIN);
print "</markers>\n";

sub print_ob {
    my $ob = shift;
    printf "<marker lat=\"%f\" lng=\"%f\" type=\"%d\" ", $ob->{LAT}, $ob->{LON},
      $ob->{LI};
    my $Date = sprintf "%04d/%02d/%02d:%02d", $ob->{YR}, $ob->{MO}, $ob->{DY},
      $ob->{HR};
    if($ob->{LI}==6) { printf "port=\"%s\" ",substr($ob->{SUPD},19,20); }
    if ( defined( $ob->{End_date} ) ) {
        $Date .= " to $ob->{End_date}";
    }
    printf "name=\"%s\" date=\"%s\" />\n", $Ship_name, $Date;
}
