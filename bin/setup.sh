#!/bin/bash
set -euo pipefail

# --- Paths relative to repo root ---
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

# Get repo root (this file can be run from anywhere)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create directories first (so realpath works)
for dir in "${required_dirs[@]}"; do
  if [ ! -d "$REPO_ROOT/$dir" ]; then
    echo "Creating: $dir"
    mkdir -p "$REPO_ROOT/$dir"
  fi
done
echo "Directory creation complete."

# Absolute paths for tmp & cache
TMP_ABS="$(realpath "$REPO_ROOT/$TMP_DIR")"
CACHE_ABS="$(realpath "$REPO_ROOT/$CACHE_DIR")"

# --------------------------
# Host-side build/pull config
# --------------------------
export SINGULARITY_TMPDIR="$TMP_ABS"
export APPTAINER_TMPDIR="$TMP_ABS"
export SINGULARITY_CACHEDIR="$CACHE_ABS"
export APPTAINER_CACHEDIR="$CACHE_ABS"
echo "Singularity tmp:   $SINGULARITY_TMPDIR"
echo "Singularity cache: $SINGULARITY_CACHEDIR"

# Some versions accept explicit --tmpdir for build/pull
EXTRA_BUILD_ARGS=(--tmpdir "$TMP_ABS")

# --------------------------------
# Runtime binds + language caches
# --------------------------------
# Bind host ./bin/tmp into container at /opt/tmp
export SINGULARITY_BINDPATH="${SINGULARITY_BINDPATH:-}"
BIND_SPEC="$TMP_ABS:/opt/tmp"
if [[ -n "$SINGULARITY_BINDPATH" ]]; then
  export SINGULARITY_BINDPATH="$BIND_SPEC,$SINGULARITY_BINDPATH"
else
  export SINGULARITY_BINDPATH="$BIND_SPEC"
fi
echo "Bind path: $SINGULARITY_BINDPATH"

# Tell containers (at runtime) to use /opt/tmp for installs & temp
# Use SINGULARITYENV_* so they are visible inside the container.
export SINGULARITYENV_TMPDIR="/opt/tmp"
export SINGULARITYENV_TMP="/opt/tmp"
export SINGULARITYENV_XDG_CACHE_HOME="/opt/tmp/.cache"

# Python: caches & user installs
export SINGULARITYENV_PIP_CACHE_DIR="/opt/tmp/pip-cache"
export SINGULARITYENV_PIP_TARGET="/opt/tmp/pip"
export SINGULARITYENV_PYTHONPYCACHEPREFIX="/opt/tmp/pyc"

# R: user libs & temp
export SINGULARITYENV_R_LIBS_USER="/opt/tmp/Rlib"
export SINGULARITYENV_R_TMPDIR="/opt/tmp/Rtmp"
# If you use renv:
export SINGULARITYENV_RENV_PATHS_CACHE="/opt/tmp/renv-cache"

# Ensure the directories exist on host (they’ll appear inside container via bind)
mkdir -p \
  "$TMP_ABS/.cache" \
  "$TMP_ABS/pip-cache" \
  "$TMP_ABS/pip" \
  "$TMP_ABS/pyc" \
  "$TMP_ABS/Rlib" \
  "$TMP_ABS/Rtmp" \
  "$TMP_ABS/renv-cache"

# --------------------------
# Build/pull SIFs
# --------------------------
build_if_missing () {
  local sif="$1" def="$2" label="$3"
  if [ ! -f "$REPO_ROOT/$sif" ]; then
    echo "Building $label..."
    singularity build "${EXTRA_BUILD_ARGS[@]}" "$REPO_ROOT/$sif" "$REPO_ROOT/$def"
  else
    echo "$label already exists: $sif"
  fi
}

pull_if_missing () {
  local sif="$1" ref="$2" label="$3"
  if [ ! -f "$REPO_ROOT/$sif" ]; then
    echo "Pulling $label..."
    singularity pull "${EXTRA_BUILD_ARGS[@]}" "$REPO_ROOT/$sif" "$ref"
  else
    echo "$label already exists: $sif"
  fi
}

build_if_missing "$LONGQC_SIF" "$LONGQC_DEF" "LongQC"
pull_if_missing  "$BUSCO_IMAGE" "$BUSCO_DOCKER" "BUSCO"
build_if_missing "$TELFINDER_SIF" "$TELFINDER_DEF" "TelFinder"
build_if_missing "$FLYE_SIF"     "$FLYE_DEF"     "Flye"
build_if_missing "$COVERM_SIF"   "$COVERM_DEF"   "CoverM"
build_if_missing "$DIAMOND_SIF"  "$DIAMOND_DEF"  "Diamond"

if [ -f "$REPO_ROOT/$REPORT_DEF" ]; then
  build_if_missing "$REPORT_SIF" "$REPORT_DEF" "mycoBinR report"
else
  echo "Report def not found (skip): $REPORT_DEF"
fi

echo "Setup complete."
