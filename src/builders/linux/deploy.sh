#!/bin/bash

# DEPLOYMENT BUILDER FUNCTIONS
# THE SCRIPT IS PART OF THE CERBERUS X BUILDER TOOL.

#############################################
# BUILD A DEPLOYMENT ARCHIVE
#############################################
# This function requires that git be installed.
# It works by cloning the the current repository, removing any git related items from the clone, and then running the 
# builder script in the clone with the basic set of parameters that were passed. After the cloned builder script has
# finished and control is returned to this function. A archive is generated from the freshly built files in the clone.
do_deploy(){
    EXIT_CODE=0

    # Set some local variables. Just to make it a bit easier to follow.
    local DEPLOYMENT_ROOT_DIR="$DEPLOY_PATH/cx_deploy_root"
    local DEPLOYMENT_BUILD_DIR="$DEPLOYMENT_ROOT_DIR/build"
    local DEPLOYMENT_TARGET_DIR="$DEPLOYMENT_BUILD_DIR/Cerberus"
    local DEPLOYMENT_TARGET_BIN_DIR="$DEPLOYMENT_TARGET_DIR/bin"
    local DEPLOYMENT_TARGET_SRC_DIR="$DEPLOYMENT_TARGET_DIR/src"
    
    # Test for a .git folder. If there isn't one, then it must be a normal set of sources files.
    [ ! -d "$CERBERUS_ROOT_DIR/.git" ] && {
        do_error "Deployment requires that the sources are contained in a git repository."
        return;
    }

    # Only do a deployment build if git is installed.
    execute git --version
    [ $EXIT_CODE -ne 0 ] && {
        do_error "git is required to build."
        return;
    }

    # Set up the deploy directories
    [ -d "$DEPLOYMENT_ROOT_DIR" ] && { do_delete "$DEPLOYMENT_ROOT_DIR"; }
    execute mkdir -p "$DEPLOYMENT_TARGET_DIR"
    [ $EXIT_CODE -ne 0 ] && {
        do_error "Failed to create deploy directory: $DEPLOYMENT_TARGET_DIR"
        return;
    }

    ## Test if the git repository is in a clean state. Else issue a error message and return back
    # to the menu. If everything is okay, then clone the git repository.
    local STATUS=$(execute git status 2>&1)
    echo "$STATUS"
    if [[ $STATUS == *"nothing to commit, working tree clean"* ]]; then
        execute git -C $DEPLOYMENT_BUILD_DIR clone $CERBERUS_ROOT_DIR Cerberus
        [ $EXIT_CODE -ne 0 ] && {
            do_error "Failed to clone to directory: $DEPLOYMENT_BUILD_DIR"
            return;
        }
    else
        do_error "Repository is not clean. Check for untracked and uncommitted files."
        return
    fi

    # Clean up any git stuff that's been copied over.
    # Additional file and directories should be added here.
    local RM_FILES=("$DEPLOYMENT_TARGET_DIR/.git" "$DEPLOYMENT_TARGET_DIR/.gitignore" "$DEPLOYMENT_TARGET_DIR/.gitattributes")
    for r in "${RM_FILES[@]}"; do
        [ -d "$r" ] && {
            rm -rf "$r";
        } || {
            [ -f "$r" ] && { rm -f "$r"; };
        }
    done

    # Generate parameters to pass on to the cloned builder script.
    # Only the basic parameters need to be passed on.
    local PARAMS=("$DEPLOYMENT_TARGET_SRC_DIR/builder.sh")
    if [ -n "$QT_SDK_DIR" ]; then PARAMS+=("-q" "$QT_SDK_DIR"); fi
    if [ -n "$QT_SDK_VERSION" ]; then PARAMS+=("-k" "$QT_SDK_VERSION"); fi
    if [ -n "$ARCHIVE_TOOL" ]; then PARAMS+=("-a" "$ARCHIVE_TOOL"); fi
    if [[ $GEN_ICONS -eq 1 ]]; then PARAMS+=("-i" "$SVG_APP_ICON" "$SVG_MIME_ICON"); fi
    if [ -n "$GCC_VER" ]; then PARAMS+=("-g" "$GCC_VER"); fi

    # Start the cloned builder script with the parameters that were passed to the main builder script.
    chmod +x $DEPLOYMENT_TARGET_SRC_DIR/builder.sh
    pushd "$DEPLOYMENT_TARGET_SRC_DIR"
    do_info "Execuiting: 
    ${PARAMS[@]}"
    execute ${PARAMS[@]}
    popd

    # Check that the default files have been created before compressing to an archive. NOTE: Qt SDK's are not included in the check.
    local CHECK_FILES=("$DEPLOYMENT_TARGET_BIN_DIR/transcc_linux" "$DEPLOYMENT_TARGET_BIN_DIR/makedocs_linux")
    CHECK_FILES+=("$DEPLOYMENT_TARGET_BIN_DIR/cserver_linux" "$DEPLOYMENT_TARGET_BIN_DIR/Ted" "$DEPLOYMENT_TARGET_DIR/Cerberus");
    local CHECK_COUNT=0
    for filecheck in "${CHECK_FILES[@]}"; do
        do_info "CHECKING FOR $filecheck"
       if  [ -f "$filecheck" ]; then
            do_success "Found: $filecheck"
            ((CHECK_COUNT++))
        else
            do_error "Missing: $filecheck"
       fi
    done

    # Only compress if the file count match that of the array.
    [ $CHECK_COUNT -ne ${#CHECK_FILES[@]} ] && {
        do_error "Deployment file error."
        EXIT_CODE=1
        return $EXIT_CODE
    }

    # Make sure that the binaries will execute permissions before compressing.
    for files in "${CHECK_FILES[@]}"; do
        do_info "Setting excute permission for $files"
        execute "chmod +x $files"
    done;
    
   # Get what should be the first line in the VERSION.TXT file to retrieve the version number.
    while IFS= read -r line; do
        [ "${line:0:1}" = "*" ] && {
            CX_VERSION=$(echo "$line" | sed 's/[* ]//g')
            break;
        }
    done < "$DEPLOYMENT_TARGET_DIR/VERSIONS.TXT"

    ARCHIVE_CMD=()
    local FILE_NAME=
    # If there is a Qt version number, this means that there are Qt libraries to install.
    # Then set the file name with the Qt version.
    [[ $QT_SDK_VERSION =~ ^[0-9]+(\.[0-9]+){2,3}$ ]] && {
        FILE_NAME="$DEPLOYMENT_ROOT_DIR/Cerberus_$CX_VERSION-qt$QT_SDK_VERSION-linux."
    } || {
        FILE_NAME="$DEPLOYMENT_ROOT_DIR/Cerberus_$CX_VERSION-linux."
    };

    # The command to generate an archive package
    FILE_NAME+="tar.gz"
    ARCHIVE_CMD+=("tar" "-czvf" "$FILE_NAME" "-C" "$DEPLOYMENT_BUILD_DIR" "Cerberus");

    # Generate archive files
    pushd "$DEPLOYMENT_ROOT_DIR"
    if [ -f "$FILE_NAME" ]; then rm -f "$FILE_NAME"; fi
    execute ${ARCHIVE_CMD[@]}
    popd;
}