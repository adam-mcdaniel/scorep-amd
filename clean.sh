#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
INSTALL_DIR="$CURRENT_DIR/install"
BUILD_DIR="$CURRENT_DIR/build"
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

# If neither build nor install directories exist, exit
if [ ! -d "$INSTALL_DIR" ] && [ ! -d "$BUILD_DIR" ]; then
    log_error "Neither install nor build directories exist. Nothing to clean."
    exit 1
fi

function clean_install_dir () {
    log_info "Cleaning install directory: $INSTALL_DIR"
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        log_info "Install directory cleaned."
    else
        log_warn "Install directory does not exist, nothing to clean."
    fi
}

function clean_build_dir () {
    log_info "Cleaning build directory: $BUILD_DIR"
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        log_info "Build directory cleaned."
    else
        log_warn "Build directory does not exist, nothing to clean."
    fi
}

function clean_all () {
    clean_install_dir
    clean_build_dir
}

# Ask the user what kind of clean they want
log_info "Choose clean option:"
log_info "(1) Clean install directory ($INSTALL_DIR)"
log_info "(2) Clean build directory ($BUILD_DIR)"
log_info "(3) Clean both install and build directories"
log_info "(4) Environment variables (unset all variables)"
prompt "Enter your choice (1/2/3/4):"
case "$choice" in
    1)
        clean_install_dir
        ;;
    2)
        clean_build_dir
        ;;
    3)
        clean_all
        ;;
    4)
        log_info "Unsetting all environment variables related to this setup."
        # Unset all variables that were set in setup-env.sh
        unset INSTALL_DIR
        unset BUILD_DIR
        unset SCOREP_HOME
        unset C_INCLUDE_PATH
        unset CPLUS_INCLUDE_PATH
        unset LD_LIBRARY_PATH
        unset LIBRARY_PATH
        unset CFLAGS
        unset CXXFLAGS
        unset LDFLAGS
        unset CC
        unset CXX
        unset HIPCC
        unset SCOREP_EXPERIMENT_DIRECTORY
        unset SCOREP_ENABLE_PROFILING
        unset SCOREP_ENABLE_TRACING
        unset SCOREP_DEBUG
        unset SCOREP_VERBOSE
        unset SCOREP_TOTAL_MEMORY
        unset SCOREP_METRIC_PLUGINS
        unset SCOREP_METRIC_AROCM_SMI_PLUGIN
        unset SCOREP_METRIC_AROCM_SMI_INTERVAL_US
        unset SCOREP_METRIC_CORETEMP_PLUGIN
        unset SCOREP_METRIC_CORETEMP_INTERVAL_US
        log_info "Resetting the shell environment to a clean state."
        PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        exec bash --login
        ;;
    *)
        log_error "Invalid choice. Please enter 1, 2, 3, or 4."
        exit 1
        ;;
esac

log_info "Clean operation completed successfully."

log_note "If you want to clean your Bash environment (unset all variables)"
log_note "-- you can run the following command:"
log_note "$ exec bash --login"

# Exit with success
exit 0