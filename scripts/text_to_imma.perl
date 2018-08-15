#!/usr/bin/perl

# Brocess the digitised logbook data from NCDC into
#  IMMA records.

use strict;
use warnings;
use lib "/home/hc1300/hadpb/tasks/digitisation/imma/";
use IMMA;
use Getopt::Long;
use FindBin;

my ( $Ship_name, $Last_lat_f, $Last_lon_f, $Last_tz );
$Last_lat_f = undef;
$Last_lon_f = undef;
GetOptions( "name=s" => \$Ship_name );

# Get the list of port locations
my %Ports;
open( DIN, "$FindBin::Bin/../fixed_data/locations.processed" )
  or die "Can't get port locations";
while (<DIN>) {
    my @Fields = split /\t/, $_;
    my $Port = shift(@Fields);
    $Ports{$Port} = [@Fields];
}
close(DIN);

# Set the list of port exceptions
# These harbour names are used for multiple places, and these ships
#  are not in the location given in the ports list, so don't set
#  locations from harbour in these cases.
my %Port_exceptions;
$Port_exceptions{AUSONIA}{SYDNEY}               = 1;    # Not Australia
$Port_exceptions{DUNDEE}{SYDNEY}                = 1;
$Port_exceptions{DUNDEE}{PICTON}                = 1;
$Port_exceptions{ENTERPRISE}{'NEWPORT NEWS'}    = 1;    # Probably Wales
$Port_exceptions{HOBART}{HALIFAX}               = 1;    # Halife ?
$Port_exceptions{MALOJA}{SYDNEY}                = 1;
$Port_exceptions{MILFORD}{BAHIA}                = 1;    # Not Brazil
$Port_exceptions{PERTH}{HALIFAX}                = 1;
$Port_exceptions{RORQUAL}{HALIFAX}              = 1;
$Port_exceptions{SCARBOROUGH}{PENANG}           = 1;    # Not Malaya
$Port_exceptions{SCARBOROUGH}{'PUNTA DEL ESTE'} = 1;
$Port_exceptions{SEARCHER}{PORTLAND}            = 1;    # Oregon, not UK
$Port_exceptions{SHOREHAM}{SHANGHAI}            = 1;    # Not China
$Port_exceptions{TRACKER}{FREMANTLE}            = 1;    # Not Australia
$Port_exceptions{WESTON}{PORTLAND}              = 1;
$Port_exceptions{YORK}{'ST JOHNS'}              = 1;    # Not Canada

