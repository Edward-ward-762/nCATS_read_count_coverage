#!/usr/bin/env nextflow

process readsCount {
    tag "$meta.id"
    label 'process_low'

    container "docker.io/edwardward762/transgenemapping:latest"

    input: 
        tuple val(meta), path(bamPath)

    output:
        tuple val(meta), path("${meta.id}_read_count.csv"), emit: count
        path "versions.yml"                               , emit: versions
    
    script:
    """
    echo "${meta.id}, \$(samtools view $bamPath -c)" >> ${meta.id}_read_count.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """    
}