#!/usr/bin/perl -w

# Convert the (degrees-minutes-seconds) locations file into a
#  decimal degrees format.

while (<>) {
    unless ( $_ =~
        /^(....................)\s+\d+\s+([\s\d]+)°([\s\d]+)\'([\s\d]+)\'\' ([NS]), +([\s\d]+)°([\s\d]+)\'([\s\d]+)\'\' ([WE])/
      )
    {
        warn "Bad line: $_";
        next;
    }
    my $Ship = $1;
    my $Lat  = $2 + $3 / 60 + $4/3600;
    if ( $5 eq 'S' ) { $Lat *= -1; }
    my $Lon = $6 + $7 / 60 + $8/3600;
    if ( $9 eq 'W' ) { $Lon *= -1; }
    printf "%s\t%6.1f\t%5.1f\n", $Ship, $Lon, $Lat;
}
