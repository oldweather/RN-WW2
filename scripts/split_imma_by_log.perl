#!/usr/bin/perl -w

# The IMMA file for the Arethusa is actually a merge from two ships
#  splti by logbook number (in supplementary attachment) to sparate them

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module";
use IMMA;

my $Ship = "MILFORD";
open( DIN, "../imma_files/sorted_by_ship/$Ship" . "_QC.imma" ) or die;
my $Last_log;
while ( my $Ob = imma_read( \*DIN ) ) {
    my $Log = substr( $Ob->{SUPD}, 0, 4 );
    unless(defined($Log) && $Log =~ /\d/) {
        $Ob->write(\*STDERR);
        die "Bad log";
    }
    unless(defined($Last_log) && $Log==$Last_log) {
        open(DOUT,">>$Log") or die;
    }
    $Ob->write(\*DOUT);
    $Last_log = $Log;
}
close(DIN);
