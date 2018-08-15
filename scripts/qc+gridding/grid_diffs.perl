#!/usr/bin/perl

# Make a gridded datasets showing differences between the ICOADS
#  and new digitised WW2 data

use strict;
use warnings;
use lib "$ENV{PP_PERL}";
use PP;
use FindBin;
use Getopt::Long;

my $Parameter = 'sst';
GetOptions( "parameter=s" => \$Parameter );
$Parameter = lc($Parameter);
unless ( $Parameter eq 'sst'
    || $Parameter eq 'nat'
    || $Parameter eq 'dat'
    || $Parameter eq 'pre' )
{
    die "--parameter must be sst, nat, dat or pre";
}

my $Old_file;
if ( $Parameter eq 'sst' ) {
    $Old_file = "$ENV{OBSDIR}/marine/HadSST2/anomalies/5x5/HadSST2.pp";
}
elsif ( $Parameter eq 'nat' ) {
    $Old_file =
      "$ENV{OBSDIR}/../icoads/mds2.1_datasets/NAT/5x5/ICNAT3A.pp";
}
elsif ( $Parameter eq 'dat' ) {
    $Old_file =
      "$ENV{OBSDIR}/../icoads/mds2.1_datasets/DAT/5x5/ICDAT2A.pp";
}
elsif ( $Parameter eq 'pre' ) {
    $Old_file =
      "$ENV{OBSDIR}/../icoads/mds2.1_datasets/pressure/5x5/pressure_anomaly.pp";
}
my $New_file = "$FindBin::Bin/../../gridded_fields/$Parameter/5x5/new.pp";

open( DIN_O, $Old_file ) or die "Can't open $Old_file";
open( DIN_N, $New_file ) or die "Can't open $New_file";
open( DOUT, ">$FindBin::Bin/../../gridded_fields/$Parameter/5x5/diffs.pp" )
  or die "Can't open output file";

while ( my $new = pp_read( \*DIN_N ) ) {
    my $old = pp_read( \*DIN_O ) or die "Unexpected end of old data";
    while ($old->{lbyr} != $new->{lbyr}
        || $old->{lbmon} != $new->{lbmon} )
    {
        $old = pp_read( \*DIN_O ) or die "Unexpected end of old data";
    }
    for ( my $i = 0 ; $i < $new->{lbrow} ; $i++ ) {
        for ( my $j = 0 ; $j < $new->{lbnpt} ; $j++ ) {
            if (   $new->{data}->[$i][$j] != $new->{bmdi}
                && $old->{data}->[$i][$j] != $old->{bmdi} )
            {
                $new->{data}->[$i][$j] -= $old->{data}->[$i][$j];
            }
            else {
                $new->{data}->[$i][$j] = $new->{bmdi};
            }
        }
    }
    $new->write_to_file( \*DOUT );
}
