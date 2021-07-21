rule split_bed:
    input:
        bed=config["vardict"]["bed"],
    output:
        dir=directory("analysis_output/temp/"),
        files=expand("analysis_output/temp/{position}.bed", position=get_position()),
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
        bed="analysis_output/temp/{position}.bed",
    output:
        "analysis_output/{sample}/vardict/{sample}_{position}.vcf",
    params:
        f="0.01",
        c="1",
        S="2",
        E="3",
        g="4",
    log:
        "analysis_output/{sample}/vardict/{sample}_{position}.log",
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


rule merge_vcf_vardict:
    input:
        dct=config["reference"]["dct"],
        files=get_all_vcf_vardict,
    output:
        "analysis_output/{sample}/vardict/{sample}.vcf",
    params:
        get_all_vcf_fmt_vardict,
    log:
        "analysis_output/{sample}/vardict/{sample}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Concatenate {wildcards.sample} vcf files"
    shell:
        "gatk MergeVcfs "
        "-I {params} "
        "-D {input.dct} "
        "-O {output} &> {log}"
