#!/usr/bin/env python3

import sys
import os
import gzip

def main():
    if len(sys.argv) != 4:
        print("Usage: merge.py SELECTION_FILE TEMP_DIR OUTPUT_FILE")
        sys.exit(1)

    sel = sys.argv[1]
    temp = sys.argv[2]
    out_file = sys.argv[3]

    # read chromosome order
    order = []
    with open(sel) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            order.append(line.split("\t")[0])

    # merge in order
    with gzip.open(out_file, "wt") as out:
        for chrom in order:
            fname = os.path.join(temp, f"{chrom}_sorted.bed")
            if not os.path.exists(fname):
                continue
            with open(fname) as f:
                for l in f:
                    out.write(l)

if __name__ == "__main__":
    main()
