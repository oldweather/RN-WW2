#!/usr/bin/perl 

# Plot a graph of ship positions, distinguishing between those
#  from the logs, those inferred from metadata, and those interpolated

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;

my $Term        = 'x11';    # Terminal type for gnuplot
my $Output_file = undef;    # Output file name (otherwise STDOUT or screen)
my $Gp_options  = undef;    # Gnuplot options, passed unchecked to gnuplot

# Process and check the options
GetOptions(
    "term=s"    => \$Term,
    "output=s"  => \$Output_file,
    "options=s" => \$Gp_options
  )
  or die;

# Get the positions from an IMMA file
my ( @Digitised, @Metadata, @Interpolated, $Missing_s, $Missing_p, $Total );
while ( my $ob = imma_read( \*STDIN ) ) {
    $Total++;
    unless ( defined( $ob->{LAT} ) && defined( $ob->{LON} ) ) {
        if ( substr( $ob->{SUPD}, 19, 20 ) =~ /\w/ ) {
            $Missing_p++;
        }
        else {
            $Missing_s++;
        }
        next;
    }
    if ( $ob->{LI} == 4 ) {
        push @Digitised, [ $ob->{LON}, $ob->{LAT} ];
    }
    elsif ( $ob->{LI} == 6 ) {
        push @Metadata, [ $ob->{LON}, $ob->{LAT} ];
    }
    elsif ( $ob->{LI} == 3 ) {
        push @Interpolated, [ $ob->{LON}, $ob->{LAT} ];
    }
    else {
        die "Bad LI in IMMA ob: $ob->{LI}";
    }
}

open( DOUT, "|gnuplot -persist" ) or die "Can't start gnuplot";

#open( DOUT, ">tmp.gp" ) or die "Can't start gnuplot";
print DOUT "set grid\n";
print DOUT "set size ratio -1\n";    # prevent distortions in regional maps
if ( defined($Term) ) {
    print DOUT "set term $Term\n";
}
if ( defined($Output_file) ) {
    print DOUT "set output '$Output_file'\n";
}
print DOUT "set xrange [-180:180]\n";
print DOUT "set yrange [-90:90]\n";
print DOUT "set key below\n";
my $Title_string = sprintf "%5d obs: ", $Total;
$Title_string .= sprintf "%3d%% Digitised, ",
  scalar( @Digitised / $Total ) * 100;
$Title_string .= sprintf "%3d%% Metadata, ", scalar( @Metadata / $Total ) * 100;
$Title_string .= sprintf "%3d%% Interpolated, ",
  scalar( @Interpolated / $Total ) * 100;
$Title_string .= sprintf "%3d%% Missing (in port), ",
  ( $Missing_p / $Total ) * 100;
$Title_string .= sprintf "%3d%% Missing (at sea).",
  ( $Missing_s / $Total ) * 100;
print DOUT "set title '$Title_string'\n";
print DOUT "plot '-' title 'Digitised' w p ps 0.5 pt 3 lt 3,\\\n";
print DOUT "      '' title 'Interpolated' w p ps 0.5 pt 1 lt 1,\\\n";
print DOUT "      '' title 'From metadata' w p pt 18 lt 2,\\\n";
print DOUT "'/home/hc1300/hadpb/tasks/software/pp_utilities/pp_map/data/w4.dat'"
  . " using 2:1 notitle w l lt -1\n";

foreach (@Digitised) {
    printf DOUT "%g %g\n", $_->[0], $_->[1];
}
print DOUT "185 95\n";  # Dud point to prevent gnuplot error when no data
print DOUT "e\n";
foreach (@Interpolated) {
    printf DOUT "%g %g\n", $_->[0], $_->[1];
}
print DOUT "185 95\n";
print DOUT "e\n";
foreach (@Metadata) {
    printf DOUT "%g %g\n", $_->[0], $_->[1];
}
print DOUT "185 95\n";  
close(DOUT);

