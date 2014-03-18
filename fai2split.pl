#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std;

# Split fasta index (fai) in different intervals. Developed following the code of fai2split_src.pl (downloaded from internet)

my %opts = (l=>5000000, o=>"split.intervals");
getopts('l:', \%opts);
my $l = $opts{l};
my %fai;
die(qq/Usage: fai2split.pl [-l $opts{l} -o $opts{o}] <in.fa.fai>\n/) if (@ARGV == 0 && -t STDIN);

# Reading fai and separate in chunks of l intervals
my $c = 0;
while (<>) {
	chomp;
	my @t = split;
	$fai{$c}{CHR} = $t[0];
	$fai{$c}{LENGTH} = $t[1];
	push (@{$fai{$c}{INTV}},$t[1]) if ( $t[1] <= $l );
	if ( $t[1] > $l )
	{
		my $s = 1;
		my $intv = $l;
		for  (my $intv = $l; $intv <= $t[1]; $intv += $l )
		{
			push @{$fai{$c}{INTV}}, $intv;
		}
		push @{$fai{$c}{INTV}}, $fai{$c}{LENGTH};
	}
	#print $fai{$c}{CHR}."\t".$fai{$c}{LENGTH}."\t";
	#print join("\t", @{$fai{$c}{INTV}})."\n";
	$c++;	
}

# Creating Intervals
my $i = 1;
my $intc = 0;
open(OUT, ">", $i.".".$opts{o});

for (my $r = 0; $r < $c; $r++)
{
	my $chrS = 1;
	if ( ($fai{$r}{LENGTH} + $intc) <= ($i*$l) )
	{
		print OUT $fai{$r}{CHR}.":".$chrS."-".$fai{$r}{LENGTH}."\n";
		#print $i."\t"."ALLIN"."\t".$fai{$r}{CHR}.":".$chrS."-".$fai{$r}{LENGTH}."\n";
		$intc += $fai{$r}{LENGTH};
	} else {
		for my $intv ( @{$fai{$r}{INTV}} )
		{
			#print "\t".$intv."\t".$intc."\t".$i."\t".$l."\n";
			if ( ($intv + $intc - $chrS) > ($i*$l) )
			{
				my $e = ($i*$l) - $intc + $chrS;
				$e = $fai{$r}{LENGTH} if ($e > $fai{$r}{LENGTH});
				print OUT $fai{$r}{CHR}.":".$chrS."-".$e."\n";
				my $intlength = $e - $chrS;
				#print $i."\t"."SPLIT1"."\t".$fai{$r}{CHR}.":".$chrS."-".$e."\t".$intlength."\n";
				
				if ($e < $fai{$r}{LENGTH})
				{
					$chrS = $e + 1;
					$e = $intv;
					$intc += $intlength;
					$i++;
					close(OUT);
					open(OUT, ">", $i.".".$opts{o});
					$intlength = $e - $chrS;
					print OUT $fai{$r}{CHR}.":".$chrS."-".$e."\n";
					#print $i."\t"."SPLIT2"."\t".$fai{$r}{CHR}.":".$chrS."-".$e."\t".$intlength."\n";
					$intc += $intlength;
					$chrS = $e + 1;				
				}
	
			} else {
				print OUT $fai{$r}{CHR}.":".$chrS."-".$intv."\n";
				#print $i."\t"."ALLIN2"."\t".$fai{$r}{CHR}.":".$chrS."-".$intv."\n";
				my $intlength = $intv - $chrS;
				$intc += $intlength;
				$chrS = $intv + 1;	
			}
		}
	}
}
