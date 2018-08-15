#!/usr/bin/perl -T

# Convert an IMMA file into KML
# Version to be run as a CGI script

use strict;
use warnings;
use lib "/home/philip/public_html/job/imma/perl_module";
use IMMA;
use Getopt::Long;
#use Date::Calc qw(Delta_Days);
use CGI qw(fatalsToBrowser);

my $q = new CGI;
$q->cgi_error and error( $q, "Error generating KML: " . $q->cgi_error );

my $Title       = "IMMA data";
my $FirstColour = 1;            # Choose the colour where there is only one ship
if ( defined( $q->param("title") ) ) { $Title = $q->param("title"); }
if ( defined( $q->param("firstcolour") ) ) {
    $FirstColour = $q->param("firstcolour");
}
#my $InFile = "/home/philip/public_html/job/digitisation/rn_ww2_data/imma_files/sorted_by_ship/VALIANT.imma";
my $InFile = $q->param("file") || error( $q, "No filename given." );
unless ( $InFile =~ /(.*\.imma)/ ) { error( $q, "Bad filename" ); }
open( DIN, $1 ) or error( $q, "Can't open file $1" );

# Group the IMMA data by ship and sort by date
my %Ships;
while ( my $Record = imma_read( \*DIN ) ) {
    unless ( defined( $Record->{LAT} ) && defined( $Record->{LON} ) ) {
        next;
    }
    if ( defined( $Record->{ID} ) ) {
        push @{ $Ships{ $Record->{ID} } }, $Record;
    }
    else { push @{ $Ships{' '} }, $Record; }
}
close(DIN);
# 
#for my $Ship ( keys %Ships ) {
#    @{ $Ships{$Ship} } = sort by_date @{ $Ships{$Ship} };
#}

# Output the KML file header
print $q->header("application/vnd.google-earth.kml+xml");
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<kml xmlns=\"http://earth.google.com/kml/2.2\">\n";
print "  <Document>\n";
print "    <name>$Title</name>\n";
print "    <open>0</open>\n";

# Make styles for the placemarks - use the BIOME icon colours
my $HTML_base = "http://brohan.org/philip/kml";
for ( my $i = 1 ; $i <= 28 ; $i++ ) {
    my $Style_name = sprintf "Ship_%02d", $i;
    my $Icon_href = sprintf "%s/biome_6000/img/biome_%02d.png", $HTML_base, $i;
    print "<Style id=\"$Style_name\">\n";
    print " <IconStyle>\n";
    print "  <Icon>\n";
    print "   <href>$Icon_href</href>\n";
    print " </Icon>\n";
    print " </IconStyle>\n";
    print "</Style>\n";
}

# Add a default style for unnamed ships
print "<Style id=\"Ship_other\">\n";
print " <IconStyle>\n";
print "  <Icon>\n";
print
  "   <href>http://labs.google.com/ridefinder/images/mm_20_red.png</href>\n";
print " </Icon>\n";
print " </IconStyle>\n";
print "</Style>\n";

# Add a style for ship route lines
print "<Style id=\"Ship_route\">\n";
print "  <LineStyle>\n";
print "    <color>ff777777</color>\n";
print "    <width>2</width>\n";
print "  </LineStyle>\n";
print "</Style>\n";

# One folder per named ship
my $Count = $FirstColour;

#foreach my $Ship (sort { scalar(@{$Ships{$a}}) <=> scalar(@{$Ships{$b}}) } ( keys %Ships ));
foreach my $Ship ( sort ( keys %Ships ) ) {
    if ( $Ship eq ' ' ) { next; }    # Leave nameless ships until later
    makePlacemarks($Ship);
}
if ( defined( $Ships{' '} ) ) {
    makePlacemarks(' ');             # Nameless ships
}

# KML file footer
print "</Document>\n";
print "</kml>\n";

# Sort IMMA records by date
sub by_date {
    my $aYR = $a->{YR};
    unless ( defined($aYR) ) { $aYR = 0; }
    my $aMO = $a->{MO};
    unless ( defined($aMO) ) { $aMO = 0; }
    my $aDY = $a->{DY};
    unless ( defined($aDY) ) { $aDY = 0; }
    my $aHR = $a->{HR};
    unless ( defined($aHR) ) { $aHR = 0; }
    my $bYR = $b->{YR};
    unless ( defined($bYR) ) { $bYR = 0; }
    my $bMO = $b->{MO};
    unless ( defined($bMO) ) { $bMO = 0; }
    my $bDY = $b->{DY};
    unless ( defined($bDY) ) { $bDY = 0; }
    my $bHR = $b->{HR};
    unless ( defined($bHR) ) { $bHR = 0; }
    return $bYR <=> $aYR
      or $bMO <=> $aMO
      or $bDY <=> $aDY
      or $bHR <=> $aHR;
}

