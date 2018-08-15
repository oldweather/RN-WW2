#!/usr/bin/perl

# Change wind speeds for the RN WW2 IMMA observations from
#  the range midpoints I calculated to those recommended
#  for use in ICOADS (WMO 1100)

my %Conversion = (
    '   ' => '   ',
    '  0' => '  0',
    '  8' => ' 10',
    ' 10' => ' 10',
    ' 24' => ' 26',
    ' 26' => ' 26',
    ' 42' => ' 46',
    ' 43' => ' 46',
    ' 46' => ' 46',
    ' 67' => ' 67',
    ' 93' => ' 93',
    '123' => '123',
    '155' => '154',
    '154' => '154',
    '189' => '190',
    '190' => '190',
    '226' => '226',
    '264' => '268',
    '268' => '268',
    '305' => '309',
    '309' => '309',
    '327' => '350',
    '350' => '350',
);

for my $Record (<ARGV>) {
    if ( length($Record) < 53 ) { next; }
    my ( $Start, $Wind, $End ) =
      unpack( sprintf( "A50 A3 A%d", length($Record) - 52 ), $Record );
    if ( $Wind =~ /\d/ ) {
        if ( defined( $Conversion{$Wind} ) ) {
            printf "%50s%3s%s\n", $Start, $Conversion{$Wind}, $End;
        }
        else {
            die "Unexpected wind value $Wind";
        }
    }
    else {    # Wind missing
        print "$Record";
    }
}
