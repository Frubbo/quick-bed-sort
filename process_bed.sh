#!/bin/bash
# Main script to process BED files using Quick BED Sort approach
# Phases: Split -> Sort -> Merge -> Cleanup

set -e  # Exit on any error

usage() {
    cat << EOF
Usage: $0 -s SELECTION_FILE -n SAMPLE_NAME [OPTIONS] BED_FILE1 BED_FILE2 ...

Required Arguments:
    -s SELECTION_FILE    TSV file with chromosome selection
    -n SAMPLE_NAME       Sample name for output file

Optional Arguments:
    -o OUTPUT_DIR        Output directory (default: sorted_bed_file_per_sample)
    -t TEMP_DIR          Temp directory (default: temp_SAMPLE_PID)
    --keep-temp          Keep temporary files after completion
    -h                   Show this help message

Example:
    $0 -s standard_selection.tsv -n X shuf.a.bed.gz shuf.b.bed.gz

EOF
    exit 1
}

# Default values
OUTPUT_DIR="sorted_bed_file_per_sample"
TEMP_DIR=""
KEEP_TEMP=false
SELECTION_FILE=""
SAMPLE_NAME=""

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -s)
            SELECTION_FILE="$2"
            shift 2
            ;;
        -n)
            SAMPLE_NAME="$2"
            shift 2
            ;;
        -o)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t)
            TEMP_DIR="$2"
            shift 2
            ;;
        --keep-temp)
            KEEP_TEMP=true
            shift
            ;;
        -h)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            break
            ;;
    esac
done

# Remaining arguments are BED files
BED_FILES=("$@")

# Check required arguments
if [ -z "$SELECTION_FILE" ]; then
    echo "Error: Selection file (-s) is required"
    usage
fi

if [ -z "$SAMPLE_NAME" ]; then
    echo "Error: Sample name (-n) is required"
    usage
fi

if [ ${#BED_FILES[@]} -eq 0 ]; then
    echo "Error: At least one BED file is required"
    usage
fi

# Check if selection file exists
if [ ! -f "$SELECTION_FILE" ]; then
    echo "Error: Selection file not found: $SELECTION_FILE"
    exit 1
fi

# Check if all BED files exist
for bed_file in "${BED_FILES[@]}"; do
    if [ ! -f "$bed_file" ]; then
        echo "Error: BED file not found: $bed_file"
        exit 1
    fi
done

# Extract selection name from selection file
SELECTION_NAME=$(basename "$SELECTION_FILE" .tsv)
SELECTION_NAME=${SELECTION_NAME%_selection}

# Set temp directory if not provided
if [ -z "$TEMP_DIR" ]; then
    TEMP_DIR="temp_${SAMPLE_NAME}_$$"
fi

# Create directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_DIR"

# Construct output filename
OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE_NAME}.${SELECTION_NAME}.bed.gz"

# Print configuration
# echo "========================================"
# echo "BED CHROMOSOME SORTER"
# echo "========================================"
# echo "Sample name: $SAMPLE_NAME"
# echo "Selection: $SELECTION_NAME"
# echo "Selection file: $SELECTION_FILE"
# echo "BED files: ${#BED_FILES[@]}"
# echo "Temp directory: $TEMP_DIR"
# echo "Output file: $OUTPUT_FILE"
# echo "========================================"
# echo ""

# echo "SPLITTING BY CHROMOSOME"
# echo "----------------------------------------"

python3 scripts/split_by_chromosome.py "$SELECTION_FILE" "$TEMP_DIR" "${BED_FILES[@]}"

if [ $? -ne 0 ]; then
    echo "Error: Split failed"
    exit 1
fi

# echo ""

# echo "SORTING EACH CHROMOSOME"
# echo "----------------------------------------"

# Count files to sort
UNSORTED_FILES=("$TEMP_DIR"/*.bed)
NUM_FILES=${#UNSORTED_FILES[@]}

# echo "Sorting $NUM_FILES chromosome files..."

# Sort each chromosome file
count=0
for file in "$TEMP_DIR"/*.bed; do
    if [ -f "$file" ]; then
        count=$((count + 1))
        chrom=$(basename "$file" .bed)
        echo "  [$count/$NUM_FILES] Sorting $chrom..."
        
        # Sort by column 2 (start), then column 3 (end)
        sort --parallel=4 -S4G -k2,2n -k3,3n  "$file" -o "${file%.bed}_sorted.bed"
    fi
done

# echo "Sorting complete!"
# echo ""

# echo "MERGING IN CHROMOSOME ORDER"
# echo "----------------------------------------"

python3 scripts/merge_by_order.py "$SELECTION_FILE" "$TEMP_DIR" "$OUTPUT_FILE"

if [ $? -ne 0 ]; then
    echo "Error: Merge failed"
    exit 1
fi

# echo ""

# echo "CLEANUP"
# echo "----------------------------------------"

if [ "$KEEP_TEMP" = true ]; then
    echo "Keeping temporary files at: $TEMP_DIR"
else
    echo "Removing temporary files..."
    rm -rf "$TEMP_DIR"
    echo "Cleanup complete!"
fi

# echo ""

# echo "========================================"
# echo "SUCCESS!"
# echo "========================================"
# echo "Output file created: $OUTPUT_FILE"
# echo ""

# Show file size
if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "File size: $FILE_SIZE"
fi

# echo "========================================"