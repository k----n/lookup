use strict;
use warnings;

use utf8;
no utf8;
use JSON;

my $counter = 0;
my @docs;

my $v = $ARGV[0];
my $s = $ARGV[1];
my %d;
my $cnt = 0;
for my $ty ("A2a","A2c","A2f","A2fb","A2g","A2P","A2tspan"){
  my $str = "zcat ../gz/A2summFull.$ty.$v$s.gz|";
  $str = "zcat ../gz/${ty}FullH$v.$s.gz|" if $ty eq "A2a";
  $str = "zcat ../c2fb/${ty}Full$v$s.s|" if $ty eq "A2tspan";
  open A, $str;
  while (<A>){
    chop(); 
    my ($a, @x) = split (/;/);
    if ($ty eq "A2tspan"){
      $d{$a}{EarlistCommitDate} = $x[0]+0;
      $d{$a}{LatestCommitDate} = $x[1]+0;
      next;
    }
    if ($ty eq "A2a"){
      $d{$a}{Alias}{$x[0]}++;
      next;
    }
    if ($ty eq "A2g"){
      $d{$a}{Gender} = $x[0];
      next;
    }
    my $k = shift @x;
    next if !defined $k;
    if ($k =~ /=/){
      $cnt ++ if $ty eq "A2c";
      my ($ke, $va) = split (/=/, $k, -1);
      $ke = 'NumCommits' if $ke eq "A2c";
      $ke = 'NumFiles' if $ke eq "A2f";
      $ke = 'NumFirstBlobs' if $ke eq "A2fb";
      $ke = 'NumProjects' if $ke eq "A2P";
      $d{$a}{$ke} = $va;
    }else{
      for $k (@x){
        my ($ke, $va) = split (/=/, $k, -1);  
        $d{$a}{e}{$ke} = $va;
      }
    }
  }
}
#print STDERR "read $cnt\n";
$cnt = 0;
for my $a (keys %d){
  if (!defined $d{$a}{NumCommits}){
    my @k = keys %{$d{$a}};
    print STDERR "@a;@k\n";
    last;
  }
  my $doc = {
    AuthorID => $a,
    NumCommits => $d{$a}{NumCommits}+0
  };
  for my $f ("Gender","NumFiles", "NumFirstBlobs", "NumProjects", "EarlistCommitDate", "LatestCommitDate"){
    if (defined $d{$a}{$f}){
      my $val = $d{$a}{$f};
      $val += 0 if $f =~ /^Num/;
      $doc->{$f} = $val;
    }
  }
  if (defined $d{$a}{Alias}){
    my @as = keys %{$d{$a}{Alias}};
    if ($#as > 0){
      $doc->{NumAlias} = $#as+1;
    }
  }
  my @ext = keys %{$d{$a}{e}};
  my %stats = ();
  for my $ee (@ext){
    $v = $d{$a}{e}{$ee} + 0;
    $ee =~ s/TypesSript/TypeScript/;
    $stats{$ee} = $v;
  }
  if ($#ext>=0){
    $doc->{FileInfo} = \%stats;
  }
  $cnt++;
  print "$doc->{AuthorID}";
  for my $k ("Gender","NumCommits", "NumFiles", "NumFirstBlobs", "NumProjects", "EarlistCommitDate", "LatestCommitDate", "NumAlias"){
     my $val = defined $doc ->{$k} ? $doc ->{$k} : "";
     print ";$val";
  }
  for my $e (keys %stats){ print ";$e=$stats{$e}"; }
  print "\n";
}
#print STDERR "wrote $cnt\n";
