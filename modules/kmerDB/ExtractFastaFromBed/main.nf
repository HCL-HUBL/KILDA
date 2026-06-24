process ExtractFastaFromBed {
    label 'kmerDB'

    cpus 1
    memory { 1.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
        path(fasta)
        path(fai)
        path(region_bed)
        
    output:
        path(region_fasta)
        
    script:
        region_fasta = "${region_bed.baseName}.fasta"
        
        """
        set -eo pipefail
        
        awk -F '\t' '{printf("%s:%d-%s\\n",\$1,int(\$2)+1,\$3);}' ${region_bed} > region.regions
        ${params.tools.samtools} faidx ${fasta} -r region.regions > ${region_fasta}
        """
}
