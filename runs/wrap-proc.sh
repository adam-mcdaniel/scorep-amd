#!/bin/bash

source ../setup-env.sh
source ./setup-run-params.sh

export MPICH_GPU_SUPPORT_ENABLED=1

echo HPL on Host: $(hostname)
echo NODE_NUMBER=$NODE_NUMBER

# Get the name of the application from the basename of the first path in the arguments
app_name=$(basename "$1")
echo "Application name: $app_name"
echo "Full command: $*"
# Skip the first argument and join the rest with underscores to create a unique identifier for the run
flags=$(echo "$*" | cut -d' ' -f2- | tr ' ' '_')
echo "Run flags: $flags"

# Create a directory for the SCOREP experiment data based on the application name and hostname
export SCOREP_EXPERIMENT_DIRECTORY="./results/$(hostname)-${app_name}-${flags}"
echo "Writing to $SCOREP_EXPERIMENT_DIRECTORY..."

# export OMP_NUM_THREADS=8

exec "$@"
