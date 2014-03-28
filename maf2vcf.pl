#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# Join two files by the specified columns
my %opts = (SAMTOOLS=>"samtools", FASTA=>undef, INFO=>"Tumor_Sample_Barcode,Matched_Norm_Sample_Barcode,Validation_Method,Hugo_Symbol,Entrez_Gene,Variant_Type,Variant_Classification,NCBI_Build,dbSNP_RS");
my $res = GetOptions ("f:s"  => \$opts{FASTA}, "s:s"  => \$opts{SAMTOOLS}, "i:s"  => \$opts{INFO});
	
die(qq/
Description: Tranform a MAF file in TCGA format to a VCF files with
Usage:	maf2vcf.pl -f <fasta file> -s <samtools path> <MAF file>
		cat <MAF file> \| maf2vcf.pl -f <fasta file> -s <samtools path> -
		
Options:
	-f	REQ STR	Path to genome fasta file. 
	-s	OPT STR Path to samtools executble. Default : samtools
	-i	OPT CSV Column names from maf to be included in the INFO field. Default : "Tumor_Sample_Barcode,Matched_Norm_Sample_Barcode,Validation_Method,Hugo_Symbol,Entrez_Gene,Variant_Type,Variant_Classification,NCBI_Build,dbSNP_RS"

Details:
	- MAF Specification v2.3
	- Insertion and deletions will be converted to VCF format
	- Columns to be included by default
		Chromosome | Chrom
		Start_Position | Start_position
		End_Position | End_position
		Reference_Allele
		Tumor_Seq_Allele1
		Tumor_Seq_Allele2
	- Columns to be included in the INFO field by default
		Tumor_Sample_Barcode
		Matched_Norm_Sample_Barcode
		Validation_Method
		Hugo_Symbol
		Entrez_Gene
		Variant_Type
		Variant_Classification
		NCBI_Build
		dbSNP_RS

Date : 20140213
Contact: fcastroginer\@gmail.com
\n/) if (@ARGV != 1 || !defined($opts{FASTA}));	

