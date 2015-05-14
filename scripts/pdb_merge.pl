#! /usr/bin/perl -w

use strict;

if ($#ARGV<0) {
    print "Usage: joinModelsPDB.pl <pdb1> <pdb2> ...\n";
    exit;
}

my $num = $#ARGV;

for(my $i=0; $i<=$#ARGV; $i++) {
    my $pdb=$ARGV[$i];
    my $modelNum = $i+1;
    print "MODEL        $modelNum\n";
    `grep -v -E \"MODEL\|ENDMDL\" $pdb > tmp.pdb`;
  #rename ("tmp.pdb", $pdb);
  #open FILE, $pdb;
    open FILE, "tmp.pdb";
    print <FILE>;
    close FILE;
    `rm -f tmp.pdb`;
    print "ENDMDL\n";
}
