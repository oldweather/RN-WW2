#!/usr/bin/perl

# Make pressure, SST or AT trend maps from the company data

use strict;
use warnings;
use Time::Local;
use Getopt::Long;
use Carp;
use FindBin;

# Use latest gnuplot executable
my $Gp = "/home/hc0100/hadobs/tools/gnuplot-4.2rc1/bin/gnuplot";

my $VarChoice = 'slp';
GetOptions( "var=s" => \$VarChoice );
$VarChoice = lc($VarChoice);
unless ( $VarChoice eq 'slp' || $VarChoice eq 'sst' || $VarChoice eq 'at' ) {
    die;
}

my %By_ship;
my %Slp;
my %Sst;
my %At;
open( DIN, "$FindBin::Bin/../data/company.out" ) or die;
while (<DIN>) {
    my @Fields = split;
    my $Nships = ( scalar(@Fields) - 3 ) / 4;
    for ( my $i = 0 ; $i < $Nships ; $i++ ) {
        $By_ship{ $Fields[ $i + 3 ] }{ $Fields[0] } = $_;
        $Slp{ $Fields[ $i + 3 ] }{ $Fields[0] } = $Fields[ $Nships + 3 + $i ];
        $Sst{ $Fields[ $i + 3 ] }{ $Fields[0] } =
          $Fields[ $Nships * 2 + 3 + $i ];
        $At{ $Fields[ $i + 3 ] }{ $Fields[0] } =
          $Fields[ $Nships * 3 + 3 + $i ];
    }
}
close(DIN);

# For each ship - make a figure showing pressure trends
foreach my $Ship (keys(%By_ship)) {
    unless ( scalar( keys( %{ $By_ship{$Ship} } ) ) > 20 ) { next; }

    # Make a set of times for when data is available from this ship:
    #  in days, set to zero for the first observation, and with long gaps
    #  in the record reduced to 2 days in length
    my %rTimes;
    my %tGaps;     # Record points where a gap has been reduced
    my $tStart;    # Start time
    my $tLast;     # Time of previous observation
    my $tSkip = 0; # Time with no observations to be skipped
    foreach my $Entry ( sort keys( %{ $By_ship{$Ship} } ) ) {

        # Convert time to epoch seconds
        $Entry =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)/ or die $Entry;
        my $Epoch = timegm( 0, 0, $4, $3, $2 - 1, $1 );

        # First point has time=0;
        if ( !defined($tStart) ) {
            $rTimes{$Entry} = 0;
            $tStart         = $Epoch;
            $tLast          = $Epoch;
            next;
        }

        # Is it more than 2 days since last entry?
        if ( ( $Epoch - $tLast ) > 172800 ) {
            $tGaps{$Entry} = 1;
            $tSkip += $Epoch - $tLast - 172800;
        }

        $rTimes{$Entry} = $Epoch - $tSkip - $tStart;
        $tLast = $Epoch;
    }

    # List the other ships in company at some point
    my %Companions;
    foreach my $Entry ( keys( %{ $By_ship{$Ship} } ) ) {
        my @Fields = split /\s+/, $By_ship{$Ship}{$Entry};
        my $Nships = ( scalar(@Fields) - 3 ) / 4;
        for ( my $i = 0 ; $i < $Nships ; $i++ ) {
            if ( $Fields[ $i + 3 ] ne $Ship ) {
                $Companions{ $Fields[ $i + 3 ] } = 1;
            }
        }
    }

    # Make the trends figure
    open( DOUT, "| $Gp - 1> /dev/null 2> /dev/null" )
      or die "Can't start gnuplot";
    printf DOUT "set output '%s/../figs/%s.%s.ts.ps'\n", $FindBin::Bin, $Ship,
      $VarChoice;
    print DOUT "set term postscript color\n";
    print DOUT "set grid\n";
    print DOUT "set key below\n";
    print DOUT
      "set xlabel 'Day (consecutive, but gaps are reduced to 2 days)'\n";
    if ( $VarChoice eq 'slp' ) {
        print DOUT "set ylabel 'SLP (hPa)'\n";
    }
    if ( $VarChoice eq 'sst' ) {
        print DOUT "set ylabel 'SST (C)'\n";
    }
    if ( $VarChoice eq 'at' ) {
        print DOUT "set ylabel 'Air Temperature (C)'\n";
    }
    my $Sht = $Ship;
    $Sht =~ s/_+$//;
    print DOUT "plot '-' title '$Sht' w l lt -1";

    foreach ( sort( keys(%Companions) ) ) {
        $_ =~ s/_+$//;    # Strip trailing underscores from the name
        print DOUT ",\\\n '-' title '$_' w l lw 2";
    }
    print DOUT"\n";

    # Data for each ship
    my $i = 0;
    foreach my $Shp ( $Ship, sort( keys(%Companions) ) ) {
        if ( $i++ > 0 ) { print DOUT "e\n"; }
        my $lTime;
        my $lEntry;
        foreach my $Entry ( sort keys( %{ $By_ship{$Shp} } ) ) {

            # Throw out points with no data from the main ship
            if ( !defined( $rTimes{$Entry} ) ) { next; }
            if ( !defined( getVar( $Shp, $Entry ) )
                || getVar( $Shp, $Entry ) !~ /\d/ )
            {
                next;
            }
            $Entry =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)/ or die $Entry;
            my $Epoch = timegm( 0, 0, $4, $3, $2 - 1, $1 );

            # Put in gaps explicitly
            if ( defined($lTime) && ( $Epoch - $lTime ) > 172800 ) {
                printf DOUT "%g %g\n", $rTimes{$lEntry} / 86400 + 1,
                  getVar( $Shp, $lEntry );
                print DOUT "\n";
            }

            # Add the value for the current point
            printf DOUT "%g %g\n", $rTimes{$Entry} / 86400,
              getVar( $Shp, $Entry );
            $lTime  = $Epoch;
            $lEntry = $Entry;
        }
    }
    close(DOUT);

    # Convert the postscript figure to PNG
    my $Figname = sprintf "%s/../figs/%s.%s.ts", $FindBin::Bin, $Ship,
      $VarChoice;
    `convert -rotate 90 \"$Figname.ps\" \"$Figname.png\"`;
}

# Get the variable of choice
sub getVar {
    my $Ship  = shift;
    my $Entry = shift;
    unless ( defined($Ship) && defined($Entry) ) { croak; }
    if ( $VarChoice eq 'slp' ) {
        if ( !defined( $Slp{$Ship}{$Entry} ) ) { return; }
        return $Slp{$Ship}{$Entry};
    }
    elsif ( $VarChoice eq 'sst' ) {
        if ( !defined( $Sst{$Ship}{$Entry} ) ) { return; }
        return $Sst{$Ship}{$Entry};
    }
    elsif ( $VarChoice eq 'at' ) {
        if ( !defined( $At{$Ship}{$Entry} ) ) { return; }
        return $At{$Ship}{$Entry};
    }
    else {
        die;
    }
}
