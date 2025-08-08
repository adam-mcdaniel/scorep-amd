#!/bin/bash
source ../setup-env.sh
source ./setup-run-params.sh

mkdir -p experiments
cd "$(dirname "$0")"

scorep-hipcc -std=c++17 -w -o idle-compute-square-wave idle-compute-square-wave.cpp

IDLE_VALUES=(1 5 20 30 50 75 100 150 200 400 600 800 1000)
ACTIVE_VALUES=(1 5 20 30 50 75 100 150 200 400 600 800 1000)
# IDLE_VALUES=(400)
# ACTIVE_VALUES=(800)

# IDLE_VALUES=(300)
# ACTIVE_VALUES=(400)

for IDLE_PERIOD_MS in "${IDLE_VALUES[@]}"; do
  for ACTIVE_PERIOD_MS in "${ACTIVE_VALUES[@]}"; do
    export IDLE_PERIOD_MS
    export ACTIVE_PERIOD_MS
    export SCOREP_EXPERIMENT_DIRECTORY="experiments/idle-compute-square-wave-${IDLE_PERIOD_MS}ms-${ACTIVE_PERIOD_MS}ms"
    # Check if the `traces.otf2` file already exists
    if [ -f "${SCOREP_EXPERIMENT_DIRECTORY}/traces.otf2" ]; then
      echo "Skipping existing experiment: $SCOREP_EXPERIMENT_DIRECTORY"
      continue
    fi
    echo "Running $SCOREP_EXPERIMENT_DIRECTORY"
    srun -A gen010 -t10 -N 1 --ntasks-per-node=1 --gpu-srange=800-801 --gpu-freq=800 ./idle-compute-square-wave
  done
done