#!/usr/bin/perl 

# Compare the expected log numbers from Clive's directory with
#  those from the IMMA files.

use strict;
use warnings;
use FindBin;

# Extract the expected log numbers from Clive's directory
my %Directory;
open( DIN, "$FindBin::Bin/../Clive_directory.csv" ) or die;
while (<DIN>) {
    my @Fields = split /,/, $_;
    my $Name   = $Fields[5];

    # Convert name into IMMA format
    $Name =~ s/"//g;
    $Name =~ s/ /_/g;
    $Name = uc( sprintf "%-9s", substr( $Name, 0, 9 ) );

    # Get and store logs for this ship
    my $Logs_s = $Fields[1];
    $Logs_s =~ s/"//g;
    my @Logs_v = split /\s+/, $Logs_s;
    foreach my $Log_s2 (@Logs_v) {
        if ( $Log_s2 =~ /(\d+)-(\d+)/ ) {
            my $Start = $1;
            my $End = substr( $1, 0, length($1) - length($2) ) . $2;
            for ( my $i = $Start ; $i <= $End ; $i++ ) {
                $Directory{$i} = $Name;
            }
        }
        else {
            $Directory{$Log_s2} = $Name;
        }
    }
}
close(DIN);

# Get the observed logbook numbers from the IMMA list
open( DIN, "$FindBin::Bin/list_logs" ) or die;
while (<DIN>) {
    my @Missing;
    my @Correct;
    my %Incorrect;
    my @Fields = split;
    my $Name = sprintf "%-9s", $Fields[0];
    for ( my $i = 1 ; $i < scalar(@Fields) ; $i++ ) {
        unless ( defined( $Directory{ $Fields[$i] } ) ) {
            push @Missing, $Fields[$i];
            next;
        }
        if ( $Directory{ $Fields[$i] } eq $Name ) {
            push @Correct, $Fields[$i];
        }
        else {
            $Incorrect{ $Fields[$i] } = $Directory{ $Fields[$i] };
        }
    }
    print "$Name :\n";
    print "Correct: ";
    @Correct = Compress(@Correct);
    for ( my $i = 0 ; $i < scalar(@Correct) ; $i++ ) {
        print "$Correct[$i] ";
    }
    print "\nMissing: ";
    @Missing = Compress(@Missing);
    for ( my $i = 0 ; $i < scalar(@Missing) ; $i++ ) {
        print "$Missing[$i] ";
    }
    print "\nIncorrect: ";
    foreach ( sort( keys(%Incorrect) ) ) {
        print "$_-$Incorrect{$_} ";
    }
    print "\n";
}

# Remove runs in an array
sub Compress {
    my @Result;
    my $Start = $_[0];
    my $End;
    for ( my $i = 1 ; $i < scalar(@_) ; $i++ ) {
        if ( $_[$i] != $_[ $i - 1 ] + 1 ) {
            if ( defined($End) ) {
                push @Result, sprintf "%d-%d", $Start, $End;
            }
            else {
                push @Result, $Start;
            }
            $Start = $_[$i];
            $End   = undef();
        }
        else {
            $End = $_[$i];
        }
        if ( $i == $#_ ) {    # Last array element
            if ( defined($End) ) {
                push @Result, sprintf "%d-%d", $Start, $End;
            }
            else {
                push @Result, $Start;
            }
        }
    }
    return @Result;
}

