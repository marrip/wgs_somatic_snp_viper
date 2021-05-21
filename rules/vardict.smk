rule vardict:
    input:
        bam="analysis_output/{sample}/gather_bam_files/{sample}.bam",
        ref=config["reference"]["fasta"],
        bed=config["vardict"]["bed"],
    output:
        "analysis_output/{sample}/vardict/{sample}.vcf",
    params:
        f="0.01",
        c="1",
        S="2",
        E="3",
        g="4",
    log:
        "analysis_output/{sample}/vardict/{sample}.log",
    container:
        config["tools"]["vardict"]
    message:
        "{rule}: Call short somatic variants for {wildcards.sample}"
    shell:
        "(vardict "
        "-G {input.ref} "
        "-f {params.f} "
        "-N {wildcards.sample} "
        "-b {input.bam} "
        "-c {params.c} "
        "-S {params.S} "
        "-E {params.E} "
        "-g {params.g} "
        "{input.bed} | "
        "teststrandbias.R | "
        "var2vcf_valid.pl "
        "-N {wildcards.sample} "
        "-E "
        "-f {params.f} > {output}) &> {log}"