while (<STDIN>) {
    chomp($_);

    if ( $_ =~ /^1/ ) {                                 # Header line
        $Ship_name = substr( $_, 7, 20 );
        $Ship_name =~ s/^ +//;
        $Last_lat_f = undef;
        $Last_lon_f = undef;
    }

    if ( $_ =~ /^2/ ) {                                 # Data line

        my $Ob = new IMMA;
        $Ob->clear();                                   # Why is this necessary?
        push @{ $Ob->{attachments} }, 0;
        $Ob->{YR} = num_read( substr( $_, 13, 4 ) );
        $Ob->{MO} = num_read( substr( $_, 11, 2 ) );
        $Ob->{DY} = num_read( substr( $_, 9,  2 ) );
        $Ob->{HR} = num_read( substr( $_, 39, 2 ) );

        $Ob->{LAT} = num_read( substr( $_, 75, 4 ) );
        if ( defined( $Ob->{LAT} ) ) {
            my $Minutes = num_read( substr( $_, 77, 2 ) );
            unless ( defined($Minutes) ) { $Minutes = 30; }
            my $Degrees = num_read( substr( $_, 75, 2 ) );
            $Ob->{LAT} = ( $Degrees + $Minutes / 60 );
            my $Lat_flag = uc( substr( $_, 79, 1 ) );

            if ( $Lat_flag eq 'N' or $Lat_flag eq 'S' ) {
                $Last_lat_f = $Lat_flag;
            }
            if ( defined($Last_lat_f) && $Last_lat_f eq 'S' ) {
                $Ob->{LAT} = -$Ob->{LAT};
            }
            if ( abs( $Ob->{LAT} ) > 900 ) { $Ob->{LAT} /= 10; }
        }

        $Ob->{LON}       = num_read( substr( $_, 80, 5 ) );
        $Ob->{time_zone} = num_read( substr( $_, 71, 3 ) );
        if ( defined( $Ob->{time_zone} ) ) {
            $Last_tz = $Ob->{time_zone};
        }
        elsif ( defined($Last_tz) ) {
            $Ob->{time_zone} = $Last_tz;
        }
        if ( defined( $Ob->{LON} ) ) {
            my $Minutes = num_read( substr( $_, 83, 2 ) );
            unless ( defined($Minutes) ) { $Minutes = 30; }
            my $Degrees = num_read( substr( $_, 80, 3 ) );
            $Ob->{LON} = ( $Degrees + $Minutes / 60 );
            my $Lon_flag = uc( substr( $_, 85, 1 ) );

            if ( $Lon_flag eq 'E' or $Lon_flag eq 'W' ) {
                $Last_lon_f = $Lon_flag;
            }
            if ( defined($Last_lon_f) && $Last_lon_f eq 'W' ) {
                $Ob->{LON} = -$Ob->{LON};
            }

            if ( abs( $Ob->{LON} ) > 1800 ) { $Ob->{LON} /= 10; }
            $Ob->{LON} = check_long_against_tz( $Ob->{LON}, $Ob->{time_zone} );
        }
        if ( !defined( $Ob->{LON} ) && !defined( $Ob->{LAT} ) ) {
            my $Port = substr( $_, 19, 20 );
            if ( $Port =~ /^DEVONPORT/ ) {

           # Plymouth, or Auckland? Guess Plymouth unless in Southern Hemisphere
                if ( defined($Last_lat_f) && $Last_lat_f eq 'S' ) {
                    $Port =~ s/^DEVONPORT /DEVONPORT2/;
                }
            }
            my $Tport = $Port;
            $Tport =~ s/\s+$//;
            if ( defined( $Ports{$Port} )
                && !defined( $Port_exceptions{$Ship_name}{$Tport} ) )
            {
                $Ob->{LON} = $Ports{$Port}[0];
                $Ob->{LAT} = $Ports{$Port}[1];
                $Ob->{LI}  = 6;                  # position from metadata
            }
        }
        else {
            $Ob->{LI} = 4;                       # Deg+Min position precision
        }
        if ( defined( $Ob->{time_zone} ) && defined( $Ob->{HR} ) ) {
            correct_hour_for_tz($Ob);
        }
        else {
            $Ob->{HR} = undef;
        }
        $Ob->{IM}   = 0;                           # Check with Scott
        $Ob->{ATTC} = 2;                           # icoads and supplemental
        $Ob->{TI}   = 0;                           # Nearest hour time precision
        $Ob->{DS}   = undef;                       # Unknown course
        $Ob->{VS}   = undef;                       # Unknown speed
        $Ob->{NID}  = 3;                           # Check with Scott
        $Ob->{II}   = 10;                          # Check with Scott
        $Ob->{ID}   = substr( $Ship_name, 0, 9 );
        unless ( $Ob->{ID} =~ /\w/ ) { $Ob->{ID} = undef; }
        $Ob->{C1} = '03';                          # UK recruited

        if ( substr( $_, 41, 3 ) =~ /\d/ ) {
            $Ob->{DI} = 5;                         # Winds on 360 point compass
            $Ob->{D} = num_read( substr( $_, 41, 3 ) );
            if ( $Ob->{D} == 0 ) {
                $Ob->{D} = 360;
            }    # Code is 1-360, 0 is not allowed
        }
        elsif ( substr( $_, 41, 3 ) =~ /\w/ ) {
            $Ob->{DI} = 3;    # Winds on 16 point compass
            $Ob->{D}  =
              compass_to_degrees( substr( $_, 41, 3 ) );    # Wind direction
        }
        else {
            $Ob->{DI} = undef;                              # No wind data
            $Ob->{D}  = undef;
        }
        $Ob->{W} =
          beaufort_to_mps( num_read( substr( $_, 44, 2 ) ) );    # Wind force
        if ( defined( $Ob->{W} ) ) {
            $Ob->{WI} = 5;    # Beaufort wind force
        }
        $Ob->{VV} = encode_visibility( num_read( substr( $_, 49, 2 ) ) );
        if ( defined( $Ob->{VV} ) ) {
            $Ob->{VI} = 0;    # Unknown visibility method (check)
        }
        $Ob->{WW}  = undef;
        $Ob->{W1}  = undef;
        $Ob->{SLP} = substr( $_, 53, 5 );
        unless ( $Ob->{SLP} =~ /\d/ ) { $Ob->{SLP} = undef; }

        if ( defined( $Ob->{SLP} ) ) {
            $Ob->{SLP} =~ s/ /0/g;    # positional, so infil 0s
            if ( $Ob->{SLP} =~ /^i/ ) {    # Convert from inches
                $Ob->{SLP} = substr( $Ob->{SLP}, 1, 4 ) * 3.386;
            }
            $Ob->{SLP} /= 10;
        }
        $Ob->{A}   = undef;                              # No pressure tendency
        $Ob->{PPP} = undef;                              # No pressure change
        $Ob->{AT}  = num_read( substr( $_, 58, 5 ) );    # Dry bulb temp
        if ( defined( $Ob->{AT} ) ) {    # Convert from farenheit
            $Ob->{AT} = ( $Ob->{AT} - 320 ) * 5 / 90;
        }
        $Ob->{WBTI} = undef;                            # Don't know how derived
        $Ob->{WBT} = num_read( substr( $_, 63, 5 ) );   # Wet bulb temp
        if ( defined( $Ob->{WBT} ) ) {                  # Convert from farenheit
            $Ob->{WBT} = ( $Ob->{WBT} - 320 ) * 5 / 90;
        }
        $Ob->{DPTI} = undef;    # No dew point temperature
        $Ob->{DPT}  = undef;    # No dew point temperature
        $Ob->{SI}   = undef;    # Don't know how SST measured (find out?)
        $Ob->{SST} = num_read( substr( $_, 68, 3 ) );    # SST
        if ( defined( $Ob->{SST} ) ) {    # Convert from farenheit
            $Ob->{SST} = ( $Ob->{SST} - 320 ) * 5 / 90;
        }
        if (   defined( $Ob->{AT} )
            || defined( $Ob->{WBT} )
            || defined( $Ob->{DPT} )
            || defined( $Ob->{SST} ) )
        {
            $Ob->{IT} = 4;                # Temps in degF and 10ths
        }

        # No data on cloud, waves or swell
        foreach my $Var (qw(N NH CL HI H CM CH WD WP WH SD SP SH)) {
            $Ob->{$Var} = undef;
        }

        # Add the icoads attachment
        push @{ $Ob->{attachments} }, 1;
        $Ob->{BSI} = undef;
        $Ob->{B10} = undef;               # 10 degree box
        $Ob->{B1}  = undef;               # 1 degree box
        $Ob->{DCK} = 245;                 # Deck ID - from Scott
        $Ob->{SID} = 126;                 # Source ID - from Scott
        $Ob->{PT}  = 1;                   # 'Foreign military'
        foreach my $Var (qw(DUPS DUPC TC PB WX SX C2)) {
            $Ob->{$Var} = undef;
        }

        # Other elements all missing
        foreach my $Var ( @{ $IMMA::parameters[1] } ) {
            unless ( exists( $Ob->{$Var} ) ) {
                $Ob->{$Var} = undef;
            }
        }

        # Add the original data as a supplemental attachment
        push @{ $Ob->{attachments} }, 99;
        $Ob->{ATTE} = undef;
        $Ob->{SUPD} = $_;

        # Output the IMMA ob
        $Ob->write( \*STDOUT );

    }

}

