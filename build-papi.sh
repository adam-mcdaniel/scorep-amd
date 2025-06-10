#!/bin/bash


BUILD_DIR=$(pwd)/build
INSTALL_DIR=$(pwd)/install

export PAPI_ROCM_ROOT=$INSTALL_DIR/rocm_smi_lib
export PAPI_ROCMSMI_ROOT=$INSTALL_DIR/rocm_smi_lib

export PAPI_ROOT=$INSTALL_DIR/papi
export PAPI_LIB=$PAPI_ROOT/lib

cd $BUILD_DIR/rocm_smi_lib/

rm -Rf build
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR/rocm_smi_lib
make -j16 install



# Install PAPI
cd $BUILD_DIR/papi/src
make clean
./configure --with-components="coretemp rocm_smi" --prefix $INSTALL_DIR/papi
make -j16
make install-all