process CountKmersOutsideRegion {
    label 'kmerDB'

    cpus 10
    memory { 10.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
        path(fasta)
        path(fai)
        path(region_bed)
        
    output:
        path(kmers_outside_region_count)
    
    script:
        kmers_outside_region_count = "genome_without_region.kmers"
        
        """
        set -eo pipefail
        
        awk -F '\t' '{ print \$1"\\t0\\t"\$2 }' '${fai}' > genome.bed
        
        ${params.tools.bedtools} intersect -v -a genome.bed -b ${region_bed} | awk -F '\t' '{printf("%s:%d-%s\\n",\$1,int(\$2)+1,\$3);}' > genome_without_region.regions
        ${params.tools.samtools} faidx ${fasta} -r genome_without_region.regions > genome_without_region.fasta
        
        ${params.tools.jellyfish} count -C -t ${task.cpus} -m ${params.kmer_size} -s 10G -o ${kmers_outside_region_count} genome_without_region.fasta
        """
}