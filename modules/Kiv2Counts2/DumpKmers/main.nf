// Querying the relevant kmers (KIV2 + normalisation regions)
process DumpKmers {
    publishDir "${params.wdir}/counts/", mode: 'copy'

    label 'kiv2Counts'

    cpus 1
    memory { 10.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
        path(jellyfish_kmers)
        
    output:
        path(counts)
    
    script:
        counts = "${jellyfish_kmers}".replaceAll(/.kmers/, ".counts")
        
        """
        set -eo pipefail
        ${params.tools.jellyfish} dump ${jellyfish_kmers} -c -t > ${counts}
        """
}