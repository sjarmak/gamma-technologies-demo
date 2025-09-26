#!/usr/bin/env bash
set -euo pipefail

# Batch translation tool for parallel subagent processing
ALGORITHM=""; STAGE2_DIR=""; MAX_AGENTS=4; DRY_RUN=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --algorithm) ALGORITHM="$2"; shift 2;;
        --stage2-dir) STAGE2_DIR="$2"; shift 2;;
        --max-agents) MAX_AGENTS="$2"; shift 2;;
        --dry-run) DRY_RUN=1; shift;;
        *) echo "Usage: $0 --algorithm NAME --stage2-dir PATH [--max-agents N] [--dry-run]"; exit 2;;
    esac
done

[[ -z "$ALGORITHM" ]] && { echo "ERROR: --algorithm required"; exit 2; }
[[ -z "$STAGE2_DIR" ]] && { echo "ERROR: --stage2-dir required"; exit 2; }

# Validate stage2 artifacts exist
TRANSITION_PLAN="$STAGE2_DIR/plan/transition_plan.md"
[[ ! -f "$TRANSITION_PLAN" ]] && { echo "ERROR: Missing transition plan: $TRANSITION_PLAN"; exit 1; }

echo "Spawning subagents for parallel translation: $ALGORITHM"
echo "Max agents: $MAX_AGENTS"

# Define translation tasks that can run in parallel
TASKS=(
    "translate_core:Translate core algorithm to Kokkos"
    "optimize_memory:Optimize memory layouts and views"
    "implement_timing:Add timing and profiling infrastructure"
    "add_validation:Implement numerical validation checks"
)

# Create task directories
TASK_DIR="$STAGE2_DIR/tasks"
mkdir -p "$TASK_DIR"

# Generate subagent prompt template
create_subagent_prompt() {
    local task_name="$1"
    local task_desc="$2"
    local prompt_file="$TASK_DIR/${task_name}_prompt.md"
    
    cat > "$prompt_file" << EOF
# Subagent Task: $task_desc

## Algorithm Context
- **Name**: $ALGORITHM
- **Transition Plan**: $TRANSITION_PLAN

## Task-Specific Instructions
EOF

    case "$task_name" in
        "translate_core")
            cat >> "$prompt_file" << 'EOF'

### Core Translation Requirements
1. Convert Fortran loops to Kokkos::parallel_for where appropriate
2. Replace arrays with Kokkos::View declarations
3. Maintain identical numerical algorithm
4. Add Kokkos::fence() before any timing measurements
5. Follow memory layout recommendations from transition plan

### Success Criteria
- [ ] Code compiles without warnings
- [ ] Numerical results match Fortran baseline within 1e-10 tolerance
- [ ] All loops properly converted to Kokkos patterns

### Output Files
- `kokkos/{algorithm}/src/kernel.cpp`
- `translation_notes.md` documenting changes made
EOF
            ;;
        "optimize_memory")
            cat >> "$prompt_file" << 'EOF'

### Memory Optimization Requirements
1. Implement optimal Kokkos::View layouts per transition plan
2. Minimize memory allocations in hot paths
3. Ensure coalesced memory access patterns for GPU
4. Add memory usage profiling hooks

### Success Criteria
- [ ] Memory layouts follow GPU best practices
- [ ] No unnecessary memory allocations in loops
- [ ] Coalesced access patterns verified

### Output Files
- Memory layout optimizations in kernel.cpp
- `memory_optimization_report.md`
EOF
            ;;
        "implement_timing")
            cat >> "$prompt_file" << 'EOF'

### Timing Infrastructure Requirements
1. Add high-resolution timing around kernel execution
2. Implement CSV output format matching Fortran baseline
3. Add FLOPS calculation and bandwidth estimates
4. Include warm-up iterations before timing

### Success Criteria
- [ ] Timing accuracy within microsecond precision
- [ ] CSV format matches: algorithm,implementation,N,reps,time_ms,gflops
- [ ] Performance metrics properly calculated

### Output Files
- Timing infrastructure in kernel.cpp
- `timing_implementation_notes.md`
EOF
            ;;
        "add_validation")
            cat >> "$prompt_file" << 'EOF'

### Validation Infrastructure Requirements
1. Implement numerical comparison against Fortran baseline
2. Add boundary condition verification
3. Create test cases for different problem sizes
4. Implement error handling for edge cases

### Success Criteria
- [ ] max_abs_diff calculation implemented
- [ ] Tolerance checking (1e-10) with clear pass/fail reporting
- [ ] Boundary conditions properly validated
- [ ] Edge cases handled gracefully

### Output Files
- Validation code in kernel.cpp
- `validation_implementation_notes.md`
EOF
            ;;
    esac
}

# Generate prompts for all tasks
for task_info in "${TASKS[@]}"; do
    IFS=':' read -r task_name task_desc <<< "$task_info"
    echo "Creating prompt for task: $task_name"
    create_subagent_prompt "$task_name" "$task_desc"
