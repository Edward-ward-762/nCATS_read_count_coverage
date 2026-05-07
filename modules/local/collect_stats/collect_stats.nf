process COLLECT_STATS {
    label 'process_single'

    input:
    path input

    output:
    path "read_count_and_coverage.csv"

    script:
    """
    echo "sample_id,input_read_count,filtered_read_count, input_coverage, filtered_coverage" > "read_count_and_coverage.csv"
    cat ${input} >> "read_count_and_coverage.csv"
    """
}