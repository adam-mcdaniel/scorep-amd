#!/bin/bash
if [ -z $INSTALL_DIR ]; then
        echo "Please source setup-env.sh in the root directory of this project"
        echo "before sourcing this file."
	exit 1
fi

source $INSTALL_DIR/../setup-env.sh
source load-scorep-plugin-parameters.sh

echo "Building Score-P plugins..."

cd scorep-arocm-smi-plugin
./c_all
if [ $? -ne 0 ]; then
    echo "Score-P AROCM-SMI plugin build failed."
    exit 1
fi
cd ..

cd scorep-coretemp-plugin
./c_all
if [ $? -ne 0 ]; then
    echo "Score-P CoreTemp plugin build failed."
    exit 1
fi

cd ..
echo "Done building Score-P plugins."
