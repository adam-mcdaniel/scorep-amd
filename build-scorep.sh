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
    # printf "\033[1;36m[PROMPT]\033[0m %s " "$*"
    # read -p "Enter your choice (1/2/3): " choice

    # Read with the colored prompt plus the input
    printf "\033[1;36m[PROMPT]\033[0m %s " "$*"
    read -r choice
}

# Confirm this script is executed, not sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    log_error "This script should be executed, not sourced."
    log_error "Please run it with: ./build-scorep.sh"
    exit 1
fi

###############################################################################
# SCORE-P COMPILER + LINKER FLAGS, LIBRARIES, AND INCLUDE PATHS
###############################################################################

# This defines whether to use MPI or not.
# If set to 1, it will use MPI for building Score-P.
# If set to 0, it will not use MPI.
USE_MPI=1

# This defines which compiler to use for non-cross-compiled builds which
# are created with Score-P.
DEFAULT_COMPILER_SUITE="clang"

# This function sets up the environment variables for Score-P
# It sets the compiler, linker flags, and paths for ROCm libraries.
# This must ONLY be called before building Score-P.
function setup_scorep_env() {
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
    # export CXXFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib ${CXXFLAGS}"
    # export LDFLAGS="-L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib ${LDFLAGS}"
    export LDFLAGS=" -L$INSTALL_DIR/rocm_smi_lib/lib -Wl,-rpath,$INSTALL_DIR/rocm_smi_lib/lib -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib"
    export CFLAGS="-I/$INSTALL_DIR/rocm_smi_lib/include -I/opt/rocm-$ROCM_VERSION/include ${LDFLAGS} ${CFLAGS}"
    export CXXFLAGS="-I/$INSTALL_DIR/rocm_smi_lib/include -I/opt/rocm-$ROCM_VERSION/include ${LDFLAGS} ${CXXFLAGS}"

    export OMPI_MPICC="/opt/rocm-$ROCM_VERSION/llvm/bin/clang"
    export OMPI_MPICXX="/opt/rocm-$ROCM_VERSION/llvm/bin/clang++"
    export OMPI_FC="/opt/rocm-$ROCM_VERSION/llvm/bin/flang"
    export OMPI_CFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $(mpicc --showme:compile)"
    export OMPI_CXXFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $(mpicxx --showme:compile)"
    export OMPI_LDFLAGS="-L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $OMPI_LDFLAGS $(mpicc --showme:link)"

    export PAPI_ROCM_ROOT="$INSTALL_DIR/rocm_smi_lib"
    export PAPI_ROCMSMI_ROOT="$PAPI_ROCM_ROOT"

    export PAPI_ROOT=$INSTALL_DIR/papi
    export PAPI_LIB=$PAPI_ROOT/lib

    export PATH="$PAPI_ROCM_ROOT/bin:$PAPI_ROOT/bin:$PATH"

    if [ -z "$C_INCLUDE_PATH" ]; then
        export C_INCLUDE_PATH="$PAPI_ROCM_ROOT/include:/opt/rocm-$ROCM_VERSION/include"
    else
        export C_INCLUDE_PATH="$PAPI_ROCM_ROOT/include:/opt/rocm-$ROCM_VERSION/include:$C_INCLUDE_PATH"
    fi
    if [ -z "$LIBRARY_PATH" ]; then
        export LIBRARY_PATH="$PAPI_ROCM_ROOT/lib:/opt/rocm-$ROCM_VERSION/lib"
    else
        export LIBRARY_PATH="$PAPI_ROCM_ROOT/lib:/opt/rocm-$ROCM_VERSION/lib:$LIBRARY_PATH"
    fi
    if [ -z "$LD_LIBRARY_PATH" ]; then
        export LD_LIBRARY_PATH="$PAPI_ROCM_ROOT/lib:/opt/rocm-$ROCM_VERSION/lib"
    else
        export LD_LIBRARY_PATH="$PAPI_ROCM_ROOT/lib:/opt/rocm-$ROCM_VERSION/lib:$LD_LIBRARY_PATH"
    fi

    if [ $USE_MPI -eq 1 ]; then
        log_info "Using MPI for building Score-P."
        export OMPI_MPICC="/opt/rocm-$ROCM_VERSION/llvm/bin/clang"
        export OMPI_MPICXX="/opt/rocm-$ROCM_VERSION/llvm/bin/clang++"
        export OMPI_FC="/opt/rocm-$ROCM_VERSION/llvm/bin/flang"

        export OMPI_CFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $(mpicc --showme:compile)"
        export OMPI_CXXFLAGS="-I/opt/rocm-$ROCM_VERSION/include -L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $(mpicxx --showme:compile)"
        export OMPI_LDFLAGS="-L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib $OMPI_LDFLAGS $(mpicc --showme:link)"
    else
        log_info "Not using MPI for building Score-P."
    fi
    # export OMPI_LIBS="-L/opt/rocm-$ROCM_VERSION/lib -Wl,-rpath,/opt/rocm-$ROCM_VERSION/lib -lrocm_smi64 -lroctracer64 -lamdhip64 ${OMPI_LIBS}"
}


