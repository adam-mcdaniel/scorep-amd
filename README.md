# ScoreP Config for AMD Mi300

A project to build and configure the `ScoreP` performance measurement framework for AMD GPUs, specifically the Mi300, with support for the `ROCm` stack.

## Table of Contents

- [Introduction](#introduction)
    - [Purpose](#purpose)
    - [Functionality](#functionality)
        - [Patches to PAPI](#patches-to-papi)
- [Before You Start](#before-you-start)
- [Usage](#usage)
    - [1. Directory Structure](#1-directory-structure)
    - [2. Building ScoreP](#2-building-scorep)
    - [3. Adding ScoreP to Your Environment](#3-adding-scorep-to-your-environment)
    - [4. Building ScoreP Plugins](#4-building-scorep-plugins)
    - [5. Choose Your Measurement Parameters](#5-choose-your-measurement-parameters)
    - [6. Compiling CPU-Only Applications](#6-compiling-cpu-only-applications)
    - [7. Compiling GPU Applications](#7-compiling-gpu-applications)
    - [8. Running Applications](#8-running-applications)
    - [9. Viewing Results](#9-viewing-results)
    - [10. Cleaning Up](#10-cleaning-up)
- [Conclusion](#conclusion)

## Introduction

### Purpose

The purpose of this project is to provide a comprehensive setup for HPC researchers and developers to gather performance metrics on exascale systems using AMD GPUs, especially those based on the Mi300 and Mi200 architectures (e.g. El Capitan, Frontier, etc.). 

Additionally, this project provides extensions to the [PAPI](https://icl.utk.edu/papi/) interface so that researchers can perform analysis of the energy consumption of their applications on AMD GPUs. This is particularly useful for researchers who are interested in research questions surrounding how different applications or design choices affect the energy consumption of their applications on AMD GPUs, and how to optimize for energy efficiency.

### Functionality

This project performs the following tasks:
- Builds the `ScoreP` performance measurement framework with support for AMD GPUs, and all the necessary dependencies from source.
- Configures `ScoreP` to use the `ROCm` stack for performance measurement on AMD GPUs using the `hipcc` compiler infrastructure.
- Provides scripts to automate the build and configuration process.

#### Patches to PAPI

Additionally, this project provides two patches which extend to the [PAPI](https://github.com/icl-utk-edu/papi) interface to provide access to some `ROCm` features not available in the standard `PAPI` interface

- The energy consumption of the GPU provided in the `rocm-smi` API. The documentation for this metric can be found [here](https://rocm.docs.amd.com/projects/rocm_smi_lib/en/latest/doxygen/html/group__PowerQuer.html#ga1f61b24edaca83a0e395a34c466fcf86).
- The Mi300 GPU introduces new performance counters for collecting instantaneous GPU power consumption metrics in microwatts. These counters are not available in the standard `PAPI` interface, but can be accessed through the `rocm-smi` API. The documentation for this metric can be found [here](https://rocm.docs.amd.com/projects/rocm_smi_lib/en/latest/doxygen/html/group__PowerQuer.html#gafb3d36d17698b411c320982cc8f8da82).

## Before You Start

You need to have the following prerequisites installed:
- `ROCm` (Radeon Open Compute) stack - You'll need to check the [ROCm documentation](https://rocmdocs.amd.com/en/latest/) for installation instructions. The system requirements can be found [here](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/reference/system-requirements.html). This project assumes you're using Linux, and have a compatible AMD GPU for use with `hipcc` and LLVM.
- Your `ROCm` installation must be in the `/opt/rocm-<version>` directory. This script will adapt to your version automatically, assuming it's compatible with ScoreP.
- Your `ROCm` installation must support the `rocm-smi` API, which is used to query GPU information.
- You must have a C compiler installed. The dependencies of ScoreP in this project were built and tested with `gcc` version `13.3.0` on `Ubuntu 24.04`, but other versions of `gcc` and `clang` should work too.

> [!CAUTION]
> This project *should* work with other versions of `ROCm` and other compatible AMD GPUs in the Mi200 and Mi300 series, but it has not been tested with many other configurations.
> If you encounter issues, please feel free to [open an issue on the GitHub repository.](https://github.com/adam-mcdaniel/scorep-amd/issues/new)

If you encounter issues refer to the following documentation:
- [Make sure you have permissions to access the API for your AMD GPU.](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/install/prerequisites.html#using-group-membership) To run GPU applications, your account may need to be in the `render` group.
- [ScoreP documentation](./docs/scorep.pdf)
- [ROCm documentation](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/reference/system-requirements.html)

## Usage

All sections of this project are designed to run in a `bash` environment without root privileges.

## 1. Directory Structure

The project directory structure is as follows:

```bash
scorep-amd/
├── README.md             # This file
├── docs/                 # Directory containing documentation files
│   └── scorep.pdf        # Documentation for ScoreP
│
├── patches/              # Directory containing patches for PAPI
│   ├── coretemp          # The PAPI patch for more SYSFS data (power usage)
│   └── rocm_smi          # The PAPI patch for rocm_smi (energy consumption)
│
├── runs/                 # Directory for running ScoreP applications
│   ├── build-plugins.sh      # Script to build ScoreP plugins for AMD GPUs
│   ├── setup-run-params.sh   # Script to set up ScoreP measurement parameters
│   ├── scorep-arocm-smi-plugin/ # ROCm SMI plugin for ScoreP
│   └── scorep-coretemp-plugin/  # Coretemp plugin for ScoreP
│
├── build-scorep.sh       # Script to build ScoreP and its dependencies
├── clean.sh              # Script to clean builds, installs, environment
├── setup-env.sh          # Script to add ScoreP to the environment
│
├── build/                # Auto-generated directory where everything is built
└── install/              # Auto-generated directory for all installed files
```

The details of each directory and file will be explained piecemeal in the following sections.

## 2. Building ScoreP

First, clone the repository and navigate to the project directory.
The placement of this directory is not important to the project's functionality, as long as you have write permissions in the directory.

```bash
$ # Clone the repository
$ git clone https://github.com/adam-mcdaniel/scorep-amd.git
$ # Navigate to the project directory
$ cd scorep-amd
```

To build `ScoreP`, run the `build-scorep.sh` script. This script will:
- Download all the necessary dependencies.
- Add the patched `PAPI` components to the `PAPI` source tree, if they are not already present.
- Build each dependency from source in the `./build` directory.
- Configure `ScoreP` to use the `ROCm` stack for performance measurement on AMD GPUs.
- Install `ScoreP` in the `./install` directory.

```bash
$ ./build-scorep.sh
```

The script will automatically detect the version of `ROCm` installed on your system and adapt the build process accordingly.

> [!IMPORTANT]
> You may want to disable the `PAPI` patches if you do not desire the additional functionality provided by the `rocm_smi` and `coretemp` patches.
> To do this, you can either: remove the patches from the `patches/` directory individually, remove the `patches/` directory entirely, or comment out the lines in the `build-scorep.sh` script that apply the patches.

### Expected Result

After running the script, you should see output indicating that `ScoreP` and its dependencies have been built successfully. The final output will indicate the installation directory, which is `./install` by default.

Check to make sure that all your desired binaries for ScoreP exist in the `./install/bin/` directory. For compiling applications that use GPU kernels, you should see the `scorep-hipcc` binary, which is a wrapper around the `hipcc` compiler that adds the necessary `ScoreP` instrumentation.

## 3. Adding ScoreP to Your Environment

To use `ScoreP` in your applications conveniently, you need to add the `ScoreP` binaries to your environment. You can do this by running the `setup-env.sh` script:

```bash
$ source setup-env.sh
```

This script will:
- Add the `ScoreP` binaries to your `PATH`.
- Set the `LD_LIBRARY_PATH` to include the `ScoreP` libraries.
- Set the `LIBRARY_PATH` to include the `ScoreP` libraries for linking.
- Set the `C_INCLUDE_PATH` to include the `ScoreP` headers for compilation.
- Define the `INSTALL_DIR` environment variable to point to the `./install` directory. This is used for the scripts in `runs/` to find the `ScoreP` installation, and for setting up their internal paths.

> [!IMPORTANT]
> This `setup-env.sh` script must be `source`d before running any scripts in the `runs/` directory, or before compiling applications with `ScoreP`.

### Expected Result

After running the `setup-env.sh` script, you should be able to run `scorep-hipcc` and other `ScoreP` tools from any directory in your terminal. You can verify this by running:

```bash
$ scorep-info config-summary
```

If everything is set up correctly, you should see a summary of the `ScoreP` configuration, including the `hipcc` support and the `ROCm` provided LLVM tools.

## 4. Building ScoreP Plugins

To use the metrics provided by PAPI, whether you use the `rocm_smi` or `coretemp` patches, you need to build the ScoreP plugins. The `runs/build-plugins.sh` script will do this for you.

> [!IMPORTANT]
> *Make sure you have run all previous steps!*
> Also, don't forget to `source` the `setup-env.sh` script in your current environment before running the `build-plugins.sh` file.

```bash
$ # Make sure you've already run the previous steps!
$ # Navigate to the runs directory
$ cd runs/
$ # Build the ScoreP plugins to add ROCm instrumentation
$ ./build-plugins.sh
```

### Expected Result

If your environment is setup correctly and the `ScoreP` installation was successful, you should see output indicating that the plugins have been built successfully.

You can verify that the plugins are installed correctly with the following command:

```bash
$ ls $INSTALL_DIR/lib/lib*plugin*.so
/path/to/scorep-amd/install/lib/libarocm_smi_plugin.so
/path/to/scorep-amd/install/lib/libcoretemp_plugin.so
```

If you see the `libarocm_smi_plugin.so` and `libcoretemp_plugin.so` files, then the plugins have been built successfully.

## 5. Choose Your Measurement Parameters

To run applications with `ScoreP` instrumentation, you must first set up the `ScoreP` measurement parameters.

```bash
$ # Make sure you've already run the previous steps!
$ # Navigate to the runs/ directory
$ cd /path/to/scorep-amd/runs
$ # Set up the ScoreP measurement parameters
$ ./setup-run-params.sh
```

This script will configure the `ScoreP` environment variables to specify the metrics to collect, the tracing/profiling options, the output directory and file formats, etc.

> [!NOTE]
> For more information about the options, run `scorep-info config-vars`.

Now that you have built `ScoreP` and the necessary plugins, you can compile and run applications with `ScoreP` instrumentation!

## 6. Compiling CPU-Only Applications

You can compile CPU applications with `ScoreP` instrumentation by using `scorep-clang`, `scorep-clang++`, or `scorep-flang` as your compiler. For example:

```bash
$ scorep-clang -o my_cpu_app my_cpu_app.c
```

You may also write your own `Makefile`s that use the appropriate `ScoreP` wrapper as your `CC` or `CXX` variables, for example.

## 7. Compiling GPU Applications

To compile GPU applications that use `hipcc`, you should use the `scorep-hipcc` wrapper. This wrapper will automatically instrument your code for `ScoreP` and link against the necessary libraries.

```bash
$ scorep-hipcc rocm-blas-gemm.cpp -o rocm-blas-gemm -lrocblas
```

## 8. Running Applications

To run your instrumented applications, simply execute them as you normally would. `ScoreP` will automatically collect performance data based on the configuration set in the `setup-run-params.sh` script, and produce output files in the specified output directories (e.g., `experiments/scorep-experiment-<time>`).

For example:

```bash
$ scorep-clang -o my_cpu_app my_cpu_app.c
$ ./my_cpu_app
```

Or for a GPU application:

```bash
$ scorep-hipcc rocm-blas-gemm.cpp -o rocm-blas-gemm -lrocblas
$ ./rocm-blas-gemm
```

## 9. Viewing Results

By default, `ScoreP` will generate `.otf2` files in the specified output directory (e.g., `experiments/scorep-experiment-<time>`).

To analyze the results, it is recommended (but not required) to use [Vampir](https://vampir.eu).


## 10. Cleaning Up

To clean up the `build/` and `install/` directories, you can run the `clean.sh` script:

```bash
$ ./clean.sh
```

This script provides you with the option to clean the specific directories you want, as well as the option to clear all the environment variables set by `setup-env.sh`. This is useful if you want to start with a fresh environment, or if you want to test a different configuration without the previous settings interfering.

## Conclusion

This project provides a comprehensive setup for building and configuring `ScoreP` for AMD GPUs, specifically the Mi300, with support for the `ROCm` stack. By following the steps outlined in this README, you should be able to successfully build `ScoreP`, configure it for AMD GPUs, and run applications with performance measurement capabilities.

If you have any unexpected or unanticipated issues, please feel free to [open an issue on the GitHub repository!](https://github.com/adam-mcdaniel/scorep-amd/issues/new)