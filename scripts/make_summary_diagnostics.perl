#!/usr/bin/perl

# Make summary diagnostics for the new digitised data

use strict;
use warnings;
use FindBin;
use lib "$ENV{PP_PERL}";
use PP;
use PP::average;
use Getopt::Long;

# Gnuplot scripts need to be run from this directory
chdir "$FindBin::Bin" or die "Can't cd to working directory";

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

my $pp_map  = "/home/hc1300/hadpb/tasks/software/bin/pp_map";
my $gnuplot = "/home/hc0100/hadobs/tools/gnuplot-4.2rc1/bin/gnuplot";

# Make the coverage improvement plot
`$FindBin::Bin/qc+gridding/grid_coverage_improvement.perl --parameter=$Parameter`;
`$pp_map $FindBin::Bin/../gridded_fields/$Parameter/5x5/coverage_improvement.pp --term="png size 800,600" > $FindBin::Bin/../docs/coverage_improvement_$Parameter.png`;
`/usr/bin/mogrify -crop 695x365+75+125 $FindBin::Bin/../docs/coverage_improvement_$Parameter.png`;

# Make the nobs+coverage figs
`$FindBin::Bin/make_nobs+coverage.perl < ../gridded_fields/$Parameter/5x5/nobs_both.pp > ../docs/n+c_$Parameter\_withnew`;
if ( $Parameter eq 'sst' && !-r "../docs/n+c_sst_old" ) {
    `$FindBin::Bin/make_nobs+coverage.perl < $ENV{OBSDIR}/marine/HadSST2/anomalies/5x5/nobs.pp > ../docs/n+c_sst_old`;
}
if ( $Parameter eq 'nat' && !-r "../docs/n+c_nat_old" ) {
    `$FindBin::Bin/make_nobs+coverage.perl < $ENV{OBSDIR}/../icoads/mds2.1_datasets/NAT/5x5/nobs.pp > ../docs/n+c_nat_old`;
}
if ( $Parameter eq 'dat' && !-r "../docs/n+c_dat_old" ) {
    `$FindBin::Bin/make_nobs+coverage.perl < $ENV{OBSDIR}/../icoads/mds2.1_datasets/DAT/5x5/nobs.pp > ../docs/n+c_dat_old`;
}
if ( $Parameter eq 'dat' && !-r "../docs/n+c_pre_old" ) {
    `$FindBin::Bin/make_nobs+coverage.perl < $ENV{OBSDIR}/../icoads/mds2.1_datasets/pressure/5x5/nobs.pp > ../docs/n+c_pre_old`;
}

open( DOUT, "|$gnuplot 1>/dev/null 2>/dev/null" )
  or die "Can't start gnuplot";

#open( DOUT, ">tmp.gp" )
#  or die "Can't start gnuplot";
print DOUT "set term png size 695,365\n";
print DOUT "set output '../docs/n+c_$Parameter.png'\n";
print DOUT "set multiplot layout 2,1 upwards\n";
print DOUT "set grid\n";
print DOUT "set xdata time\n";
print DOUT "set timefmt '%Y/%m'\n";
print DOUT "set xrange ['1936/01':'1948/12']\n";
print DOUT "set format x '%Y/%m'\n";
print DOUT "set xlabel 'Date'\n";
print DOUT "set ylabel 'Number of obs.'\n";
print DOUT
  "plot '../docs/n+c_$Parameter\_old' using 1:2 title 'Original number of obs' w l lw 3 lt 1,\\\n"
  . "     '../docs/n+c_$Parameter\_withnew' using 1:2 title 'New number of obs.' w l lw 3 lt 3\n";
print DOUT "set ylabel 'Fractional coverage'\n";
print DOUT "unset xlabel\n";
print DOUT
  "plot     '../docs/n+c_$Parameter\_old' using 1:3 title 'Original coverage' w l lw 3 lt 1,\\\n"
  . "     '../docs/n+c_$Parameter\_withnew' using 1:3 title 'New coverage' w l lw 3 lt 3\n";
close(DOUT);

# Calculate the mean diffs and show a plot
my @Count;
my $Diffs;
open( DIN, "$FindBin::Bin/../gridded_fields/$Parameter/5x5/diffs.pp" )
  or die "Can't open diffs file.";
while ( my $pp = pp_read( \*DIN ) ) {
    unless ( defined($Diffs) ) {
        $Diffs = pp_copy($pp);
        for ( my $i = 0 ; $i < $Diffs->{lbrow} ; $i++ ) {
            for ( my $j = 0 ; $j < $Diffs->{lbnpt} ; $j++ ) {
                $Diffs->{data}->[$i][$j] = $Diffs->{bmdi};
            }
        }
    }
    for ( my $i = 0 ; $i < $Diffs->{lbrow} ; $i++ ) {
        for ( my $j = 0 ; $j < $Diffs->{lbnpt} ; $j++ ) {
            if ( $pp->{data}->[$i][$j] == $pp->{bmdi} )       { next; }
            if ( $Diffs->{data}->[$i][$j] == $Diffs->{bmdi} ) {
                $Diffs->{data}->[$i][$j] = $pp->{data}->[$i][$j];
                $Count[$i][$j] = 1;
            }
            else {
                $Diffs->{data}->[$i][$j] += $pp->{data}->[$i][$j];
                $Count[$i][$j]++;
            }
        }
    }
}
close(DIN);
for ( my $i = 0 ; $i < $Diffs->{lbrow} ; $i++ ) {
    for ( my $j = 0 ; $j < $Diffs->{lbnpt} ; $j++ ) {
        if ( $Diffs->{data}->[$i][$j] == $Diffs->{bmdi} ) { next; }
        $Diffs->{data}->[$i][$j] /= $Count[$i][$j];
    }
}
open( DOUT, ">$FindBin::Bin/../gridded_fields/$Parameter/5x5/mean_diffs.pp" )
  or die "Can't open mean diffs file";