###############################################################################
# DETECT MPI BACKEND
###############################################################################

AVAILABLE_MPI_IMPLEMENTATIONS="bullxmpi cray hp ibmpoe intel intel2 intel3 intelpoe lam mpibull2 mpich mpich2 mpich3 mpich4 openmpi openmpi3 platform scali sgimpt sgimptwrapper spectrum sun"

function detect_mpi_backend() {
    if [ $USE_MPI -eq 0 ]; then
        log_info "MPI backend detection is disabled. Skipping."
        return
    fi
    mpicc --version
    # Check if mpicc is available
    if command -v mpicc &> /dev/null; then
        log_info "Detecting MPI backend using mpicc..."
        MPI_IMPLEMENTATION=$(mpicc --showme:link)
        echo "Detected MPI implementation: $MPI_IMPLEMENTATION"

        # Check if `openmpi` is in the output
        if [[ $(echo "$MPI_IMPLEMENTATION" | grep "openmpi") ]]; then
            log_info "Detected OpenMPI as the MPI backend."
            MPI_IMPLEMENTATION="openmpi"
        elif [[ $(echo "$MPI_IMPLEMENTATION" | grep "mpich") ]]; then
            log_info "Detected MPICH as the MPI backend."
            MPI_IMPLEMENTATION="mpich"
        elif [[ $(echo "$MPI_IMPLEMENTATION" | grep "intelmpi") ]]; then
            log_info "Detected Intel MPI as the MPI backend."
            MPI_IMPLEMENTATION="intelmpi"
        else
            log_error "Unknown MPI implmentation"
            log_error "Please set the MPI implementation variable manually."
            log_info "Available MPI implementations:"
            for mpi_impl in $AVAILABLE_MPI_IMPLEMENTATIONS; do
                log_info "   - $mpi_impl"
            done
            prompt "Please enter the MPI implmentation you want to use (e.g., openmpi, mpich, intelmpi): "
            if [ -z "$choice" ]; then
                log_error "No MPI implmentation provided. Exiting."
                exit 1
            else
                MPI_IMPLEMENTATION="$choice"
                log_info "Using user-provided MPI implmentation: $MPI_IMPLEMENTATION"
            fi
        fi
    else
        log_error "mpicc not found. Please install an MPI implementation or set the MPI_IMPLEMENTATION variable."
        exit 1
    fi
}

