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
