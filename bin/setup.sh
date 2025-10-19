#!/usr/bin/env bash
# setup_containers.sh
set -Eeuo pipefail
IFS=$'\n\t'

# -----------------------------
# Flags
#   -f|--force   : rebuild/pull even if SIF exists
#   -v|--verbose : print commands (set -x)
# -----------------------------
FORCE=0
VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    -f|--force)   FORCE=1 ;;
    -v|--verbose) VERBOSE=1 ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--force|-f] [--verbose|-v]
Build/pull all required containers and create output directories.

Env you may set for Apptainer/Singularity:
  APPTAINER_TMPDIR, APPTAINER_CACHEDIR, SINGULARITY_TMPDIR, SINGULARITY_CACHEDIR
EOF
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
[ "$VERBOSE" -eq 1 ] && set -x

# -----------------------------
# Resolve repo root
# -----------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../repo/bin
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"                    # .../repo
cd "$REPO_ROOT"

# -----------------------------
# Choose container CLI
# -----------------------------
if command -v apptainer >/dev/null 2>&1; then
  CTL=apptainer
elif command -v singularity >/dev/null 2>&1; then
  CTL=singularity
else
  echo "ERROR: Neither 'apptainer' nor 'singularity' found in PATH." >&2
  exit 1
fi

# -----------------------------
# Paths relative to repo root
# -----------------------------
INPUT_DIR="PacBio_data"
OUTPUT_DIR="PacBio_output"
DEF_DIR="bin/definitions"
SIF_DIR="bin/singularity"

# Ensure required directories exist
mkdir -p \
  "$SIF_DIR" \
  "$INPUT_DIR" \
  "$OUTPUT_DIR/longqc_output" \
  "$OUTPUT_DIR/flye_output" \
  "$OUTPUT_DIR/coverm_output" \
  "$OUTPUT_DIR/busco_output" \
  "$OUTPUT_DIR/diamond_output" \
  "$OUTPUT_DIR/telfinder_output" \
  "$OUTPUT_DIR/reports"

# -----------------------------
# Image specs
#   kind, label, SIF path, source(.def or docker ref)
#   kind = build|pull
# -----------------------------
IMAGES=(
  "build|LongQC|$SIF_DIR/longqc.sif|$DEF_DIR/longqc.def"
  "pull|BUSCO|$SIF_DIR/busco.sif|docker://ezlabgva/busco:v5.8.2_cv1"
  "build|TelFinder|$SIF_DIR/telfinder.sif|$DEF_DIR/telfinder.def"
  "build|Flye|$SIF_DIR/flye.sif|$DEF_DIR/flye.def"
  "build|CoverM|$SIF_DIR/coverm.sif|$DEF_DIR/coverm.def"
  "build|Diamond|$SIF_DIR/diamond.sif|$DEF_DIR/diamond.def"
  "build|Report|$SIF_DIR/report.sif|$DEF_DIR/report.def"
)

# -----------------------------
# Helpers
# -----------------------------
build_if_needed() {
  local sif="$1" def="$2" label="$3"
  if [[ $FORCE -eq 1 || ! -f "$sif" ]]; then
    if [[ ! -f "$def" ]]; then
      echo "WARN: Definition not found for $label, skipping: $def" >&2
      return 0
    fi
    echo "Building $label -> $sif (from $def)"
    "$CTL" build "$sif" "$def"
  else
    echo "$label already exists: $sif"
  fi
}

pull_if_needed() {
  local sif="$1" ref="$2" label="$3"
  if [[ $FORCE -eq 1 || ! -f "$sif" ]]; then
    echo "Pulling $label -> $sif (from $ref)"
    "$CTL" pull "$sif" "$ref"
  else
    echo "$label already exists: $sif"
  fi
}

# -----------------------------
# Process all images
# -----------------------------
for spec in "${IMAGES[@]}"; do
  IFS='|' read -r kind label sif src <<<"$spec"
  case "$kind" in
    build) build_if_needed "$sif" "$src" "$label" ;;
    pull)  pull_if_needed  "$sif" "$src" "$label" ;;
    *)     echo "BUG: unknown kind '$kind' in spec: $spec" >&2; exit 3 ;;
  esac
done

echo "Setup complete."