# Info Fields Definitions
my %InfoDef;
{
	$InfoDef{Hugo_Symbol} = "##INFO=<ID=Hugo_Symbol,Number=1,Type=String,Description=\"HUGO symbol for the gene\">";
	$InfoDef{Entrez_Gene_Id} = "##INFO=<ID=Entrez_Gene_Id,Number=1,Type=String,Description=\"Entrez gene ID\">";
	$InfoDef{Entrez_Gene} = "##INFO=<ID=Entrez_Gene_Id,Number=1,Type=String,Description=\"Entrez gene ID\">";
	$InfoDef{Center} = "##INFO=<ID=Center,Number=1,Type=String,Description=\"Genome sequencing center reporting the variant. If multiple institutions report the same mutation separate list using semicolons>";
	$InfoDef{NCBI_Build} = "##INFO=<ID=NCBI_Build,Number=1,Type=String,Description=\"Any TGCA accepted genome identifier.NCBI human genome build number\">";
	$InfoDef{Strand} = "##INFO=<ID=Strand,Number=1,Type=String,Description=\"Genomic strand of the reported allele. Variants should always be reported on the positive genomic strand\">";
	$InfoDef{Variant_Classification} = "##INFO=<ID=Variant_Classification,Number=1,Type=String,Description=\"Translational effect of variant allele\">";
	$InfoDef{Variant_Type} = "##INFO=<ID=Variant_Type,Number=1,Type=String,Description=\"Type of mutation. TNP (tri-nucleotide polymorphism) is analogous to DNP but for 3 consecutive nucleotides. ONP (oligo-nucleotide polymorphism) is analogous to TNP but for consecutive runs of 4 or more\">";
	$InfoDef{Reference_Allele} = "##INFO=<ID=Reference_Allele,Number=1,Type=String,Description=\"The plus strand reference allele at this position. Include the sequence deleted for a deletion, or \"-\" for an insertion\">";
	$InfoDef{Tumor_Seq_Allele1} = "##INFO=<ID=Tumor_Seq_Allele1,Number=1,Type=String,Description=\"Primary data genotype. Tumor sequencing (discovery) allele 1. \" -\" for a deletion represent a variant. \"-\" for an insertion represents wild-type allele. Novel inserted sequence for insertion should not include flanking reference bases\">";
	$InfoDef{Tumor_Seq_Allele2} = "##INFO=<ID=Tumor_Seq_Allele2,Number=1,Type=String,Description=\"Primary data genotype. Tumor sequencing (discovery) allele 2. \" -\" for a deletion represents a variant. \"-\" for an insertion represents wild-type allele. Novel inserted sequence for insertion should not include flanking reference bases\">";
	$InfoDef{dbSNP_RS} = "##INFO=<ID=dbSNP_RS,Number=1,Type=String,Description=\"Latest dbSNP rs ID (dbSNP_ID) or \"novel\" if there is no dbSNP record\">";
	$InfoDef{dbSNP_Val_Status} = "##INFO=<ID=dbSNP_Val_Status,Number=1,Type=String,Description=\"dbSNP validation status. Semicolon- separated list of validation statuses\">";
	$InfoDef{Tumor_Sample_Barcode} = "##INFO=<ID=Tumor_Sample_Barcode,Number=1,Type=String,Description=\"BCR aliquot barcode for the tumor sample including the two additional fields indicating plate and well position\">";
	$InfoDef{Matched_Norm_Sample_Barcode} = "##INFO=<ID=Matched_Norm_Sample_Barcode,Number=1,Type=String,Description=\"BCR aliquot barcode for the matched normal sample including the two additional fields indicating plate and well position\">";
	$InfoDef{Match_Norm_Seq_Allele1} = "##INFO=<ID=Match_Norm_Seq_Allele1,Number=1,Type=String,Description=\"Primary data. Matched normal sequencing allele 1. \"-\" for deletions; novel inserted sequence for INS not including flanking reference bases\">";
	$InfoDef{Match_Norm_Seq_Allele2} = "##INFO=<ID=Match_Norm_Seq_Allele2,Number=1,Type=String,Description=\"Primary data. Matched normal sequencing allele 2. \"-\" for deletions; novel inserted sequence for INS not including flanking reference bases\">";
	$InfoDef{Tumor_Validation_Allele1} = "##INFO=<ID=Tumor_Validation_Allele1,Number=1,Type=String,Description=\"Secondary data from orthogonal technology. Tumor genotyping (validation) for allele 1. \"-\" for deletions; novel inserted sequence for INS not including flanking reference bases\">";
	$InfoDef{Match_Norm_Validation_Allele1} = "##INFO=<ID=Match_Norm_Validation_Allele1,Number=1,Type=String,Description=\"Secondary data from orthogonal technology. Matched normal genotyping (validation) for allele 1. \"-\" for deletions; novel inserted sequence for INS not including flanking reference bases\">";
	$InfoDef{Match_Norm_Validation_Allele2} = "##INFO=<ID=Match_Norm_Validation_Allele2,Number=1,Type=String,Description=\"Secondary data from orthogonal technology. Matched normal genotyping (validation) for allele 2. \"-\" for deletions; novel inserted sequence for INS not including flanking reference bases\">";
	$InfoDef{Verification_Status4} = "##INFO=<ID=Verification_Status4,Number=1,Type=String,Description=\"Second pass results from independent attempt using same methods as primary data source. Generally reserved for 3730 Sanger Sequencing\">";
	$InfoDef{Validation_Status4} = "##INFO=<ID=Validation_Status4,Number=1,Type=String,Description=\"Second pass results from orthogonal technology\">";
	$InfoDef{Mutation_Status} = "##INFO=<ID=Mutation_Status,Number=1,Type=String,Description=\"Updated to reflect validation or verification status\">";
	$InfoDef{Sequencing_Phase} = "##INFO=<ID=Sequencing_Phase,Number=1,Type=String,Description=\"TCGA sequencing phase. Phase should change under any circumstance that the targets under consideration change\">";
	$InfoDef{Sequence_Source} = "##INFO=<ID=Sequence_Source,Number=1,Type=String,Description=\"Molecular assay type used to produce the analytes used for sequencing\">";
	$InfoDef{Validation_Method} = "##INFO=<ID=Validation_Method,Number=1,Type=String,Description=\"The assay platforms used for the validation call. Examples: Sanger_PCR_WGA, Sanger_PCR_gDNA, 454_PCR_WGA, 454_PCR_gDNA; separate multiple entries using semicolons\">";
	$InfoDef{Sequencer} = "##INFO=<ID=Sequencer,Number=1,Type=String,Description=\"Instrument used to produce primary data. Separate multiple entries using semicolons\">";
	$InfoDef{Tumor_Sample_UUID} = "##INFO=<ID=Tumor_Sample_UUID,Number=1,Type=String,Description=\"BCR aliquot UUID for tumor sample\">";
	$InfoDef{Matched_Norm_Sample_UUID} = "##INFO=<ID=Matched_Norm_Sample_UUID,Number=1,Type=String,Description=\"BCR aliquot UUID for matched normal\">";
	$InfoDef{Chromosome} = "##INFO=<ID=Chromosome,Number=1,Type=String,Description=\"Chromosome\">";
	$InfoDef{Chrom} = "##INFO=<ID=Chrom,Number=1,Type=String,Description=\"Chromosome\">";
	$InfoDef{Start_Position} = "##INFO=<ID=Start_Position,Number=1,Type=String,Description=\"Lowest numeric position of the reported variant on the genomic reference sequence. Mutation start coordinate (1-based coordinate system)\">";
	$InfoDef{Start_position} = "##INFO=<ID=Start_position,Number=1,Type=String,Description=\"Lowest numeric position of the reported variant on the genomic reference sequence. Mutation start coordinate (1-based coordinate system)\">";
	$InfoDef{End_Position} = "##INFO=<ID=End_Position,Number=1,Type=String,Description=\"Highest numeric genomic position of the reported variant on the genomic reference sequence. Mutation end coordinate (inclusive, 1-based coordinate system)\">";
	$InfoDef{End_position} = "##INFO=<ID=End_position,Number=1,Type=String,Description=\"Highest numeric genomic position of the reported variant on the genomic reference sequence. Mutation end coordinate (inclusive, 1-based coordinate system)\">";
}


