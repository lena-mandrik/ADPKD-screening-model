#!/bin/bash
#SBATCH --job-name=PSA_ADPKD
#SBATCH --output=logs/PSA_ADPKD_%A_%a.out
#SBATCH --error=logs/PSA_ADPKD_%A_%a.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1          # one core per PSA run
#SBATCH --time=02:00:00            # per run; adjust after timing one run
#SBATCH --mem=40G                  # per run; adjust after checking one run (sacct -j <jobid> -o MaxRSS)
#SBATCH --array=1-1000%50               # test with 10 runs; change to 1-1000%50 for the full PSA

# ADPKD PSA: array task k loads the saved parameters and population from
# Results/PSA/PSA_setup.rds, runs parameter set k, and saves
# Results/PSA/sets/PSA_set_000k.rds
#
# Before submitting (once):
#   1. Create Results/PSA/PSA_setup.rds, locally or on the HPC:
#        Rscript "R files/PSA_setup.R"      (or the setup chunk in ADPKD_report.Rmd)
#      with N.sets at least as large as the highest array task number,
#      and copy it to the same folder on the HPC.
#   2. Install the R packages once (mvtnorm, truncnorm, dplyr, tidyr, ggplot2, scales)
#      under the same R module as below.
#   3. mkdir -p logs
#
# Submit (from the project root):   sbatch run_PSA.sh
# Test one run:                     sbatch --array=1 run_PSA.sh
# Re-run failed:                    sbatch --array=17,245,988 run_PSA.sh   (finished runs are skipped)
#
# After all runs finish, summarise locally or on the HPC:
#   Rscript "R files/PSA_combine.R"

# Load R (the module name available on this cluster)
module load R/4.5.2-gfbf-2025b || { echo "✗ Could not load module R/4.5.2-gfbf-2025b"; exit 1; }

if ! command -v Rscript > /dev/null; then
    echo "✗ Rscript not found after loading the R module"
    exit 1
fi

# Keep R on the single core allocated to this task
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1

cd "$SLURM_SUBMIT_DIR" || exit 1   # project root with "R files/", "Data/" and "Results/"
mkdir -p Results/PSA/sets

OUT_FILE=$(printf 'Results/PSA/sets/PSA_set_%04d.rds' "$SLURM_ARRAY_TASK_ID")

echo "=== ADPKD PSA ==="
echo "Array job ID:  $SLURM_ARRAY_JOB_ID"
echo "Array task ID: $SLURM_ARRAY_TASK_ID (parameter set $SLURM_ARRAY_TASK_ID)"
echo "Node:          $(hostname)"
echo "R version:     $(Rscript --version 2>&1)"
echo "Timestamp:     $(date)"
echo ""

if [ ! -f Results/PSA/PSA_setup.rds ]; then
    echo "✗ Results/PSA/PSA_setup.rds not found. Create the saved parameters first (R files/PSA_setup.R)."
    exit 1
fi

Rscript "R files/PSA_run.R"
status=$?

if [ $status -eq 0 ] && [ -f "$OUT_FILE" ]; then
    echo ""
    echo "✓ PSA run $SLURM_ARRAY_TASK_ID completed: $OUT_FILE"
else
    echo ""
    echo "✗ PSA run $SLURM_ARRAY_TASK_ID failed (exit status $status)"
    exit 1
fi

echo "Completed at: $(date)"
