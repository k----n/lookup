use strict;
use warnings;

my $v = $ARGV[0];
my $s = $ARGV[1];

my %d = ();
my $pP = "";
my %tmp = ();
open A, 'zcat P2cFull'.$v.'{'.$s.",".($s+32).",".($s+64).",".($s+96).'}'.'.s|';
my $cnt = 0;
while (<A>){
  chop ();
  #print "$_\n";
  my ($p, $c) = split (/;/, $_, -1);
  if ($pP ne "" && $pP ne $p){
    $d{c}{$pP} = scalar(keys %tmp);
    %tmp = ();
    print STDERR "$s P2c $cnt\n" if (!($cnt++%1000000));
    #last if $cnt > 1000;
  }
  $tmp{$c}++;
  $pP = $p;
}
$d{c}{$pP} = scalar(keys %tmp);
print STDERR "done $s P2c $cnt\n";

for my $ty ("P2f"){
  $cnt = 0;
  %tmp = ();
  $pP = "";
  open A, "zcat ${ty}Full$v$s.s |";
  while (<A>){
    chop ();
    my ($p, $c) = split (/;/, $_, -1);
    if ($pP ne "" && $pP ne $p){
      $d{$ty}{$pP} = scalar(keys %tmp);
      if ($ty eq "P2f"){
        doExt ($pP, \%tmp);
      }
      %tmp = ();
      print STDERR "$s $ty $cnt prs\n" if (!($cnt++%1000000));
      #last if $cnt > 1000;
    }
    $tmp{$c}++;
    $pP = $p;
  }
  $d{$ty}{$pP} = scalar(keys %tmp);
  doExt ($pP, \%tmp) if ($ty eq "P2f");
  print STDERR "done $s $ty $cnt\n";
}

my @a = keys %{$d{c}};
print STDERR "$#a\n";
for my $p (keys %{$d{c}}){
  my $fs = defined $d{P2f}{$p} ?  $d{P2f}{$p} : "";
  print "$p;$d{c}{$p};$fs";
  for my $e (keys %{$d{e}{$p}}){
    print ";$e=$d{e}{$p}{$e}";
  }
  print "\n";
}

sub doExt {
  my ($p, $tmp) = @_;
  my @a = keys %$tmp;
  my %e = ();
  for my $fi (@a){ ext ($fi, \%e, $tmp->{$fi}) if $fi ne ""; }
  #my @a = sort { $e{$b} <=> $e{$a} }  keys %e;
  for my $i (keys %e){ $d{e}{$p}{$i}=$e{$i}; }
}

sub ext {
  my ($f, $stats) = @_;
  if( $f =~ m/(\.java$|\.iml|\.jar|\.class|\.dpj|\.xrb)$/ ) {$stats->{'Java'}++;}
  elsif( $f =~ m/\.(js|iced|liticed|iced.md|coffee|litcoffee|coffee.md|cs|ls|es6|jsx|sjs|co|eg|json|json.ls|json5)$/ ) {$stats->{'JavaScript'}++;}
  elsif( $f =~ m/\.(py|py3|pyx|pyo|pyw|pyc|whl)$/ ) {$stats->{'Python'}++;}
  elsif( $f =~ m/\.CPP$|\.CXX$|\.cpp$|\.[Cch]$|\.hh$|\.cc$|\.cxx$|\.hpp$|\.hxx$|\.Hxx$|\.HXX$|\.C$|\.c$|\.h$|\.H$/ ) { $stats->{'C/C++'}++; }
  elsif( $f =~ m/\.cs$/ )    {$stats->{'C#'}++;}
  elsif( $f =~ m/\.php$/ )     {$stats->{'PHP'}++;}
  elsif( $f =~ m/\.(rb|erb|gem|gemspec)$/ )    {$stats->{'Ruby'}++;  }
  elsif( $f =~ m/\.go$/ )      {$stats->{'Go'}++;}
  elsif( $f =~ m/\.ipy$/ ) {$stats->{'ipy'}++;}
  elsif( $f =~ m/\.swift$/ )   {$stats->{'Swift'}++;}
  elsif( $f =~ m/\.scala$/ )   {$stats->{'Scala'}++;}
  elsif( $f =~ m/\.(kt|kts|ktm)$/ ) {$stats->{'Kotlin'}++;}
  elsif( $f =~ m/\.(ts|tsx)$/ ) {$stats->{'TypeScript'}++;}
  elsif( $f =~ m/\.dart$/ ) {$stats->{'Dart'}++;}
  elsif( $f =~ m/\.(rs|rlib|rst)$/ )   {$stats->{'Rust'}++;}
  elsif( $f =~ m'./*(\.Rd|\.[Rr]|\.Rprofile|\.Rdata|\.Rhistory|\.Rproj|^NAMESPACE|^DESCRIPTION|/NAMESPACE|/DESCRIPTION)$' )    {$stats->{'R'}++;}
  elsif( $f =~ m/(\.perl|\.pod|\.pl|\.PL|\.pm)$/ ){ $stats->{'Perl'}++; }
  elsif( $f =~ m/\.(f[hi]|[fF]|[fF]77|[fF]9[0-9]|fortran|forth)$/ )    {$stats->{'Fortran'}++;}
  elsif( $f =~ m/\.ad[abs]$/ ) {$stats->{'Ada'}++;}
  elsif( $f =~ m/\.erl$/ )     {$stats->{'Erlang'}++;}
  elsif( $f =~ m/\.lua$/ )     {$stats->{'Lua'}++;}
  elsif( $f =~ m/\.(sql|sqllite|sqllite3|mysql)$/ )    {$stats->{'Sql'}++;}
  elsif( $f =~ m/\.(el|lisp|elc)$/ )   {$stats->{'Lisp'}++;}
  elsif( $f =~ m/\.(fs|fsi|ml|mli|hs|lhs|sml|v)$/ )    {$stats->{'fml'}++;}
  elsif( $f =~ m/\.jl$/ )      {$stats->{'Julia'}++;}   
  elsif( $f =~ m/\.(COB|CBL|PCO|FD|SEL|CPY|cob|cbl|pco|fd|sel|cpy)$/ ) {$stats->{'Cobol'}++;}
  elsif( $f =~ m/\.(cljs|cljc|clj)$/ ) {$stats->{'Clojure'}++;}
  elsif( $f =~ m/\.(aug|mli|ml|aug)$/ ) {$stats->{'OCaml'}++;}
  elsif( $f =~ m/\.(bas|bb|bi|pb)$/ ) {$stats->{'Basic'}++;}
  else {$stats->{'other'}++};
}

