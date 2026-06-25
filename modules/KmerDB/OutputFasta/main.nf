process OutputFasta {
    publishDir "${params.outdir}/", mode: 'copy'

    cpus 1
    memory { 1.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
        tuple(path(kiv2_unique_kmers_list), path(norm_unique_kmers_list))
    
    output:
        tuple(path(kiv2_unique_kmers_fasta), path(norm_unique_kmers_fasta))

    script:
        kiv2_unique_kmers_fasta = "${kiv2_unique_kmers_list.baseName}.fasta"
        norm_unique_kmers_fasta = "${norm_unique_kmers_list.baseName}.fasta"
        
        """
        set -eo pipefail
        
        awk '{print ">kmer_KIV2_"NR"\\n"\$1 }' ${kiv2_unique_kmers_list} > ${kiv2_unique_kmers_fasta}
        awk '{print ">kmer_NORM_"NR"\\n"\$1 }' ${norm_unique_kmers_list} > ${norm_unique_kmers_fasta}
        """
}