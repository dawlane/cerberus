#!/bin/bash

# TOOL BUILDER FUNCTIONS
# THE SCRIPT IS PART OF THE CERBERUS X BUILDER TOOL.

#######################################################################################################
#   Build transcc, cserver, makedocs, launcher and the IDE Ted
#######################################################################################################

# TRANSCC
# This function basically just builds from the c++ sources.
# Any new or update version of the transcc c++ source should replace the ones in the src/transcc/transcc.build directory. 
do_transcc(){
    EXIT_CODE=0
    do_info "BUILDING TRANSCC WITH $COMPILER"
    
    # Check for an existing transcc
    [ -f "$CERBERUS_BIN_DIR/transcc_linux" ] && { do_delete "$CERBERUS_BIN_DIR/transcc_linux"; }
    
    local PROJECT_DIR="$CERBERUS_SRC_DIR/transcc/transcc.build/cpptool"
    local BUILD_DIR="$PROJECT_DIR/gcc_linux/Release"

    local ARG=("make")
    ARG+=("CXX_COMPILER=$COMPILER" "C_COMPILER=$C_COMPILER" "CCOPTS=-DNDEBUG" "CCOPTS+=-Os")
    ARG+=("BUILD_DIR=$BUILD_DIR")
    ARG+=("OUT=transcc_linux" "OUT_PATH=$CERBERUS_BIN_DIR" "LIBOPTS=-lpthread" "LIBOPTS+=-ldl" "LDOPTS=-no-pie" "LDOPTS+=-s");

    mkdir -p $BUILD_DIR
    pushd "$CERBERUS_SRC_DIR/transcc/transcc.build/cpptool/gcc_linux"
    execute ${ARG[@]}
    popd

    do_build_result

    do_delete "$BUILD_DIR";
    
    return $EXIT_CODE
}

# CSERVER TOOL
do_cserver(){
    EXIT_CODE=0
    
    # Call transcc
    transcc "CServer" "Desktop_Game" "cserver"

    local BUILD_DIR="$CERBERUS_SRC_DIR/cserver/cserver.build"

    # If transcc execution was successful; then update CServer.
    [ $EXIT_CODE -eq 0 ] && {
        local PROJECT_DIR="$BUILD_DIR/glfw3/gcc_linux"

        # Clean out the olds and move new associated CServer files into the Cerberus bin directory.
        [ ! -d "$CERBERUS_BIN_DIR/data" ] && {
            [ -d "$PROJECT_DIR/Release/data" ] && {
                do_move "$PROJECT_DIR/Release/data" "$CERBERUS_BIN_DIR/data";
            } || {
                do_warning "DATA DIRECTORY NOT CREATED\n$PROJECT_DIR/Release/data";
            }
        }

        [ -f "$CERBERUS_BIN_DIR/cserver_linux" ] && { do_delete "$CERBERUS_BIN_DIR/cserver_linux"; };
        
        # Move the newly built CServer into the Cerberus bin directory.
        do_move "$PROJECT_DIR/Release/CerberusGame" "$CERBERUS_BIN_DIR/cserver_linux";
    }
    
    # Remove the build directory if it was created.
    [ -d "$BUILD_DIR" ]  && { do_delete "$BUILD_DIR"; }
    return $EXIT_CODE
}

# LAUNCHER TOOL
do_launcher(){
    EXIT_CODE=0
    
    local BUILD_DIR="$CERBERUS_SRC_DIR/launcher/launcher.build"
    # Use transcc to build the launcher on a Linux host
    transcc "Launcher" "C++_Tool" "launcher"
        
    # Only update the launcher if the build was successful.
    [ $EXIT_CODE -eq 0 ] && {
        [ -f "$CERBERUS_ROOT_DIR/Cerberus" ] && { do_delete "$CERBERUS_ROOT_DIR/Cerberus"; }
        do_move "$BUILD_DIR/cpptool/main_linux" "$CERBERUS_ROOT_DIR/Cerberus";
    }

    # Remove the build directory if it was created.
    [ -d "$BUILD_DIR" ]  && { do_delete "$BUILD_DIR"; }

    return $EXIT_CODE
}

# MAKEDOCS TOOL
do_makedocs(){
    EXIT_CODE=0
    
    # Call transcc to build makedocs.
    transcc "Makedocs" "C++_Tool" "makedocs"

    local BUILD_DIR="$CERBERUS_SRC_DIR/makedocs/makedocs.build"
    # Only update the makedocs if the build was successful.
    [ $EXIT_CODE -eq 0 ] && {
        [ -f "$CERBERUS_BIN_DIR/makedocs_linux" ] && { do_delete "$CERBERUS_BIN_DIR/makedocs_linux"; }
        do_move "$BUILD_DIR/cpptool/main_linux" "$CERBERUS_BIN_DIR/makedocs_linux";
    }
    
    # Remove the build directory if it was created.
    [ -d "$BUILD_DIR" ]  && { do_delete "$BUILD_DIR"; }

    return $EXIT_CODE
}

