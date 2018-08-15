#!/usr/bin/perl

# Convert the wind speeds to WMO 1100 midpoints

use strict;
use warnings;
use File::Basename;
use FindBin;

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

my @Ships = <$FindBin::Bin/../imma_files/sorted_by_ship/*.imma>;

foreach my $Ship (@Ships) {
    my $Sp = sprintf "%s", basename($Ship);
    print "$Sp\n";
    my $Infh;
    open( $Infh, "<", $Ship ) or die "Can't open $Ship";
    my $Opfh;
    open( $Opfh, ">", "$Ship.tmp" ) or die "Can't open $Ship.tmp";

    for my $Record (<$Infh>) {
        if ( length($Record) < 53 ) { next; }
        my ( $Start, $Wind, $End ) =
          unpack( sprintf( "A50 A3 A%d", length($Record) - 52 ), $Record );
        if ( $Wind =~ /\d/ ) {
            if ( defined( $Conversion{$Wind} ) ) {
                printf $Opfh "%50s%3s%s\n", $Start, $Conversion{$Wind}, $End;
            }
            else {
                die "Unexpected wind value $Wind";
            }
        }
        else {    # Wind missing
            print $Opfh "$Record";
        }
    }
    close($Infh);
    close($Opfh);

    #    `$FindBin::Bin/convert_wind_speeds.perl < "$Ship" > "$Opfile"`;
    `mv "$Ship.tmp" "$Ship"`;
}
