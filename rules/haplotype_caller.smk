rule haplotype_caller:
    input:
        bam="analysis_output/{sample}/gather_bam_files/{sample}.bam",
        ref=config["reference"]["fasta"],
    output:
        temp("analysis_output/{sample}/haplotype_caller/{sample}_{locus}.vcf"),
    log:
        "analysis_output/{sample}/haplotype_caller/{sample}_{locus}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Call short germline variants for {wildcards.sample} {wildcards.locus}"
    shell:
        "gatk HaplotypeCaller "
        "--input {input.bam} "
        "--output {output} "
        "-L {wildcards.locus} "
        "--reference {input.ref} &> {log}"
