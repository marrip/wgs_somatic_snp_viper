include: "rules/common.smk"
include: "rules/mutect2.smk"

rule all:
    input:
        compile_output_list(),