$Diffs->write_to_file( \*DOUT );
close(DOUT);
`$pp_map --range=[-3:3] $FindBin::Bin/../gridded_fields/$Parameter/5x5/mean_diffs.pp --term="png size 800,600" > $FindBin::Bin/../docs/mean_diffs_$Parameter.png`;
`/usr/bin/mogrify -crop 695x365+75+125 $FindBin::Bin/../docs/mean_diffs_$Parameter.png`;

# Make the time-series
if ( $Parameter eq 'sst' ) {
    open( DIN, "$FindBin::Bin/../gridded_fields/$Parameter/5x5/new_bc.pp" )
      or die "Can't open gridded $Parameter fields";
}
else {
    open( DIN, "$FindBin::Bin/../gridded_fields/$Parameter/5x5/new.pp" )
      or die "Can't open gridded $Parameter fields";
}
open( DOUT, ">$FindBin::Bin/../gridded_fields/$Parameter/5x5/new_global_mean" )
  or die "Can't open global mean output file";
while ( my $pp = pp_read( \*DIN ) ) {
    my $Res = area_average($pp);
    if ( defined($Res) ) {
        printf DOUT "%04d/%02d %g\n", $pp->{lbyr}, $pp->{lbmon},
          area_average($pp);
    }
    else {
        print DOUT "\n";
    }
}
close(DIN);
close(DOUT);
my $Old_file;
my $Title;
if ( $Parameter eq 'sst' ) {

    #    $Old_file = "$ENV{OBSDIR}/marine/HadSST2/anomalies/5x5/HadSST2.pp";
    $Old_file = "$ENV{OBSDIR}/../icoads/mds2.1_datasets/SST/5x5/ICSST4B.pp";
    $Title    = 'HadSST2 - bucket corrected';
}
elsif ( $Parameter eq 'nat' ) {
    $Old_file = "$ENV{OBSDIR}/../icoads/mds2.1_datasets/NAT/5x5/ICNAT3A.pp";
    $Title    = 'HadNAT2 (no bias adjustments)';
}
elsif ( $Parameter eq 'dat' ) {
    $Old_file = "$ENV{OBSDIR}/../icoads/mds2.1_datasets/DAT/5x5/ICDAT2A.pp";
    $Title    = 'ICDAT (no bias adjustments)';
}
elsif ( $Parameter eq 'pre' ) {
    $Old_file =
      "$ENV{OBSDIR}/../icoads/mds2.1_datasets/pressure/5x5/pressure_anomaly.pp";
    $Title = "Pressure from ICOADS2.0";
}
open( DIN, "$Old_file" )
  or die "Can't open $Old_file";
open( DOUT, ">$FindBin::Bin/../gridded_fields/$Parameter/5x5/old_global_mean" )
  or die "Can't open old global mean output file";
while ( my $pp = pp_read( \*DIN ) ) {
    if ( $pp->{lbyr} < 1936 || $pp->{lbyr} > 1948 ) { next; }
    printf DOUT "%04d/%02d %g\n", $pp->{lbyr}, $pp->{lbmon}, area_average($pp);
}
close(DIN);
close(DOUT);
open( DOUT, "|$gnuplot 1>/dev/null 2>/dev/null" ) or die "Can't start gnuplot";

#open( DOUT, ">tmp.gp" ) or die "Can't start gnuplot";
print DOUT "set term png size 695,365\n";
print DOUT "set grid\n";
print DOUT "set xdata time\n";
print DOUT
  "set output '$FindBin::Bin/../docs/time_series_mean_$Parameter.png'\n";
print DOUT "set timefmt '%Y/%m'\n";
print DOUT "set xrange ['1936/01':'1948/12']\n";
print DOUT "set xlabel 'Date'\n";
print DOUT "set ylabel 'Anomaly (C)'\n";

if ( $Parameter eq 'sst' ) {
    print DOUT "set yrange [-1.5:*]\n";
}
if ( $Parameter eq 'pre' ) {
    print DOUT "set yrange [-4:*]\n";
}
print DOUT
  "plot '$FindBin::Bin/../gridded_fields/$Parameter/5x5/old_global_mean' using 1:2 title '$Title' w l lw 3,\\\n";
print DOUT
  "'$FindBin::Bin/../gridded_fields/$Parameter/5x5/new_global_mean' using 1:2 title 'New data' w l lt 3 lw 3\n";
close(DOUT);
close(DIN);
