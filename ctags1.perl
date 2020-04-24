#!/usr/bin/perl

use strict;
use warnings;
use Compress::LZF;
use File::Basename;
use Getopt::Long;
use TokyoCabinet;
use Digest::SHA qw (sha1_hex sha1);

my %ctagsHangs = ("8209fa2425c1c1d0bf20a3870d6f0546540c0958" => "operatorservice.proto",
    "9a47ff27af14024249378f749e2097b3da7185ea" => "broker.proto",
    "17383b248e9c1221916771f96a6ecf73f4b0ec50" => "wishlist.proto",
    "7f7d775242dd83df60df9ae2c20cd1b60d396c5b" => "mastersvc.proto", 
    "7e832be15a29257298da48ef3445606e9ec6d7aa" => "gTogether.proto",
    "7a5e1def59408c0a82f7762959b7ce07c0cb1327" => "todo-service.proto",
    "7aead53de23be4193ac29711899c0bf230156c75" => "todo-service.proto",
    "fac3b539ae1a7433e4d7fbd2f33dbf2e43c8636d" => "todo-service.proto",
    "7af256a5e30a0c260f055e2a122d7b52e60e3831" => "todo-service.proto",
    "7afe7b6b64d78faa740a19a451d7334360c8f7d2" => "todo-service.proto",
    "7764d1e496837d9566463610236e8801dea6f0ed" => "ChatService.proto");

my %ctagsHangsF;

for my $f (values %ctagsHangs){
  $ctagsHangsF{$f}++;
}


my $types =  <<"EOT";
Math
alias
anchor
array
artifactId
boolean
nsprefix
number
object
previous
string
function
class
macro
member
method
field
constant
package
label
namespace
define
type
enumerator
subroutine
struct
typedef
enum
union
var
module
RecordField
variable
heading1
heading2
heading3
heading4
heading5
key
property
section
source
citation
id
packageName
inproceedings
signal
subprogspec
category
play
generator
library
subst
accessor
methodSpec
subprogram
Constructor
group
const
describe
entity
getter
book
target
implementation
singletonMethod
tag
unknown
paragraph
enumConstant
procedure
interface
subsubsection
globalVar
data
arg
chapter
null
func
article
functionVar
subsection
selector
entry
fd
frametitle
l5subsection
ltlibrary
misc
phdthesis
placeholder
protected
record
register
script
signature
structure
directory
node
packspec
template
annotation
division
program
project
root
title
trait
Exception
component
event
heredoc
message
common
optwith
def
incollection
setter
value
anonMember
mixin
port
repositoryId
modifiedFile
context
constructor
index
optenable
command
inbook
table
condition
definition
parameter
groupId
hunk
l4subsection
counter
custom
derivedMode
exception
face
namelist
role
submethod
attribute
keyword
mastersthesis
test
version
view
block
proceedings
protocol
service
task
global
testcase
feature
rpc
map
net
mxtag
cursor
newFile
resource
augroup
derivedMode
mastersthesis
protocol
resource
attribute
feature
map
subtype
face
manual
minorMode
unpublished
test
part
techreport
mxtag
custom
blockData
oneof
set
wrapper
accelerators
assert
format
qualname
loggerSection
delegate
langstr
varalias
option
bibitem
subparagraph
man
literal
menu
icon
bitmap
framesubtitle
symbol
dialog
val
option
qualname
sectionGroup
accelerators
callback
loggerSection
matchedTemplate
subparagraph
trigger
talias
bibitem
langstr
man
booklet
deletedFile
bitmap
menu
local
dialog
literal
symbol
icon
parameterEntity
conference
domain
element
formal
functor
grammar
guard
operator
protectspec
region
repoid
rule
separate
taskspec
theme
token
toplevelVariable
element
functor
inline
modport
modulepar
namedPattern
namedTemplate
repoid
synonym
theme
timer
submodule
error
probe
covergroup
error
altstep
identifier
infoitem
MSI
Series
edesc
filename
fragment
iparam
kind
langdef
notation
oparam
phandler
pkg
publication
qmp
reopen
slot
font
EOT

my $regExp = $types;
$regExp =~ s/\n/|/g;
$regExp = "^$regExp\$";
my %matches;
for my $k (split(/\n/, $types, -1)){
  $matches{$k}++;
}

my $sec = $ARGV[0];

#print STDERR "/fast/All.sha1o/sha1.blob_$sec.tch\n";
my %fhosc;
tie %fhosc, "TokyoCabinet::HDB", "/fast/All.sha1o/sha1.blob_$sec.tch", TokyoCabinet::HDB::OREADER,
  16777213, -1, -1, TokyoCabinet::TDB::TLARGE, 100000
  or die "cant open /fast/All.sha1o/sha1.blob_$sec.tch\n";
open CNT, "/data/All.blobs/blob_$sec.bin" or die "$!";
open RESULTST, ">$ARGV[1].idx";
open RESULTSB, ">$ARGV[1].bin";
my $offset = 0;
my $record = 0;

