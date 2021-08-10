rule mutect2:
    input:
        unpack(get_bam),
        ref=config["reference"]["fasta"],
        gnomad=config["mutect2"]["gnomad"],
        pon=config["mutect2"]["pon"],
    output:
        vcf=temp("analysis_output/{sample}/mutect2/{sample}_{locus}.vcf"),
        stats=temp("analysis_output/{sample}/mutect2/{sample}_{locus}.vcf.stats"),
        f1r2=temp("analysis_output/{sample}/mutect2/{sample}_{locus}.f1r2.tar.gz"),
    params:
        get_mutect2_fmt_input,
    log:
        "analysis_output/{sample}/mutect2/mutect2_{locus}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Call short somatic variants for {wildcards.sample} at {wildcards.locus}"
    shell:
        """
        gatk Mutect2 \
        -I {params} \
        -R {input.ref} \
        -L {wildcards.locus} \
        --germline-resource {input.gnomad} \
        --panel-of-normals {input.pon} \
        --f1r2-tar-gz {output.f1r2} \
        -O {output.vcf} &> {log}
        """


rule merge_vcfs:
    input:
        expand(
            "analysis_output/{{sample}}/mutect2/{{sample}}_{locus}.vcf",
            locus=get_loci(config["reference"]["loci"]),
        ),
    output:
        "analysis_output/{sample}/mutect2/{sample}.vcf",
    params:
        lambda wildcards, input: " -I ".join(input),
    log:
        "analysis_output/{sample}/mutect2/merge_vcfs.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Merge all vcf files of {wildcards.sample}"
    shell:
        """
        gatk MergeVcfs \
        -I {params} \
        -O {output} &> {log}
        """


rule get_pileup_summaries:
    input:
        bam="analysis_output/{sample}/gather_bam_files/{sample}_{unit}.bam",
        ref=config["reference"]["fasta"],
        vcf=config["mutect2"]["gnomad"],
    output:
        temp("analysis_output/{sample}/mutect2/{sample}_{unit}_{locus}.tsv"),
    log:
        "analysis_output/{sample}/mutect2/get_pileup_summaries_{unit}_{locus}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Get pileup summaries for {wildcards.sample}_{wildcards.unit} at {wildcards.locus}"
    shell:
        """
        gatk GetPileupSummaries \
        -I {input.bam} \
        -R {input.ref} \
        --interval-set-rule INTERSECTION \
        -L {wildcards.locus} \
        -V {input.vcf} \
        -L {input.vcf} \
        -O {output} &> {log}
        """


rule gather_pileup_summaries:
    input:
        tsv=expand(
            "analysis_output/{{sample}}/mutect2/{{sample}}_{{unit}}_{locus}.tsv",
            locus=get_loci(config["reference"]["loci"]),
        ),
        dct=config["reference"]["dct"],
    output:
        "analysis_output/{sample}/mutect2/{sample}_{unit}.tsv",
    params:
        lambda wildcards, input: " -I ".join(input.tsv),
    log:
        "analysis_output/{sample}/mutect2/get_pileup_summaries_{unit}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Gather pileup summaries for {wildcards.sample}_{wildcards.unit}"
    shell:
        """
        gatk GatherPileupSummaries \
        -I {params} \
        --sequence-dictionary {input.dct} \
        -O {output} &> {log}
        """


rule calculate_contamination:
    input:
        unpack(get_pileup_summaries),
    output:
        tsv="analysis_output/{sample}/mutect2/{sample}.tsv",
        seg="analysis_output/{sample}/mutect2/{sample}.seg",
    params:
        get_calculate_contamination_fmt_input,
    log:
        "analysis_output/{sample}/mutect2/calculate_contamination.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Get contamination table for {wildcards.sample}"
    shell:
        """
        gatk CalculateContamination \
        -I {params} \
        --tumor-segmentation {output.seg} \
        -O {output.tsv} &> {log}
        """


rule learn_read_orientation_model:
    input:
        expand(
            "analysis_output/{{sample}}/mutect2/{{sample}}_{locus}.f1r2.tar.gz",
            locus=get_loci(config["reference"]["loci"]),
        ),
    output:
        "analysis_output/{sample}/mutect2/{sample}.f1r2.tar.gz",
    params:
        lambda wildcards, input: " -I ".join(input),
    log:
        "analysis_output/{sample}/mutect2/learn_read_orientation_model.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Learn read orientation model for {wildcards.sample}"
    shell:
        """
        gatk LearnReadOrientationModel \
        -I {params} \
        -O {output} &> {log}
        """


rule merge_mutect_stats:
    input:
        expand(
            "analysis_output/{{sample}}/mutect2/{{sample}}_{locus}.vcf.stats",
            locus=get_loci(config["reference"]["loci"]),
        ),
    output:
        "analysis_output/{sample}/mutect2/{sample}.vcf.stats",
    params:
        lambda wildcards, input: " -stats ".join(input),
    log:
        "analysis_output/{sample}/mutect2/merge_mutect_stats.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Merge stats files for {wildcards.sample}"
    shell:
        """
        gatk MergeMutectStats \
        -stats {params} \
        -O {output} &> {log}
        """


rule filter_mutect_calls:
    input:
        vcf="analysis_output/{sample}/mutect2/{sample}.vcf",
        ref=config["reference"]["fasta"],
        tsv="analysis_output/{sample}/mutect2/{sample}.tsv",
        seg="analysis_output/{sample}/mutect2/{sample}.seg",
        f1r2="analysis_output/{sample}/mutect2/{sample}.f1r2.tar.gz",
        stats="analysis_output/{sample}/mutect2/{sample}.vcf.stats",
    output:
        vcf="analysis_output/{sample}/mutect2/{sample}.filtered.vcf",
        stats="analysis_output/{sample}/mutect2/{sample}.filtered.vcf.stats",
    log:
        "analysis_output/{sample}/mutect2/filter_mutect_calls.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Filter mutect2 vcf file for {wildcards.sample}"
    shell:
        """
        gatk FilterMutectCalls \
        -V {input.vcf} \
        -R {input.ref} \
        --contamination-table {input.tsv} \
        --tumor-segmentation {input.seg} \
        --ob-priors {input.f1r2} \
        --stats {input.stats} \
        --filtering-stats {output.stats} \
        -O {output.vcf} &> {log}
        """
