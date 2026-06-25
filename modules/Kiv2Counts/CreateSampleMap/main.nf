// Generate the list of counts, to be used as input by the "kilda" process
process CreateSampleMap {
    publishDir "${params.wdir}/", mode: 'copy'

    label 'kiv2Counts'

    cpus 1
    memory { 1.MB * task.attempt }
    time { 1.hour * task.attempt }

    input:
        path(counts)

    output:
        path(counts_list), emit: counts_list

    script:	
        counts_list = "counts.list"
        list_content = ""
        
        for(String count : counts) {
            // "split("/").last()" as a basename, then removing the ".counts" to get the sampleID (cf previous processes for naming conventions)
            sampleID = count.split("/").last().split(".counts").first()    
            list_content = list_content + sampleID + "\t${params.wdir}/counts/" + count + "\n"
        }
        // Remove the last trailing '\n' (empty final line)
        list_content = list_content.trim()

        """
        set -eo pipefail
        echo "${list_content}" > ${counts_list}
        """
}