#!/usr/bin/perl

# Make images and a html file for each month

use strict;
use warnings;
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

my $pp_map = "/home/hc1300/hadpb/tasks/software/bin/pp_map";

for ( my $Year = 1938 ; $Year <= 1947 ; $Year++ ) {
    for ( my $Month = 1 ; $Month <= 12 ; $Month++ ) {
        my $Target_dir = sprintf "%s/%04d%02d",
          "$FindBin::Bin/../docs/monthly_$Parameter", $Year, $Month;

        unless ( -d $Target_dir ) {
            mkdir $Target_dir, 0777
              or die "Failed to make directory $Target_dir";
        }

        `$pp_map --year $Year --month $Month --range=[-3:3] $Old_file --term="png size 800,600" > $Target_dir/old.png`;
        `/usr/bin/mogrify -crop 695x365+75+125 $Target_dir/old.png`;
        `$pp_map --year $Year --month $Month --range=[-3:3] $FindBin::Bin/../gridded_fields/$Parameter/5x5/new.pp --term="png size 800,600" > $Target_dir/new.png`;
        `/usr/bin/mogrify -crop 695x365+75+125 $Target_dir/new.png`;
        `$pp_map --year $Year --month $Month --range=[-1:1] $FindBin::Bin/../gridded_fields/$Parameter/5x5/coverage.pp --term="png size 800,600" > $Target_dir/coverage.png`;
        `/usr/bin/mogrify -crop 695x365+75+125 $Target_dir/coverage.png`;
        `$pp_map --year $Year --month $Month --range=[-3:3] $FindBin::Bin/../gridded_fields/$Parameter/5x5/diffs.pp --term="png size 800,600" > $Target_dir/diffs.png`;
        `/usr/bin/mogrify -crop 695x365+75+125 $Target_dir/diffs.png`;

        my $Up = uc($Parameter);
        if($Up eq 'PRE') { $Up = 'SLP'; }
        open( DOUT, ">$Target_dir/index.html" )
          or die "Can't open $Target_dir/index.html";
        print DOUT "<html>\n<head>\n";
        printf DOUT
          "<title>Digitisation $Up diagnostics for %04d/%02d</title>\n", $Year,
          $Month;
        print DOUT "</head>\n<body bgcolor=\"white\">\n";
        print DOUT "<small><a href=\"../index.html\">$Up Diagnostics index</a>\n";
        printf DOUT
          "<center><h1>Digitisation $Up diagnostics for %04d/%02d</h1></center>\n",
          $Year, $Month;
        print DOUT "<center><table>\n";
        print DOUT
          "<tr><th><img src=\"old.png\" width=695 height=365></th></tr>\n";
        print DOUT "<tr><th>$Up from old (ICOADS) obs only.</th></tr>\n";
        print DOUT "</table></center><p>\n";
        print DOUT "<center><table>\n";
        print DOUT
          "<tr><th><img src=\"new.png\" width=695 height=365></th></tr>\n";
        print DOUT "<tr><th>$Up from new obs only.</th></tr>\n";
        print DOUT "</table></center><p>\n";
        print DOUT "<center><table>\n";
        print DOUT
          "<tr><th><img src=\"diffs.png\" width=695 height=365></th></tr>\n";
        print DOUT "<tr><th>$Up difference (new-old).</th></tr>\n";
        print DOUT "</table></center><p>\n";
        print DOUT "<center><table>\n";
        print DOUT
          "<tr><th><img src=\"coverage.png\" width=695 height=365></th></tr>\n";
        print DOUT
          "<tr><th>Coverage (red=new only, blue=old only, cyan=both).</th></tr>\n";
        print DOUT "</table></center><p>\n";
        print DOUT "<hr>\n";
        my ( $day, $mon, $year ) = ( localtime(time) )[ 3, 4, 5 ];
        printf DOUT "<em>Updated on</em>: %04d-%02d-%02d\n", $year + 1900,
          $mon + 1, $day;
        print DOUT "</body>\n</html>\n";
        close(DOUT);

    }
}
