// Counting the number of kiv2, from all the counts files
process kilda {
    publishDir "${params.wdir}/", mode: 'copy'
    
    label 'kiv2Counts'

    cpus 1
    memory { 10.GB * task.attempt }
    time { 2.hour * task.attempt }

    input:
       path(kiv2_kmers)
       path(norm_kmers)
       path(counts_list)
       path(quantiles)
    
    output:
        path(kiv2_outdir)
    
    script:
        kiv2_outdir = "kilda_kiv2_CNs/"
        
        rsid_param = ""
        if("${params.rsids_list}" != "") {
            rsid_param = " -r ${params.rsids_list}"
        }

        q_params = ""
        if(quantiles) q_params = "-q ${quantiles}"

        """
        set -eo pipefail

        kilda.py \
        -c ${counts_list} -o ${kiv2_outdir} -v -p \
        -k ${kiv2_kmers} -l ${norm_kmers} \
        ${rsid_param} ${q_params}
        """
}