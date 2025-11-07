process EXTRACT_COVERAGE {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(file)

    output:
    tuple val(meta), path("${file.baseName}_value.txt"), emit: coverage_value
    path "versions.yml"                                , emit: versions, optional: true

    script:
    """
    python3 $workflow.projectDir/bin/extract_coverage_information.py --input $file --output "${file.baseName}_value.txt" --process_name $task.process
    """
}