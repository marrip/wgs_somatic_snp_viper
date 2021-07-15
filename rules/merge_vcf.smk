rule merge_vcf:
    input:
        dct=config["reference"]["dct"],
        files=get_all_vcf,
    output:
        "analysis_output/{sample}/{tool}/{sample}.vcf",
    params:
        get_all_vcf_fmt,
    log:
        "analysis_output/{sample}/{tool}/{sample}.log",
    container:
        config["tools"]["gatk"]
    message:
        "{rule}: Concatenate {wildcards.sample} vcf files"
    shell:
      "gatk MergeVcfs "
      "-I {params} "
      "-D {input.dct} "
      "-O {output} &> {log}"
      #"bcftools concat "
        #"-o {output} "
        #"{params} &> {log}"