function verify_mpi_backend() {
    if [ $USE_MPI -eq 0 ]; then
        log_info "MPI backend detection is disabled. Skipping."
        return
    fi

    # Check if the user-provided MPI backend is valid
    if [[ ! " $AVAILABLE_MPI_IMPLEMENTATIONS " =~ " $MPI_IMPLEMENTATION " ]]; then
        log_error "Invalid MPI implementation: $MPI_IMPLEMENTATION"
        log_error "Please choose from the available implementations:"
        for mpi_impl in $AVAILABLE_MPI_IMPLEMENTATIONS; do
            log_info "   - $mpi_impl"
        done
        exit 1
    fi

    # Confirm the MPI backend compiler matches the selected compiler suite
    # local mpi_compiler=$(mpicc --version | head -n 1 | awk '{print $1}')
    local mpi_compiler=$(mpicc --showme:command)
    local mpi_compiler_matches=$(echo "$mpi_compiler" | grep $DEFAULT_COMPILER_SUITE)

    if [[ -z "$mpi_compiler_matches" ]]; then
        log_warn "The selected MPI implementation ($mpi_compiler) does not match the default compiler suite ($DEFAULT_COMPILER_SUITE)."
        log_warn "The build may fail due to incompatible compiler versions."
        prompt "Do you want to continue with the selected MPI implementation anyways? (y/n): "
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            log_warn "Continuing with the selected MPI implementation $MPI_IMPLEMENTATION using $mpi_compiler as the compiler."
        else
            log_error "Exiting due to incompatible MPI implementation."
            exit 1
        fi
    fi
    log_info "Using MPI implementation $MPI_IMPLEMENTATION with $mpi_compiler as the compiler."
}

###############################################################################
# ENVIRONMENT VARIABLES FOR DIRECTORIES, ROCm VERSION, AND INSTALLATION PATHS
###############################################################################

# The current directory is set to the script's directory.
# Every install/build is done relative to this directory.
CURRENT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))

# The patch directory is set to a subdirectory named "patches" in the current directory.
# This directory is expected to contain patches for the `rocm_smi` and `coretemp` components of PAPI.
PATCH_DIR=$CURRENT_DIR/patches
# Where everything will be installed
export INSTALL_DIR="$CURRENT_DIR/install"
# The build directory is set to a subdirectory named "build" in the current directory.
export BUILD_DIR="$CURRENT_DIR/build"
# The ROCm installation is assumed to be in /opt/rocm-<version>
# The script will automatically detect the latest ROCm version installed in /opt/.
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


###############################################################################
# DEPENDENCIES BUILD PARAMETERS
###############################################################################

# This sets which dependencies will be built from source for
# this script.
# Set them to 1 to build, 0 to skip.
# If the directory already exists, it will not be built again.

# BUILD_PAPI=$( [ -d "$BUILD_DIR/papi" ] && echo 0 || echo 1 )
BUILD_PAPI=1
BUILD_LLVM=$( [ -d "$BUILD_DIR/llvm-project" ] && echo 0 || echo 1 )
BUILD_AFS=$( [ -d "$BUILD_DIR/afs-dev-latest" ] && echo 0 || echo 1 )
BUILD_PERFTOOLS=$( [ -d "$BUILD_DIR/perftools-dev-latest" ] && echo 0 || echo 1 )
BUILD_OTF2=$( [ -d "$BUILD_DIR/otf2-3.1.1" ] && echo 0 || echo 1 )
BUILD_CUBEW=$( [ -d "$BUILD_DIR/cubew-4.9" ] && echo 0 || echo 1 )
BUILD_OPARI2=$( [ -d "$BUILD_DIR/opari2-2.0.9" ] && echo 0 || echo 1 )
BUILD_CUBELIB=$( [ -d "$BUILD_DIR/cubelib-4.9" ] && echo 0 || echo 1 )
# BUILD_ROCM_SMI_LIB=$( [ -d "$BUILD_DIR/rocm_smi_lib" ] && echo 0 || echo 1 )
BUILD_ROCM_SMI_LIB=1
BUILD_SCOREP=1

# Set the number of parallel jobs for building
PROC=64

# Set the GCC directory/toolchain for building LLVM
LLVM_WHICH_GCC_DIR=$(realpath $(dirname $(which gcc))/..)

###############################################################################
# CHECK CURRENT ENVIRONMENT AND SETUP
###############################################################################

# Check if the current directory is set
if [ -z "$CURRENT_DIR" ]; then
    log_error "Current directory is not set. Exiting."
    exit 1
fi
# Check if the patch directory exists
if [ ! -d "$PATCH_DIR" ]; then
    log_error "Patch directory does not exist: $PATCH_DIR"

    # Ask user if they want to continue without the patches
    prompt "Do you want to continue without the patches? (y/n): "
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        log_warn "Continuing without patches. This may lead to build failures."
    else
        log_error "Exiting due to missing patches."
        exit 1
    fi
