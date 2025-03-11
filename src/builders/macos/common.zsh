#!/bin/zsh

# COMMON FUNCTIONS
# THE SCRIPT IS PART OF THE CERBERUS X BUILDER TOOL.

########################################
# COMMON FUNCTION USE BY OTHER SCRIPTS
########################################

# Various flags and variables
EXIT_CODE=-1                 # Used to store the exit code after any call to functions and applications.
COMPILER=g++                # The file name of the compiler to use.
QT_INSTALLS=()              # Holds the total number of Qt kits installed
QTVER=                      # Holds the Qt version number
SHOW_MENU=0                 # Flag used to show the menu
TRANSCC_EXE=0               # The flag use to check if transcc_macos has been built.
FORCE_CODESIGN_TED=0        # The flag to trigger a local code signing of Ted
DEPLOY_PATH=                # Holds the path that will be use to create the deployment build.
BREAK_ON_BUILD_ALL=0       # Used skip building deployment builds when in menu mode and the all option is selected.

QTDIR="$HOME/Qt";           # Set the default Qt Installer directory location to the users home directory.

# From Qt 6.2.4 the directory is no longer clang_64, but macOS. So extra checks will be needed.
QMAKE_TYPE="clang_64";

CODESIGN_CERT=                          # Holds the path to the developer certificate. Empty will force codesign -s -
MACOS_BUNDLE_PREFIX="com.cerberus-x"    # Holds the default application bundle prefix.
QT_SELECTED=                            # Holds the selected/found Qt SDK.
DEPLOY_PATH=                            # Deployment path. See deploy.zsh
ARCHIVE_TOOL=hdiutil                    # Default archive tool to use.

#########################################
# Display colourized information
#########################################
do_info(){
    echo -e "\033[36m$1\033[0m"
}

do_header(){
    echo -e "\033[33m$1\033[0m"
}

do_build(){
    echo -e "\033[34m$1\033[0m"
}

do_error(){
    echo -e "\033[31m$1\033[0m"
}

do_success(){
    echo -e "\033[32m$1\033[0m"
}

do_unknown(){
    echo -e "\033[35m$1\033[0m"
}

do_warning(){
    echo -e "\033[93;5m$1\033[0m"
}

###################################################
# General external application execution function.
###################################################
execute(){
    PARAM=
    for exec_param in $@; do
        PARAM+="$exec_param "
    done
    
    do_build "Executing:\n$PARAM"
    $@
    [[ $? -eq 0 ]] && {
        EXIT_CODE=0
        return $EXIT_CODE;
    } || {
        EXIT_CODE=1
        return $EXIT_CODE;
    }
}

###########################################
# Function to remove any file or directory
##########################################
# Passing anything as the second parameter will allow a non .build directory to be deleted.
do_delete(){
    EXIT_CODE=0
    do_info "DELETING:"

    [ -z "$1" ] && {
        do_warning "EMPTY PATH NAME PASSED AS PARAMETER"
        return $EXIT_CODE
    }
    
    [ ! -e "$1" ] && {
        do_warning "$1\nPARAMETER PASSED IS NOT A VALID FILE OR DIRECTORY"
        return $EXIT_CODE;
    }

    do_unknown "$1"
    [ -f "$1" ] && {
        do_info "$1"
        execute rm -f "$1"
        [ $EXIT_CODE -ne 0 ] && {
            do_warning "FAILED TO DELETE FILE\n$1"
        } || {
            do_success "DELETED FILE:\n$1"
        }
        return $EXIT_CODE
    }

    [ -d "$1" ] && {
        do_info "$1"
        execute rm -rf "$1"
        [ $EXIT_CODE -ne 0 ] && {
            do_warning "FAILED TO DELETE DIRECTORY\n$1"
        } || {
            do_success "DELETED DIRECTORY:\n$1"
        }
        return $EXIT_CODE
    }
}

######################################
# Function to move a file or directory
######################################
do_move(){
    do_unknown "MOVING:"
    do_unknown "SOURCE: $1"
    do_unknown "DESTINATION: $2"
    execute mv "$1" "$2"
    [ $EXIT_CODE -ne 0 ] && {
        do_warning "FAILED TO MOVE:"
        do_warning "SOURCE: $1"
        do_warning "DESTINATION: $2"
    }
    do_success "SUCCESSFULLY MOVED:"
    do_success "SOURCE: $1"
    do_success "DESTINATION: $2"
}

# General function to call after a build
do_build_result(){
    [ $EXIT_CODE -eq 0 ] && {
        do_success "BUILD SUCCESSFUL"
        echo "";
        } || {
        do_error "BUILD FAILED"
        echo "";
    }
}

########################################
# Function to build with transcc
########################################
# The last parameter sets the garbage collection mode to use. The default is to use gc mode 1.
# See the Cerberus config documentation about garbage collection.
transcc(){
    EXIT_CODE=0
    [ ! -f "$CERBERUS_BIN_DIR/transcc_macos" ] && {
        do_error "NO TRANSCC PRESENT"
        EXIT_CODE=1
        return $EXIT_CODE;
    } || {
        local target=$2
        local srcpath="$CERBERUS_SRC_DIR/$3"
        local srcfile="$3"
        [ -z "$4" ] && { gc_mode="0"; } || { gc_mode="1"; }
        ARG=("$CERBERUS_BIN_DIR/transcc_macos" "-target=$target")
        ARG+=("-builddir=$srcfile.build" "-clean" "-config=release" "+CPP_GC_MODE=$gc_mode" "$srcpath/$srcfile.cxs")
        execute ${ARG[@]}
        do_build_result
        
        return $EXIT_CODE;
    }
}


########################################
#   LAST RESORT CODE SIGN LOCAL
########################################
# Force local use codesign
do_force_ted_codesign(){
    [ -z "$CODESIGN_CERT" ] && {
       array=( $(find "$CERBERUS_BIN_DIR/Ted.app") )
        local i=0;
        while [ $i -lt ${#array[@]} ]
        do
            execute codesign -s - ${array[$i]}
            ((i++))
        done;
    }
}