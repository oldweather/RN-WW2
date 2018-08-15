#!/usr/bin/perl

# Find cases where 1 ship has interleaved logs.

use strict;
use warnings;
use lib "$ENV{HOME}/tasks/imma/perl_module";
use IMMA;

my $Current_log;
my $Previous_log;
my $Mismatch;
while ( my $Ob = imma_read( \*STDIN ) ) {
    unless ( defined( $Ob->{YR} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{ID} )
        && defined( $Ob->{SUPD} ) )
    {
        next;
    }
    my $Date = sprintf "%04d%02d%02d", $Ob->{YR}, $Ob->{MO}, $Ob->{DY};
    my $Log = substr( $Ob->{SUPD}, 1, 6 );
    if (   defined($Current_log)
        && $Log ne $Current_log
        && defined($Previous_log)
        && $Current_log ne $Previous_log )
    {    # Found inconsistent logs
        if ( defined($Mismatch)
            && ( $Log eq $Mismatch || $Current_log eq $Mismatch ) )
        {

            # Already know about this one
            next;
        }
        print "$Ob->{ID} $Date $Log $Current_log\n";
        $Mismatch = $Log;
    }
    $Previous_log = $Current_log;
    $Current_log  = $Log;

}