fi

if [ ! -d "$BUILD_DIR" ]; then
    log_info "Creating build directory at $BUILD_DIR"
    mkdir -p $BUILD_DIR
else
    log_info "Build directory $BUILD_DIR already exists, skipping creation."
fi

if [ ! -d "$INSTALL_DIR" ]; then
    log_info "Creating install directory at $INSTALL_DIR"
else
    log_info "Install directory $INSTALL_DIR already exists, skipping creation."
fi


###############################################################################
# CHECK ROCm VERSION
###############################################################################

log_info "Using $PROC parallel jobs for building."
# Check if the ROCm version is set
if [ -z "$ROCM_VERSION" ]; then
    log_error "No ROCm found in /opt/"
    prompt "Please enter the ROCm version you want to use (e.g., 6.4.0): "
    if [ -z "$choice" ]; then
        log_error "No ROCm version provided. Exiting."
        exit 1
    else
        ROCM_VERSION="$choice"
        log_info "Using user-provided ROCm version: $ROCM_VERSION"
        if [ ! -d "/opt/rocm-$ROCM_VERSION" ]; then
            log_error "The specified ROCm version does not exist: /opt/rocm-$ROCM_VERSION"
            exit 1
        fi
    fi
fi

log_info "Using ROCm version: $ROCM_VERSION"

###############################################################################
# REPORT BUILD CONFIGURATION
###############################################################################

log_note "Building the following from source:"
# Only print if the build variable is set to 1
for var in ROCM_SMI_LIB PAPI LLVM AFS PERFTOOLS OTF2 CUBEW OPARI2 CUBELIB SCOREP; do
    value_var="BUILD_${var}"
    if [ "${!value_var}" = "1" ]; then
        log_note "   - $var"
    fi
done

log_note "Skipping the following:"
for var in ROCM_SMI_LIB PAPI LLVM AFS PERFTOOLS OTF2 CUBEW OPARI2 CUBELIB SCOREP; do
    value_var="BUILD_${var}"
    if [ "${!value_var}" = "0" ]; then
        log_note "   - $var"
    fi
done


###############################################################################
# BUILD & INSTALL ROCM_SMI_LIB
###############################################################################

cd $BUILD_DIR
if [ $BUILD_ROCM_SMI_LIB -eq 1 ]; then
    if [ -d "$PATCH_DIR/rocm_smi_lib" ]; then
        log_info "Copying patched rocm_smi_lib from $PATCH_DIR..."
        rm -rf $BUILD_DIR/rocm_smi_lib
        cp -r $PATCH_DIR/rocm_smi_lib $BUILD_DIR/rocm_smi_lib
    else
        exit 1
        log_warn "Patch directory for rocm_smi_lib does not exist: $PATCH_DIR/rocm_smi_lib"
        log_warn "Skipping patching of rocm_smi_lib."
        if [ ! -d "rocm_smi_lib" ]; then
            log_info "rocm_smi_lib directory not found, cloning..."
            git clone --depth 1 https://github.com/ROCm/rocm_smi_lib
            if [ $? -ne 0 ]; then
                log_error "Failed to download rocm_smi_lib."
                exit 1
            fi
        fi
    fi
    # cd rocm_smi_lib
    # # Install ROCm SMI Library
    # rm -Rf build
    # mkdir build
    # cd build

    # log_info "Configuring ROCm SMI Library..."
    # cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR
    # if [ $? -ne 0 ]; then
    #     log_error "ROCm SMI Library configure failed."
    #     exit 1
    # fi
    # make -j $PROC install
    # if [ $? -ne 0 ]; then
    #     log_error "ROCm SMI Library build failed."
    #     exit 1
    # fi
    # cd $BUILD_DIR
    # log_info "ROCm SMI Library installed successfully."
else
    log_note "Skipping ROCm SMI Library build."
fi

###############################################################################
# BUILD & INSTALL PAPI
###############################################################################

