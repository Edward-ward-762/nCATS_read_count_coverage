process APPEND_COVERAGE {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), file(read), file(coverage)

    output:
    tuple val(meta), file("${meta.id}_read_coverage.csv"), emit: merged

    script:
    """
    echo "\$(cat $read), \$(cat $coverage)" >> "${meta.id}_read_coverage.csv"
    """
}