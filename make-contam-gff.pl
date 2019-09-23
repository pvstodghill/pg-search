#! /usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Carp::Always;

# use FindBin;
# use lib "$FindBin::Bin";
# use Xyzzy;

use constant { TRUE => 1, FALSE => 0 };

my $molecule_name = "contam";
my $is_protein = TRUE;
my $add_stop_codon = TRUE;


# ------------------------------------------------------------------------

my @names;
my %lengths;


my $defline;
my $seq = "";

sub notice_seq {
  if (!defined($defline)) { return; }
  my $name = $defline;
  $name =~ s/^>//;
  push @names, $name;
  my $l = length($seq);
  if ( $is_protein ) {
    if ( $add_stop_codon ) {
      $l += 1; # stop codon
    }
    $l *= 3; # 3 nt/aa;
  }
  $lengths{$name} = $l;
  $defline = undef;
  $seq = "";
}

while (<STDIN>) {
  chomp;
  if ( /^>/ ) {
    notice_seq;
    $defline = $_;
  } else {
    (defined($defline)) || die "No defline?,";
    $seq .= $_;
  }
}
notice_seq;

# ------------------------------------------------------------------------

my $max_length = -1;

foreach my $name ( keys(%lengths) ) {
  my $l = $lengths{$name};
  if ( $l > $max_length ) {
    $max_length = $l;
  }
}

my $bin_size;

foreach my $n ( 10, 100, 100, 10000, 100000 ) {
  if ( $n > $max_length ) {
    $bin_size = $n;
    last;
  }
}
(defined($bin_size)) || die "failed to determine bin size <<$max_length>>,";


# ------------------------------------------------------------------------

my $molecule_length = $bin_size*scalar(@names) - 1;

print "##gff-version 3\n";
print "##sequence-region $molecule_name 1 $molecule_length\n";

my $start = 1;
foreach my $name ( @names ) {
  my $end = $start + $lengths{$name} - 1;

  my $source = "fixme";
  my $feature = "CDS";
  my $score = ".";
  my $strand = "+";
  my $frame = 0;

  print join("\t",$molecule_name,$source,$feature,$start,$end,
	     $score,$strand,$frame,"name=$name"),"\n";


  $start += $bin_size;
}
