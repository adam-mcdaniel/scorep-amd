#!/bin/bash
source ../setup-env.sh
source ./setup-run-params.sh

mkdir -p experiments
cd "$(dirname "$0")"

scorep-hipcc -std=c++17 -w -o idle-compute-square-wave idle-compute-square-wave.cpp

# ./idle-compute-square-wave
export IDLE_PERIOD_MS=500
export ACTIVE_PERIOD_MS=5
export SCOREP_EXPERIMENT_DIRECTORY="experiments/idle-compute-square-wave-${IDLE_PERIOD_MS}ms-${ACTIVE_PERIOD_MS}ms"
echo "Running $SCOREP_EXPERIMENT_DIRECTORY"
srun -A gen010 -t10 -N 1 --ntasks-per-node=1 ./idle-compute-square-wave

# # ./idle-compute-square-wave
# export IDLE_PERIOD_MS=100
# export ACTIVE_PERIOD_MS=100
# export SCOREP_EXPERIMENT_DIRECTORY="experiments/idle-compute-square-wave-${IDLE_PERIOD_MS}ms-${ACTIVE_PERIOD_MS}ms"
# echo "Running $SCOREP_EXPERIMENT_DIRECTORY"
# srun -A gen010 -t10 -N 1 --ntasks-per-node=1 ./idle-compute-square-wave


# export IDLE_PERIOD_MS=200
# export ACTIVE_PERIOD_MS=200
# export SCOREP_EXPERIMENT_DIRECTORY="experiments/idle-compute-square-wave-${IDLE_PERIOD_MS}ms-${ACTIVE_PERIOD_MS}ms"
# echo "Running $SCOREP_EXPERIMENT_DIRECTORY"
# srun -A gen010 -t10 -N 1 --ntasks-per-node=1 ./idle-compute-square-wave


# export IDLE_PERIOD_MS=300
# export ACTIVE_PERIOD_MS=300
# export SCOREP_EXPERIMENT_DIRECTORY="experiments/idle-compute-square-wave-${IDLE_PERIOD_MS}ms-${ACTIVE_PERIOD_MS}ms"
# echo "Running $SCOREP_EXPERIMENT_DIRECTORY"
# srun -A gen010 -t10 -N 1 --ntasks-per-node=1 ./idle-compute-square-wave


# export IDLE_PERIOD_MS=400
# export ACTIVE_PERIOD_MS=400
# export SCOREP_EXPERIMENT_DIRECTORY="experiments/idle-compute-square-wave-${IDLE_PERIOD_MS}ms-${ACTIVE_PERIOD_MS}ms"
# echo "Running $SCOREP_EXPERIMENT_DIRECTORY"
# srun -A gen010 -t10 -N 1 --ntasks-per-node=1 ./idle-compute-square-wave

# export IDLE_PERIOD_MS=500
# export ACTIVE_PERIOD_MS=500
# export SCOREP_EXPERIMENT_DIRECTORY="experiments/idle-compute-square-wave-${IDLE_PERIOD_MS}ms-${ACTIVE_PERIOD_MS}ms"
# echo "Running $SCOREP_EXPERIMENT_DIRECTORY"
# srun -A gen010 -t10 -N 1 --ntasks-per-node=1 ./idle-compute-square-wave