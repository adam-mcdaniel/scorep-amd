#!/usr/bin/env bash
#SBATCH -A gen010
#SBATCH -p batch
#SBATCH -N 1
#SBATCH --exclusive
#SBATCH -t 01:40:00
#SBATCH -J multi-node-benchmarks
#SBATCH -o slurm-%j.out
#SBATCH -e slurm-%j.err

# -----------------------------------------------------------------------------
# Compilation (run before submitting job)
# -----------------------------------------------------------------------------
# source ../setup-env.sh
# scorep-hipcc -std=c++17 -O3 -w -o ./power_benchmarking/benchmark_step_function/bin/step_function ./power_benchmarking/benchmark_step_function/src/main.cpp -I$MPICH_DIR/include -L$MPICH_DIR/lib -lmpi -DN_ITER=64 --offload-arch=gfx90a -lmpi_gtl_hsa

# export VECTOR_SIZE=1073741824 # Avg 7ms per kernel
export VECTOR_SIZE=134217728 # Avg ~0.9ms per kernel (suitable for 1ms period)

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

for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching square wave on ${node} (NODE_NUMBER=${i}) with target time 15s"
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 7500 --time_active 1 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 5000 --time_active 1 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 2500 --time_active 1 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 714 --time_active 1 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 294 --time_active 1 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 149 --time_active 1 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 99 --time_active 1 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 75 --time_active 1 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 37 --time_active 1 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 15 --time_active 1 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 5000 --time_active 2 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 3750 --time_active 2 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 2143 --time_active 2 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 682 --time_active 2 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 288 --time_active 2 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 147 --time_active 2 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 99 --time_active 2 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 74 --time_active 2 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 37 --time_active 2 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 15 --time_active 2 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 2500 --time_active 5 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 2143 --time_active 5 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 1500 --time_active 5 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 600 --time_active 5 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 273 --time_active 5 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 143 --time_active 5 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 97 --time_active 5 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 73 --time_active 5 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 37 --time_active 5 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 15 --time_active 5 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 714 --time_active 20 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 682 --time_active 20 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 600 --time_active 20 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 375 --time_active 20 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 214 --time_active 20 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 125 --time_active 20 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 88 --time_active 20 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 68 --time_active 20 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 36 --time_active 20 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 15 --time_active 20 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 294 --time_active 50 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 288 --time_active 50 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 273 --time_active 50 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 214 --time_active 50 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 150 --time_active 50 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 100 --time_active 50 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 75 --time_active 50 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 60 --time_active 50 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 33 --time_active 50 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 14 --time_active 50 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 149 --time_active 100 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 147 --time_active 100 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 143 --time_active 100 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 125 --time_active 100 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 100 --time_active 100 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 75 --time_active 100 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 60 --time_active 100 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 50 --time_active 100 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 30 --time_active 100 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 14 --time_active 100 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 99 --time_active 150 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 99 --time_active 150 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 97 --time_active 150 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 88 --time_active 150 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 75 --time_active 150 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 60 --time_active 150 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 50 --time_active 150 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 43 --time_active 150 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 27 --time_active 150 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 13 --time_active 150 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 75 --time_active 200 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 74 --time_active 200 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 73 --time_active 200 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 68 --time_active 200 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 60 --time_active 200 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 50 --time_active 200 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 43 --time_active 200 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 38 --time_active 200 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 25 --time_active 200 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 12 --time_active 200 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 37 --time_active 400 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 37 --time_active 400 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 37 --time_active 400 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 36 --time_active 400 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 33 --time_active 400 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 30 --time_active 400 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 27 --time_active 400 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 25 --time_active 400 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 19 --time_active 400 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 11 --time_active 400 --time_sleep 1000
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 15 --time_active 1000 --time_sleep 1
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 15 --time_active 1000 --time_sleep 2
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 15 --time_active 1000 --time_sleep 5
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 15 --time_active 1000 --time_sleep 20
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 14 --time_active 1000 --time_sleep 50
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 14 --time_active 1000 --time_sleep 100
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 13 --time_active 1000 --time_sleep 150
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 12 --time_active 1000 --time_sleep 200
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 11 --time_active 1000 --time_sleep 400
    srun -N1 -w $node env NODE_NUMBER=$i --ntasks-per-node=4 --gpus-per-task=2 --gpu-bind=closest ./wrap-proc.sh ./power_benchmarking/benchmark_step_function/bin/step_function --vector_size ${VECTOR_SIZE} --n_steps 8 --time_active 1000 --time_sleep 1000

done
wait
echo "Job $SLURM_JOB_ID completed: $(date)"
