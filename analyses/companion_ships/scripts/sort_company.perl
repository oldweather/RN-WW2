#!/usr/bin/perl

# Split the company file into long trips made by individual ships
#  with others in company

use strict;
use warnings;
use Time::Local;

my %By_ship;
while (<>) {
    my @Fields = split;
    my $Nships = ( scalar(@Fields) - 3 ) / 4;
    for ( my $i = 0 ; $i < $Nships ; $i++ ) {
        $By_ship{ $Fields[ $i + 3 ] }{ $Fields[0] } = $_;
    }
}

# Find the longest continuous run for each ship
my @Seq;
foreach my $Ship ( keys(%By_ship) ) {
    my $LastDate;
    my $LastEpoch;
    my $StartDate;
    my $StartEpoch;
    foreach my $Date ( sort keys( %{ $By_ship{$Ship} } ) ) {
        unless ( defined($StartDate) ) {
            $StartDate = $Date;
            $StartDate =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)/ or die $StartDate;

            #            print "$4 $3 $2 $1\n";
            $StartEpoch = timegm( 0, 0, $4, $3, $2 - 1, $1 );
            $LastDate = $Date;
            $LastDate =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)/ or die $LastDate;
            $LastEpoch = timegm( 0, 0, $4, $3, $2 - 1, $1 );
            next;
        }
        $Date =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)/ or die $Date;
        my $Epoch = timegm( 0, 0, $4, $3, $2 - 1, $1 );
        if ( $Epoch - $LastEpoch < 200000 ) {
            $LastDate  = $Date;
            $LastEpoch = $Epoch;
        }
        else {    # Too long a break - start a new sequence
            push @Seq,
              [ $Ship, $StartDate, $LastDate, $LastEpoch - $StartEpoch ];
            $StartDate  = $LastDate;
            $StartEpoch = $LastEpoch;
        }
    }
}
@Seq = sort { $b->[3] <=> $a->[3] } @Seq;

for ( my $i = 0 ; $i < scalar(@Seq) ; $i++ ) {
    printf "%s %s %s %d\n", @{ $Seq[$i] };
}
