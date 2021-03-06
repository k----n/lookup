#!/usr/bin/perl
use lib ("$ENV{HOME}/lookup", "$ENV{HOME}/lib64/perl5", "/home/audris/lib64/perl5","$ENV{HOME}/lib/perl5", "$ENV{HOME}/lib/x86_64-linux-gnu/perl", "$ENV{HOME}/share/perl5");
use strict;
use warnings;
use Error qw(:try);

open A, "zcat $ARGV[0]|";
open B, "zcat $ARGV[1]|";


my $a = <A>;
my $b = <B>;

while ($a || $b){
  if (defined $a && defined $b){
    my ($bla, $ta, $aa) = split(/;/, $a, -1);
    my ($blb, $tb, $ab) = split(/;/, $b, -1);
    my $c = $bla cmp $blb;
    if ($c == 0){
      print $a if $ta <= $tb;
      print $b if $ta > $tb;
      $a = <A>;
      $b = <B>;
      next;
    }else{
      if ($c > 0){
        print $b;
        $b = <B>;
      }else{
        print $a;
        $a = <A>;
      }
    }
  }else{
    if (defined $a){
      print $a;
      $a = <A>;
    }
    if (defined $b){
      print $b;
      $b = <B>;
    }
  } 
}


