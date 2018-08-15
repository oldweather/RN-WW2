#!/usr/bin/perl -w

# Make histograms of ship differences from the Calchot data.

use strict;
use warnings;
use lib "$ENV{MY_PERL}";
use Numeric::histogram;

my @Ships = qw(Boreas Challenger Coventry Dispatch
  Dunedin Enterprise Manchester Nelson
  Rodney Velox Wrestler Calshot);

my $Ship = 0;
my @Data;
while (<>) {
    if ( $_ =~ /^e/ ) {
        $Ship++;
        next;
    }
    unless ( $_ =~ /^\d/ ) { next; }
    my @fields = split;
    $Data[$Ship]{ $fields[0] } = $fields[1];
}

my @Strings;
for ( my $i = 0 ; $i < scalar(@Ships) ; $i++ ) {
    my @Diffs;
    foreach ( keys( %{ $Data[$i] } ) ) {
        if ( defined( $Data[11]{$_} ) ) {
            push @Diffs, ( $Data[$i]{$_} - $Data[11]{$_} );
        }
    }
    my $Hi = make_hist( data => \@Diffs, max => 10, min => -10, step => 0.5 );
    write_to_strings($Hi);
}
for ( my $i = 0 ; $i < scalar(@Strings) ; $i++ ) {
    print "$Strings[$i]\n";
}

# Output the histograms in a suitable format for plotting
sub write_to_strings {

    my $self = shift;

    my $Point       = $self->{min} + $self->{step} / 2;
    my $Stringindex = 0;
    while ( $Point < $self->{max} ) {
        my $index = int( ( $Point - $self->{min} ) / $self->{step} );
        if ( defined( $self->{values}[$index] ) ) {
            if ( defined( $Strings[$Stringindex] ) ) {
                $Strings[$Stringindex] .= sprintf "%g ",
                  $self->{values}[$index];
            }
            else {
                $Strings[$Stringindex] = sprintf "%g %g ", $Point,
                  $self->{values}[$index];
            }
        }
        else {
            if ( defined( $Strings[$Stringindex] ) ) {
                $Strings[$Stringindex] .= sprintf "%g ", 0;
            }
            else {
                $Strings[$Stringindex] = sprintf "%g %g ", $Point, 0;
            }
        }
        $Point += $self->{step};
        $Stringindex++;
    }
    return 1;
}
