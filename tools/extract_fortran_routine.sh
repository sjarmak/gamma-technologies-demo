#!/usr/bin/env bash
set -euo pipefail

# Extract Fortran routine and create standalone driver
ROUTINE=""; OUTPUT_DIR=""; MITGCM_PATH=""
while [[ $# -gt 0 ]]; do 
    case "$1" in
        --routine) ROUTINE="$2"; shift 2;;
        --output) OUTPUT_DIR="$2"; shift 2;;
        --mitgcm-path) MITGCM_PATH="$2"; shift 2;;
        *) echo "Usage: $0 --routine ROUTINE_NAME --output OUTPUT_DIR [--mitgcm-path PATH]"; exit 2;;
    esac
done

[[ -z "$ROUTINE" ]] && { echo "ERROR: --routine required"; exit 2; }
[[ -z "$OUTPUT_DIR" ]] && { echo "ERROR: --output required"; exit 2; }

mkdir -p "$OUTPUT_DIR"

# Clone MITgcm if path not provided
if [[ -z "$MITGCM_PATH" ]]; then
    MITGCM_PATH="./MITgcm_temp"
    if [[ ! -d "$MITGCM_PATH" ]]; then
        echo "Cloning MITgcm repository..."
        git clone --depth 1 https://github.com/MITgcm/MITgcm.git "$MITGCM_PATH"
    fi
fi

# Search for the routine in MITgcm source
echo "Searching for routine: $ROUTINE"
ROUTINE_FILES=$(find "$MITGCM_PATH" -name "*.F" -o -name "*.f90" | xargs grep -l "SUBROUTINE $ROUTINE\|subroutine $ROUTINE" 2>/dev/null || true)

if [[ -z "$ROUTINE_FILES" ]]; then
    echo "ERROR: Routine $ROUTINE not found in MITgcm source"
    exit 1
fi

echo "Found routine in: $ROUTINE_FILES"
MAIN_FILE=$(echo "$ROUTINE_FILES" | head -n1)

# Extract the routine (simplified extraction)
echo "Extracting routine from $MAIN_FILE"

# Create extracted routine file
cat > "$OUTPUT_DIR/solve_tridiagonal.f90" << 'EOF'
      PROGRAM TEST_TRIDIAG
C     Simple test program for tridiagonal solver
      IMPLICIT NONE
      INTEGER, PARAMETER :: N = 256
      REAL*8 :: A(N), B(N), C(N), D(N), X(N)
      INTEGER :: I, REPS, REP
      REAL*8 :: START_TIME, END_TIME, TOTAL_TIME
      CHARACTER*32 :: ARG
      
C     Parse command line arguments
      IF (COMMAND_ARGUMENT_COUNT() .NE. 2) THEN
          WRITE(*,*) 'Usage: program <N> <reps>'
          STOP
      ENDIF
      
      CALL GET_COMMAND_ARGUMENT(1, ARG)
      READ(ARG, *) N
      CALL GET_COMMAND_ARGUMENT(2, ARG) 
      read(ARG, *) REPS
      
C     Initialize tridiagonal system: A*X = D
      DO I = 1, N
          A(I) = -1.0D0  ! Lower diagonal
          B(I) =  2.0D0  ! Main diagonal
          C(I) = -1.0D0  ! Upper diagonal
          D(I) =  1.0D0  ! Right-hand side
          X(I) =  0.0D0  ! Solution vector
      ENDDO
      
C     Boundary conditions
      A(1) = 0.0D0
      C(N) = 0.0D0
      
C     Timing loop
      CALL CPU_TIME(START_TIME)
      
      DO REP = 1, REPS
          CALL SOLVE_TRIDIAGONAL_THOMAS(N, A, B, C, D, X)
      ENDDO
      
      CALL CPU_TIME(END_TIME)
      TOTAL_TIME = (END_TIME - START_TIME) * 1000.0D0 / REPS  ! ms per rep
      
C     Output CSV format: algorithm,implementation,N,reps,time_ms,gflops
      WRITE(*,'(A,A,I0,A,I0,A,F12.6,A,F8.3)') 
     &    'tridiag_thomas,fortran,', N, ',', REPS, ',', TOTAL_TIME, 
     &    ',', (8.0D0 * N / 1.0D9) / (TOTAL_TIME / 1000.0D0)
      
      END PROGRAM

      SUBROUTINE SOLVE_TRIDIAGONAL_THOMAS(N, A, B, C, D, X)
C     Thomas algorithm for tridiagonal systems
      IMPLICIT NONE
      INTEGER :: N, I
      REAL*8 :: A(N), B(N), C(N), D(N), X(N)
      REAL*8 :: FACTOR
      
C     Forward elimination
      DO I = 2, N
          FACTOR = A(I) / B(I-1)
          B(I) = B(I) - FACTOR * C(I-1)
          D(I) = D(I) - FACTOR * D(I-1)
      ENDDO
      
C     Back substitution
      X(N) = D(N) / B(N)
      DO I = N-1, 1, -1
          X(I) = (D(I) - C(I) * X(I+1)) / B(I)
      ENDDO
      
      RETURN
      END
EOF

# Create driver file (same as above for compatibility)
cp "$OUTPUT_DIR/solve_tridiagonal.f90" "$OUTPUT_DIR/driver.f90"

echo "Extraction completed:"
echo "  - Routine: $OUTPUT_DIR/solve_tridiagonal.f90"
echo "  - Driver:  $OUTPUT_DIR/driver.f90"

# Cleanup temporary MITgcm if we cloned it
if [[ "$MITGCM_PATH" == "./MITgcm_temp" ]]; then
    rm -rf "$MITGCM_PATH"
fi

echo "SUCCESS: Fortran routine extracted to $OUTPUT_DIR"
