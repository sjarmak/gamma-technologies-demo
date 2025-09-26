#!/usr/bin/env bash
set -euo pipefail
KERNEL=""; N=1024; REPS=2; SBATCH=0
while [[ $# -gt 0 ]]; do case "$1" in
  --kernel) KERNEL="$2"; shift 2;;
  --n) N="$2"; shift 2;;
  --reps) REPS="$2"; shift 2;;
  --sbatch) SBATCH=1; shift;;
  *) echo "unknown $1"; exit 2;;
esac; done
BIN="kokkos/$KERNEL/build/kernel"
mkdir -p outputs
if [[ $SBATCH -eq 1 ]]; then
  sbatch .slurm/run_kokkos.sbatch "$BIN" "$N" "$REPS"
else
  "$BIN" "$N" "$REPS" | tee "outputs/${KERNEL}_kokkos.log"
fi
