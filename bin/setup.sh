#!/bin/bash
set -u

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

# Where is this repo?
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../repo/bin
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"                   # .../repo

# Create directories first (so realpath works)
for dir in "${required_dirs[@]}"; do
  if [ ! -d "$REPO_ROOT/$dir" ]; then
    echo "Creating: $dir"
    mkdir -p "$REPO_ROOT/$dir"
  fi
done
echo "Directory creation complete."

# Absolute paths for tmp & cache (your vars already include 'bin/')
TMP_ABS="$(realpath "$REPO_ROOT/$TMP_DIR")"
CACHE_ABS="$(realpath "$REPO_ROOT/$CACHE_DIR")"

# --------------------------
# Host-side build/pull config
# --------------------------
# Always use repo-local temp/cache/work
export TMPDIR="$TMP_ABS"
export TMP="$TMP_ABS"
export TEMP="$TMP_ABS"

# Build & runtime work dirs
export SINGULARITY_TMPDIR="$TMP_ABS"
export APPTAINER_TMPDIR="$TMP_ABS"
export SINGULARITY_WORKDIR="$TMP_ABS"
export APPTAINER_WORKDIR="$TMP_ABS"

# Caches
export SINGULARITY_CACHEDIR="$CACHE_ABS"
export APPTAINER_CACHEDIR="$CACHE_ABS"

# Bind host tmp into the container
BIND_SPEC="$TMP_ABS:/opt/tmp"
export APPTAINER_BINDPATH="${APPTAINER_BINDPATH:+$APPTAINER_BINDPATH,}$BIND_SPEC"
export SINGULARITY_BINDPATH="${SINGULARITY_BINDPATH:+$SINGULARITY_BINDPATH,}$BIND_SPEC"

# Inside the container: set BOTH prefixes
export SINGULARITYENV_TMPDIR="/opt/tmp";          export APPTAINERENV_TMPDIR="/opt/tmp"
export SINGULARITYENV_TMP="/opt/tmp";             export APPTAINERENV_TMP="/opt/tmp"
export SINGULARITYENV_XDG_CACHE_HOME="/opt/tmp/.cache";      export APPTAINERENV_XDG_CACHE_HOME="/opt/tmp/.cache"
export SINGULARITYENV_PIP_CACHE_DIR="/opt/tmp/pip-cache";     export APPTAINERENV_PIP_CACHE_DIR="/opt/tmp/pip-cache"
export SINGULARITYENV_PIP_TARGET="/opt/tmp/pip";              export APPTAINERENV_PIP_TARGET="/opt/tmp/pip"
export SINGULARITYENV_PYTHONPYCACHEPREFIX="/opt/tmp/pyc";     export APPTAINERENV_PYTHONPYCACHEPREFIX="/opt/tmp/pyc"
export SINGULARITYENV_R_LIBS_USER="/opt/tmp/Rlib";            export APPTAINERENV_R_LIBS_USER="/opt/tmp/Rlib"
export SINGULARITYENV_R_TMPDIR="/opt/tmp/Rtmp";               export APPTAINERENV_R_TMPDIR="/opt/tmp/Rtmp"
export SINGULARITYENV_RENV_PATHS_CACHE="/opt/tmp/renv-cache"; export APPTAINERENV_RENV_PATHS_CACHE="/opt/tmp/renv-cache"

# Make sure the host-side dirs exist
mkdir -p "$TMP_ABS" "$CACHE_ABS" \
         "$TMP_ABS/.cache" "$TMP_ABS/pip-cache" "$TMP_ABS/pip" "$TMP_ABS/pyc" \
         "$TMP_ABS/Rlib" "$TMP_ABS/Rtmp" "$TMP_ABS/renv-cache"


EXTRA_BUILD_ARGS=(--tmpdir "$TMP_ABS")


# --------------------------
# Build/pull SIFs
# --------------------------
build_if_missing () {
  local sif="$1" def="$2" label="$3"
  if [ ! -f "$REPO_ROOT/$sif" ]; then
    echo "Building $label..."
    "$REPO_ROOT/bin/sing" build "${EXTRA_BUILD_ARGS[@]}" "$REPO_ROOT/$sif" "$REPO_ROOT/$def"
  else
    echo "$label already exists: $sif"
  fi
}

pull_if_missing () {
  local sif="$1" ref="$2" label="$3"
  if [ ! -f "$REPO_ROOT/$sif" ]; then
    echo "Pulling $label..."
    "$REPO_ROOT/bin/sing" pull "${EXTRA_BUILD_ARGS[@]}" "$REPO_ROOT/$sif" "$ref"
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
