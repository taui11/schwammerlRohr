#!/bin/bash

INPUT_DIR="PacBio_data"
OUTPUT_DIR="PacBio_output"
DEF_DIR="bin/definitions"
SINGULARITY_DIR="bin/singularity"
TMP_DIR="bin/tmp"
CACHE_DIR="bin/cache"

required_dirs=(
    "$SINGULARITY_DIR"
    "$TMP_DIR"
    "$CACHE_DIR"
    "$INPUT_DIR"
    "$OUTPUT_DIR/longqc_output"
    "$OUTPUT_DIR/flye_output"
    "$OUTPUT_DIR/coverm_output"
    "$OUTPUT_DIR/busco_output"
    "$OUTPUT_DIR/diamond_output"
    "$OUTPUT_DIR/telfinder_output"
    "$OUTPUT_DIR/reports"

)

LONGQC_DEF="$DEF_DIR/longqc.def"
LONGQC_SIF="$SINGULARITY_DIR/longqc.sif"

BUSCO_DOCKER="docker://ezlabgva/busco:v5.8.2_cv1"
BUSCO_IMAGE="$SINGULARITY_DIR/busco.sif"

FLYE_DEF="$DEF_DIR/flye.def"
FLYE_SIF="$SINGULARITY_DIR/flye.sif"

COVERM_DEF="$DEF_DIR/coverm.def"
COVERM_SIF="$SINGULARITY_DIR/coverm.sif"

TELFINDER_DEF="$DEF_DIR/telfinder.def"
TELFINDER_SIF="$SINGULARITY_DIR/telfinder.sif"

DIAMOND_DEF="$DEF_DIR/diamond.def"
DIAMOND_SIF="$SINGULARITY_DIR/diamond.sif"

REPORT_DEF="$DEF_DIR/report.def"
REPORT_SIF="$SINGULARITY_DIR/report.sif"

# Get the directory of the setup script (so it works even if run from elsewhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define temp/cache paths relative to repo
TMP_REL="$SCRIPT_DIR/tmp"
CACHE_REL="$SCRIPT_DIR/cache"

# Convert to absolute paths (required by Singularity)
TMP_ABS="$(realpath "$TMP_REL")"
CACHE_ABS="$(realpath "$CACHE_REL")"

# Export for Singularity/Apptainer
export SINGULARITY_TMPDIR="$TMP_ABS"
export APPTAINER_TMPDIR="$TMP_ABS"
export SINGULARITY_CACHEDIR="$CACHE_ABS"
export APPTAINER_CACHEDIR="$CACHE_ABS"

echo "Using Singularity tmp:   $SINGULARITY_TMPDIR"
echo "Using Singularity cache: $SINGULARITY_CACHEDIR"

# Extra build args (some versions prefer explicit flags)
EXTRA_BUILD_ARGS=(--tmpdir "$TMP_ABS" --cache-dir "$CACHE_ABS")

# Create Directories if not there
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating Directories: $dir"
        mkdir -p "$dir"
    else
        echo "Directory already exists: $dir"
    fi
done

echo "Directory creation complete!"

# Creating Singularity files

# LongQC
if [ ! -f "$LONGQC_SIF" ]; then
    echo "Building LongQC Singularity container..."
    singularity build "${EXTRA_BUILD_ARGS[@]}" "$LONGQC_SIF" "$LONGQC_DEF"
else
    echo "LongQC Singularity container already exists: $LONGQC_SIF"
fi

# Busco
if [ ! -f "$BUSCO_IMAGE" ]; then
    echo "Pulling BUSCO Singularity image from Docker Hub..."
    singularity pull "${EXTRA_BUILD_ARGS[@]}" "$BUSCO_IMAGE" "$BUSCO_DOCKER"
else
    echo "BUSCO Singularity image already exists: $BUSCO_IMAGE"
fi

# Telfinder
if [ ! -f "$TELFINDER_SIF" ]; then
    echo "Building TelFinder Singularity container..."
    singularity build "${EXTRA_BUILD_ARGS[@]}" "$TELFINDER_SIF" "$TELFINDER_DEF"
else
    echo "TelFinder Singularity container already exists: $TELFINDER_SIF"
fi

# Flye
if [ ! -f "$FLYE_SIF" ]; then
    echo "Building Flye Singularity container..."
    singularity build "${EXTRA_BUILD_ARGS[@]}" "$FLYE_SIF" "$FLYE_DEF"
else
    echo "Flye Singularity container already exists: $FLYE_SIF"
fi

# CoverM
if [ ! -f "$COVERM_SIF" ]; then
    echo "Building CoverM Singularity container..."
    singularity build "${EXTRA_BUILD_ARGS[@]}" "$COVERM_SIF" "$COVERM_DEF"
else
    echo "CoverM Singularity container already exists: $COVERM_SIF"
fi

# Diamond
if [ ! -f "$DIAMOND_SIF" ]; then
    echo "Building Diamond Singularity container from $DIAMOND_DEF..."
    singularity build "${EXTRA_BUILD_ARGS[@]}" "$DIAMOND_SIF" "$DIAMOND_DEF"
else
    echo "Diamond Singularity container already exists: $DIAMOND_SIF"
fi

if [ -f "$REPORT_DEF" ]; then
    if [ ! -f "$REPORT_SIF" ]; then
        echo "Building mycoBinR Singularity container..."
        singularity build "${EXTRA_BUILD_ARGS[@]}" "$REPORT_SIF" "$REPORT_DEF"
        echo "Reporting image built: singularity/report.sif"
    else
        echo "mycoBinR Singularity container already exists: $REPORT_SIF"
    fi
else
    echo "mycoBinR def not found (skip): $REPORT_DEF"
fi

echo "Setup complete!"

