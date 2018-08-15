#!/usr/bin/perl -w

#  Run QC on the tenday obs.
# this version works on the new NCDC obs

use strict;
use lib "$ENV{MDS2}/data_structures/source";
use Tenday;
use Symbol;
use POSIX;
use FindBin;

# Run QC on each month's obs
my @Files = <../../tenday_files/??????>;
foreach my $Ob_file_name (@Files) {

    `$ENV{MDS2}/qc/base_qc/bin/base_qc.perl --infile $Ob_file_name --outfile tenday_tmp 1> base_qc.out 2> base_qc.err`;
    unless ( -s "base_qc.out" && -z "base_qc.err" ) {
        Cleanup();
        die "Failed to run base QC for $Ob_file_name";
    }
    `mv tenday_tmp $Ob_file_name`;

    `$ENV{MDS2}/qc/sst_qc/bin/sst_qc.perl --infile $Ob_file_name --outfile tenday_tmp 1> sst_qc.out 2> sst_qc.err`;
    unless ( -s "sst_qc.out" && -z "sst_qc.err" ) {
        Cleanup();
        die "Failed to run sst QC for $Ob_file_name";
    }
    `mv tenday_tmp $Ob_file_name`;

    `$ENV{MDS2}/qc/mat_qc/bin/mat_qc.perl --infile $Ob_file_name --outfile tenday_tmp 1> mat_qc.out 2> mat_qc.err`;
    unless ( -s "mat_qc.out" && -z "mat_qc.err" ) {
        Cleanup();
        die "Failed to run mat QC for $Ob_file_name";
    }
    `mv tenday_tmp $Ob_file_name`;

    `$ENV{MDS2}/qc/ast_qc/bin/ast_qc.perl --infile $Ob_file_name --outfile tenday_tmp 1> ast_qc.out 2> ast_qc.err`;
    unless ( -s "ast_qc.out" && -z "ast_qc.err" ) {
        Cleanup();
        die "Failed to run ast QC for $Ob_file_name";
    }
    `mv tenday_tmp $Ob_file_name`;

    `$ENV{MDS2}/qc/pressure_qc/bin/pressure_qc.perl --infile $Ob_file_name --outfile tenday_tmp 1> pressure_qc.out 2> pressure_qc.err`;
    unless ( -s "pressure_qc.out" && -z "pressure_qc.err" ) {
        Cleanup();
        die "Failed to run pressure QC for $Ob_file_name";
    }
    `mv tenday_tmp $Ob_file_name`;
    
    
    unless ( open( DOUT, ">>$FindBin::Bin/../../tenday_files/qc/base_qc_log" ) ) {
        Cleanup();
        die "Failed to open base QC log file";
    }
    print DOUT "$Ob_file_name\n";
    close(DOUT);
    `cat base_qc.out >> $FindBin::Bin/../../tenday_files/qc/base_qc_log`;

    unless ( open( DOUT, ">>$FindBin::Bin/../../tenday_files/qc/sst_qc_log" ) ) {
        Cleanup();
        die "Failed to open SST QC log file";
    }
    print DOUT "$Ob_file_name\n";
    close(DOUT);
    `cat sst_qc.out >> $FindBin::Bin/../../tenday_files/qc/sst_qc_log`;

    unless ( open( DOUT, ">>$FindBin::Bin/../../tenday_files/qc/mat_qc_log" ) ) {
        Cleanup();
        die "Failed to open MAT QC log file";
    }
    print DOUT "$Ob_file_name\n";
    close(DOUT);
    `cat mat_qc.out >> $FindBin::Bin/../../tenday_files/qc/mat_qc_log`;

    unless ( open( DOUT, ">>$FindBin::Bin/../../tenday_files/qc/ast_qc_log" ) ) {
        Cleanup();
        die "Failed to open AST QC log file";
    }
    print DOUT "$Ob_file_name\n";
    close(DOUT);
    `cat ast_qc.out >> $FindBin::Bin/../../tenday_files/qc/ast_qc_log`;

    unless ( open( DOUT, ">>$FindBin::Bin/../../tenday_files/qc/pressure_qc_log" ) ) {
        Cleanup();
        die "Failed to open Pressure QC log file";
    }
    print DOUT "$Ob_file_name\n";
    close(DOUT);
    `cat pressure_qc.out >> $FindBin::Bin/../../tenday_files/qc/pressure_qc_log`;

#    Cleanup();

}
Cleanup();
    
# Delete all the temporary files and directories
sub Cleanup {
    my @files = qw(data_extraction.err base_qc.out base_qc.err
      sst_qc.out sst_qc.err mat_qc.out mat_qc.err
      ast_qc.out ast_qc.err pressure_qc.out pressure_qc.err
      tenday_tmp);
    foreach (@files) {
        if ( -r $_ ) { unlink $_; }
    }
    chdir "..";
    rmdir $$;
}
