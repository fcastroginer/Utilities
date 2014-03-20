#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;


my %opts = (BASES => 1000000, LENGTH => 10);
my $results = GetOptions ("b:s"  => \$opts{BASES}, "l:s"  => \$opts{LENGTH});

	
die(qq/
Usage:   sel-random-bed.pl [options] <bed.file[.gz]>
Options:
	-b	NUM	Number of bases to select (Default = 1000000) [$opts{BASES}]
	-l	NUM	Minimum region length (Default = 10) [$opts{LENGTH}]

Note: info, format and id rely on the heading descriptions in the VCF files.
\n/) if (@ARGV == 0 && -t STDIN);	
	

# Open BED file and counting the number of lines
my $nlines;
if ($ARGV[0] =~ m/\.gz$/){
	open (BED, "gunzip -c $ARGV[0]|");
	$nlines = `zcat $ARGV[0] | wc -l`;
} else {
	open (BED, "<$ARGV[0]");
	$nlines = `wc -l $ARGV[0] | cut -f1 -d" "`;
}
chomp $nlines;

# Select random positions
my @rposi = (1..$opts{BASES});
my %rpos;
for(@rposi)
{ 
	$rpos{int(rand($nlines))} = 1; 
}

# Reading regions
my $i = 1;
my %bed;
while(<BED>){ chomp; $bed{$i} = $_; $i++}

# Selecting random regions
my $cumBases = 0;
for my $p (keys(%rpos)) 
{
	my @l = split(" ", $bed{$p});
	if ( $l[0] =~ /chr\d+/)
	{
		my $length = $l[2] - $l[1];
		next if( $length < $opts{LENGTH});
		$cumBases = $cumBases + $l[2] - $l[1] + 1;
		print $l[0]."\t".$l[1]."\t".$l[2]."\n";
	}
	last if ($cumBases > $opts{BASES}) ;
}