# Read in the ob as a number
sub num_read {
    my $Str = shift;
    if ( !defined($Str) || $Str !~ /\d/ || $Str =~ /\~/ ) { return; }
    $Str =~ s/ /0/g;    # positional, so infil 0s
    return $Str + 0;
}

# Convert visibility from miles into code 90-99
sub encode_visibility {
    my $Vis = shift;
    unless ( defined($Vis) && $Vis =~ /\d/ && $Vis >= 0 ) {
        return;
    }
    $Vis *= 1.61;       # Convert miles to kilometers
    if    ( $Vis < 0.05 ) { return 90; }
    elsif ( $Vis < 0.2 )  { return 91; }
    elsif ( $Vis < 0.5 )  { return 92; }
    elsif ( $Vis < 1 )    { return 93; }
    elsif ( $Vis < 2 )    { return 94; }
    elsif ( $Vis < 4 )    { return 95; }
    elsif ( $Vis < 10 )   { return 96; }
    elsif ( $Vis < 20 )   { return 97; }
    elsif ( $Vis < 50 )   { return 98; }
    else { return 99; }
}

# Convert Beaufort force to speed im m/s
# Use (WMO 1100) beaufort equivalent speeds (for COADS compatibility) 
sub beaufort_to_mps {
    my $Beau = shift;
    unless ( defined($Beau) && $Beau =~ /\d/ && $Beau >= 0 && $Beau <= 12 ) {
        return;
    }
    return (0.,1.,2.6,4.6,6.7,9.3,12.3,15.4,19.,22.6,26.8,30.9,35.)
      [$Beau];
}

