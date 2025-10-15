#!/usr/bin/env bash

# default values
CORES=20
PROJECT_NR=nr_
SAMPLES=001,002,003
DIAMOND_DB=/path/to/DiamondDB.dmnd

# parse named args
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --cores) CORES="$2"; shift ;;
    --project_nr) PROJECT_NR="$2"; shift ;;
    --samples) SAMPLES="$2"; shift ;;
    --db|--diamond_db) DIAMOND_DB="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

echo "Running Snakemake with:"
echo "  CORES=$CORES"
echo "  PROJECT_NR=$PROJECT_NR"
echo "  SAMPLES=$SAMPLES"
echo "  DIAMOND_DB=$DIAMOND_DB"

snakemake \
  --cores "$CORES" \
  --snakefile ./bin/Snakefile \
  --use-singularity \
  --singularity-args "--bind $(realpath bin/tmp):/opt/tmp --env TMPDIR=/opt/tmp --bind $DIAMOND_DB"\
  --config project_nr="$PROJECT_NR" samples="$SAMPLES" diamond_db="$DIAMOND_DB"
