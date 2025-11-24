#!/usr/bin/env python3

import sys
import os
import gzip

def main():
    if len(sys.argv) < 4:
        print("Usage: split.py SELECTION_FILE TEMP_DIR BED1 BED2 ...")
        sys.exit(1)

    sel_file = sys.argv[1]
    temp_dir = sys.argv[2]
    bed_files = sys.argv[3:]

    # read chromosomes
    chroms = set()
    with open(sel_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            chroms.add(line.split("\t")[0])

    os.makedirs(temp_dir, exist_ok=True)

    # open one file per chromosome
    out = {}
    for c in chroms:
        out[c] = open(os.path.join(temp_dir, f"{c}.bed"), "w")

    # read bed files and write by chrom
    for bf in bed_files:
        with gzip.open(bf, "rt") as f:
            for line in f:
                line = line.rstrip()
                if not line:
                    continue
                parts = line.split("\t")
                if len(parts) < 3:
                    continue
                ch = parts[0]
                if ch in out:
                    out[ch].write(line + "\n")

    for h in out.values():
        h.close()

if __name__ == "__main__":
    main()
