#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# Join two files by the specified columns
my %opts = (GENE=>undef, IMPACT=>undef, VARIANT=>'0,1,2,3');
my $res = GetOptions ("g:s"  => \$opts{GENE}, "i:s"  => \$opts{IMPACT}, "var:s" => \$opts{VARIANT}, "a:s" => \$opts{ANNOTATE});


die(qq/
Description: For a table created from snpEff that contains multiple effects for each variant, select only one effect based on Gene annotation and predicted Impact. The harmful impact will be selected for each variants. The impact is categorised as : HIGH > MODERATE > LOW > MODIFIER. Header must be present

Usage:   select-HImut.pl [-a annot.col] -g gene.col\/col.name -i effectImpact.col\/col.name -var [range] <file1>

Options:
	-g	NUM\/STRING	Column for gene annotation. If column not provided, column will be extracted from the header field with the name GENE. Column name string or Column number (1-based). 
	-i	NUM\/STRING	Column for impact annotation. If column not provided, column will be extracted from the header field with the name IMPACT. Column name string or Column number (1-based).
	-var	STR	Range of columns used for create the identification of the variants. 0-based. By default : 0,1,2,3
	-a	STR	Annotate variants with an additional column (name indicated in this option) instead of deleting the columns. Default: disabled
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
chomp $header;
$header .= "\t".$opts{ANNOTATE} if( defined $opts{ANNOTATE});
print $header."\n";

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
} elsif ($opts{GENE} =~ /\D+/) {
	$geneCol = $header{GENE};
} else {
	$geneCol = $opts{GENE}-1;
}

my $impactCol;
if(!defined $opts{IMPACT}) {
	$impactCol = $header{IMPACT};
} elsif ($opts{IMPACT} =~ /\D+/) {
	$impactCol = $header{IMPACT};
}  else {
	$impactCol = $opts{IMPACT}-1;
}

# Reading file first time and create an hash with Gene-Impact information. We keep the line number to print in the second run.
my %VAR;
while(<FILE>)
{
	chomp;
	my @F = split "\t";
	my $var = join "_",@F[eval($opts{VARIANT})];
	push(@{$VAR{$var}{$F[$geneCol]}{$F[$impactCol]}}, $_);
}

close FILE;

# Reading Hash and printing output

foreach my $var (sort (keys %VAR)) {
	if(!defined $opts{ANNOTATE}) {
		foreach my $gene (keys %{$VAR{$var}}) {
			if (exists $VAR{$var}{$gene}{HIGH}) { print $VAR{$var}{$gene}{HIGH}[0]."\n"}
			elsif (exists $VAR{$var}{$gene}{MODERATE}) { print $VAR{$var}{$gene}{MODERATE}[0]."\n"}
			elsif (exists $VAR{$var}{$gene}{LOW}) { print $VAR{$var}{$gene}{LOW}[0]."\n"}
			elsif (exists $VAR{$var}{$gene}{MODIFIER}) { print $VAR{$var}{$gene}{MODIFIER}[0]."\n"}
		}
	} else {
		foreach my $gene (keys %{$VAR{$var}}) {
			if (exists $VAR{$var}{$gene}{HIGH}) {
				foreach (@{$VAR{$var}{$gene}{HIGH}}) { print $_."\t1"."\n"; }
				for my $impacteff (keys %{$VAR{$var}{$gene}}) {
					if($impacteff ne "HIGH") {
						foreach (@{$VAR{$var}{$gene}{$impacteff}}) { print $_."\t0"."\n"; }
					}
				}
			} elsif (exists $VAR{$var}{$gene}{MODERATE}) {
				foreach (@{$VAR{$var}{$gene}{MODERATE}}) { print $_."\t1"."\n"; }
				for my $impacteff (keys %{$VAR{$var}{$gene}}) {
					if($impacteff ne "MODERATE") {
						foreach (@{$VAR{$var}{$gene}{$impacteff}}) { print $_."\t0"."\n"; }
					}
				}
			} elsif (exists $VAR{$var}{$gene}{LOW}) {
				foreach (@{$VAR{$var}{$gene}{LOW}}) { print $_."\t1"."\n"; }
				for my $impacteff (keys %{$VAR{$var}{$gene}}) {
					if($impacteff ne "LOW") {
						foreach (@{$VAR{$var}{$gene}{$impacteff}}) { print $_."\t0"."\n"; }
					}
				}
			} elsif (exists $VAR{$var}{$gene}{MODIFIER}) {
				foreach (@{$VAR{$var}{$gene}{MODIFIER}}) { print $_."\t1"."\n"; }
				for my $impacteff (keys %{$VAR{$var}{$gene}}) {
					if($impacteff ne "MODIFIER") {
						foreach (@{$VAR{$var}{$gene}{$impacteff}}) { print $_."\t0"."\n"; }
					}
				}
			}
		}		
		
	}
}