export PAPI_ROCM_ROOT="$INSTALL_DIR/rocm_smi_lib"
export PAPI_ROCMSMI_ROOT="$INSTALL_DIR/rocm_smi_lib"

export PAPI_ROOT=$INSTALL_DIR/papi
export PAPI_LIB=$PAPI_ROOT/lib

cd $BUILD_DIR
if [ $BUILD_PAPI -eq 1 ]; then
    if [ ! -d "papi" ]; then
        log_info "PAPI directory not found, cloning..."
        git clone --depth 1 https://github.com/icl-utk-edu/papi
    fi
    cd papi/src
    if [ -d "$PATCH_DIR/rocm_smi" ]; then
        log_info "Removing original PAPI rocm_smi component..."
        rm -rf components/rocm_smi
        log_info "Copying patched rocm_smi component from $PATCH_DIR..."
        cp -R $PATCH_DIR/rocm_smi components/
    else
        log_warn "Patch directory for rocm_smi does not exist: $PATCH_DIR/rocm_smi"
        log_warn "Skipping patching of rocm_smi component."
    fi

    if [ -d "$PATCH_DIR/coretemp" ]; then
        log_info "Removing original PAPI coretemp component..."
        rm -rf components/coretemp
        log_info "Copying patched coretemp component from $PATCH_DIR..."
        cp -R $PATCH_DIR/coretemp components/
    else
        log_warn "Patch directory for coretemp does not exist: $PATCH_DIR/coretemp"
        log_warn "Skipping patching of coretemp component."
    fi


    # log_info "Configuring PAPI with coretemp and rocm_smi components..."
    # ./configure --with-components="coretemp rocm_smi" --prefix=$PAPI_ROOT
    # if [ $? -ne 0 ]; then
    #     log_error "PAPI configure failed."
    #     exit 1
    # fi

    # make clean
    # make -j $PROC
    # if [ $? -ne 0 ]; then
    #     log_error "PAPI build failed."
    #     exit 1
    # fi
    
    # make install-all -j $PROC
    # if [ $? -ne 0 ]; then
    #     log_error "PAPI install failed."
    #     exit 1
    # fi
    # cd $CURRENT_DIR
    # log_info "PAPI installed successfully."
else
    log_note "Skipping PAPI build."
fi

cd $CURRENT_DIR
./build-papi.sh

###############################################################################
# BUILD & INSTALL LLVM
###############################################################################

# Add our installed libraries to the library path
# This will let us use our installed dependencies to build other dependencies
export LDFLAGS="-L$INSTALL_DIR/lib -Wl,-rpath,$INSTALL_DIR/lib"
# Add our installed binaries to the PATH
export PATH="$INSTALL_DIR/bin:$PATH"

cd $BUILD_DIR
if [ $BUILD_LLVM -eq 1 ]; then
    if [ ! -d "llvm-project" ]; then
        log_info "llvm-project directory not found, cloning..."
        git clone --depth 1 https://github.com/llvm/llvm-project.git
    fi

    # Go into the llvm-project directory and build LLVM
    cd llvm-project
    log_info "Using GCC from $LLVM_WHICH_GCC_DIR for LLVM build."
    cmake -S llvm \
        -B build \
        -G Ninja \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld" \
        -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;openmp;offload;libunwind;compiler-rt" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_C_COMPILER=$LLVM_WHICH_GCC_DIR/bin/gcc \
        -DCMAKE_CXX_COMPILER=$LLVM_WHICH_GCC_DIR/bin/g++ \
        -DLIBOMPTARGET_DEBUG=1 \
        -DRUNTIMES_CMAKE_ARGS="-DCMAKE_C_FLAGS=--gcc-toolchain=$LLVM_WHICH_GCC_DIR -DCMAKE_CXX_FLAGS=--gcc-toolchain=$LLVM_WHICH_GCC_DIR" \
        -DOPENMP_TEST_FLAGS=--gcc-toolchain=$LLVM_WHICH_GCC_DIR
    log_info "Building LLVM project..."
    cmake --build build --target install -- -j $PROC
    if [ $? -ne 0 ]; then
        log_error "LLVM build failed."
        exit 1
    fi
    cd $BUILD_DIR
    log_info "LLVM project installed successfully."
