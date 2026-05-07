process APPEND_COVERAGE {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), file(read), file(filt_read), file(coverage), file(filt_cov)

    output:
    tuple val(meta), file("${meta.id}_read_coverage.csv"), emit: merged

    script:
    """
    echo "${meta.id}, \$(cat $read), \$(cat $filt_read), \$(cat $coverage), \$(cat $filt_cov)" >> "${meta.id}_read_coverage.csv"
    """
}