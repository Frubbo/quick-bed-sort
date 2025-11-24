# Quick BED Sort

Merge and sort multiple BED files by chromosome selection criteria.

## File Structure

```
.
├── quick_bed_sort.sh
├── scripts/
│   ├── split.py
│   └── merge.py
└── README.md
```

## Requirements

- Python 3.x
- Bash

## Usage

```bash
./quick_bed_sort.sh -s SELECTION_FILE -n SAMPLE_NAME BED_FILE1 BED_FILE2 ...
```

### Example

```bash
./quick_bed_sort.sh -s standard_selection.tsv -n X shuf.a.bed.gz shuf.b.bed.gz
```

This creates: `sorted_bed_file_per_sample/X.standard_selection.bed.gz`

### Arguments

- `-s`: Selection file (TSV with one chromosome per line)
- `-n`: Sample name
- `-o`: Output directory (optional, default: `sorted_bed_file_per_sample`)
- `-t`: Temp directory (optional, default: `tmp`)

## How It Works

The script merges multiple BED files, filters by selected chromosomes, and sorts intervals. Chromosomes appear in the output in the same order as the selection file.