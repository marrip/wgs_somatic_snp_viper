rule mutect2:
    input:
        bam="analysis_output/{sample}/gather_bam_files/{sample}.bam",
        ref=config["reference"]["fasta"],
    output:
        "analysis_output/{sample}/mutect2/{sample}.vcf",
    log:
        "analysis_output/{sample}/mutect2/{sample}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Call short somatic variants for {wildcards.sample}"
    shell:
        "gatk Mutect2 "
        "-I {input.bam} "
        "-R {input.ref} "
        "-O {output} &> {log}"
