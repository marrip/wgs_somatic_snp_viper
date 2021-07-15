include: "rules/common.smk"
include: "rules/haplotype_caller.smk"
include: "rules/merge_vcf.smk"
include: "rules/mutect2.smk"
include: "rules/vardict.smk"


rule all:
    input:
        expand(
            "analysis_output/{sample}/wgs_somatic_snp_viper.ok", sample=samples.index
        ),


rule workflow_complete:
    input:
        unpack(compile_output_list),
    output:
        "analysis_output/{sample}/wgs_somatic_snp_viper.ok",
    log:
        "analysis_output/{sample}/wgs_somatic_snp_viper.workflow_complete.log",
    container:
        config["tools"]["common"]
    shell:
        "touch {output} &> {log}"