else
    log_note "Skipping LLVM build."
fi

###############################################################################
# BUILD & INSTALL AFS
###############################################################################

cd $BUILD_DIR
# Check if the tar file exists
if [ $BUILD_AFS -eq 1 ]; then
    if [ ! -f "afs-dev-latest.tar.gz" ]; then
        log_info "afs-dev-latest.tar.gz not found, downloading..."
        wget https://perftools.pages.jsc.fz-juelich.de/utils/afs-dev/afs-dev-latest.tar.gz
        if [ $? -ne 0 ]; then
            log_error "Failed to download afs-dev-latest."
            exit 1
        fi
    fi
    rm -Rf afs-dev-latest
    log_info "Extracting afs-dev-latest..."
    tar xf afs-dev-latest.tar.gz
    if [ $? -ne 0 ]; then
        log_error "Failed to extract afs-dev-latest.tar.gz."
        exit 1
    fi
    cd afs-dev-latest
    ./install-afs-dev.sh --continue-after-download --prefix=$INSTALL_DIR
    if [ $? -ne 0 ]; then
        log_error "afs-dev-latest installation failed."
        exit 1
    fi
    cd $BUILD_DIR
    log_info "afs-dev-latest installed successfully."
else
    log_note "Skipping afs-dev-latest build."
fi

###############################################################################
# BUILD & INSTALL PERFTOOLS
###############################################################################

cd $BUILD_DIR
if [ ! -d "perftools-dev-latest" ]; then
    # log_info "Downloading perftools-dev-latest..."
    if [ ! -f "perftools-dev-latest.tar.gz" ]; then
        log_info "perftools-dev-latest.tar.gz not found, downloading..."
        wget https://perftools.pages.jsc.fz-juelich.de/utils/perftools-dev/perftools-dev-latest.tar.gz
        if [ $? -ne 0 ]; then
            log_error "Failed to download perftools-dev-latest."
            exit 1
        fi
    fi
    rm -Rf perftools-dev-latest
    tar xf perftools-dev-latest.tar.gz
    if [ $? -ne 0 ]; then
        log_error "Failed to extract perftools-dev-latest.tar.gz."
        exit 1
    fi
    cd perftools-dev-latest
    ./install-perftools-dev.sh --continue-after-download --prefix=$INSTALL_DIR
    if [ $? -ne 0 ]; then
        log_error "perftools-dev-latest installation failed."
        exit 1
    fi
    cd $BUILD_DIR
    log_info "perftools-dev-latest installed successfully."
else
    log_note "Skipping perftools-dev-latest build."
fi


###############################################################################
# BUILD & INSTALL OTF2
###############################################################################

cd $BUILD_DIR
if [ $BUILD_OTF2 -eq 1 ]; then
    # log_info "Downloading OTF2 3.1.1..."
    if [ ! -f "otf2-3.1.1.tar.gz" ]; then
        log_info "otf2-3.1.1.tar.gz not found, downloading..."
        wget https://perftools.pages.jsc.fz-juelich.de/cicd/otf2/tags/otf2-3.1.1/otf2-3.1.1.tar.gz
        if [ $? -ne 0 ]; then
            log_error "Failed to download OTF2 3.1.1."
            exit 1
        fi
    fi
    rm -Rf otf2-3.1.1
    tar xf otf2-3.1.1.tar.gz
    if [ $? -ne 0 ]; then
        log_error "Failed to extract OTF2 3.1.1."
        exit 1
    fi
    cd otf2-3.1.1
    ./configure --prefix=$INSTALL_DIR
    if [ $? -ne 0 ]; then
        log_error "OTF2 configure failed."
        exit 1
    fi
    make -j $PROC
    if [ $? -ne 0 ]; then
        log_error "OTF2 build failed."
        exit 1
    fi
    make install
    if [ $? -ne 0 ]; then
        log_error "OTF2 install failed."
        exit 1
    fi
    cd $BUILD_DIR
    log_info "OTF2 3.1.1 installed successfully."
