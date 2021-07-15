#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import os
import re

def split_bed(loci_fp, bed_fp, output_fp):
    loci = open(loci_fp, "r")
    bed = open(bed_fp, "r")
    for locus in loci.read().splitlines():
        output = open(
            get_output_name(locus, output_fp),
            "w",
        )
        for line in bed.read().splitlines():
            if re.search(r"^%s" % locus, line):
                output.writelines((line))
        output.close()
    return

def get_output_name(locus, output_fp):
    return os.path.join(
        output_fp,
        "%s.bed" % locus,
    )

logging.basicConfig(level=logging.INFO, filename=snakemake.log[0])
split_bed(
    snakemake.input["loci"],
    snakemake.input["bed"],
    snakemake.output["dir"],
)
