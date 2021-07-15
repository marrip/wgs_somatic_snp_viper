rule split_bed:
    input:
        loci=config["reference"]["loci"],
        bed=config["vardict"]["bed"],
    output:
        dir=directory("analysis_output/temp/"),
        files=temp(expand("analysis_output/temp/{locus}.bed", locus=get_loci())),
    log:
        "analysis_output/temp/split_bed.log",
    container:
        config["tools"]["python"]
    message:
        "{rule}: Split VarDict bed file per chromosome"
    script:
        "../scripts/split_bed.py"


rule vardict:
    input:
        bam="analysis_output/{sample}/gather_bam_files/{sample}.bam",
        ref=config["reference"]["fasta"],
        bed="analysis_output/temp/{locus}.bed",
    output:
        temp("analysis_output/{sample}/vardict/{sample}_{locus}.vcf"),
    params:
        f="0.01",
        c="1",
        S="2",
        E="3",
        g="4",
    log:
        "analysis_output/{sample}/vardict/{sample}_{locus}.log",
    container:
        config["tools"]["vardict"]
    message:
        "{rule}: Call short somatic variants for {wildcards.sample} {wildcards.locus}"
    threads: 4
    shell:
        "(VarDict "
        "-G {input.ref} "
        "-f {params.f} "
        "-N {wildcards.sample} "
        "-b {input.bam} "
        "-c {params.c} "
        "-S {params.S} "
        "-E {params.E} "
        "-g {params.g} "
        "-th {threads} "
        "{input.bed} | "
        "teststrandbias.R | "
        "var2vcf_valid.pl "
        "-A "
        "-N {wildcards.sample} "
        "-E "
        "-f {params.f} > {output}) &> {log}"
