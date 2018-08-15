#!/usr/bin/perl -w

# Calculate annual number of obs and fractional coverage in HadSST2

use strict;
use warnings;
use lib "$ENV{PP_PERL}";
use PP;

open( DIN,
    "/ibackup/cr1/hadobs/OBS/marine/HadSST2/fixed_fields/cdc_NCEP_NEW_stn_anomaly_full_range_sea_only.pp"
  )
  or die;
my $Full_coverage_field = pp_read( \*DIN );
close(DIN);
my $Full_coverage = get_coverage($Full_coverage_field);

my ( @Nobs, @Coverage );
while ( my $pp = pp_read( \*STDIN ) ) {
    $Nobs[ $pp->{lbyr} ][ $pp->{lbmon} ]     += get_nobs($pp);
    $Coverage[ $pp->{lbyr} ][ $pp->{lbmon} ] +=
      get_coverage($pp) / $Full_coverage;
}
close(DIN);
for ( my $i = 1850 ; $i < scalar(@Nobs) ; $i++ ) {
    for ( my $j = 1 ; $j <= 12 ; $j++ ) {
        unless ( defined( $Nobs[$i][$j] ) ) {
            printf "%4d/%02d\n", $i, $j;
        }
        else {
            printf "%4d/%02d %d %g\n", $i, $j, $Nobs[$i][$j], $Coverage[$i][$j];
        }
    }
}

sub get_coverage {
    my $pp     = shift;
    my $Result = 0;
    for ( my $i = 0 ; $i < $pp->{lbrow} ; $i++ ) {
        my $Lat = $pp->{bzy} + ( $i + 1 ) * $pp->{bdy};
        my $Weight = cos( $Lat * 3.141592 / 180 );
        for ( my $j = 0 ; $j < $pp->{lbnpt} ; $j++ ) {
            if ( $pp->{data}->[$i][$j] != $pp->{bmdi} ) {
                $Result += $Weight;
            }
        }
    }
    return $Result;
}

sub get_nobs {
    my $pp     = shift;
    my $Result = 0;
    for ( my $i = 0 ; $i < $pp->{lbrow} ; $i++ ) {
        for ( my $j = 0 ; $j < $pp->{lbnpt} ; $j++ ) {
            if ( $pp->{data}->[$i][$j] != $pp->{bmdi} ) {
                $Result += $pp->{data}->[$i][$j];
            }
        }
    }
    return $Result;
}

