#!/bin/bash

###############################################################################
# LOGGING FUNCTIONS
###############################################################################
DEBUG=0
log_info()  { printf "\033[1;32m[INFO]\033[0m %s\n" "$*"; }
log_warn()  { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
log_error() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }
log_note() { printf "\033[1;35m[NOTE]\033[0m %s\n" "$*"; }
log_debug() { [ "$DEBUG" = 1 ] && printf "\033[1;36m[DEBUG]\033[0m %s\n" "$*"; }

prompt() {
    # Read with the colored prompt plus the input
    printf "\033[1;36m[PROMPT]\033[0m %s " "$*"
    read -r choice
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_error "Do not run this script directly."
    log_error "Please source it instead: 'source setup-env.sh'"
    exit 1
fi

log_info "Setting up environment for using your installed Score-P profiling tools..."

if [ ! -f "$ORIGINAL_BASH_ENV" ]; then
    # Get all the environment variables that are set in the original bash environment
    ORIGINAL_BASH_VARS=$(compgen -v)
    # Save them to a file
    export ORIGINAL_BASH_ENV=$(mktemp /tmp/original_bash_env.XXXXXX)
    for var in $ORIGINAL_BASH_VARS; do
        echo "$var=${!var}" >> "$ORIGINAL_BASH_ENV"
    done
    log_info "Saved original, untainted bash environment saved to $ORIGINAL_BASH_ENV"
else
    log_info "Original bash environment already saved to $ORIGINAL_BASH_ENV"
fi

###############################################################################
# DETERMINE INSTALL LOCATION
###############################################################################

# Go to where this file is
SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))
log_info "Base project directory: $SCRIPT_DIR"
log_info "Using install directory: $SCRIPT_DIR/install"

export INSTALL_DIR="$SCRIPT_DIR/install"
if [ ! -d "$INSTALL_DIR" ]; then
    log_error "Install directory does not exist: $INSTALL_DIR"
    log_error "Please run the Score-P build script first."
    exit 1
fi

###############################################################################
# SETUP ENVIRONMENT FOR USING SCORE-P
###############################################################################

export PATH="$INSTALL_DIR/bin:$PATH"
log_info "Appending to PATH: $INSTALL_DIR/bin"

if [ -z "$C_INCLUDE_PATH" ]; then
    log_info "Setting C_INCLUDE_PATH to $INSTALL_DIR/include"
    export C_INCLUDE_PATH="$INSTALL_DIR/include"
else
    log_info "Appending to C_INCLUDE_PATH: $INSTALL_DIR/include"
    export C_INCLUDE_PATH="$INSTALL_DIR/include:$C_INCLUDE_PATH"
fi
if [ -z "$LIBRARY_PATH" ]; then
    log_info "Setting LIBRARY_PATH to $INSTALL_DIR/lib"
    export LIBRARY_PATH="$INSTALL_DIR/lib"
else
    log_info "Appending to LIBRARY_PATH: $INSTALL_DIR/lib"
    export LIBRARY_PATH="$INSTALL_DIR/lib:$LIBRARY_PATH"
fi
if [ -z "$LD_LIBRARY_PATH" ]; then
    log_info "Setting LD_LIBRARY_PATH to $INSTALL_DIR/lib"
    export LD_LIBRARY_PATH="$INSTALL_DIR/lib"
else
    log_info "Appending to LD_LIBRARY_PATH: $INSTALL_DIR/lib"
    export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
fi


ROCM_VERSIONS=$(ls /opt/ | sed 's|/opt/rocm-||' | sort -V)
# Strip the `-rocm-` prefixes if they exist
ROCM_VERSIONS=$(echo "$ROCM_VERSIONS" | sed 's/rocm-//g')
log_info "Available ROCm versions:"
for version in $ROCM_VERSIONS; do
    log_info "   - $version"
done
# Get the latest ROCm version
# This assumes the versions are in the format x.y.z
ROCM_VERSION=$(echo "$ROCM_VERSIONS" | tail -n 1)
log_info "Selecting latest ROCm version: $ROCM_VERSION"

