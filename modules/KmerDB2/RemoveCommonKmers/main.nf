process RemoveCommonKmers {
    label 'kmerDB'
    publishDir "${params.outdir}/", mode: 'copy'

    cpus 1
    memory { 1.GB * task.attempt }
    time { 1.hour * task.attempt }

    
    input:
        path(kiv2_kmers_list)
        path(norm_kmers_list)

    output:
        path(kiv2_unique_kmers_list), emit: kiv2_list
        path(norm_unique_kmers_list), emit: norm_list
        
    script:
        kiv2_unique_kmers_list = "${kiv2_kmers_list.baseName}.tsv"
        norm_unique_kmers_list = "${norm_kmers_list.baseName}.tsv"
    
        """
        set -eo pipefail
        
        grep -vf ${kiv2_kmers_list} ${norm_kmers_list} > ${norm_unique_kmers_list}
        grep -vf ${norm_kmers_list} ${kiv2_kmers_list} > ${kiv2_unique_kmers_list}
        """
}