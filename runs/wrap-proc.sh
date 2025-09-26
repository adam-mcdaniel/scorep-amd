#!/bin/bash

source ../setup-env.sh
source ./setup-run-params.sh

set -euo pipefail

export MPICH_GPU_SUPPORT_ENABLED=1

echo HPL on Host: $(hostname)
echo NODE_NUMBER=${NODE_NUMBER:-}

# Identity of the run
app_name=$(basename "$1")
echo "Application name: $app_name"
echo "Full command: $*"

# Flags (everything except the first argument)
flags=$(echo "${*:2}" | tr ' ' '_' | tr '/' '_')
echo "Run flags: $flags"

# Prepare SCOREP experiment directory
host=$(hostname)
base_name="${host}-${app_name}-${flags}"
results_root="./results"
trial_root="${results_root}/${app_name}-${flags}"

# Create results root if it doesn't exist
trial=1
while :; do
  if [ ! -d "$trial_root" ]; then
    mkdir -p "$trial_root"
  fi
  trial_dir="${trial_root}/trial_${trial}-${base_name}"
  if [ ! -d "$trial_dir" ]; then
    # Directory does not exist, safe to use
    export SCOREP_EXPERIMENT_DIRECTORY="$trial_dir"
    break
  else
    echo "Directory $trial_dir already exists. Trying next trial number..."
  fi
  trial=$((trial + 1))
done

echo "Writing to $SCOREP_EXPERIMENT_DIRECTORY..."

# --- Log de mapeo GPU / rank ---
echo "Rank ${SLURM_PROCID:-?} running on host $(hostname) bound to GPU ${SLURM_STEP_GPUS:-?}"
# echo "[$(date)] Host $(hostname) Command \"$*\" Task ${SLURM_PROCID:-?} LocalID ${SLURM_LOCALID:-?} GPUs=${SLURM_STEP_GPUS:-?}" >> "${results_root}/gpu_mapping.log"
# rocminfo | grep 'Name:' >> "${results_root}/gpu_mapping.log"

# export OMP_NUM_THREADS=8

exec "$@" > "${trial_root}/trial_$trial-$base_name-stdout.log" 2> "${trial_root}/trial_$trial-$base_name-stderr.log"