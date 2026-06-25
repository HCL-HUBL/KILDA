process CreateFastaKmers {
    publishDir "${params.wdir}/", mode: 'copy'

    label 'kiv2Counts'

    cpus 1
    memory { 1.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
       path(kiv2_kmers)
       path(norm_kmers)
       path(rsids_list)
    
    output:
        path(norm_kiv2_fasta)
    
    script:
        norm_kiv2_fasta = "NORM_KIV2_kmers.fasta"

        // rsids is optional, if the file was not provided in the config file, do not add the rsid kmers to the FASTA:
        add_rsids = ""
        if(rsids_list) add_rsids = "awk '{ print \">\"\$1\"_ref\\n\"\$2\"\\n>\"\$1\"_alt\\n\"\$3 }' ${rsids_list} >> ${norm_kiv2_fasta};"

        """
        set -eo pipefail

        awk '{ print ">KIV2_"NR"\\n"\$1 }' ${kiv2_kmers} > ${norm_kiv2_fasta};
        awk '{ print ">NORM_"NR"\\n"\$1 }' ${norm_kmers} >> ${norm_kiv2_fasta};

        ${add_rsids}
        """
}