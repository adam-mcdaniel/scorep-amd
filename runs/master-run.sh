#!/usr/bin/env bash

PROJECT_ACCOUNT="gen010"
NUMBER_OF_NODES=4
PARTITION="batch"
WALL_MIN="15"
JOB_NAME="multi-node-benchmarks"

ROCM_VERSION=6.4.1

###############################################################################
# 0. Setup common environment for all compute nodes
###############################################################################
module load libfabric/1.22.0 \
            perftools-base/24.11.0 \
            PrgEnv-amd/8.6.0 \
            amd/$ROCM_VERSION \
            cray-mpich/8.1.31 \
            rocm/$ROCM_VERSION \

source ../setup-env.sh
source ./setup-run-params.sh

echo "ROCm PATH: $ROCM_PATH"
echo "ROCm VERSION: $ROCM_VERSION"

set -euo pipefail

###############################################################################
# 1. Create a persistent allocation
###############################################################################
JOBID="$(sbatch -A "$PROJECT_ACCOUNT" -p "$PARTITION" \
            -N "$NUMBER_OF_NODES" --exclusive -t "$WALL_MIN" \
            -J "$JOB_NAME" --parsable \
            --wrap 'sleep infinity' 2>/dev/null || true)"

echo "Allocated JOBID=$JOBID. Started $(date)."

###############################################################################
# 2. Wait for the allocation to become RUNNING
###############################################################################
echo -n "Waiting for RUNNING allocation"
while :; do
    state="$(squeue -h -j "$JOBID" -o %T || true)"
    [[ "$state" == "RUNNING" ]] && break
    [[ -z "$state" ]] && { echo; echo "Job $JOBID disappeared."; exit 1; }
    echo -n "."
    sleep 2
done
echo
echo "Allocation is RUNNING."

###############################################################################
# 3. Retrieve the node list for the job
###############################################################################
NODELIST="$(squeue -h -j "$JOBID" -o %N)"
mapfile -t NODES < <(scontrol show hostnames "$NODELIST")

echo "Running on ${#NODES[@]} nodes: ${NODES[*]}"

###############################################################################
# 4. Run the workloads on the nodes
###############################################################################
for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching on ${node} with NODE_NUMBER=${i}"
    srun --jobid="$JOBID" \
        --nodes=1 --ntasks=1 --gpus-per-task=1 --exclusive -w "$node" \
        env NODE_NUMBER="$i" \
        bash -lc 'echo HPL on Host: $(hostname); echo NODE_NUMBER=$NODE_NUMBER; export SCOREP_EXPERIMENT_DIRECTORY="./results/rocHPL-$(hostname)"; echo "Writing to $SCOREP_EXPERIMENT_DIRECTORY..."; ./scorep-rocHPL/install-scorep-amd/bin/rochpl -P 1 -Q 1 -N 45312' \
        > "rocHPL_${node}.out" 2>&1 &
done
wait
echo "1. rocHPL finished."

for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching on ${node} with NODE_NUMBER=${i}"
    srun --jobid="$JOBID" \
        --nodes=1 --ntasks=1 --gpus-per-task=1 --exclusive -w "$node" \
        env NODE_NUMBER="$i" \
        bash -lc 'echo HPL-MxP on Host: $(hostname); echo NODE_NUMBER=$NODE_NUMBER; export SCOREP_EXPERIMENT_DIRECTORY="./results/rocHPL-MxP-$(hostname)"; echo "Writing to $SCOREP_EXPERIMENT_DIRECTORY..."; ./scorep-rocHPL-MxP/install-scorep-amd/bin/rochplmxp -P 1 -Q 1 -N 45312' \
        > "rocHPL_MxP_${node}.out" 2>&1 &
done
wait
echo "2. rocHPL-MxP finished."


for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching on ${node} with NODE_NUMBER=${i}"
    srun --jobid="$JOBID" \
        --nodes=1 --ntasks=1 --gpus-per-task=1 --exclusive -w "$node" \
        env NODE_NUMBER="$i" \
        bash -lc 'echo HPG on Host: $(hostname); echo NODE_NUMBER=$NODE_NUMBER; export SCOREP_EXPERIMENT_DIRECTORY="./results/HPG-$(hostname)"; echo "Writing to $SCOREP_EXPERIMENT_DIRECTORY..."; ./scorep-HPG-MxP/install-scorep-amd/bin/xhpgmp --runtype=standalone_ref' \
        > "HPG_${node}.out" 2>&1 &
done
wait
echo "3. HPG finished."

for i in "${!NODES[@]}"; do
    node="${NODES[$i]}"
    echo "Launching on ${node} with NODE_NUMBER=${i}"
    srun --jobid="$JOBID" \
        --nodes=1 --ntasks=1 --gpus-per-task=1 --exclusive -w "$node" \
        env NODE_NUMBER="$i" \
        bash -lc 'echo HPG on Host: $(hostname); echo NODE_NUMBER=$NODE_NUMBER; export SCOREP_EXPERIMENT_DIRECTORY="./results/HPG-MxP-$(hostname)"; echo "Writing to $SCOREP_EXPERIMENT_DIRECTORY..."; ./scorep-HPG-MxP/install-scorep-amd/bin/xhpgmp --runtype=standalone_mxp' \
        > "HPG_MxP_${node}.out" 2>&1 &
done
wait
echo "4. HPG-MxP finished."

###############################################################################
# 5. Free the job allocation
###############################################################################
scancel "$JOBID"
echo "Waiting for job $JOBID to disappear from the queue."
while :; do
    state="$(squeue -h -j "$JOBID" -o %T || true)"
    [[ -z "$state" ]] && break
    echo -n "."
    sleep 2
done
echo
echo "Job $JOBID is gone. All done! Finished $(date)."