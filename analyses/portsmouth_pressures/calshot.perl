#!/usr/bin/perl -w

my @Dim = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

while (<>) {
    @fields = split;
    for ( my $i = 4 ; $i < 11 ; $i++ ) {
        $Day = $fields[3];
        $Mo  = $fields[2];
        $Hr  = ( $i - 4 ) * 3 + 9;
        if ( $Hr > 23 ) {
            $Hr -= 24;
            $Day++;
            if ( $Day > $Dim[ $Mo - 1 ] ) {
                $Mo++;
                $Day = 1;
            }
        }
        $Date = sprintf "%04d%02d%02d%02d", $fields[1], $Mo, $Day, $Hr;
        if ( $fields[$i] < 9000 ) { print "$Date $fields[$i]\n"; }
    }
}
