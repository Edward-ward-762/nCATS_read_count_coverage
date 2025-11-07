#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Blank pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { DUMP_SOFTWARE_VERSIONS } from './modules/local/dump_software_versions.nf'
include { readsCount             } from './modules/local/readsCount.nf'
include { EXTRACT_COVERAGE       } from './modules/local/extract_coverage/extract_coverage.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMTOOLS_COVERAGE } from './modules/nf-core/samtools/coverage/main.nf'
include { SAMTOOLS_INDEX    } from './modules/nf-core/samtools/index/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow{

    //
    // ****************************
    //
    // SECTION: Creating input Channels
    //
    // ****************************
    //

    ch_inputData = Channel.fromPath(params.inputFile)
                        .splitCsv(header: true)
                        .map { row ->
                            [[id: row.sample_id,referenceName: row.reference_name,startCutSite: row.start_cut_site,endCutSite: row.end_cut_site],row.bam_path]
                        }

    ch_versions = Channel.empty()


    //
    // ****************************
    //
    // SECTION: Calculate coverage stats of input bam file(s)
    //
    // ****************************
    //

    //
    // MODULE: SAMTOOLS INDEX
    //

    SAMTOOLS_INDEX(
        ch_inputData.map{ meta, bam -> [meta, bam] }
    )
    ch_versions  = ch_versions.mix(SAMTOOLS_INDEX.out.versions)
    ch_input_bai = SAMTOOLS_INDEX.out.bai

    //
    // CHANNEL: Combine BAM and BAI
    //
    ch_input_bam_bai = ch_inputData
        .join(ch_input_bai, by: [0])
        .map {
            meta, bam, bai ->
                if (bai) {
                    [ meta, bam, bai ]
                }
        }

    //
    // MODULE: SAMTOOLS COVERAGE
    //

    SAMTOOLS_COVERAGE(
        ch_input_bam_bai.map{ meta, bam, bai -> [meta, bam, bai] },
        [[],[]],
        [[],[]]
    )
    ch_versions = ch_versions.mix(SAMTOOLS_COVERAGE.out.versions)


    //
    // ****************************
    //
    // SECTION: Calculate number of reads in input bam file(s)
    //
    // ****************************
    //

    //
    // MODULE: readsCount
    //

    readsCount(
        ch_inputData.map{ meta, bam -> [meta, bam] }
    )
    ch_versions = ch_versions.mix(readsCount.out.versions)

    //
    // ****************************
    //
    // SECTION: Software version dump
    //
    // ****************************
    //

    //
    // MODULE: Collect software versions
    //
    DUMP_SOFTWARE_VERSIONS (
        ch_versions.unique().collectFile()
    )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
