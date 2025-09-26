#!/usr/bin/env bash
set -euo pipefail
SRC=""; N=1024; REPS=2; OUT="outputs/fortran_out.csv"
while [[ $# -gt 0 ]]; do case "$1" in
  --src) SRC="$2"; shift 2;;
  --n) N="$2"; shift 2;;
  --reps) REPS="$2"; shift 2;;
  --out) OUT="$2"; shift 2;;
  *) echo "unknown $1"; exit 2;;
esac; done
[[ -z "$SRC" ]] && { echo "need --src path/to.f90"; exit 2; }
mkdir -p fortran/build outputs
gfortran -O3 -fopenmp "$SRC" -o fortran/build/a.out
fortran/build/a.out "$N" "$REPS" > "$OUT"