# Convert 16-point compass direction to direction in degrees
sub compass_to_degrees {
    my $Dir_c      = shift;
    my %Directions = (
        n   => 360,
        nne => 23,
        ne  => 45,
        ene => 68,
        e   => 90,
        ese => 113,
        se  => 135,
        sse => 158,
        s   => 180,
        ssw => 203,
        sw  => 225,
        wsw => 248,
        w   => 270,
        wnw => 293,
        nw  => 315,
        nnw => 348,
        c   => 361,    # Calm
        v   => 362     # Variable
    );
    unless ( defined($Dir_c) ) { return undef; }
    $Dir_c =~ s/\W//g;
    if ( exists( $Directions{ lc($Dir_c) } ) ) {
        return $Directions{ lc($Dir_c) };
    }
    else {
        return undef;
    }
}

sub check_long_against_tz {
    my $longitude = shift;
    my $time_zone = shift;
    unless ( defined($longitude)
        && defined($time_zone) )
    {
        return $longitude;
    }
    if ( $longitude * $time_zone > 0 ) {

        #        $longitude = -$longitude;
        return $longitude;
    }
    if ( abs( ( $longitude * 12 / 180 ) + $time_zone ) > 3 ) {
        if ( abs( ( $longitude * 12 / 1800 ) + $time_zone ) < 1.5 ) {
            $longitude /= 10;
        }
        elsif ( abs( ( $longitude * 12 / 18 ) + $time_zone ) < 1.5 ) {
            $longitude *= 10;
        }
    }
    return $longitude;
}

# Correct the date to UTC from local time
sub correct_hour_for_tz {
    my @Days_in_month = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
    my $Ob            = shift;
    unless ( defined( $Ob->{time_zone} )
        && defined( $Ob->{HR} )
        && defined( $Ob->{DY} )
        && defined( $Ob->{MO} )
        && defined( $Ob->{YR} ) )
    {
        $Ob->{HR} = undef;
        return;
    }
    $Ob->{HR} += $Ob->{time_zone};
    if ( $Ob->{HR} < 0 ) {
        $Ob->{HR} += 24;
        $Ob->{DY}--;
        if ( $Ob->{DY} < 0 ) {
            $Ob->{MO}--;
            if ( $Ob->{MO} < 1 ) {
                $Ob->{YR}--;
                $Ob->{MO} = 12;
            }
            $Ob->{DY} = $Days_in_month[ $Ob->{MO} - 1 ];
        }
    }
    if ( $Ob->{HR} > 23.59 ) {
        $Ob->{HR} -= 24;
        $Ob->{DY}++;
        if ( $Ob->{DY} > $Days_in_month[ $Ob->{MO} - 1 ] ) {
            $Ob->{DY} = 1;
            $Ob->{MO}++;
            if ( $Ob->{MO} > 12 ) {
                $Ob->{YR}++;
                $Ob->{MO} = 1;
            }
        }
    }
    return 1;
}
