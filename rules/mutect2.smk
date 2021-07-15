rule mutect2:
    input:
        bam="analysis_output/{sample}/gather_bam_files/{sample}.bam",
        ref=config["reference"]["fasta"],
    output:
        temp("analysis_output/{sample}/mutect2/{sample}_{locus}.vcf"),
    log:
        "analysis_output/{sample}/mutect2/{sample}_{locus}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Call short somatic variants for {wildcards.sample} {wildcards.locus}"
    shell:
        "gatk Mutect2 "
        "-I {input.bam} "
        "-R {input.ref} "
        "-L {wildcards.locus} "
        "-O {output} &> {log}"
