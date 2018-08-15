#!/usr/bin/perl

# Apply bucket_corrections to the new gridded SST datasets

use strict;
use warnings;
use lib "$ENV{PP_PERL}";
use PP;

my $Corrections_file =
    "/ibackup/cr1/hadobs/icoads/mds2.1_datasets/bias_corrections/SST/"
  . "data/bucket_median_HadSST2_newclim_HadNAT2_1+allunc_WW2adj_stn.pp";

open( DIN, $Corrections_file ) or die "Couldn't open corrections file";
my @Bc;
while ( my $pp = pp_read( \*DIN ) ) {
    $Bc[ $pp->{lbyr} ][ $pp->{lbmon} ] = $pp;
}
close(DIN);

while ( my $pp = pp_read( \*STDIN ) ) {
    if ( defined( $Bc[ $pp->{lbyr} ][ $pp->{lbmon} ] ) ) {
        $pp = pp_add( $pp, $Bc[ $pp->{lbyr} ][ $pp->{lbmon} ] );
    }
    $pp->write_to_file( \*STDOUT );
}
