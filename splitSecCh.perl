#!/usr/bin/perl
use IO::File;  
use PerlIO::gzip;
use strict;
use warnings;


my $filename = $ARGV[0];
my $nseg = $ARGV[1];


my $fileno = 0;
my $line = 0;
my @fh;
for my $seg (0..($nseg-1)){
  my $fh;
  open $fh, '>:gzip', "${filename}$seg.gz";
  $fh [$seg] = *$fh;
}
while (<STDIN>) {
  my $l = $_;
  my $seg = (unpack "C", substr ($l, 0, 1))%$nseg;
  my $f = $fh[$seg]; 
  print $f $_; 
}