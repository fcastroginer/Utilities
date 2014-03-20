#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# Join two files by the specified columns
my %opts = (GENE=>undef, IMPACT=>undef, VARIANT=>'0,1,2,3');
my $res = GetOptions ("g:s"  => \$opts{GENE}, "i:s"  => \$opts{IMPACT}, "var:s" => \$opts{VARIANT});


die(qq/
Description: For a table created from snpEff that contains multiple effects for each variant, select only one effect based on Gene annotation and predicted Impact. The harmful impact will be selected for each variants. The impact is categorised as : HIGH > MODERATE > LOW > MODIFIER. Header must be present

Usage:   snpeff2uniq.pl -g gene.col -i effectImpact.col -var [range] <file1>

Options:
	-g	NUM	Column for gene annotation. If column not provided, column will be extracted from the header field with the name GENE. 1-based
	-i	NUM	Column for impact annotation. If column not provided, column will be extracted from the header field with the name IMPACT. 1-based
	-var	STR	Range of columns used for create the identification of the variants. 0-based. By default : 0,1,2,3

Contact: fcastroginer\@gmail.com
\n/) if (@ARGV != 1);	


# Reading the input file
if ($ARGV[0] =~ m/\.gz$/){
	open (FILE, "gunzip -c $ARGV[0]|");
} else {
	open (FILE, "<$ARGV[0]");
}


# Read Column names
my $header = <FILE>;
print $header;
chomp $header;
my @header = split "\t", $header;
my %header;
my $i = 0; 
while ($i <= $#header) {
	$header{$header[$i]} = $i;
    $i++;
}

# Get column names
my $geneCol;
if(!defined $opts{GENE}) {
	$geneCol = $header{GENE};
} else {
	$geneCol = $opts{GENE}-1;
}

my $impactCol;
if(!defined $opts{IMPACT}) {
	$impactCol = $header{IMPACT};
} else {
	$impactCol = $opts{IMPACT}-1;
}


# Reading file first time and create an hash with Gene-Impact information. We keep the line number to print in the second run.
my %VAR;
while(<FILE>)
{
	chomp;
	my @F = split "\t";
	my $var = join "_",@F[eval($opts{VARIANT})];
	$VAR{$var}{$F[$geneCol]}{$F[$impactCol]} = $_;
}

close FILE;

# Reading Hash and printin output

foreach my $var (sort (keys %VAR)) {
	foreach my $gene (keys %{$VAR{$var}}) {
		if (exists $VAR{$var}{$gene}{HIGH}) { print $VAR{$var}{$gene}{HIGH}."\n"}
		elsif (exists $VAR{$var}{$gene}{MODERATE}) { print $VAR{$var}{$gene}{MODERATE}."\n"}
		elsif (exists $VAR{$var}{$gene}{LOW}) { print $VAR{$var}{$gene}{LOW}."\n"}
		elsif (exists $VAR{$var}{$gene}{MODIFIER}) { print $VAR{$var}{$gene}{MODIFIER}."\n"}
	}
}
