#!/usr/bin/perl -w

# Sort out a complete set of post-QC IMMA files and name them correctly

use strict;
use warnings;
use FindBin;

chdir "$FindBin::Bin/../imma_files/sorted_by_ship" or die;
my @Ships = glob("*.imma");
my %Ships;
foreach (@Ships) {
    $Ships{$_} = 1;
}

# Rename files to remove QC tail
foreach ( keys(%Ships) ) {
    unless ( $_ =~ /([\w\(\)]+)_QC.imma/ ) {
        die "Bad ship name $_";
    }
    `mv "$_" "$1.imma"`;
}

chdir "before_qc" or die;
my @Ships2 = glob("*.imma");
my %Ships2;
foreach (@Ships2) {
    $Ships2{$_} = 1;
}


# Copy missing files (those where no QC was needed).
foreach ( keys(%Ships2) ) {
    unless ( $_ =~ /([\w\(\)]+).imma/ ) {
        die "Bad ship name $_";
    }
    unless ( exists( $Ships{"$1_QC.imma"} ) ) {
        `cp "$_" ..`;
    }
}
