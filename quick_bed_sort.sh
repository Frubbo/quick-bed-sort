#!/bin/bash
# Script to split, sort, and merge BED files
# Usage: ./quick_bed_sort.sh -s SELECTION_FILE -n SAMPLE_NAME BED_FILE1 BED_FILE2 ...

# Default values
OUTPUT_DIR="sorted_bed_file_per_sample"
TEMP_DIR="tmp"
SELECTION_FILE=""
SAMPLE_NAME=""

# Parse options (simpler getopts)
while getopts ":s:n:o:t:h" opt; do
    case $opt in
        s) SELECTION_FILE=$OPTARG ;;
        n) SAMPLE_NAME=$OPTARG ;;
        o) OUTPUT_DIR=$OPTARG ;;
        t) TEMP_DIR=$OPTARG ;;
        h)
            echo "Usage: $0 -s selection.tsv -n sample [bed files]"
            exit 0
            ;;
        *)
            echo "Unknown option"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

BED_FILES=("$@")

# Basic checks
[ -z "$SELECTION_FILE" ] && echo "Missing -s selection file" && exit 1
[ -z "$SAMPLE_NAME" ] && echo "Missing -n sample name" && exit 1
[ ! -f "$SELECTION_FILE" ] && echo "Selection file not found" && exit 1
[ ${#BED_FILES[@]} -eq 0 ] && echo "No BED files given" && exit 1

# Create dirs
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# Derive output name
SELECTION_NAME=$(basename "$SELECTION_FILE" .tsv)
OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}.${SELECTION_NAME}.bed.gz"

# Run split
python3 scripts/split.py "$SELECTION_FILE" "$TEMP_DIR" "${BED_FILES[@]}"
if [ $? -ne 0 ]; then
    echo "Split failed"
    exit 1
fi

# Sort each chromosome file
for f in "$TEMP_DIR"/*.bed; do
    [ -f "$f" ] || continue
    sorted="${f%.bed}_sorted.bed"
    sort -k2,2n -k3,3n "$f" > "$sorted"
done

# Merge
python3 scripts/merge.py "$SELECTION_FILE" "$TEMP_DIR" "$OUTPUT_FILE"
if [ $? -ne 0 ]; then
    echo "Merge failed"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo "Done: $OUTPUT_FILE"