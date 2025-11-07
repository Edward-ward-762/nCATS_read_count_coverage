process COLLECT_STATS {
    label 'process_single'

    input:
    path input

    output:
    path "read_count_and_coverage.csv"

    script:
    """
    cat ${input} > "read_count_and_coverage.csv"
    """
}