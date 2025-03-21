# KILDA

## Introduction 

High concentrations of Lipoprotein(a) is a risk factor for cardiovascular diseases. This concentration is mostly genetically determined by a complex interplay between the number of Kringle-IV type 2 (KIV-2) repeats and Lp(a)-affecting genetic variants.

KILDA (KIv2 Length Determined from a kmer Analysis) provides an alignment-free estimation of the number of KIV2 repeats from FASTQ files. The KIV2 copy number is estimated from the occurrences of kmers specific to the KIV2 sequence, normalised by kmers from one or more normalisation region(s). KILDA can also estimate the presence of Lp(a) variants and can be used as a tool to detect high-risk individuals based on their genetic profile.

This repository contains:

 - Pre-computed sets of KIV-2 and *LPA* specific kmers

 - A Nextflow pipeline for streamlined and reproducible analysis (*kilda.nf*)

 - A standalone Python script for flexible use (*kilda.py*)

## Table of Contents

1. [Introduction](#introduction)
2. [Table of Contents](#table-of-contents)
3. [Rationale](#rationale)
4. [Dependencies](#dependencies)
5. [Test Dataset](#test-dataset)
6. [Quick start](#quick-start)
7. [Running the pipeline](#running-the-pipeline)
    - [The config file](#the-config-file)
    - [Input formats](#input-formats)
    - [Standalone use kilda.py](#standalone-use-kildapy)
8. [FAQ](#faq)

## Rationale

The KIV2 copy number is determined by comparing the mean occurrence of kmers specific to the KIV2 repeats (in blue in the plot below) against the mean occurrence of kmers specific to a normalisation region (e.g. the *LPA* gene, yellow in the plot below):

![kilda_plot](./images/HG00590_cov.png "Plot generated by KILDA. The distribution of the occurrences of the KIV2 and LPA kmers are represented in blue and yellow respectively.")

KILDA needs kmers specific to the regions of interest to work. For ease-of-use we are providing pre-computed lists of kmers in this repository, with the *LPA* gene as the normalisation region: see [KIV2 kmers](./data/kmers_GRCh38_LPA_k31/KIV2_hg38_kmers_6copies_specific.tsv) and [LPA kmers](./data/kmers_GRCh38_LPA_k31/KIV2_hg38_kmers_6copies_specific.tsv) in [./data/](./data/).

These lists have been built using [GRCh38](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/GRCh38.primary_assembly.genome.fa.gz "GRCh38 primary assembly from GenCode") based on the regions defined in [KIV2_hg38.bed](./data/KIV2_hg38.bed) and [LPA_hg38.bed](./data/LPA_hg38.bed)

If you want to change the normalisation region(s), see [Creating a new kmer DB](#creating-a-new-kmer-db).

## Dependencies

The following needs to be installed on your machine:

- [Nextflow](https://www.nextflow.io/docs/latest/install.html) (v21+ required)

- [Singularity](https://docs.sylabs.io/guides/3.0/user-guide/installation.html) __or__ [Apptainer](https://apptainer.org/docs/admin/main/installation.html)

*Note: The scripts were developed and tested on Linux (Debian release 11) using nextflow v22.04.5 and Python v3.9.2.*

The rest of the dependencies, available in our Singularity image, are listed below: 

- **jellyfish** (tested with v2.2.10)

- **samtools**  (tested with v1.19)

- **bedtools**  (tested with v2.27.1)

- **Python v3 or higher**

- **The following python packages:** pandas, numpy, matplotlib (note: the following packages should be available by default: getopt, sys, os, warnings)

You can build the image using the recipe provided in this repository [kiv2_20240530.def](./kiv2_20240530.def) with Apptainer or Singularity:

```shell
apptainer build kiv2_20240530_0.2.sif kiv2_20240530.def # with apptainer
singularity build kiv2_20240530_0.2.sif kiv2_20240530.def  # with singularity
```

## Test Dataset

A test dataset is available under [./test_dataset/](./test_dataset), it can be launched with the following commands:

```shell
cd /path/to/kilda/

apptainer build kiv2_20240530_0.2.sif kiv2_20240530.def

cd ./test_dataset/

nextflow run ../kilda.nf -c kilda_test.conf
```

The analysis should run in a few minutes, and KILDA output will be available under: *./results/kilda_kiv2_CNs/kilda_kiv2.CNs*

The file should contain the following results (the samples order might be different):
```
ID      KIV2_CN rs41272114_ref  rs41272114_alt  rs10455872_ref  rs10455872_alt  rs3798220_ref   rs3798220_alt   quantile
HG02597 40.09   3       1       6       0       7       0       7
HG00099 19.58   8       0       0       12      7       0       0
HG00126 24.22   8       0       7       1       4       4       2
NA21141 42.58   3       0       6       0       10      0       9
HG02601 27.94   9       0       5       1       6       0       4
```

*ID*: the sample identifier

*KIV_CN*: the KIV2 copy number detected with KILDA

*rsxxx_ref*: the occurrence of kmers representing rsxxx reference allele

*rsxxx_alt*: the occurrence of kmers representing rsxxx alternative allele

*quantile*: The sample decile (in term of KIV-2 repeats), between 0 and 9, computed against all the other samples

## Quick start

The pipeline is centralised around [kilda.nf](./kilda.nf).

First, move to KILDA's installation directory and build the Apptainer image:

```shell
cd /path/to/kilda/
apptainer build kiv2_20240530_0.2.sif kiv2_20240530.def
```

Then:

 - Create an input samplesheet, see [input formats](#input-formats)
 
 - Define the path to *wdir* (default is the current folder)
 
 - Define the path to *samplesheet* in the config file
 
Finally, launch the pipeline:

```shell
nextflow run /path/to/kilda.nf -c /path/to/kilda.conf
```

Output example:

```
ID      KIV2_CN rs41272114_ref  rs41272114_alt 	quantile
HG00114 32.53   47      		0      			4
HG00111 34.64   46      		0      			6
HG00106 40.68   44      		0      			9
HG00149 38.95   41      		0      			8
HG00112 37.01   44      		0      			7
HG00109 35.12   58      		0      			6
HG00141 29.96   52      		0      			3
HG00233 26.81   27      		22     			1
HG00123 28.53   31      		0      			2
```

## Running the pipeline

### The config file

The config file contains the parameters necessary to launch the analysis. You can use the default values for most of them, unless you need to change the normalisation regions or add SNPs to the rsids list.

#### General options

- *wdir*: the directory where the analysis will be run and where the output will be stored.

- *kmer_size*: the kmer length, we recommend a value > 21, larger values are more accurate but need more computational power and are more sensitive to errors in the kmers.

KILDA can take a list of SNPs with representative reference/alternative kmers (see [input formats](#input-formats)), and will return the occurrences of each kmer. This can be used to assess the presence/absence of Lp(a)-related SNPs to add context around the KIV2 copy-number.

#### Creating a new kmer DB

This is an example of the *params* section of the [configuation file](./confs/kilda.conf), to create a new kmer database (instead of the one given within this repo [./data/kmers_GRCh38_LPA_k31/](./data/kmers_GRCh38_LPA_k31/)).

```
params {
    wdir = ${launchDir}                             // The working directory
    kmer_size = 31

    build_DB = true                                 // If true the kmer DB step will be run
    outdir = ${projectDir}/data/my_kmer_DB/         // Path to the output directory
    genome_fasta = /path/to/GRCh38.fa               // Path to the reference genome
    genome_fai = /path/to/GRCh38.fa.fai             // Path the reference index
    norm_bed = "${projectDir}/data/LPA_hg38.bed"    // Path to the bed file defining the normalisation region(s)
    kiv2_bed = "${projectDir}/data/KIV2_hg38.bed"   // Path to the bed file defining the KIV-2 region
}
```

The pipeline will then (i) extract the kmers from the regions defined in the beds, (ii) keep the one with the correct occurrences (1 for normalisation and 6 for KIV2), (iii) remove kmers that are occuring elsewhere on the genome, and (iv) remove common kmers between the normalisation region(s) and the KIV2 region.

This will produce two *.tsv* files, named as following:

 - For KIV2: <input_bed_name>_kmers_6copies_specific.tsv
    
 - For the normalisation: <input_bed_name>_kmers_1copies_specific.tsv

The *.tsv* files are the one needed for the KIV2 count step.

#### KIV2 counts

This is an example of the *params* section of the [configuation file](./confs/kilda.conf), to count the number of KIV-2 in a cohort.

```
params {
    wdir = ${launchDir}                                             // The working directory
    kmer_size = 31

    count_kiv2 = true                                               // If true, the KIV-2 inference step will be counted
    samplesheet = ${params.wdir}/samplesheet.txt                    // Path to the samplesheet defining the samples and their IDs
    kiv2_kmers = "/path/to/KIV2_hg38_kmers_6copies_specific.tsv"    // Path to the specific KIV2 kmers
    norm_kmers = "/path/to/LPA_hg38_kmers_1copies_specific.tsv"     // Path to the specific normalisation kmers
    rsids_list  = "${projectDir}/data/lpa_three_rsids.tsv"          // Optional: if set KILDA will infer SNPs from the kmers defined in it
}
```

/!\ If *kmer_DB* is true, the "kiv2_kmers" and "norm_kmers" should be empty (since KILDA will directly use the output from the "kmer_DB" step as lists of kmers!). In case of conflict, an error will be printed on the terminal.

The pipeline will use *jellyfish* to count the kmers and then launch *kilda.py* to count the KIV2 repeats.

The output will be available in the directory set in *wdir*, notably the estimated KIV2 copy numbers are stored in *kilda_kiv2.CNs/kilda_kiv2.CNs*

This step will also produce a *counts/* folder with the kmer counts files (one per sample), a *counts.list* file, listing the sample IDs and counts file (needed as input to *kilda.py*) and *NORM_KIV2_kmers.fasta* a FASTA file with the concatenated kmers from the KIV2 and normalisation regions.

### Input formats

The samplesheet must have one sample per line, with the sample ID, a tabulation and the list of FASTQs separated by a space:

```
HG00403	/path/to/HG00403_chr6_R1.fastq /path/to/HG00403_chr6_R2.fastq
HG00318	/path/to/HG00318_chr6_R1.fastq /path/to/HG00318_chr6_R2.fastq
HG00304	/path/to/HG00304_chr6_R1.fastq /path/to/HG00304_chr6_R2.fastq
```

The rsid file must have one rsid per line, with the variant ID, a tabulation, a kmer representing the reference sequence, a tabulation and a kmer representing the alternative sequence. 

This file can be created using the helper script [variant_kmers.sh](./bin/variant_kmers.sh), see the [FAQ](#generating-the-variant-kmers).

*Note*: the variant IDs will only be used to name columns in the output file.

```
rs41272114  AACATGATAGACATACGCATTTGGATAGTAT AACATGATAGACATATGCATTTGGATAGTAT
rs10455872  TGTTCTCAGAACCCAATGTGTTTATACAGGT TGTTCTCAGAACCCAGTGTGTTTATACAGGT
rs3798220   CAGCCTAGACACTTCTATTTCCTGAACATGA CAGCCTAGACACTTCCATTTCCTGAACATGA
```

If you are starting from BAM files, you will need to transform them into FASTQ files first, this can be done using samtools:

```shell
# First using 'view' to remove unmapped, not primary, duplicate and supplementary reads:
samtools collate -f --threads 20 -O -u --no-PG --reference reference.fasta sample_1.bam TMP/tmp.collate |\
     samtools fastq -n --threads 20 -1 sample_1_R1.fastq.gz -2 sample_1_R2.fastq.gz -s /dev/null -0 /dev/null
```

*note*: you can extract the reads corresponding to the regions of interest to speed up execution time.

### Standalone use kilda.py

This python script is run as part of *kilda.nf* but can be run independently if needed. See [dependencies](#dependencies) for the list of packages to install.

Python script to estimate the number of KIV2 repeats, based on the kmer occurrences counted with [kilda.nf](#quick-start)

This is run as part of [kilda.nf](#quick-start), but can be launched independently.

#### Usage

```
kilda.py -c [counts_list.tsv] -k [KIV2_unique_31mer_with_rc.tsv] -l [LPA_unique_31mer_with_rc.tsv] -r [lpa_rsids.tsv] -o [output_folder] -p -v

Input:
     -c/--counts          File with the list of ids and counts (generated by 'jellyfish dump') files. One id and file per line, tab_delimited (required).
     -k/--kiv             File listing the curated KIV2 kmers. (required, default = './KIV2_hg38_kmers_6copies_specific.tsv')
     -l/--lpa             File listing the curated Normalisation kmers. (required, default = './LPA_hg38_kmers_1copies_specific.tsv')
     -r/--rsids           File listing rsids of interest and their ref and alt kmers. (optionnal, tab-delimited, no header)

Output:
     -o/--output          The path to the output folder. (default = './kilda-output/')
     -p/--plot            If set, will produce a pdf plot of the kmer occurrences for each sample.

Other:
     -v/--verbose         If set, will print messages to the screen about the analysis progress.
     -h/--help            Print the usage and help and exit.
     -V/--version         Print the version and exit.
```

You can run it from within the image:

```shell
apptainer exec kiv2_20240530_0.2.sif ./bin/kilda.py 
```

#### Input

The list of counts files (option -c) should contain two columns (tab delimited), *ID* and *path to the counts file*:
```
S1	/path/to/counts/S1.counts
S2	/path/to/counts/S2.counts
S3	/path/to/counts/S3.counts
S4	/path/to/counts/S4.counts
S5	/path/to/counts/S5.counts
```

Each counts file should contain 2 columns (tab delimited): *kmer* and *occurrence*, and can be generated using "jellyfish dump".

```shell
k=31
sample_id="S1"

# Counting the kmers in the fastq files corresponding to the sample:
jellyfish count -t 6 -m ${k} -s 100M -C -o ./counts/${sample_id}_${k}mer <(zcat ./${sample_id}/fastqs/*.filt.fastq.gz);

# Querying the count file to extract the curated KIV2 and LPA kmers:
jellyfish dump ./counts/${sample_id}_${k}mer -c -t > .counts/${sample_id}.counts
```

The lists of kmers (options -k and -l) should be in txt format, one kmer per line. This can be generated with *kilda.nf* see ["Creating a new kmer DB"](#creating-a-new-kmer-db)

```
GAAACCATTTTTCCATGTCTC
CACTGATACAAATTGCCAATG
AAGTCTTTCAAGAGCTCAGGC
AACCATTTTTCCATGTCTCTG
ACGTAGATATAGAAACAGATC
AGGCTTCCTCCTACATGGTAG
GGAGGAAAAGAGCTCTACAAA
...
```

For the identification of rsids from the kmers (option -r), the input format is (ID reference\_kmer alternative\_kmer), tab-delimited, one rsid per line. See [Generating the variant kmers](#generating-the-variant-kmers) for help with generating this file.

```
rs41272114      GATAGACATACGCATTTGGAT   GATAGACATATGCATTTGGAT
rs10455872      TCAGAACCCAATGTGTTTATA   TCAGAACCCAGTGTGTTTATA
rs3798220       TAGACACTTCTATTTCCTGAA   TAGACACTTCCATTTCCTGAA
```

#### Output

The script will write "kilda_kiv2.CNs" in the output folder, containing three columns: the sample ID, the CN number and the corresponding quantile within the cohort:
```
ID      KIV2_CN quantile
HG00123 14.81   2
HG00233 12.59   1
HG00141 12.36   0
HG00109 16.01   4
HG00112 17.53   6
HG00149 14.30   2
HG00106 13.03   1
HG00111 17.83   7
HG00114 17.60   7
```

If rsids are provided with the -r option, two additional columns per rsid will be created: one with the counts for the reference kmer and one with the counts for the alternative kmer:

```
ID      KIV2_CN rs41272114_ref  rs41272114_alt 	quantile
HG00114 32.53   47      		0      			4
HG00111 34.64   46      		0      			6
HG00106 40.68   44      		0      			9
HG00149 38.95   41      		0      			8
HG00112 37.01   44      		0      			7
HG00109 35.12   58      		0      			6
HG00141 29.96   52      		0      			3
HG00233 26.81   27      		22     			1
HG00123 28.53   31      		0      			2
```

If "-p" is set when launching the script, a "plots/" folder will be created and one plot per sample, showing the distribution of the occurrences of the KIV2 and LPA kmers, will be saved as a pdf file.
See Figure in [Rationale](#rationale).

If the verbose option is set (-v), then a report for each sample will be written to the terminal, indicating the number of kmers with 0 occurrences, the number of unknown kmers and he mean occurrences:

```
	Processing 'HG00663'
        KIV2 kmers with 0 counts: 0 / 2933
        LPA kmers with 0 counts: 2680 / 74564
        Unknown kmers: 9
        KIV2 mean kmer occurrence:'73.34'
        LPA  mean kmer occurrence:'4.87'
        CN = 30.10

	Processing 'HG00671'
        KIV2 kmers with 0 counts: 0 / 2933
        LPA kmers with 0 counts: 2364 / 74564
        Unknown kmers: 9
        KIV2 mean kmer occurrence:'88.97'
        LPA  mean kmer occurrence:'5.20'
        CN = 34.19
```

### FAQ

#### kmer size discordance

If you have 0 kmers for some samples (see example below), please check the concordance of the kmer length between the list of kmers and the config file ('kmer_size')

```
Processing 'C0016B8_1'
        KIV2 kmers with 0 counts: 0 / 0
        Normalisation kmers with 0 counts: 0 / 0
        Unknown kmers: 91036
```

#### GRCh37 vs GRCh38

For the list of kmers provided here, building them on GRCh37 or GRCh37 did not yield significant differences. When using custom kmer lists, there should be an impact on the KIV2 count only if the normalisation and/or KIV2 regions are different between the two versions.

#### Generating the variant kmers

We wrote a bash script to generate the reference and alternative kmers for use with KILDA: [variant_kmers.sh](./bin/variant_kmers.sh).

You will need to provide the kmer length and the path to the same reference genome as was used for the generation of the kmer DB with kilda.nf. This is [GRCh38](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_47/GRCh38.primary_assembly.genome.fa.gz "GRCh38 primary assembly from GenCode") if you are using the kmer DB provided within this repository.

You will also need to provide the name, position and REF and ALT alleles for the SNP of interest. *Note*: the name of the variant will only be used to name columns in the output file.
