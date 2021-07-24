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


def get_loci(loci):
    loci_tab = pd.read_table(loci, header=None, dtype=str)
    if len(loci_tab.columns) == 1:
        return loci_tab[0].tolist()
    else:
        loci_tab["locus"] = loci_tab[0].str.cat(loci_tab[1], ":")
        loci_tab["locus"] = loci_tab["locus"].str.cat(loci_tab[2], "-")
        return loci_tab["locus"].tolist()


def get_all_vcf(wildcards):
    if wildcards.tool == "vardict":
        locus = get_loci(config["vardict"]["bed"])
    else:
        locus = get_loci(config["reference"]["loci"])
    return expand(
        "analysis_output/{sample}/{tool}/{sample}_{locus}.vcf",
        sample=wildcards.sample,
        tool=wildcards.tool,
        locus=locus,
    )


def get_fmt_vcf(wildcards):
    return " -I ".join(get_all_vcf(wildcards))


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
