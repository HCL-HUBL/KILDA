// Counting all the kmers in the fastq files
process CountKmers {
    label 'kiv2Counts'

    cpus 1
    memory { 1.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
        tuple val(sampleID), path(fastqs)
        val(norm_kiv2_fasta)
    
    output:
        path(jellyfish_kmers)
    
    script:
        jellyfish_kmers = "${sampleID}.kmers"

        """
        set -eo pipefail
        ${params.tools.jellyfish} count -t ${task.cpus} -m ${params.kmer_size} -s 100M -C -o ${jellyfish_kmers} --if=${norm_kiv2_fasta} <(zcat -f ${fastqs.join(" ")});
        """
}