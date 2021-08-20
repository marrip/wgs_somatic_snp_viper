import pandas as pd
from snakemake.exceptions import WorkflowError
from snakemake.utils import validate
from snakemake.utils import min_version

min_version("6.0.0")

### Set and validate config file


configfile: "config.yaml"


validate(config, schema="../schemas/config.schema.yaml")


### Read and validate samples file

samples = pd.read_table(config["samples"], dtype=str).set_index("sample", drop=False)
validate(samples, schema="../schemas/samples.schema.yaml")


### Read and validate units file

units = (
    pd.read_table(config["units"], dtype=str)
    .sort_values(["sample", "unit"], ascending=False)
    .set_index(["sample", "unit"], drop=False)
)
validate(units, schema="../schemas/units.schema.yaml")


### Generate modus dictionary

modus = (
    units[["sample", "unit"]]
    .drop_duplicates()
    .reset_index(drop=True)
    .groupby("sample")
    .unit
)
modus = pd.concat([modus.apply("".join)], axis=1, keys=["modus"]).to_dict()["modus"]


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


def get_bam(wildcards):
    if modus[wildcards.sample] == "TN":
        return {
            "t_bam": "analysis_output/{sample}/gather_bam_files/{sample}_T.bam".format(
                sample=wildcards.sample
            ),
            "n_bam": "analysis_output/{sample}/gather_bam_files/{sample}_N.bam".format(
                sample=wildcards.sample
            ),
        }
    elif modus[wildcards.sample] == "T":
        return {
            "t_bam": "analysis_output/{sample}/gather_bam_files/{sample}_T.bam".format(
                sample=wildcards.sample
            ),
        }
    else:
        raise WorkflowError("%s is not paired with a tumor sample" % wildcards.sample)


def check_mutect2_pon():
    if config["mutect2"]["pon"] == "":
        return "analysis_output/pon/mutect2_somatic_pon.vcf"
    else:
        return config["mutect2"]["pon"]


def get_mutect2_fmt_input(wildcards):
    files = get_bam(wildcards)
    if modus[wildcards.sample] == "TN":
        return "%s -I %s -normal %s_N" % (
            files["t_bam"],
            files["n_bam"],
            wildcards.sample,
        )
    else:
        return files["t_bam"]


def get_pileup_summaries(wildcards):
    if modus[wildcards.sample] == "TN":
        return {
            "t_tsv": "analysis_output/{sample}/mutect2/{sample}_T.tsv".format(
                sample=wildcards.sample
            ),
            "n_tsv": "analysis_output/{sample}/mutect2/{sample}_N.tsv".format(
                sample=wildcards.sample
            ),
        }
    elif modus[wildcards.sample] == "T":
        return {
            "t_tsv": "analysis_output/{sample}/mutect2/{sample}_T.tsv".format(
                sample=wildcards.sample
            ),
        }
    else:
        raise WorkflowError("%s is not paired with a tumor sample" % wildcards.sample)


def get_calculate_contamination_fmt_input(wildcards):
    files = get_pileup_summaries(wildcards)
    if modus[wildcards.sample] == "TN":
        return "%s -matched %s" % (files["t_tsv"], files["n_tsv"])
    else:
        return files["t_tsv"]


def get_vardict_fmt_input(wildcards):
    files = get_bam(wildcards)
    if modus[wildcards.sample] == "TN":
        return "'%s|%s'" % (
            files["t_bam"],
            files["n_bam"],
        )
    else:
        return files["t_bam"]


def get_test_cmd(wildcards):
    if modus[wildcards.sample] == "TN":
        return "testsomatic.R"
    else:
        return "teststrandbias.R"


def get_v2v_cmd(wildcards):
    if modus[wildcards.sample] == "TN":
        return "var2vcf_paired.pl -N '%s_T|%s_N'" % (
            wildcards.sample,
            wildcards.sample,
        )
    else:
        return "var2vcf_valid.pl -N %s_T -E" % wildcards.sample


def compile_output_list(wildcards):
    output_list = []
    files = {
        "mutect2": [
            "filtered.vcf",
            "filtered.vcf.stats",
        ],
        "vardict": [
            "vcf",
        ],
    }
    for key in files.keys():
        output_list = output_list + expand(
            "analysis_output/{sample}/{tool}/{sample}.{ext}",
            sample=samples.index,
            tool=key,
            ext=files[key],
        )
    return output_list
