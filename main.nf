#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nCATS read count and coverage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { DUMP_SOFTWARE_VERSIONS                   } from './modules/local/dump_software_versions.nf'
include { readsCount                               } from './modules/local/readsCount.nf'
include { readsCount as bam_filt_count             } from './modules/local/readsCount.nf'
include { EXTRACT_COVERAGE                         } from './modules/local/extract_coverage/extract_coverage.nf'
include { EXTRACT_COVERAGE as extract_bam_filt_cov } from './modules/local/extract_coverage/extract_coverage.nf'
include { APPEND_COVERAGE                          } from './modules/local/append_coverage/append_coverage.nf'
include { COLLECT_STATS                            } from './modules/local/collect_stats/collect_stats.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMTOOLS_COVERAGE                     } from './modules/nf-core/samtools/coverage/main.nf'
include { SAMTOOLS_COVERAGE as SAM_COV_BAM_FILT } from './modules/nf-core/samtools/coverage/main.nf'
include { SAMTOOLS_INDEX                        } from './modules/nf-core/samtools/index/main.nf'
include { SAMTOOLS_INDEX as SAM_INDEX_BAM_FILT  } from './modules/nf-core/samtools/index/main.nf'
include { SAMTOOLS_VIEW                         } from './modules/nf-core/samtools/view/main.nf'

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
                            [[id: row.sample_id,referenceName: row.reference_name,startCutSite: row.start_cut_site,endCutSite: row.end_cut_site,lengthFilter: row.filter_length],row.bam_path]
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
    ch_coverage_file = SAMTOOLS_COVERAGE.out.coverage
    ch_versions      = ch_versions.mix(SAMTOOLS_COVERAGE.out.versions)

    //
    // MODULE: Extract coverage information from coverage text file
    //

    EXTRACT_COVERAGE(
        ch_coverage_file.map{ meta, coverage -> [meta, coverage] }
    )
    ch_versions       = ch_versions.mix(EXTRACT_COVERAGE.out.versions)
    ch_coverage_value = EXTRACT_COVERAGE.out.coverage_value

    //
    // ****************************
    //
    // SECTION: Count reads in input bam file
    //
    // ****************************
    //

    //
    // MODULE: Count reads in bam file
    //

    readsCount(
        ch_inputData.map{ meta, bam -> [meta, bam] }
    )
    ch_versions         = ch_versions.mix(readsCount.out.versions)
    ch_input_read_count = readsCount.out.count 


    //
    // ****************************
    //
    // SECTION: Calculate coverage stats of filtered bam file(s)
    //
    // ****************************
    //  

    //
    // MODULE: Filter reads in bam file
    //

    SAMTOOLS_VIEW(
        ch_input_bam_bai.map{ meta, bam, bai -> [meta, bam, bai] },
        [[],[],[]],
        [[],[]],
        [[],[]],
        "bai"
    )
    ch_bam_filt = SAMTOOLS_VIEW.out.bam

    //
    // CHANNEL: Filter empty bams
    //
    ch_bam_filt = ch_bam_filt.filter { row ->
        file(row[1]).size() >= params.min_bam_size
    }

    //
    // MODULE: Index size filtered bam file
    //

    SAM_INDEX_BAM_FILT(
        ch_bam_filt.map{ meta, bam -> [meta, bam] }
    )
    ch_versions     = ch_versions.mix(SAM_INDEX_BAM_FILT.out.versions)
    ch_bam_filt_bai = SAM_INDEX_BAM_FILT.out.bai

    //
    // CHANNEL: Combine BAM and BAI
    //
    ch_bam_filt_bam_bai = ch_bam_filt
        .join(ch_bam_filt_bai, by: [0])
        .map {
            meta, bam, bai ->
                if (bai) {
                    [ meta, bam, bai ]
                }
        }

    //
    // MODULE: SAMTOOLS COVERAGE
    //

    SAM_COV_BAM_FILT(
        ch_bam_filt_bam_bai.map{ meta, bam, bai -> [meta, bam, bai] },
        [[],[]],
        [[],[]]
    )
    ch_bam_filt_coverage_file = SAM_COV_BAM_FILT.out.coverage
    ch_versions               = ch_versions.mix(SAM_COV_BAM_FILT.out.versions)

    //
    // MODULE: Extract coverage information from coverage text file
    //

    extract_bam_filt_cov(
        ch_bam_filt_coverage_file.map{ meta, coverage -> [meta, coverage] }
    )
    ch_versions            = ch_versions.mix(extract_bam_filt_cov.out.versions)
    ch_filt_coverage_value = extract_bam_filt_cov.out.coverage_value

    //
    // ****************************
    //
    // SECTION: Count reads in alignment length filtered bam file(s)
    //
    // ****************************
    //

    //
    // MODULE: Count reads in size filtered bam file
    //

    bam_filt_count(
        ch_bam_filt.map{ meta, bam -> [meta, bam] }
    )
    ch_versions            = ch_versions.mix(bam_filt_count.out.versions)
    ch_bam_filt_read_count = bam_filt_count.out.count


    //
    // ****************************
    //
    // SECTION: Collate read count and coverage stats
    //
    // ****************************
    //

    ch_collated_data = ch_input_read_count
        .join(ch_bam_filt_read_count, by: [0])
        .join(ch_coverage_value, by: [0])
        .join(ch_filt_coverage_value, by: [0])

/*
    //
    // CHANNEL: combine read count and coverage
    //

    ch_read_coverage = ch_input_read_count
        .join(ch_coverage_value, by: [0])
        .map {
            meta, read, coverage ->
                if (coverage) {
                    [meta, read, coverage]
                }
        }

*/

    //
    // MODULE: Append coverage information to read count file
    //

    APPEND_COVERAGE(
        ch_collated_data.map{ meta, read, filt_count, coverage, filt_cov -> [meta, read, filt_count, coverage, filt_cov] }
    )
    ch_merged = APPEND_COVERAGE.out.merged

    ch_merged_file = ch_merged
        .map{ meta, file -> [file] }
        .collect()

/*

    //
    // ****************************
    //
    // SECTION: Collate all read coverage stats
    //
    // ****************************
    //

    //
    // MODULE: Collect all read coverage stats
    //

    COLLECT_STATS(
        ch_merged_file
    )


    //
    // ****************************
    //
    // SECTION: Software version dump
    //
    // ****************************
    //
*/
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
