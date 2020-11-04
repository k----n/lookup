#!/usr/bin/perl
use lib ("$ENV{HOME}/lookup", "$ENV{HOME}/lib64/perl5", "/home/audris/lib64/perl5","$ENV{HOME}/lib/perl5", "$ENV{HOME}/lib/x86_64-linux-gnu/perl", "$ENV{HOME}/share/perl5");
use strict;
use warnings;
use Error qw(:try);

use TokyoCabinet;
use Compress::LZF;
use cmt;

my $npar = 32;
sub extrPar {
  my $codeC = $_[0];
  my $code = safeDecomp ($codeC);

  my $parent = "";
  my ($pre, @rest) = split(/\n\n/, $code, -1);
  for my $l (split(/\n/, $pre, -1)){
     $parent .= ":$1" if ($l =~ m/^parent (.*)$/);
  }
  $parent =~ s/^:// if defined $parent;
  return $parent;
}

my $part = -1;
$part = $ARGV[2] if defined $ARGV[2];
my $minRow = $ARGV[1];
my (%fhos, %fhoc, %fhoc1);
my $sections = 128;
my $fbase="/data/All.blobs/commit_";
for my $s (0..($npar-1)){
  next if $part >= 0 && $s != $part; 
  tie %{$fhoc1{$s}}, "TokyoCabinet::HDB", "$ARGV[0].$s.tch", TokyoCabinet::HDB::OWRITER | TokyoCabinet::HDB::OCREAT,
        16777213, -1, -1, TokyoCabinet::TDB::TLARGE, 100000
     or die "cant open $ARGV[0].$s.tch\n";
}
for my $s (0..127){
  print STDERR "reading $s\n";
  open A, "tac $fbase$s.idx|";
  open A, "$fbase$s.idx" if $part >= 0;
  open FD, "$fbase$s.bin";
  binmode(FD);
  my $n = 0;
  while (<A>){
    chop();
    my ($nn, $of, $len, $hash) = split (/\;/, $_, -1);
    my $h = fromHex ($hash);
    my $s1 = $s % $npar;
    $n++;
    # commits with existing children and commits with no existing children are taken care of by going over the new commits and making sure they are assigned as children to their parents
    #  but the new commits might be parents of the existing commits: ie, c2cc might have a commit that is not in the current set of commits, but need to loop over them as they will appear 
    #  as new commits
    #  To check for these instances loop over all c2cc and find all that are not in the commits
    #  An alternative way is export c2pc as a flat map, then sort by parent
    if ($n > $minRow && $part < 0){
      print STDERR "$s $s1 $n\n"; #handle only new commits/ what about cnc?
      last;
    }
    seek (FD, $of, 0);
    my $codeC = "";
    my $rl = read (FD, $codeC, $len);

    my ($parent) = extrPar ($codeC);
    if ($parent eq ""){
      #print "$hash\n"; #no parent
      next;
    }
    for my $p (split(/:/, $parent)){
      my $pbin = fromHex ($p);
      if ($part >= 0){
        my $sec = (unpack "C", substr ($pbin, 0, 1)) % $npar; 
        $hoc{$pbin}{$h}++ if $sec == $part;
      }else{
        $fhoc{$pbin}{$h}++;
      }
    }
  }
}
my $ndone = 0;
while (my ($c, $v) = each %fhoc){
  my $sec = (unpack "C", substr ($c, 0, 1)) % $npar; 
  if (defined $fhoc1{$sec}{$c}){
    my $vv = $fhoc1{$sec}{$c};
    for my $i (0..(length($vv)/20-1)){
      $v->{substr($vv, $i*20, 20)}++;
    }
  }
  print STDERR "$ndone processed\n" if (!($ndone++ % 10000000));
  my $v1 = join '', sort keys %{$v};
  $fhoc1{$sec}{$c} = $v1;
}
for my $s (0..($npar-1)){
  next if $part >= 0 && $s != $part;
  untie %{$fhoc1{$s}};
}

