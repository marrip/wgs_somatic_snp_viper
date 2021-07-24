#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import os.path

def split_bed(output):
    for item in output:
        with open(item, "w") as open_item:
            new_line = os.path.basename(item).replace(".bed", "").replace(":", "\t").replace("-", "\t")
            open_item.writelines(new_line)
            open_item.close()
    return

logging.basicConfig(level=logging.INFO, filename=snakemake.log[0])
split_bed(
    snakemake.output,
)
