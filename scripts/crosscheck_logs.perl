#!/usr/bin/perl

# List the log numbers associated with each ship
# For cross-checking against Clive's directory.

use strict;
use warnings;
use lib "$ENV{HOME}/tasks/imma/perl_module";
use IMMA;

my %Logs;
while(my $Ob=imma_read(\*STDIN)) {
    unless(defined($Ob->{ID})) { next; }
    my $Log = substr($Ob->{SUPD},1,6);
    $Logs{$Ob->{ID}}{$Log}=1;
}

foreach my $Ship (sort(keys(%Logs))) {
    printf "%20s ",$Ship;
    foreach my $Log (sort(keys(%{$Logs{$Ship}}))) {
        printf "%6s ",$Log;
    }
    print "\n";
}
