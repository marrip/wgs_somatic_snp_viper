import pandas as pd
from snakemake.utils import validate
from snakemake.utils import min_version

min_version("5.32.0")

### Set and validate config file


configfile: "config.yaml"


validate(config, schema="../schemas/config.schema.yaml")


### Read and validate samples file

samples = pd.read_table(config["samples"]).set_index("sample", drop=False)

validate(samples, schema="../schemas/samples.schema.yaml")


### Set wildcard constraints


wildcard_constraints:
    sample="|".join(samples.index),


### Functions


def get_loci():
    with open(config["reference"]["loci"]) as f:
        return [line.rstrip() for line in f]


def get_position():
    with open(config["vardict"]["bed"]) as f:
        return ["%s:%s-%s" % (line.split("\t")[0], line.split("\t")[1], line.split("\t")[2]) for line in f.readlines()]


def get_all_vcf(wildcards):
    return expand(
        "analysis_output/{sample}/{tool}/{sample}_{locus}.vcf",
        sample=wildcards.sample,
        tool=wildcards.tool,
        locus=get_loci(),
    )


def get_all_vcf_fmt(wildcards):
    return " -I ".join(list(get_all_vcf(wildcards)))


def get_all_vcf_vardict(wildcards):
    return expand(
        "analysis_output/{sample}/vardict/{sample}_{locus}.vcf",
        sample=wildcards.sample,
        locus=get_position(),
    )


def get_all_vcf_fmt_vardict(wildcards):
    return " -I ".join(list(get_all_vcf(wildcards)))


def compile_output_list(wildcards):
    output_list = []
    files = {
        "haplotype_caller": ["vcf",],
        "mutect2": ["vcf",],
        "vardict": ["vcf",],
    }
    for key in files.keys():
        output_list = output_list + expand(
            "analysis_output/{sample}/{tool}/{sample}.{ext}",
            sample=wildcards.sample,
            tool=key,
            ext=files[key],
        )
    return output_list