my $i = 0;
my $maxBatch = 1000;
my %batch;
my %ibatch;
while (<STDIN>){
  chop();
  my ($b, $f, $off, $len) = split(/;/, $_, -1);
  $f =~ s|.*/||;
  if ($len < 100000 && ($f !~ /\.json$/ || $len < 5000) && ! defined $ctagsHangs{$b} && ! defined $ctagsHangs{$f}){	  
    $f =~ s/[()\+\-\?\!\'\"\s]//g;
    #print STDERR "$b, $off, $len, ${i}_$f\n";
    addBlob ($b, $off, $len, ${i}."_".$f);
    $i++;
  }else{
    print STDERR "large file;$sec;$b;$off;$len;$f\n";
  }
}
dDump();

sub toHex {
  return unpack "H*", $_[0];
}
sub fromHex {
 return pack "H*", $_[0];
}
sub safeDecomp {
  my ($codeC, $msg) = @_;
  try {   
    my $code = decompress ($codeC);
    return $code;
  } catch Error with {
    my $ex = shift;
    print STDERR "Error: $ex, $msg\n";
    return "";
  }
}
sub safeComp {
  my ($codeC, $msg) = @_;
  try {   
    my $code = compress ($codeC);
    return $code;
  } catch Error with {
    my $ex = shift;
    print STDERR "Error: $ex, $msg\n";
    return "";
  }
}
sub addBlob {
  my ($b, $off, $len, $f) = @_;
  my $cnt = getBlob ($off, $len, $b);
  if ($cnt ne ""){
    open OUTPUT, "> $f";
    print OUTPUT $cnt;
    $batch{$b} = $f;
    $ibatch{$f} = $b; 
  }
  close OUTPUT;
  if ($i >= $maxBatch){
    dDump ();
  }
}

sub dDump {
  #printf STDERR "in dump\n";
  open FLIST, ">flist";
  for my $b (keys %batch){
    my $f = $batch{$b};
    print FLIST "$f\n";
  }
  close FLIST;
  open IN, '$HOME/bin/myTimeout 600s $HOME/bin/ctags --fields=kKlz  -L flist -uf - |';
  my %tmp = ();
  my %ll = ();
  while (<IN>){
    chop();
    if ($_ =~ /^TIMEOUT_TIMEOUT_TIMEOUT$/){
      for my $b (keys %batch){
        printf STDERR "BAD_BATCH:$b\;$batch{$b}\n";
      }
      last;
    }
    my ($t, $n, $f, $lan) = Declarations ($_);
    #print STDERR "$t\;$n\;$f\n";
    #$tmp{$ibatch{$f}}{"$t|$n"}++ if $t ne "" && $f ne "" && defined $ibatch{$f};
    if (defined $t && $t ne "" && $f ne "" && defined $ibatch{$f}){
      my $val = "$t|$n";
      $tmp{$ibatch{$f}} .= "\n$val";
      $ll{$ibatch{$f}} = $lan;
    }
    #push @tmp{$ibatch{$f}}{"$t|$n"}++ if $t ne "" && $f ne "" && defined $ibatch{$f};
  }
  for my $b (keys %tmp){
    #my $code = join "\n", (sort keys %{$tmp{$b}});
    my $code = $tmp{$b};
    $code =~ s/^\n//;
    my $len = length ($code);
    my $cnt = safeComp ($code);
    my $lenC = length ($cnt);
    my $bTK = sha1_hex ("tkn $len\0$code");
    print RESULTSB $cnt; 
    print RESULTST "$record;$offset;$lenC;$len;$bTK;$b;$batch{$b};$ll{$b}\n";
    $offset += $lenC;
    $record ++;
  }
  $i = 0;
  %batch = ();
  %ibatch = ();
  open II, "flist";
  while (<II>){
    chop ($_);
    unlink $_  or warn "Could not unlink $_: $!";
  }
}

sub getBinf {
  my ($blob) = $_[0];
  my $s = hex (substr($blob, 0, 2)) % 128;
  if ($s != $sec){
    die "wrong section $s $sec for blob $blob\n";
  }
  my $bB = fromHex ($blob);
  if (! defined $fhosc{$bB}){ return (0, 0);}
  return unpack ("w w", $fhosc{$bB});
}

sub getBlob {
  my ($off, $len, $blob) = @_;
  seek (CNT, $off, 0);
  #my $curpos = tell(CNT);
  my $codeC = "";
  my $rl = read (CNT, $codeC, $len);
  my $code = safeDecomp ($codeC, "$sec;$blob");
  return $code;
  # print "blob;$sec;$rl;$curpos;$off;$len\;$blob\n";
  # print "$code\n";
  #
}


sub Declarations {
  chop ();
  my ($name, $file, $rest, $type, $lang) = ("", "", "", "", "");
  m|^(.+?)\s+([0-9][^ ]+?)\s+(.*)\s+kind:([^ :]+)\s+language:([^ :]+)$|;
  if (!defined $1){
    m|^(.+?)\s+([0-9][^ ]+?)\s+(.*)\s+kind:([^ :]+)\s+language:([^ :]+)\s+([^ ]*:[^ :]*)$|;
    if (!defined $1){
      print STDERR "badLine:$_\n";
    }else{	    
      ($name, $file, $rest, $type, $lang) = ($1, $2, $3, $4, $5);
    }
  }else{
    ($name, $file, $rest, $type, $lang) = ($1, $2, $3, $4, $5);
  }
  if (defined $matches{$type}){
  }else{
    print STDERR "new type:$type:\n";
  }
  print STDERR "$type, $name, $file, $lang\n$_" if !defined $type;
  return ($type, $name, $file, $lang);
}