# IDE TED
do_ted(){
    EXIT_CODE=0
    
    local BUILD_DIR="$CERBERUS_SRC_DIR/build-ted-Desktop-Release"
    # As the qmake project expects there to be a directory with the name build-ted-Desktop-Release.
    # It's best to make sure any old version is removed and a new one created before running qmake
    [ -d "$BUILD_DIR" ] && { do_delete "$BUILD_DIR"; }
    
    # Create and store the current directory and switch to the build directory to run qmake and make
    mkdir "$BUILD_DIR"
    pushd "$BUILD_DIR"

    # Run qmake on the ted project file to create the makefile.
    execute qmake CONFIG+=release ../ted/ted.pro
    
    # If qmake was successfully executed; then proceed to build the IDE.
    [ $EXIT_CODE -eq 0 ] && {
        # Not really required with qmake cleaning out all Qt related binaries, but just in case.
        [ -f "$CERBERUS_BIN_DIR/Ted" ] && { rm -f "$CERBERUS_BIN_DIR/Ted"; };

        # For Linux. If usr is not detected in the QT_SELECT, the Qt is from the official Qt Company and will need to install the Qt libraries.
        # Else is't from the distributions repository and no need to preform an install of the libraries.
        if [[ $QT_SELECTED != *"/usr/"* ]]; then
            execute "make" "install"
        else
            execute "make"
        fi;

        do_build_result;
    }
    
    # Restore the saved directory.
    popd
    
    # Remove the build directory if it was created.
    [ -d "$BUILD_DIR" ]  && { do_delete "$BUILD_DIR"; }
    return $EXIT_CODE
}

# FREE DESKTOP
# Generate the .desktop files for desktop integration.
do_freedesktop(){
    do_init_linux_desktop
}

# BUILD ALL
# Builds all the above tools.
do_all(){
    [ $BREAK_ON_BUILD_ALL -eq 1 ] && {
        echo "$DEPLOY_PATH"
        [ -n "$DEPLOY_PATH" ] && {
            do_deploy;
            return $EXIT_CODE;
        }
    }

    do_header "\n====== BUILDING ALL TOOLS ======"
    do_info "BUILDING TransCC"
    do_transcc;
    [ $EXIT_CODE -eq 0 ] && {
        do_info "BUILDING CServer"
        do_cserver;
    }
    [ $EXIT_CODE -eq 0 ] && {
        do_info "BUILDING Makedocs"
        do_makedocs;
    }
    [ $EXIT_CODE -eq 0 ] && {
        do_info "BUILDING Launcher"
        do_launcher;
    }
    [ $EXIT_CODE -eq 0 ] && {
        do_info "Generating Free Desktop Launcher"
        do_freedesktop;
    }
    
    [[ ${#QT_INSTALLS[@]} -gt 0 && $EXIT_CODE -eq 0 ]] && { 
        do_info "BUILDING IDE Ted"
        do_ted;
    } || {
        do_error "NO QT SDK KITS INSTALLED";
    }
}

################################################
# CLEAN THE WORK REPOSITORY OF BUILT FILES
################################################
do_clean(){
    do_info "CHECKING AND REMOVING ANY LEFT OVER TOOL BUILD DIRECTORIES"
    find "$CERBERUS_SRC_DIR/transcc/transcc.build/cpptool/gcc_linux" -type d -name 'Release' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_SRC_DIR/cserver" -type d -name 'cserver.build' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_SRC_DIR/launcher" -type d -name 'launcher.build' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_SRC_DIR/makedocs" -type d -name 'makedocs.build' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_SRC_DIR" -type d -name 'build-ted-Desktop-Release' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_SRC_DIR/ted" -type d -name 'build' -prune -exec rm -rf "{}" \;
}

do_distclean(){
    do_info "CLEARING OUT ANY PREVIOUS BUILDS"

    # Remove all macOS applications. Ted and CServer
    find "$CERBERUS_BIN_DIR" -type d -name '*.app' -prune -exec rm -rf "{}" \;

    # Remove transcc linux, winnt and macos
    find "$CERBERUS_BIN_DIR" -type f -name 'transcc_*' -delete

    # Remove the launchers linux, winnt and macos
    find "$CERBERUS_ROOT_DIR" -type f -name 'Cerberus.exe' -delete
    find "$CERBERUS_ROOT_DIR" -type f -name 'Cerberus' -delete
    find "$CERBERUS_ROOT_DIR" -type d -name 'Cerberus.app' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_ROOT_DIR" -type f -name '*.desktop' -delete
  
    # Remove CServer linux and winnt
    find "$CERBERUS_BIN_DIR" -type f -name 'cserver_*' -delete

    # Remove makedocs linux, winnt and macos
    find "$CERBERUS_BIN_DIR" -type f -name 'makedocs_*' -delete

    # Remove Ted linux and winnt
    find "$CERBERUS_BIN_DIR" -type f -name 'Ted.exe' -delete
    find "$CERBERUS_BIN_DIR" -type f -name 'Ted' -delete

    # Remove Qt Linux support files and directories
    find "$CERBERUS_BIN_DIR" -type d -name 'lib*' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_BIN_DIR" -type d -name 'plugins' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_BIN_DIR" -type d -name 'resources' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_BIN_DIR" -type d -name 'translations' -prune -exec rm -rf "{}" \;

    # Remove Qt WinNT support files and directories
    find "$CERBERUS_BIN_DIR" -type f -name 'qt.conf' -delete
    find "$CERBERUS_BIN_DIR" -type f -name '*.dll' -delete
    find "$CERBERUS_BIN_DIR" -type f -name '*.exe' -delete
    find "$CERBERUS_BIN_DIR" -type f -name '*.ilk' -delete
    find "$CERBERUS_BIN_DIR" -type f -name '*.pdb' -delete
    find "$CERBERUS_BIN_DIR" -type f -name 'openal32_*' -delete
    find "$CERBERUS_BIN_DIR" -type d -name 'platforms' -prune -exec rm -rf "{}" \;

    # Remove all .buildsv20*
    find "$CERBERUS_ROOT_DIR" -type d -name '*.buildv20*' -prune -exec rm -rf "{}" \;

    # Remove html
    find "$CERBERUS_ROOT_DIR/docs" -type d -name 'html' -prune -exec rm -rf "{}" \;
    find "$CERBERUS_BIN_DIR" -type d -name 'ted_*.ini' -prune -exec rm -rf "{}" \;
 
    do_clean
}