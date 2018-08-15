#!/usr/bin/perl

# Convert IMMA records into Tenday records.

use strict;
use warnings;
use lib "$ENV{MDS2}/data_structures/source";
use Tenday;
use lib "/home/hc1300/hadpb/tasks/imma/perl_module/";
use IMMA;

my ( $Current_file, $Current_year, $Current_month );

while ( my $Ob_i = imma_read( \*STDIN ) ) {
    my $Ob_t = new Tenday;
    if ( defined( $Ob_i->{ID} ) ) {
        $Ob_t->{callsign} = substr( $Ob_i->{ID}, 0, 8 );
    }
    else {
        $Ob_t->{callsign} = "        ";
    }
    if ( defined( $Ob_i->{DY} ) ) {
        $Ob_t->{day} = $Ob_i->{DY};
    }
    else {
        $Ob_t->{day} = -32768;
    }
    if ( defined( $Ob_i->{MO} ) ) {
        $Ob_t->{month} = $Ob_i->{MO};
    }
    else {
        $Ob_t->{month} = -32768;
    }
    if ( defined( $Ob_i->{YR} ) ) {
        $Ob_t->{year} = $Ob_i->{YR};
    }
    else {
        $Ob_t->{year} = -32768;
    }
    if ( defined( $Ob_i->{HR} ) ) {
        $Ob_t->{hour} = $Ob_i->{HR} * 100;
    }
    else {
        $Ob_t->{hour} = -32768;
    }
    if ( defined( $Ob_i->{SLP} ) ) {
        $Ob_t->{pressure} = $Ob_i->{SLP} * 10;
    }
    else {
        $Ob_t->{pressure} = -32768;
    }
    if ( defined( $Ob_i->{AT} ) ) {
        $Ob_t->{mat} = $Ob_i->{AT} * 10;
    }
    else {
        $Ob_t->{mat} = -32768;
    }
    if ( defined( $Ob_i->{SST} ) ) {
        $Ob_t->{sst} = $Ob_i->{SST} * 10;
    }
    else {
        $Ob_t->{sst} = -32768;
    }
    if ( defined( $Ob_i->{LAT} ) ) {
        $Ob_t->{latitude} = $Ob_i->{LAT} * 10;
    }
    else {
        $Ob_t->{latitude} = -32768;
    }
    if ( defined( $Ob_i->{LON} ) ) {
        $Ob_t->{longitude} = $Ob_i->{LON} * 10;
    }
    else {
        $Ob_t->{longitude} = -32768;
    }
    if ( defined( $Ob_i->{DCK} ) ) {
        $Ob_t->{deck_id} = $Ob_i->{DCK};
    }
    else {
        $Ob_t->{deck_id} = 999;
    }
    if ( defined( $Ob_i->{SID} ) ) {
        $Ob_t->{source_id} = $Ob_i->{SID};
    }
    else {
        $Ob_t->{source_id} = 999;
    }
    $Ob_t->{obtype} = 2;
    write_ob($Ob_t);

}

sub write_ob {
    my $Ob_t = shift;
    if ( $Ob_t->{year} == -32768 || $Ob_t->{month} == -32768 ) { return; }
    if (   defined($Current_file)
        && $Ob_t->{year} == $Current_year
        && $Ob_t->{month} == $Current_month )
    {
        $Ob_t->write_to_file($Current_file);
    }
    else {
        if ( defined($Current_file) ) { close($Current_file); }
        my $Filename = sprintf "../tenday_files/%04d%02d", $Ob_t->{year},
          $Ob_t->{month};
        open( $Current_file, ">>$Filename" ) or die "Can't open $Filename";
        $Current_year  = $Ob_t->{year};
        $Current_month = $Ob_t->{month};
        $Ob_t->write_to_file($Current_file);
    }
}

