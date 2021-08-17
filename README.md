# wgs_somatic_snp_viper

Simple workflow to call short variants in somatic whole genome data

![Snakefmt](https://github.com/marrip/wgs_somatic_snp_viper/actions/workflows/main.yaml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## :speech_balloon: Introduction

This snakemake workflow takes `.bam` files, which were prepped according to
[GATK best practices](https://gatk.broadinstitute.org/hc/en-us/articles/360035535912-Data-pre-processing-for-variant-discovery),
and calls SNVs and small Indels. The workflow can process tumor samples
paired with normals or be run as a tumor-only analysis.

### Mutect2

The variant calling is done according to
[this tutorial](https://gatk.broadinstitute.org/hc/en-us/articles/360035531132)
and requires a panel of normals (PoN).

### VarDict

Calling variants with VarDict is performed as as indicated in the respective
[repository](https://github.com/AstraZeneca-NGS/VarDictJava).

## :heavy_exclamation_mark: Dependencies

To run this workflow, the following tools need to be available:

![python](https://img.shields.io/badge/python-3.8-blue)

[![snakemake](https://img.shields.io/badge/snakemake-5.32.0-blue)](https://snakemake.readthedocs.io/en/stable/)

[![singularity](https://img.shields.io/badge/singularity-3.7-blue)](https://sylabs.io/docs/)

## :school_satchel: Preparations

### Sample data

1. Add all sample ids to `samples.tsv` in the column `sample`.
2. Add sample type information, normal or tumor, to `units.tsv`.
3. Use the `analysis_output` folder from
[wgs_std_viper](https://github.com/marrip/wgs_std_viper) as input.

### Reference data

1. You need a reference `.fasta` file representing the genome used
for mapping. For the different tools to work, you also
need to prepare index files and a `.dict` file.

- The required files for the human reference genome GRCh38 can be downloaded from
[google cloud](https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0).
The download can be manually done using the browser or using `gsutil` via the command line:

```bash
gsutil cp gs://genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta /path/to/download/dir/
```

- If those resources are not available for your reference you may generate them yourself:

```bash
samtools faidx /path/to/reference.fasta
gatk CreateSequenceDictionary -R /path/to/reference.fasta -O /path/to/reference.dict
```

2. A VarDict `.bed` file containing all these genomic regions, which Vardict should
call variants in. The regions should be split by 5 MBp or less.
3. Mutect2 requires an `.interval_list` file to create a panel of normals (PoN).
For GRCh38, the file is also available in the google bucket. If you already have
a PoN you can simply leave `""` instead.
4. If a PoN is available indicate that in the `config.yaml`. 
5. Mutect2 also requires a modified  [gnomad database](https://gnomad.broadinstitute.org/) 
as a `.vcf.gz`. For GRCh38, the file can be retrieved from
[google cloud](https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38;tab=objects?prefix=&forceOnObjectsSortingFiltering=false)
as described under 1.
6. Add the paths of the different files to the `config.yaml`. The index files should be
in the same directory as the reference `.fasta`.
7. Make sure that the docker container versions are correct.

## :white_check_mark: Testing

The workflow repository contains a small test dataset `.tests/integration` which can be run like so:

```bash
cd .tests/integration
snakemake -s ../../workflow/Snakefile -j1 --use-singularity
```

## :rocket: Usage

The workflow is designed for WGS data meaning huge datasets which require a lot of compute power. For
HPC clusters, it is recommended to use a cluster profile and run something like:

```bash
snakemake -s /path/to/Snakefile --profile my-awesome-profile
```

## :judge: Rule Graph

### PoN for mutect2 is available

![rule_graph](https://raw.githubusercontent.com/marrip/wgs_somatic_pon/prep-t-n/images/rulegraph_with_pon.svg)

### PoN for mutect2 is missing

![rule_graph](https://raw.githubusercontent.com/marrip/wgs_somatic_pon/prep-t-n/images/rulegraph_without_pon.svg)
