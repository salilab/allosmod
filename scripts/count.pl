#!/usr/bin/perl -w

use strict;

my $L=$ARGV[0];
my $M=$ARGV[1];

die "Usage: $0 NUM1 NUM2\n" if not defined $L or not defined $M;

if($M <= 9){
    for(my $i=$L; $i<=$M; ++$i){
	printf "$i  ", $i;
    }
}
if ($L <=9 && $M > 9){
    for(my $i=$L; $i<=9; ++$i){
        printf "$i  ", $i;
    }
    for(my $i=10; $i<=$M; ++$i){
	printf "$i  ", $i;
    }
}
if ($L > 9 && $M > 9){
    for(my $i=$L; $i<=$M; ++$i){
        printf "$i  ", $i;
    }
}

print "\n";
