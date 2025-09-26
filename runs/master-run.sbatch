#!/usr/bin/env bash
#SBATCH -A gen010
#SBATCH -p batch
#SBATCH -N 4
#SBATCH --exclusive
#SBATCH -t 00:30:00
#SBATCH -J multi-node-benchmarks
#SBATCH -o slurm-%j.out
#SBATCH -e slurm-%j.err


# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
export ROCM_VERSION="${ROCM_VERSION:-6.4.1}"

module load libfabric/1.22.0
module load perftools-base/24.11.0
module load PrgEnv-amd/8.6.0
module load amd/${ROCM_VERSION}
module load cray-mpich/8.1.31
module load rocm/${ROCM_VERSION}

mkdir -p results

# Your local hooks
source ../setup-env.sh
source ./setup-run-params.sh

set -euo pipefail

# MPI + GPU (Cray MPICH + ROCm)
export MPICH_GPU_SUPPORT_ENABLED=1

echo "Job $SLURM_JOB_ID started: $(date)"
echo "ROCm PATH: ${ROCM_PATH:-<unset>}"
echo "ROCm VERSION: $ROCM_VERSION"
echo "NodeList: $SLURM_NODELIST"

# Resolve nodes in this allocation
mapfile -t NODES < <(scontrol show hostnames "$SLURM_NODELIST")
echo "Using ${#NODES[@]} nodes: ${NODES[*]}"

# Base SRUN opts for all per-node launches
SRUN_BASE=(--exclusive --ntasks=8 --gpus-per-task=1 --gpu-bind=closest)

launch_rochpl_wave() {
  echo "Launching a wave of rocHPL jobs..."
  for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching rocHPL on ${node} (NODE_NUMBER=${i})"
    srun -N1 -w "$node" "${SRUN_BASE[@]}" env NODE_NUMBER="$i" ./wrap-proc.sh ./scorep-rocHPL/install-scorep-amd/bin/rochpl -P 1 -Q 8 -N 245760 &
  done
  wait
  echo "rocHPL wave finished."
}

launch_rochplmxp_wave() {
  echo "Launching a wave of rocHPL-MxP jobs..."
  for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching rocHPL-MxP on ${node} (NODE_NUMBER=${i})"
    srun -N1 -w "$node" "${SRUN_BASE[@]}" env NODE_NUMBER="$i" ./wrap-proc.sh ./scorep-rocHPL-MxP/install-scorep-amd/bin/rochplmxp -P 1 -Q 8 -N 245760 &
  done
  wait
  echo "rocHPL-MxP wave finished."
}

launch_hpg_wave() {
  echo "Launching a wave of HPG (ref) jobs..."
  for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching HPG (ref) on ${node} (NODE_NUMBER=${i})"
    srun -N1 -w "$node" "${SRUN_BASE[@]}" env NODE_NUMBER="$i" ./wrap-proc.sh ./scorep-HPG-MxP/install-scorep-amd/bin/xhpgmp 128 128 128 --run_type=standalone_ref &
  done
  wait
  echo "HPG (ref) wave finished."
}

launch_hpgmxp_wave() {
  echo "Launching a wave of HPG-MxP jobs..."
  for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching HPG-MxP on ${node} (NODE_NUMBER=${i})"
    srun -N1 -w "$node" "${SRUN_BASE[@]}" env NODE_NUMBER="$i" ./wrap-proc.sh ./scorep-HPG-MxP/install-scorep-amd/bin/xhpgmp 128 128 128 --run_type=standalone_mxp &
  done
  wait
  echo "HPG-MxP wave finished."
}

# -----------------------------------------------------------------------------
# 1) rocHPL (FP64)
# -----------------------------------------------------------------------------
echo "Launching 3 trials of rocHPL..."
launch_rochpl_wave
launch_rochpl_wave
launch_rochpl_wave
echo "rocHPL trials finished."

# -----------------------------------------------------------------------------
# 2) rocHPL-MxP
# -----------------------------------------------------------------------------
echo "Launching 3 trials of rocHPL-MxP..."
launch_rochplmxp_wave
launch_rochplmxp_wave
launch_rochplmxp_wave
echo "rocHPL-MxP trials finished."

# -----------------------------------------------------------------------------
# 3) HPG (standalone_ref)
# -----------------------------------------------------------------------------
echo "Launching 3 trials of HPG (ref)..."
launch_hpg_wave
launch_hpg_wave
launch_hpg_wave
echo "HPG (ref) trials finished."

# -----------------------------------------------------------------------------
# 4) HPG-MxP (standalone_mxp)
# -----------------------------------------------------------------------------
echo "Launching 3 trials of HPG-MxP..."
launch_hpgmxp_wave
launch_hpgmxp_wave
launch_hpgmxp_wave
echo "HPG-MxP trials finished."

echo "All done! Finished $(date)"