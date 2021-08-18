rule vardict:
    input:
        unpack(get_bam),
        ref=config["reference"]["fasta"],
    output:
        temp("analysis_output/{sample}/vardict/{sample}_{locus}.vcf"),
    params:
        b=get_vardict_fmt_input,
        f="0.01",
        c="1",
        S="2",
        E="3",
        g="4",
        test=get_test_cmd,
        v2v=get_v2v_cmd,
    log:
        "analysis_output/{sample}/vardict/vardict_{locus}.log",
    container:
        config["tools"]["vardict"]
    message:
        "{rule}: Call short somatic variants for {wildcards.sample} {wildcards.locus}"
    threads: 4
    shell:
        """
        (VarDict \
        -G {input.ref} \
        -f {params.f} \
        -N {wildcards.sample}_T \
        -b {params.b} \
        -c {params.c} \
        -S {params.S} \
        -E {params.E} \
        -g {params.g} \
        -th {threads} \
        -R {wildcards.locus} | \
        {params.test} | \
        {params.v2v} \
        -A \
        -f {params.f} > {output}) &> {log}
        """


rule bcftools_view:
    input:
        "analysis_output/{sample}/vardict/{sample}_{locus}.vcf",
    output:
        temp("analysis_output/{sample}/vardict/{sample}_{locus}.vcf.gz"),
    log:
        "analysis_output/{sample}/vardict/bcftools_view_{locus}.log",
    container:
        config["tools"]["common"]
    message:
        "{rule}: Compress vcf file of {wildcards.sample} at {wildcards.locus}"
    shell:
        """
        bcftools view \
        {input} \
        -O z \
        -o {output} &> {log}
        """


rule bcftools_index:
    input:
        "analysis_output/{sample}/vardict/{sample}_{locus}.vcf.gz",
    output:
        temp("analysis_output/{sample}/vardict/{sample}_{locus}.vcf.gz.csi"),
    log:
        "analysis_output/{sample}/vardict/bcftools_index_{locus}.log",
    container:
        config["tools"]["common"]
    message:
        "{rule}: Generate index for vcf of {wildcards.sample} at {wildcards.locus}"
    shell:
        """
        bcftools index \
        {input} &> {log}
        """


rule bcftools_concat:
    input:
        vcf=expand(
            "analysis_output/{{sample}}/vardict/{{sample}}_{locus}.vcf.gz",
            locus=get_loci(config["vardict"]["bed"]),
        ),
        csi=expand(
            "analysis_output/{{sample}}/vardict/{{sample}}_{locus}.vcf.gz.csi",
            locus=get_loci(config["vardict"]["bed"]),
        ),
    output:
        "analysis_output/{sample}/vardict/{sample}.vcf",
    log:
        "analysis_output/{sample}/vardict/bcftools_concat.log",
    container:
        config["tools"]["common"]
    message:
        "{rule}: Concatenate vcf files for {wildcards.sample}"
    shell:
        """
        bcftools concat \
        -o {output} \
        {input.vcf} &> {log}
        """
