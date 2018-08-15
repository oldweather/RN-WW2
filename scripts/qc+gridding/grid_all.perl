#!/usr/bin/perl

# Make a load of gridded fields from the tenday obs

use strict;
use warnings;
use FindBin;

chdir "$FindBin::Bin" or die "Can't cd to working directory";

`./grid_general.perl --parameter=sst --use_old=false --use_new=true`;
`./grid_general.perl --parameter=sst --use_old=true  --use_new=true`;
`./grid_coverages.perl --parameter=sst`;
`./grid_diffs.perl --parameter=sst`;

`./grid_general.perl --parameter=nat --use_old=false --use_new=true`;
`./grid_general.perl --parameter=nat --use_old=true  --use_new=true`;
`./grid_coverages.perl --parameter=nat`;
`./grid_diffs.perl --parameter=nat`;

`./grid_general.perl --parameter=dat --use_old=false --use_new=true`;
`./grid_general.perl --parameter=dat --use_old=true  --use_new=true`;
`./grid_coverages.perl --parameter=dat`;
`./grid_diffs.perl --parameter=dat`;

`./grid_general.perl --parameter=pre --use_old=false --use_new=true`;
`./grid_general.perl --parameter=pre --use_old=true  --use_new=true`;
`./grid_coverages.perl --parameter=pre`;
`./grid_diffs.perl --parameter=pre`;

