#!/bin/bash

# ==============================================================================
# 1. GLOBAL SLURM OPTIONS (Common to all runs)
# ==============================================================================
#SBATCH --job-name="BuildCompileCFDEM"
#SBATCH --output=Job_Messages_%j.txt       # Combined stdout/stderr log
#SBATCH --time=01:30:00                    # MUSICA zen4 partition max limit (3 days)
# #SBATCH --mail-type=BEGIN,END,FAIL
# #SBATCH --mail-user=<mikael.markovic@gmail.com>
#SBATCH --export=ALL

# ==============================================================================
# 2. HARDWARE ALLOCATION TOGGLE BLOCKS
#    (Uncomment the block you want to use, and comment out the other)
# ==============================================================================

# --- OPTION A: PARTIAL NODE CONFIGURATION (e.g., 96 Cores / ~Half Node Memory) ---
# #SBATCH --partition=zen4_0768
# #SBATCH --qos=zen4_0768
# #SBATCH --ntasks=190
# #SBATCH --mem=16G

# --- OPTION B: FULL NODE CONFIGURATION (Exclusive access to all 190 cores) ---
#SBATCH --partition=zen4_0768
#SBATCH --qos=zen4_0768
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --exclusive --contiguous

# Redirect cache to persistent disk storage
#export APPTAINER_CACHEDIR="$SCRATCH/.apptainer"

# Force temporary builds to use the disk instead of memory (RAM)
#export APPTAINER_TMPDIR="${TMPDIR:-/tmp}"


# ==============================================================================
# 3. EXECUTION COMMAND
# ==============================================================================
# Forward Agent
apptainer build     \
    --bind "${HOME}/.ssh:/root/.ssh" \
    ${DATA}/image.sif ${HOME}/Container/image.def
