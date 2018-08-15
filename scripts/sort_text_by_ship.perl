#!/usr/bin/perl

# Sort the text obs by ship and date and reformat them to add the ship
#  name to the data line.

use strict;
use warnings;
use lib "$ENV{MDS2}/data_structures/source";
use Tenday;
use FindBin;

my %Ships;
my $Ship_name;
my @Files = <$FindBin::Bin/../ncdc_txt/as_received/*.txt>;
foreach my $File (@Files) {
    open( DIN, $File ) or die "Can't open $File";

    while (<DIN>) {
        chomp;

        if ( $_ =~ /^1/ ) {    # Header line
            $Ship_name = substr( $_, 7, 20 );
            $Ship_name =~ s/^\s+//;
#            $Ship_name = substr( $Ship_name, 0, 8 );
#            $Ship_name =~ s/\s+/_/g;
            unless($Ship_name =~ /\w/) {
                $Ship_name = "UNKNOWN";
            }
        }

        if ( $_ =~ /^2/ ) {    # Data line
            push @{ $Ships{$Ship_name} }, sprintf "%-103s",
              $_;
        }
    }
    close(DIN);
}

# Sort and output the ship files
foreach ( keys(%Ships) ) {
    my $File_name = sprintf "%s",$_;
    $File_name =~ s/\s/_/g;
    open( DOUT, ">$FindBin::Bin/../ncdc_txt/sorted_by_ship/$File_name" )
      or die "Can't open output for $_";
    foreach ( sort tx_compare @{ $Ships{$_} } ) {
        print DOUT "$_\n";
    }
    close(DOUT);
}

# Compare two records, sort by date
sub tx_compare {

    return 
      getnum( $a, 22-9, 4 ) <=> getnum( $b, 22-9, 4 ) ||       # Compare Year
      getnum( $a, 20-9, 2 ) <=> getnum( $b, 20-9, 2 ) ||       # Compare Month
      getnum( $a, 18-9, 2 ) <=> getnum( $b, 18-9, 2 ) ||       # Compare Day
      getnum( $a, 48-9, 2 ) <=> getnum( $b, 48-9, 2 );         # Compare Hour
}

sub getnum {
    if ( length( $_[0] ) < ( $_[1] + $_[2] ) ) { return -1; }
    my $Num = substr( $_[0], $_[1], $_[2] );
    if ( $Num =~ /\d/ ) { return $Num; }
    else { return 0; }
}