log_info "Adding all ROCm $ROCM_VERSION paths to the environment variables."
export CC="/opt/rocm-$ROCM_VERSION/llvm/bin/clang"
export CXX="/opt/rocm-$ROCM_VERSION/llvm/bin/clang++"
export HIPCC="/opt/rocm-$ROCM_VERSION/bin/hipcc"
export MPICC="/opt/rocm-$ROCM_VERSION/bin/clang"
export MPICXX="/opt/rocm-$ROCM_VERSION/bin/clang++"

export PATH="/opt/rocm-$ROCM_VERSION/bin:$PATH"
export PATH="/opt/rocm-$ROCM_VERSION/lib:$PATH"
export PATH="/opt/rocm-$ROCM_VERSION/include:$PATH"
export PATH="/opt/rocm-$ROCM_VERSION/llvm/bin:$PATH"
export CFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib ${CFLAGS}"
export CXXFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib ${CXXFLAGS}"
export LDFLAGS="-L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib ${LDFLAGS}"

export OMPI_MPICC="/opt/rocm-$ROCM_VERSION/llvm/bin/clang"
export OMPI_MPICXX="/opt/rocm-$ROCM_VERSION/llvm/bin/clang++"
export OMPI_FC="/opt/rocm-$ROCM_VERSION/llvm/bin/flang"
export OMPI_CFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $(mpicc --showme:compile)"
export OMPI_CXXFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $(mpicxx --showme:compile)"
export OMPI_LDFLAGS="-L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $OMPI_LDFLAGS $(mpicc --showme:link)"


if [ -z "$C_INCLUDE_PATH" ]; then
    export C_INCLUDE_PATH="/opt/rocm-$ROCM_VERSION/include"
else
    export C_INCLUDE_PATH="/opt/rocm-$ROCM_VERSION/include:$C_INCLUDE_PATH"
fi
if [ -z "$LIBRARY_PATH" ]; then
    export LIBRARY_PATH="/opt/rocm-$ROCM_VERSION/lib"
else
    export LIBRARY_PATH="/opt/rocm-$ROCM_VERSION/lib:$LIBRARY_PATH"
fi
if [ -z "$LD_LIBRARY_PATH" ]; then
    export LD_LIBRARY_PATH="/opt/rocm-$ROCM_VERSION/lib"
else
    export LD_LIBRARY_PATH="/opt/rocm-$ROCM_VERSION/lib:$LD_LIBRARY_PATH"
fi

###############################################################################
# REPORT ENVIRONMENT VARIABLES
###############################################################################

CHANGED_VARIABLES="CC CXX HIPCC MPICC MPICXX CFLAGS CXXFLAGS LDFLAGS OMPI_MPICC OMPI_MPICXX OMPI_FC OMPI_CFLAGS OMPI_CXXFLAGS OMPI_LDFLAGS PATH C_INCLUDE_PATH LIBRARY_PATH LD_LIBRARY_PATH"

log_note "Environment variables set for Score-P profiling tools:"
for var in $CHANGED_VARIABLES; do
    log_note "   - $var:"
    log_note "     ${!var}"
done

# log_note "  - PATH:"
# log_note "    $PATH"
# log_note "  - C_INCLUDE_PATH:"
# log_note "    $C_INCLUDE_PATH"
# log_note "  - LIBRARY_PATH:"
# log_note "    $LIBRARY_PATH"
# log_note "  - LD_LIBRARY_PATH:"
# log_note "    $LD_LIBRARY_PATH"
# log_note "  - INSTALL_DIR:"
# log_note "    $INSTALL_DIR"
# log_note "C_INCLUDE_PATH: $C_INCLUDE_PATH"
# log_note "LIBRARY_PATH: $LIBRARY_PATH"
# log_note "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

log_info "Environment setup complete. You can now run your scorep profiling tools."
log_note "If you want to remove these changes, source the clean script in this directory:"
log_note "$ source $SCRIPT_DIR/clean.sh"