#!/usr/bin/perl -w

#  Run Buddy QC on the tenday obs.
# this version works on the new NCDC obs

use strict;
use lib "$ENV{MDS2}/data_structures/source";
use Tenday;
use Symbol;
use POSIX;
use FindBin;

# Run QC on each month's obs
my @Files = <../../tenday_files/??????>;
foreach my $Ob_file_name (@Files) {
    unless($Ob_file_name =~ /(\d\d\d\d)(\d\d)/) { next; }

    print "Running buddy QC for $1/$2\n";
    `$FindBin::Bin/../../hacked_mds/update_buddy_qc_month.perl $1/$2`;

}