else
    log_note "Skipping OTF2 build."
fi


###############################################################################
# BUILD & INSTALL CUBEW
###############################################################################

cd $BUILD_DIR
if [ $BUILD_CUBEW -eq 1 ]; then
    if [ ! -f "cubew-4.9.tar.gz" ]; then
        log_info "cubew-4.9.tar.gz not found, downloading..."
        wget https://apps.fz-juelich.de/scalasca/releases/cube/4.9/dist/cubew-4.9.tar.gz
        if [ $? -ne 0 ]; then
            log_error "Failed to download cubew 4.9."
            exit 1
        fi
    fi
    echo "Extracting cubew 4.9..."
    rm -Rf cubew-4.9
    tar xf cubew-4.9.tar.gz
    if [ $? -ne 0 ]; then
        log_error "Failed to extract cubew 4.9."
        exit 1
    fi
    cd cubew-4.9
    ./configure --prefix=$INSTALL_DIR
    if [ $? -ne 0 ]; then
        log_error "cubew configure failed."
        exit 1
    fi
    make -j $PROC
    if [ $? -ne 0 ]; then
        log_error "cubew build failed."
        exit 1
    fi
    make install -j $PROC
    if [ $? -ne 0 ]; then
        log_error "cubew install failed."
        exit 1
    fi
    cd $BUILD_DIR
    log_info "cubew 4.9 installed successfully."
else
    log_note "Skipping cubew build."
fi

###############################################################################
# BUILD & INSTALL OPARI
###############################################################################

cd $BUILD_DIR
if [ $BUILD_OPARI2 -eq 1 ]; then
    if [ ! -f "opari2-2.0.9.tar.gz" ]; then
        log_info "opari2-2.0.9.tar.gz not found, downloading..."
        wget https://perftools.pages.jsc.fz-juelich.de/cicd/opari2/tags/opari2-2.0.9/opari2-2.0.9.tar.gz
        if [ $? -ne 0 ]; then
            log_error "Failed to download OPARI2 2.0.9."
            exit 1
        fi
    fi
    rm -Rf opari2-2.0.9
    tar xf opari2-2.0.9.tar.gz
    if [ $? -ne 0 ]; then
        log_error "Failed to extract OPARI2 2.0.9."
        exit 1
    fi
    cd opari2-2.0.9
    ./configure --prefix=$INSTALL_DIR
    if [ $? -ne 0 ]; then
        log_error "OPARI2 configure failed."
        exit 1
    fi
    make -j $PROC
    if [ $? -ne 0 ]; then
        log_error "OPARI2 build failed."
        exit 1
    fi
    make install -j $PROC
    if [ $? -ne 0 ]; then
        log_error "OPARI2 install failed."
        exit 1
    fi
    cd $BUILD_DIR
    log_info "OPARI2 2.0.9 installed successfully."
else
    log_note "Skipping OPARI2 build."
fi

###############################################################################
# BUILD & INSTALL CUBELIB
###############################################################################

cd $BUILD_DIR
if [ $BUILD_CUBELIB -eq 1 ]; then
    if [ ! -f "cubelib-4.9.tar.gz" ]; then
        log_info "cubelib-4.9.tar.gz not found, downloading..."
        wget https://apps.fz-juelich.de/scalasca/releases/cube/4.9/dist/cubelib-4.9.tar.gz
        if [ $? -ne 0 ]; then
            log_error "Failed to download cubelib 4.9."
            exit 1
        fi
    fi
    rm -Rf cubelib-4.9
    log_info "Extracting cubelib 4.9..."
    tar xf cubelib-4.9.tar.gz
    if [ $? -ne 0 ]; then
        log_error "Failed to extract cubelib 4.9."
        exit 1
    fi
    cd cubelib-4.9
    log_info "Configuring cubelib 4.9..."
    ./configure --prefix=$INSTALL_DIR
    if [ $? -ne 0 ]; then
        log_error "cubelib configure failed."
        exit 1
    fi
    log_info "Building cubelib 4.9..."
    make clean
    make -j $PROC
    if [ $? -ne 0 ]; then
        echo "cubelib build failed."
        exit 1
    fi
    make install -j $PROC
    if [ $? -ne 0 ]; then
        echo "cubelib install failed."
        exit 1
    fi
    cd $BUILD_DIR
    log_info "cubelib 4.9 installed successfully."
