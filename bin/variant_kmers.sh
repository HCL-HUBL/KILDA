# Script to generate the "variant kmers" file for KILDA:
# The idea is to make a kmer with only one difference, corresponding to the REF
# and ALT alleles of the rsid of interest.

# Replace below to correspond to the values used for the creation of the kmer DB with "kilda.nf":
ref="/path/to/GRCh38.fa"
k=31

# Example of rsid:
rsid="rs7412"
chr="chr6"
pos=44908822
allele_ref="C"
allele_alt="T"

kmer_start=$((${pos} - ${k}/2));
kmer_stop=$((${pos} + ${k}/2));

# If the kmer length is even, we cannot have the same length before and after the
# changing allele. So, we remove one base from the end of the kmer.
if ((k%2 == 0)); then 
    kmer_stop=$((${kmer_stop}-1))
fi

pos_m1=$((${pos}-1));
pos_p1=$((${pos}+1));

seq_before=$(samtools faidx ${ref} ${chr}:${kmer_start}-${pos_m1} | tail -n +2);
seq_after=$(samtools faidx ${ref} ${chr}:${pos_p1}-${kmer_stop} | tail -n +2);

echo "${rsid}   ${seq_before}${allele_ref}${seq_after}  ${seq_before}${allele_alt}${seq_after}"