# Reading the input file
if ($ARGV[0] =~ m/\.gz$/){
	open (FILE, "gunzip -c $ARGV[0]|");
} else {
	open (FILE, "<$ARGV[0]");
}


# Info Column names
my @infoNames = split ",", $opts{INFO};
my %info;
@info{@infoNames} = (0 .. $#infoNames);

# Read Column names from MAF file
my (@header, %requiredHeader, @infoPositions);
{
	my $header = <FILE>;
	$header = <FILE> if $header =~ /#version/;
	chomp $header;
	@header = split "\t", $header;
	my $i = 0; 
	while ($i <= $#header) 
	{
		push(@infoPositions, $i)  if(exists($info{$header[$i]}));
		$requiredHeader{Chromosome} = $i if($header[$i] =~ /Chrom/);
		$requiredHeader{Start_Position} = $i if($header[$i] =~ /Start_Position|Start_position/ );
		$requiredHeader{End_Position} = $i if($header[$i] =~ /End_Position|End_position/ );
		$requiredHeader{Reference_Allele} = $i if($header[$i] =~ /Reference_Allele/ );
		$requiredHeader{Tumor_Seq_Allele1} = $i if($header[$i] =~ /Tumor_Seq_Allele1/ );
		$requiredHeader{Tumor_Seq_Allele2} = $i if($header[$i] =~ /Tumor_Seq_Allele2/ );
		$i++;
	}

	my @requiredFields = ("Chromosome", "Start_Position", "End_Position", "Reference_Allele", "Tumor_Seq_Allele1", "Tumor_Seq_Allele2");
	foreach (@requiredFields) {die("ERROR : Field $_ doesn't exists in input file") if(!exists $requiredHeader{$_}) };
}

# Generate VCF Header
{
	print "##fileformat=VCFv4.1\n";
	foreach (keys %info)
	{	
		warn("WARNING : Header not defined for $_") if(! exists $InfoDef{$_});
		print $InfoDef{$_}."\n" if(exists $InfoDef{$_});
	}
	print "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Unphased genotypes\">\n";
	print "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSAMPLE\n";
}


# Reading Variants from MAF and printing VCF variants files
my ($Chromosome, $Start_Position, $End_Position, $Reference_Allele, $Tumor_Seq_Allele1, $Tumor_Seq_Allele2, $Allele1, $Allele2);
while(<FILE>)
{
	chomp;
	my @F = split "\t";
	
	# Required fields
	$Chromosome = $F[$requiredHeader{Chromosome}];
	$Start_Position = $F[$requiredHeader{Start_Position}];
	$End_Position = $F[$requiredHeader{End_Position}];
	$Reference_Allele = $F[$requiredHeader{Reference_Allele}];
	$Tumor_Seq_Allele1 = $F[$requiredHeader{Tumor_Seq_Allele1}];
	$Tumor_Seq_Allele2 = $F[$requiredHeader{Tumor_Seq_Allele2}];
	my $REF = $Reference_Allele;
	my $ALT = "";
	
	
	# SNP or Deletions
	if ($Reference_Allele ne "-") 
	{
		my $Reference2;
		if ($Tumor_Seq_Allele1 eq "-" || $Tumor_Seq_Allele2 eq "-")
		{
			# Check Reference Bases
			my $query_position = $Chromosome.":".$Start_Position."-".$End_Position;
			$Reference2 = uc(`$opts{SAMTOOLS} faidx $opts{FASTA} $query_position | grep -v \">\"`);
			chomp $Reference2;
			warn("WARNING : Reference allele doesn't ($Reference_Allele) match reference genome ($Reference2) at position $query_position") if ($Reference2 ne $Reference_Allele);
			# New Start Position
			$Start_Position = $Start_Position - 1;
			# Get the Base in Previous position to start site
			$query_position = $Chromosome.":".$Start_Position."-".$Start_Position;
			$Reference2 = uc(`$opts{SAMTOOLS} faidx $opts{FASTA} $query_position | grep -v \">\"`);
			chomp $Reference2;
			# New reference allele
			$REF = $Reference2.$Reference_Allele;
		}
		
		# Allele 1
		$Allele1 = 0;
		if ($Tumor_Seq_Allele1 ne $Reference_Allele){
			$Allele1 = 1;
			$ALT=$Tumor_Seq_Allele1;
		}
		if ($Tumor_Seq_Allele1 eq "-")
		{
			$ALT=$Reference2;
		}
		
		# Allele 2
		$Allele2 = 0;
		if ($Tumor_Seq_Allele2 ne $Reference_Allele){
			$Allele2 = 1;
			if ($Tumor_Seq_Allele1 eq $Reference_Allele) {
				$ALT=$Tumor_Seq_Allele2;
			} elsif ($Tumor_Seq_Allele1 ne $Tumor_Seq_Allele2) {
					$Allele2 = 2;
					$ALT=$ALT.",".$Tumor_Seq_Allele2;
			}
		}
		if ($Tumor_Seq_Allele2 eq "-")
		{
			if ($Tumor_Seq_Allele1 eq $Reference_Allele) {
				$Allele2 = 1;
				$ALT=$Reference2;
			} elsif ($Tumor_Seq_Allele1 ne $Tumor_Seq_Allele2) {
				$Allele2 = 2;
				$ALT=$ALT.",".$Reference2;
			}
		}
	}

	# Insertions
	if ($Reference_Allele eq "-")
	{
		my $Reference2;

		# New Start Position
		$Start_Position = $Start_Position - 1;
		$End_Position = $End_Position - 1;

		# Get the two bases in Previous position to start site
		my $query_position = $Chromosome.":".$Start_Position."-".$End_Position;
		$Reference2 = uc(`$opts{SAMTOOLS} faidx $opts{FASTA} $query_position | grep -v \">\"`);
		chomp $Reference2;
		# New reference allele
		$REF = $Reference2;
		
		# Allele 1
		$Allele1 = 0;
		if ($Tumor_Seq_Allele1 ne "-")
		{
			$Allele1 = 1;
			$ALT = $Reference2.$Tumor_Seq_Allele1
		}
		
		# Allele 2
		$Allele2 = 0;
		if ($Tumor_Seq_Allele2 ne "-")
		{
			$Allele2 = 1;
			$ALT = $Reference2.$Tumor_Seq_Allele2 if ($Tumor_Seq_Allele1 eq "-");
			$Allele2 = 2 if ($Tumor_Seq_Allele1 ne "-");
			$ALT = $ALT.",".$Reference2.$Tumor_Seq_Allele2 if ($Tumor_Seq_Allele1 ne "-");
		}
	}



	# Info Field
	my $infoVcf;
	for (@infoPositions)
	{
		$infoVcf .= $header[$_]."=".$F[$_].";";
	}
	chop($infoVcf);
	
	# Genotype
	my $GENO = $Allele1."/".$Allele2;
	print "$Chromosome\t$Start_Position\t-\t$REF\t$ALT\t99\tPASS\t$infoVcf\tGT\t$GENO\n";
}




