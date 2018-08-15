#!/usr/bin/perl -w

# Make the gridded fields

use strict;
use FindBin;
use Getopt::Long;

# Set the defaults
my $Variable = 'sst';
my $Old      = 'false';
my $New      = 'true';

GetOptions(
    "parameter=s" => \$Variable,
    "use_old=s"   => \$Old,
    "use_new=s"   => \$New
);
$Variable = lc($Variable);

my $Data_dir_base = "$FindBin::Bin/../../gridded_fields";

# Delete current versions of the gridded data
my $Opname;
if ( $New eq 'true' ) {
    if ( $Old eq 'true' ) {
        $Opname = 'both';
    }
    else {
        $Opname = 'new';
    }
}
else {
    $Opname = 'old';
}
unlink(
    "$Data_dir_base/$Variable/2x2/$Opname.pp",
    "$Data_dir_base/$Variable/2x2/nobs_$Opname.pp",
    "$Data_dir_base/$Variable/2x2/sd_$Opname.pp"
);

# Get start and end dates for the previous pseudomonths
my @Start_months = qw(01 01 03 04 05 05 06 07 09 10 11 12);
my @End_months   = qw(01 03 03 04 05 06 07 09 10 11 12 12);
my @Start_days   = qw(01 31 02 01 01 31 30 30 03 03 02 02);
my @End_days     = qw(30 01 31 30 30 29 29 02 02 01 01 31);

for ( my $Year = 1938 ; $Year <= 1947 ; $Year++ ) {
    for ( my $Month = 1 ; $Month <= 12 ; $Month++ ) {
        my $Start_date = sprintf "%4d/%02d/%02d:00:00", $Year,
          $Start_months[ $Month - 1 ], $Start_days[ $Month - 1 ];
        my $End_date = sprintf "%4d/%02d/%02d:23:59", $Year,
          $End_months[ $Month - 1 ], $End_days[ $Month - 1 ];
        my $Options =
            "--start_dtime $Start_date --end_dtime $End_date "
          . "--not_blacklist true --not_duplicate true "
          . "--track_check true "
          . "--lat_resolution 2 --long_resolution 2 "
          . "--use_new $New --use_old $Old "
          . "--parameter $Variable ";
        if ( $Variable eq 'sst' ) {
            $Options .=
                "--sst_climatology true --sst_no_freeze=true "
              . "--sst_buddy true";
        }
        elsif ( $Variable eq 'nat' ) {
            $Options .= "--mat_climatology true --mat_buddy true";
        }
        elsif ( $Variable eq 'pre' ) {
            $Options .= "--pressure_climatology true --pressure_buddy true";
        }
        system("$FindBin::Bin/../../hacked_mds/newgrid.perl $Options") == 0
          or die "Griding failed";
        system(
            "$FindBin::Bin/redate.perl < grid.pp >> $Data_dir_base/$Variable/2x2/$Opname.pp"
          ) == 0
          or die "Grid copy failed";
        system(
            "$FindBin::Bin/redate.perl < nobs.pp >> $Data_dir_base/$Variable/2x2/nobs_$Opname.pp"
          ) == 0
          or die "Nobs copy failed";
        system(
            "$FindBin::Bin/redate.perl < SD.pp >> $Data_dir_base/$Variable/2x2/sd_$Opname.pp"
          ) == 0
          or die "Sd copy failed";
        unlink 'grid.pp', 'nobs.pp', 'SD.pp';

        printf "%4d/%02d\n", $Year, $Month;
    }
}
