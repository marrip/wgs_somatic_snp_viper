#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import os
import re

def split_bed(bed_fp, output_fp):
    bed = open(bed_fp, "r")
    for line in bed.readlines():
        locus = "%s:%s-%s" % (line.split("\t")[0], line.split("\t")[1], line.split("\t")[2])
        output = open(
            get_output_name(locus, output_fp),
            "w",
        )
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
    snakemake.input["bed"],
    snakemake.output["dir"],
)
