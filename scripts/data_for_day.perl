#!/usr/bin/perl

# Extract all the observations for a particular day

use strict;
use warnings;
use IMMA;
use FindBin;
use File::Basename;
use Getopt::Long;

my $Date;
GetOptions( "day=s" => \$Date );
unless ( defined($Date) && $Date =~ /(\d\d\d\d)\/(\d\d)\/(\d\d)/ ) {
    die "Require option --day=yyyy/mm/dd";
}
my ( $Year, $Month, $Day ) = ( $1, $2, $3 );

my @Ships = <$FindBin::Bin/../imma_files/sorted_by_ship/*>;

my %Counts;
foreach my $Ship (@Ships) {
    my $Sp = sprintf "%s", basename($Ship);
    open( DIN, "$Ship" ) or die "Can't open $Sp";
    my $Count = 0;
    while ( my $ob = imma_read( \*DIN ) ) {
        unless ( defined( $ob->{YR} )
            && $ob->{YR} == $Year
            && defined( $ob->{MO} )
            && $ob->{MO} == $Month
            && defined( $ob->{DY} )
            && $ob->{DY} == $Day )
        {
            next;
        }
        $ob->write( \*STDOUT );
    }
    close(DIN);
}

