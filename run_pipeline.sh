#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Defaults
CORES=20
PROJECT_NR="nr_"
SAMPLES="001,002,003"    
DIAMOND_DB="/path/to/DiamondDB.dmnd"
VERBOSE=0
DRYRUN=0

usage() {
  cat <<'EOF'
Usage: run_pipeline.sh [options]

Options:
  --cores N               Number of CPU cores (default: 20)
  --project_nr STR        Project prefix, e.g. "nr_" (default: nr_)
  --samples LIST          Comma-separated sample IDs, e.g. 001,002,003
  --db PATH               Path to DIAMOND .dmnd file (required)
  -n, --dry-run           Snakemake dry-run
  -v, --verbose           Verbose shell output
  -h, --help              Show this help
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cores)        CORES="${2:?}"; shift 2;;
    --project_nr)   PROJECT_NR="${2:?}"; shift 2;;
    --samples)      SAMPLES="${2-}"; shift 2;;
    --db|--diamond_db) DIAMOND_DB="${2:?}"; shift 2;;
    -n|--dry-run)   DRYRUN=1; shift;;
    -v|--verbose)   VERBOSE=1; shift;;
    -h|--help)      usage; exit 0;;
    --) shift; break;;
    *) echo "Unknown parameter: $1" >&2; usage; exit 2;;
  esac
done
[[ "$VERBOSE" -eq 1 ]] && set -x

# Basic validation
[[ "$CORES" =~ ^[0-9]+$ ]] || { echo "Error: --cores must be an integer" >&2; exit 2; }
[[ "$CORES" -ge 1 ]] || { echo "Error: --cores must be >= 1" >&2; exit 2; }

if [[ ! -f "$DIAMOND_DB" ]]; then
  echo "Error: DIAMOND DB not found: $DIAMOND_DB" >&2
  exit 2
fi
if [[ "${DIAMOND_DB##*.}" != "dmnd" ]]; then
  echo "Warning: --db does not look like a .dmnd file: $DIAMOND_DB" >&2
fi

# Detect container runtime flag for Snakemake
USE_CONTAINER_FLAG="--use-singularity"
if command -v apptainer >/dev/null 2>&1 && ! command -v singularity >/dev/null 2>&1; then
  USE_CONTAINER_FLAG="--use-apptainer"
fi

# Build Snakemake arg list
declare -a SNK_ARGS
SNK_ARGS+=("--cores" "$CORES")
SNK_ARGS+=("--snakefile" "./bin/Snakefile")
SNK_ARGS+=("$USE_CONTAINER_FLAG")
# bind the directory containing the .dmnd so containers can read it
DMND_DIR="$(dirname "$DIAMOND_DB")"
SNK_ARGS+=("--singularity-args" "--bind $DMND_DIR")
SNK_ARGS+=("--printshellcmds" "--rerun-incomplete" "--latency-wait" "60")

# Configs
declare -a CFG
CFG+=("project_nr=$PROJECT_NR")
CFG+=("diamond_db=$DIAMOND_DB")
# Only pass samples if not empty -> allows auto-discovery in the Snakefile
if [[ -n "${SAMPLES}" ]]; then
  CFG+=("samples=${SAMPLES}")
fi

# Summary
echo "Running Snakemake with:"
echo "  CORES       = $CORES"
echo "  PROJECT_NR  = $PROJECT_NR"
echo "  SAMPLES     = ${SAMPLES:-<auto-discover>}"
echo "  DIAMOND_DB  = $DIAMOND_DB"
echo "  Container   = ${USE_CONTAINER_FLAG#--use-}"

# Dry-run?
[[ "$DRYRUN" -eq 1 ]] && SNK_ARGS+=("-n")

# Execute
snakemake \
  "${SNK_ARGS[@]}" \
  --config "${CFG[@]}"