# Make the placemarks for a ship
sub makePlacemarks {
    my $Ship = shift;
    print "   <Folder>\n";
    print "     <name>$Ship</name>\n";
    print "     <visibility>0</visibility>\n";
    print "     <open>0</open>\n";

    # One placemark for each IMMA record with a position
    for ( my $i = 0 ; $i < scalar( @{ $Ships{$Ship} } ) ; $i++ ) {
        unless ( defined( $Ships{$Ship}[$i]->{LAT} )
            && defined( $Ships{$Ship}[$i]->{LON} ) )
        {
            next;
        }
        if ( $Ships{$Ship}[$i]->{LON} > 180 ) {
            $Ships{$Ship}[$i]->{LON} -= 360;
        }
        print "      <Placemark>\n";
        my $Style_name;
        if ( $Ship eq ' ' ) {
            $Style_name = "Ship_other";
        }
        else {
            $Style_name = sprintf "Ship_%02d", $Count;
        }
        print "        <styleUrl>\#$Style_name</styleUrl>\n";
        print "        <description>\n";
        print makeDescription( $Ships{$Ship}[$i] );
        print "\n        </description>\n";
        print "        <Point>\n";
        print
          "          <coordinates>$Ships{$Ship}[$i]->{LON},$Ships{$Ship}[$i]->{LAT},0</coordinates>\n";
        print "        </Point>\n";
        my $Ts;

        if ( defined( $Ships{$Ship}[$i]->{YR} ) ) {
            $Ts = sprintf "%04d", $Ships{$Ship}[$i]->{YR};
            if ( defined( $Ships{$Ship}[$i]->{MO} ) ) {
                $Ts .= sprintf "-%02d", $Ships{$Ship}[$i]->{MO};
                if ( defined( $Ships{$Ship}[$i]->{DY} ) ) {
                    $Ts .= sprintf "-%02d", $Ships{$Ship}[$i]->{DY};
                    if ( defined( $Ships{$Ship}[$i]->{HR} ) ) {
                        $Ts .= sprintf "T%02d", int( $Ships{$Ship}[$i]->{HR} );
                        my $Minute =
                          ( $Ships{$Ship}[$i]->{HR} -
                              int( $Ships{$Ship}[$i]->{HR} ) ) * 60;
                        $Ts .= sprintf ":%02d", int($Minute);
                        my $Second = ( $Minute - int($Minute) );
                        $Ts .= sprintf ":%02dZ", $Second;
                    }
                }
            }
        }
        if ( defined($Ts) ) {
            print "        <TimeStamp>\n";
            print "          <when>$Ts</when>\n";
            print "        </TimeStamp>\n";
        }
        print "      </Placemark>\n";

        # Add a route link if no discontinuity in position
        if (   $Ship ne ' '
            && $i > 0
            && areClose( $Ships{$Ship}[$i], $Ships{$Ship}[ $i - 1 ] ) )
        {
            print "      <Placemark>\n";
            print "        <styleUrl>\#Ship_route</styleUrl>\n";
            print "        <LineString>\n";
            print "          <coordinates>";
            my $Record = $Ships{$Ship}[ $i - 1 ];
            print "$Record->{LON},$Record->{LAT},0 ";
            $Record = $Ships{$Ship}[$i];
            print "$Record->{LON},$Record->{LAT},0";
            print "</coordinates>\n";
            print "        </LineString>\n";

            if ( defined($Ts) ) {
                print "        <TimeStamp>\n";
                print "          <when>$Ts</when>\n";
                print "        </TimeStamp>\n";
            }
            print "      </Placemark>\n";
        }
    }
    print "   </Folder>\n";
    if ( $Ship ne ' ' ) {
        $Count++;
        if ( $Count > 28 ) { $Count = 1; }
    }

}

# Are two ships close enough to draw a route line linking their positions
sub areClose {
    my $First  = shift;
    my $Second = shift;
    unless ( defined( $First->{YR} )
        && defined( $Second->{YR} )
        && defined( $First->{MO} )
        && defined( $Second->{MO} )
        && defined( $First->{DY} )
        && defined( $Second->{DY} ) )
    {
        return;
    }

    #    my $deltaT = abs(
    #        Delta_Days(
    #            $First->{YR},  $First->{MO},  $First->{DY},
    #            $Second->{YR}, $Second->{MO}, $Second->{DY}
    #        )
    #    );
    #   if ( $deltaT > 2 ) { return; }
    if ( abs( $First->{LAT} - $Second->{LAT} ) > 20 ) { return; }
    my $Diff_lon = $First->{LON} - $Second->{LON};
    if ( abs($Diff_lon) > 20 ) {
        return;
    }

    return 1;
}

# Make the HTML to go in the description element for a placemark
# this is what appears in the pop-up window when the icon is
#  selected
sub makeDescription {
    my $Record      = shift;
    my $Attachment  = 0;
    my $Description = "<![CDATA[";
    $Description .= "<table cellpadding=3 bgcolor=grey>";
    for ( my $i = 0 ;
        $i < scalar( @{ $IMMA::parameters[$Attachment] } ) ; $i++ )
    {
        if ( $i % 4 == 0 ) { $Description .= "<tr>"; }

        #;. $IMMA::parameters[$Attachment][$i] . ":</td>";
        if ( defined( $Record->{ $IMMA::parameters[$Attachment][$i] } ) ) {
            $Description .= "<td bgcolor=lightgrey>";
            $Description .= sprintf "<pre>%-5s%10s</pre></td>",
              $IMMA::parameters[$Attachment][$i] . ":",
              $Record->{ $IMMA::parameters[$Attachment][$i] };
        }
        else {

#            $Description .= sprintf "<td bgcolor=grey align=\"right\">%10s</td>", "N/A";
            $Description .= "<td bgcolor=grey>";
            $Description .= sprintf "<pre>%-5s%10s</pre></td>",
              $IMMA::parameters[$Attachment][$i] . ":", "N/A";
        }
        if (   $i % 4 == 4
            || $i == scalar( @{ $IMMA::parameters[$Attachment] } ) - 1 )
        {
            $Description .= "</tr>";
        }
    }
    $Description .= "</table>";
    $Description .= "]]>";
    return $Description;
}

sub error {
    my( $q, $reason ) = @_;

    print $q->header( "text/html" ),
          $q->start_html( "Error" ),
          $q->h1( "Error" ),
          $q->p( "Your request not procesed because the following error ",
                 "occured: " ),
          $q->p( $q->i( $reason ) ),
          $q->end_html;
    exit;
}