else
    log_note "Skipping cubelib build."
fi


###############################################################################
# BUILD & INSTALL SCOREP
###############################################################################

setup_scorep_env
detect_mpi_backend
verify_mpi_backend

if [ $USE_MPI -eq 1 ]; then
    log_info "Using MPI for Score-P build."
    MPI_SCOREP_FLAG="--with-mpi=$MPI_IMPLEMENTATION"
else
    log_info "Not using MPI for Score-P build."
    MPI_SCOREP_FLAG="--without-mpi"
fi

cd $BUILD_DIR
if [ $BUILD_SCOREP -eq 1 ]; then
    if [ ! -d "scorep-9.0" ]; then
        log_info "scorep-9.0 directory not found, downloading..."
        wget https://perftools.pages.jsc.fz-juelich.de/cicd/scorep/tags/scorep-9.0/scorep-9.0.tar.gz
        if [ $? -ne 0 ]; then
            log_error "Failed to download Score-P 9.0."
            exit 1
        fi
    fi
    tar xf scorep-9.0.tar.gz
    if [ $? -ne 0 ]; then
        log_error "Failed to extract Score-P 9.0."
        exit 1
    fi
    cd scorep-9.0
    rm -Rf _build
    mkdir _build
    cd _build
    log_info "Configuring Score-P 9.0..."
    ../configure \
        --prefix="$INSTALL_DIR" \
        --enable-shared=yes \
        $MPI_SCOREP_FLAG \
        --without-shmem \
        --with-papi-lib="$PAPI_ROOT/lib" \
        --with-papi-header="$PAPI_ROOT/include" \
        --with-otf2="$INSTALL_DIR" \
        --with-cubelib="$INSTALL_DIR" \
        --with-cubew="$INSTALL_DIR" \
        --with-afs-dev="$INSTALL_DIR" \
        --with-perftools-dev="$INSTALL_DIR" \
        --with-opari2="$INSTALL_DIR" \
        --with-libgotcha=download \
        --with-libbfd=download \
        --with-libunwind=download \
        --with-libamdhip64-include="/opt/rocm-$ROCM_VERSION/include" \
        --with-libamdhip64-lib="/opt/rocm-$ROCM_VERSION/lib" \
        --with-libamdhip64=yes \
        --with-librocm_smi64-include="$INSTALL_DIR/rocm_smi_lib/include" \
        --with-librocm_smi64-lib="$INSTALL_DIR/rocm_smi_lib/lib" \
        --with-librocm_smi64=yes \
        --with-libroctracer64-include="/opt/rocm-$ROCM_VERSION/include" \
        --with-libroctracer64-lib="/opt/rocm-$ROCM_VERSION/lib" \
        --with-libroctracer64=yes \
        --with-nocross-compiler-suite="$DEFAULT_COMPILER_SUITE" \
        --with-rocm="/opt/rocm-$ROCM_VERSION" \
        --with-llvm="/opt/rocm-$ROCM_VERSION/llvm"
        # --with-librocm_smi64-include="/opt/rocm-$ROCM_VERSION/include" \
        # --with-librocm_smi64-lib="/opt/rocm-$ROCM_VERSION/lib" \
    if [ $? -ne 0 ]; then
        log_error "Score-P configure failed."
        exit 1
    fi
    make -j $PROC

    if [ $? -ne 0 ]; then
        log_error "Score-P build failed."
        exit 1
    fi
    make install -j $PROC

    if [ $? -ne 0 ]; then
        log_error "Score-P install failed."
        exit 1
    fi

    log_info "Score-P installed successfully."
    cd $BUILD_DIR
fi


cd $CURRENT_DIR

log_note "All components built and installed successfully!"

log_note "You can now set up your environment for Score-P by sourcing the setup-env.sh script."
log_note "Run the following command to set up your environment:"
log_note "source $CURRENT_DIR/setup-env.sh"