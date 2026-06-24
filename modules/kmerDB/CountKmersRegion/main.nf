process CountKmersRegion {
    label 'kmerDB'

    cpus 10
    memory { 10.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
        path(region_fasta)
        
    output:
        path(kmers)
    
    script:
        kmers = "${region_fasta.baseName}_kmers"
        
        """
        set -eo pipefail
        ${params.tools.jellyfish} count -C -t ${task.cpus} -m ${params.kmer_size} -s 10G -o ${kmers} ${region_fasta}
        """
}