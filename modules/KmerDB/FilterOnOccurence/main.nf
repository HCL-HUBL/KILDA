process FilterOnOccurence {
    label 'kmerDB'

    cpus 1
    memory { 1.GB * task.attempt }
    time { 1.hour * task.attempt }
    
    input:
        path(kmers)
        val(occurence)
        
    output:
        path(kmers_filtered_dump)
    
    script:
        kmers_filtered_dump = "${kmers}_${occurence}copies.dump"
        
        """
        set -eo pipefail
        ${params.tools.jellyfish} dump -c -t -L ${occurence} -U ${occurence} -o ${kmers_filtered_dump} ${kmers}
        """
}