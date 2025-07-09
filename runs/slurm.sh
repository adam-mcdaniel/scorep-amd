#!/bin/bash
source ../setup-env.sh
source ./setup-run-params.sh

mkdir -p experiments
cd "$(dirname "$0")"

scorep-hipcc -std=c++17 -w -o square-kernel kernel.cpp

# ./square-kernel
srun -A gen010 -t15 -N 1 --ntasks-per-node=1 ./square-kernel