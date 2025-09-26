#!/usr/bin/env bash
#SBATCH -J amp-kokkos
#SBATCH -o outputs/slurm-%j.out
#SBATCH -t 00:15:00
#SBATCH -N 1
BIN="$1"; N="$2"; REPS="$3"
module purge
# module load cuda kokkos gcc  # adapt to your site
"$BIN" "$N" "$REPS"
