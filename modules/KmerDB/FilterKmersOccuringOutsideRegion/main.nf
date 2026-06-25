process FilterKmersOccuringOutsideRegion {
    label 'kmerDB'

    cpus 1
    memory { 1.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
        path(kmers_filtered_dump)
        path(kmers_outside_region_count)
        
    output:
        path(kmers_specific)
    
    script:
        kmers_filtered_fasta = "${kmers_filtered_dump.baseName}.fasta"
        kmers_specific = "${kmers_filtered_dump.baseName}_specific.fasta"
        
        """
        set -eo pipefail
        
        cut -f 1 ${kmers_filtered_dump} | awk '{print ">kmer_"NR"\\n"\$1 }' > ${kmers_filtered_fasta}
        ${params.tools.jellyfish} query -s ${kmers_filtered_fasta} -o kmers_outside_occurences.counts ${kmers_outside_region_count}
        
        awk '\$2 == 0 { print \$1 }' kmers_outside_occurences.counts > specific_kmers.list
        cut -f 1 specific_kmers.list > ${kmers_specific}
        """
}
