#!/usr/bin/perl

# Make pressure, SST or AT scatter plots from the company data

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
foreach my $Ship ( keys(%By_ship) ) {

    #foreach my $Ship ('COLOSSUS_') {
    unless ( scalar( keys( %{ $By_ship{$Ship} } ) ) > 20 ) { next; }

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

    # Make the scatter plot
    #open( DOUT, ">tmp.gp" );
    open( DOUT, "| $Gp - 1> /dev/null 2> /dev/null" )
      or die "Can't start gnuplot";
    printf DOUT "set output '%s/../figs/%s.%s.sc.ps'\n", $FindBin::Bin, $Ship,
      $VarChoice;
    print DOUT "set term postscript color 12\n";
    print DOUT "set grid\n";
    print DOUT "set key rm width 2\n";
    my $Sht = $Ship;
    $Sht =~ s/_+$//;

    if ( $VarChoice eq 'slp' ) {
#        print DOUT "set xrange [970:1030]\n";
#        print DOUT "set yrange [970:1030]\n";
        print DOUT "set xlabel '$Sht SLP (hPa)'\n";
        print DOUT "set ylabel 'Companion SLP (hPa)'\n";
    }
    if ( $VarChoice eq 'sst' ) {
        print DOUT "set xlabel '$Sht SST (C)'\n";
        print DOUT "set ylabel 'Companion SST (C)'\n";
    }
    if ( $VarChoice eq 'at' ) {
        print DOUT "set xlabel '$Sht AT (C)'\n";
        print DOUT "set ylabel 'Companion AT (C)'\n";
    }
    print DOUT "plot ";
    my $i = 0;
    foreach ( sort( keys(%Companions) ) ) {
        if ( $i++ > 0 ) { print DOUT ","; }
        $_ =~ s/_+$//;    # Strip trailing underscores from the name
        print DOUT "\\\n '-' title '$_' w p";
    }
    print DOUT ", x notitle w l lt 0\n";

    # Data for each ship
    $i = 0;
    foreach my $Shp ( sort( keys(%Companions) ) ) {
        if ( $i++ > 0 ) { print DOUT "e\n"; }
        my $lTime;
        my $lEntry;
        foreach my $Entry ( sort keys( %{ $By_ship{$Shp} } ) ) {

            # Throw out points with no data from the main ship
            if (   !defined( $By_ship{$Ship}{$Entry} )
                || !defined( getVar( $Ship, $Entry ) )
                || getVar( $Ship, $Entry ) !~ /\d/ )
            {
                next;
            }
            if ( !defined( getVar( $Shp, $Entry ) )
                || getVar( $Shp, $Entry ) !~ /\d/ )
            {
                next;
            }

            # Add the value for the current point
            printf DOUT "%g %g\n", getVar( $Ship, $Entry ),
              getVar( $Shp, $Entry );
        }
    }
    close(DOUT);

    # Convert the postscript figure to PNG
    my $Figname = sprintf "%s/../figs/%s.%s.sc", $FindBin::Bin, $Ship,
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
