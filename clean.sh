#!/bin/bash

CURRENT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
INSTALL_DIR="$CURRENT_DIR/install"
BUILD_DIR="$CURRENT_DIR/build"
DEBUG=1

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
    log_error "Please source it instead: 'source clean.sh'"
    exit 1
fi

function save_bash_env() {
    if [[ -z "$ORIGINAL_BASH_ENV" && ! -f $ORIGINAL_BASH_ENV ]]; then
        log_info "Saving original bash environment variables to $ORIGINAL_BASH_ENV"
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
}

function restore_bash_env() {
    if [[ -f "$ORIGINAL_BASH_ENV" ]]; then
        # Unset all variables in the current shell environment
        SKIP_VARS=("SKIP_VARS DEBUG ORIGINAL_BASH_ENV BASH BASHOPTS BASHPID BASH_ALIASES BASH_ARGC BASH_ARGV BASH_ARGV0 BASH_CMDS BASH_COMMAND BASH_COMPLETION_VERSINFO BASH_ENV BASH_LINENO BASH_LOADABLES_PATH BASH_SOURCE BASH_SUBSHELL BASH_VERSINFO BASH_VERSION BUG_REPORT_URL COLUMNS COMP_WORDBREAKS DBUS_SESSION_BUS_ADDRESS DEBUGINFOD_URLS DIRSTACK EPOCHREALTIME EPOCHSECONDS EUID GROUPS HISTCMD HISTFILE HISTFILESIZE HISTSIZE HOME HOME_URL HOSTNAME HOSTTYPE ID ID_LIKE IFS LANG LINENO LINES LMOD_CMD LMOD_DIR LMOD_PKG LMOD_ROOT LMOD_SETTARG_FULL_SUPPORT LMOD_VERSION LMOD_sys LOGNAME LOGO MACHTYPE MAILCHECK MANPATH MODULEPATH MODULEPATH_ROOT MODULESHOME NAME OPTERR OPTIND OSTYPE PATH PIPESTATUS PPID PRETTY_NAME PRIVACY_POLICY_URL PS1 PS2 PS4 PWD RANDOM SECONDS SHELL SHELLOPTS SHLVL SRANDOM SSH_CLIENT SSH_CONNECTION SSH_TTY SUPPORT_URL TERM UBUNTU_CODENAME UID USER VERSION VERSION_CODENAME VERSION_ID XDG_DATA_DIRS XDG_RUNTIME_DIR XDG_SESSION_CLASS XDG_SESSION_ID XDG_SESSION_TYPE _ __git_printf_supports_v _backup_glob _xspecs cores dir ftp_proxy http_proxy https_proxy memory newnews newsstring release snap_bin_path snap_xdg_path str string")
        for var in $(compgen -v); do
            if [[ $(echo $SKIP_VARS | grep $var) ]]; then
                log_debug "Skipping variable: $var"
                continue
            else
                # Unset the variable
                log_debug "Unsetting variable: $var"
                unset "$var" > /dev/null 2>&1
            fi
        done
        
        NEW_ENV=$(while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            log_debug "Restoring variable: $line"
            # Export the variable
            export "$line" > /dev/null 2>&1
        done < "$ORIGINAL_BASH_ENV")
        log_note "Restored $ORIGINAL_BASH_ENV"
        # Restore the original environment variables
    else
        log_error "Original bash environment file not found: $ORIGINAL_BASH_ENV"
    fi
}

# save_bash_env


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
        log_info "Clean operation completed successfully."
        ;;
    2)
        clean_build_dir
        log_info "Clean operation completed successfully."
        ;;
    3)
        clean_all
        log_info "Clean operation completed successfully."
        ;;
    4)
        log_info "Unsetting all environment variables related to this setup."
        # Unset all variables in the current shell environment

        # for var in $(compgen -v); do
        #     if [[ "$var" != BASH* && "$var" != BASH_* && "$var" != "PPID" && "$var" != "EUID" && "$var" != "PPID" && "$var" != "UID" && "$var" != "SHELLOPTS" ]]; then
        #         unset "$var"
        #     fi
        # done
        
        restore_bash_env
        # log_info "Resetting the shell environment to a clean state."
        # # exec env -i HOME=$HOME bash --login
        # # Use the $ORIGINAL_BASH_ENV to restore the original environment
        # if [ -f "$ORIGINAL_BASH_ENV" ]; then
        #     log_info "Restoring original environment from $ORIGINAL_BASH_ENV"
        #     while IFS= read -r line; do
        #         # Skip empty lines and comments
        #         [[ -z "$line" || "$line" =~ ^# ]] && continue
        #         # Export the variable
        #         log_info "Restoring variable: $line"
        #         export "$line"
        #     done < "$ORIGINAL_BASH_ENV"
        #     log_info "Original environment restored."
        # else
        #     log_error "Original environment file not found: $ORIGINAL_BASH_ENV"
        #     exit 1
        # fi
        log_info "Clean operation completed successfully."
        ;;
    *)
        log_error "Invalid choice. Please enter 1, 2, 3, or 4."
        # exit 1
        ;;
esac

# Exit with success