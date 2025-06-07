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

###############################################################################
# REPORT ENVIRONMENT VARIABLES
###############################################################################

log_note "Environment variables set for Score-P profiling tools:"
log_note "  - PATH:"
log_note "    $PATH"
log_note "  - C_INCLUDE_PATH:"
log_note "    $C_INCLUDE_PATH"
log_note "  - LIBRARY_PATH:"
log_note "    $LIBRARY_PATH"
log_note "  - LD_LIBRARY_PATH:"
log_note "    $LD_LIBRARY_PATH"
log_note "  - INSTALL_DIR:"
log_note "    $INSTALL_DIR"
# log_note "C_INCLUDE_PATH: $C_INCLUDE_PATH"
# log_note "LIBRARY_PATH: $LIBRARY_PATH"
# log_note "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

log_info "Environment setup complete. You can now run your scorep profiling tools."