#!/usr/bin/perl 

# Add the Google analytics monitoring script to the botom of
#  each HTML page.

use strict;
use warnings;
use FindBin;
use File::Find;

# Make the additions - run addScript on every file under the docs directory.
find( \&addScript, ("$FindBin::Bin/../docs") );
#find( \&addScript, ("/home/h03/hadpb/tasks/imma") );

# Add the analytics script to a file
sub addScript {
    my $Filename = $File::Find::name;
    if ( $Filename !~ /\.html$/ ) { return; }    # Only do html files
    print "$Filename\n";
    open( DIN,  "$Filename" )         or die "Can't open $Filename";
    open( DOUT, ">$Filename" . "wa" ) or die "Can't open $Filename.wa";
    while (<DIN>) {
        if ( $_ =~ /_getTracker/ ) {
            warn "$Filename already has code";
            close(DIN);
            close(DOUT);
            unlink( "$Filename" . "wa" );
            return;
        }
        if ( $_ =~ /\/body/ ) {
            print DOUT "<script type=\"text/javascript\">\n";
            print DOUT
              "var gaJsHost = ((\"https:\" == document.location.protocol)"
              . " ? \"https://ssl.\" : \"http://www.\");\n";
            print DOUT
              "document.write(unescape(\"\%3Cscript src='\" + gaJsHost + "
              . "\"google-analytics.com/ga.js' type='text/javascript'\%3E\%3C/script\%3E\"));\n";
            print DOUT "</script>\n";
            print DOUT "<script type=\"text/javascript\">\n";
            print DOUT
              "var pageTracker = _gat._getTracker(\"UA-3015554-1\");\n";
            print DOUT "pageTracker._initData();\n";
            print DOUT "pageTracker._trackPageview();\n";
            print DOUT "</script>\n";
        }
        print DOUT $_;
    }
    close(DIN);
    close(DOUT);
    rename( "$Filename" . "wa", "$Filename" );
}