done

# Create orchestration script
ORCHESTRATION_SCRIPT="$TASK_DIR/run_parallel_tasks.sh"
cat > "$ORCHESTRATION_SCRIPT" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Parallel task execution script
TASK_DIR="$1"
MAX_AGENTS="$2"
ALGORITHM="$3"

echo "Starting parallel subagent execution..."
echo "Task directory: $TASK_DIR"
echo "Max agents: $MAX_AGENTS" 
echo "Algorithm: $ALGORITHM"

# Create semaphore for controlling parallel execution
SEMAPHORE_DIR="/tmp/subagent_semaphore_$$"
mkdir -p "$SEMAPHORE_DIR"
for i in $(seq 1 $MAX_AGENTS); do
    touch "$SEMAPHORE_DIR/slot_$i"
done

# Task execution function
execute_task() {
    local task_name="$1"
    local prompt_file="$2"
    
    # Acquire semaphore slot
    while true; do
        for slot in "$SEMAPHORE_DIR"/slot_*; do
            if [[ -f "$slot" ]]; then
                rm "$slot"
                echo "[$task_name] Acquired execution slot: $(basename $slot)"
                break 2
            fi
        done
        sleep 1
    done
    
    # Execute task (placeholder - would integrate with actual agent API)
    echo "[$task_name] Starting execution..."
    sleep $((5 + RANDOM % 10))  # Simulate work
    echo "[$task_name] Task completed"
    
    # Release semaphore slot
    touch "$slot"
    echo "[$task_name] Released execution slot"
}

# Launch all tasks in parallel
PIDS=()
for prompt_file in "$TASK_DIR"/*_prompt.md; do
    task_name=$(basename "$prompt_file" _prompt.md)
    execute_task "$task_name" "$prompt_file" &
    PIDS+=($!)
    echo "Launched task: $task_name (PID: ${PIDS[-1]})"
done

# Wait for all tasks to complete
echo "Waiting for all tasks to complete..."
for pid in "${PIDS[@]}"; do
    wait "$pid"
    echo "Task completed: PID $pid"
done

# Cleanup
rm -rf "$SEMAPHORE_DIR"
echo "All subagent tasks completed successfully"
EOF

chmod +x "$ORCHESTRATION_SCRIPT"

# Create results aggregation script
AGGREGATION_SCRIPT="$TASK_DIR/aggregate_results.sh"
cat > "$AGGREGATION_SCRIPT" << EOF
#!/usr/bin/env bash
set -euo pipefail

# Aggregate results from parallel subagent tasks
TASK_DIR="$1"
OUTPUT_DIR="$2"

echo "Aggregating subagent results..."
mkdir -p "\$OUTPUT_DIR"

# Combine translation notes
{
    echo "# Combined Translation Notes"
    echo "Generated: \$(date)"
    echo ""
    
    for notes_file in "\$TASK_DIR"/*_notes.md; do
        if [[ -f "\$notes_file" ]]; then
            echo "## \$(basename "\$notes_file" .md)"
            echo ""
            cat "\$notes_file"
            echo ""
        fi
    done
} > "\$OUTPUT_DIR/combined_translation_notes.md"

# Validate that core files were generated
REQUIRED_FILES=(
    "kokkos/$ALGORITHM/src/kernel.cpp"
)

MISSING_FILES=()
for file in "\${REQUIRED_FILES[@]}"; do
    if [[ ! -f "\$file" ]]; then
        MISSING_FILES+=("\$file")
    fi
done

if [[ \${#MISSING_FILES[@]} -gt 0 ]]; then
    echo "ERROR: Missing required output files:"
    printf '%s\n' "\${MISSING_FILES[@]}"
    exit 1
fi

echo "SUCCESS: All subagent results aggregated to \$OUTPUT_DIR"
EOF

chmod +x "$AGGREGATION_SCRIPT"

if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: Would execute the following tasks:"
    for task_info in "${TASKS[@]}"; do
        IFS=':' read -r task_name task_desc <<< "$task_info"
        echo "  - $task_name: $task_desc"
    done
    echo ""
    echo "Task prompts generated in: $TASK_DIR"
    echo "Run without --dry-run to execute parallel translation"
else
    echo "Executing parallel subagent tasks..."
    "$ORCHESTRATION_SCRIPT" "$TASK_DIR" "$MAX_AGENTS" "$ALGORITHM"
    
    # Aggregate results
    RESULTS_DIR="$STAGE2_DIR/results"
    "$AGGREGATION_SCRIPT" "$TASK_DIR" "$RESULTS_DIR"
    
    echo ""
    echo "SUCCESS: Parallel translation completed"
    echo "Results in: $RESULTS_DIR"
    echo "Next: Run stage 3 validation pipeline"
fi
