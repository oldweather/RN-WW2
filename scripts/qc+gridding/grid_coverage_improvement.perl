#!/usr/bin/perl

# Make a gridded dataset comparing coverage improvement over ICOADS
#  from the new digitised WW2 data

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

my $New_file = "$FindBin::Bin/../../gridded_fields/$Parameter/5x5/coverage.pp";
open( DIN_N, $New_file )
  or die "Can't open $New_file";

my $Total = 0;
my $Result;
while ( my $new = pp_read( \*DIN_N ) ) {
    unless ( $new->{lbyr} == 1938
        || ( $new->{lbyr} >= 1941 && $new->{lbyr} <= 1947 ) )
    {
        next;
    }
    unless ( defined($Result) ) { $Result = pp_copy($new); }
    for ( my $i = 0 ; $i < $new->{lbrow} ; $i++ ) {
        for ( my $j = 0 ; $j < $new->{lbnpt} ; $j++ ) {
            if ( $Total == 0 ) { $Result->{data}->[$i][$j] = $Result->{bmdi}; }
            if ( $new->{data}->[$i][$j] == 1 ) {
                if ( $Result->{data}->[$i][$j] == $Result->{bmdi} ) {
                    $Result->{data}->[$i][$j] = 1;
                }
                else {
                    $Result->{data}->[$i][$j]++;
                }
            }
        }
    }
    $Total++;
}
close(DIN_N);
for ( my $i = 0 ; $i < $Result->{lbrow} ; $i++ ) {
    for ( my $j = 0 ; $j < $Result->{lbnpt} ; $j++ ) {
        if ( $Result->{data}->[$i][$j] != $Result->{bmdi} ) {
            $Result->{data}->[$i][$j] /= $Total;
        }
    }
}

open( DOUT,
    ">$FindBin::Bin/../../gridded_fields/$Parameter/5x5/coverage_improvement.pp" )
  or die "Can't open output file";
$Result->write_to_file( \*DOUT );
