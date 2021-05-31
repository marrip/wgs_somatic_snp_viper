rule haplotype_caller:
    input:
        bam="analysis_output/{sample}/gather_bam_files/{sample}.bam",
        ref=config["reference"]["fasta"],
    output:
        "analysis_output/{sample}/haplotype_caller/{sample}.vcf",
    log:
        "analysis_output/{sample}/haplotype_caller/{sample}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Call short germline variants for {wildcards.sample}"
    shell:
        "gatk HaplotypeCaller "
        "--input {input.bam} "
        "--output {output} "
        "--reference {input.ref} &> {log}"
