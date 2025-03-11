#!/bin/zsh

# THIRD-PARTY FUNCTIONS
# THE SCRIPT IS PART OF THE CERBERUS X BUILDER TOOL.

#######################################################################################################
#   DETECTION AND SET UP OF THIRD PARTY TOOLS, FRAME WORKS AND COMPILER TOOL CHAINS
#######################################################################################################


############################
# QT FRAME WORK DETECTION
############################
# Scan the Qt directory passed as a parameter for Qt installations
do_qtsdk_scanner(){
    
    # Get all directories in the directory passed for Qt and sort in the reverse order.
    local DIRS=($(printf "%s\n" `ls ${QT_SDK_DIR}` | sort -V -r));
    
    # Only process the DIRS array if there are elements present.
    [ ${#DIRS[@]} -gt 0 ] || { return; }
    
    # Use a regular expression to only store those elements with dot version numbers in to the QT_INSTALLS array.
    re='^[0-9]+(\.[0-9]+)*$';
    for d in "${DIRS[@]}"; do
        [[ $d =~ $re ]] && {
            
            # Update the QMAKE_TYPE directory root if Qt is greater the Qt 5.     
            execute "$QT_SDK_DIR/$d/$QMAKE_TYPE/bin/qmake" -v
            [ $EXIT_CODE -eq 0 ] && { QT_INSTALLS+=("$QT_SDK_DIR/$d/$QMAKE_TYPE"); };
        }
    done
}

# Function to test if there are any Qt SDK installations.
do_qtsdk_check(){
    EXIT_CODE=0
    
    do_header "CHECKING FOR QT INSTALLATION"
    # The first test is if arguments passed were for the Qt SDK root directory and version to use.
    # If this is successful, then the systems PATH variable is update to make sure that this
    # Qt SDK is the first before any other installed.
    # If the test failed; then try to find at least one Qt SDK installation in the Qt SDK root directory
    # if that was passed.
    [ -f "${QT_SDK_DIR}/${QT_SDK_VERSION}/${QMAKE_TYPE}/bin/qmake" ] && {
        
        execute "${QT_SDK_DIR}/${QT_SDK_VERSION}/${QMAKE_TYPE}/bin/qmake" --version
        [ $EXIT_CODE -eq 0 ] && {
            export PATH="${QT_SDK_DIR}/${QT_SDK_VERSION}/${QMAKE_TYPE}/bin:$PATH"
            QT_INSTALLS+=("`which qmake`");
            QT_SELECTED=$QT_SDK_VERSION
            return $EXIT_CODE;
        };
    } || {
        
        # If the Qt root directory was passed; then test for the maintenance tool.
        # If the tool was successfully run; then proceed to get any installed Qt SDKs.
        # If there are any elements stored in the QT_INSTALLS array; then only pre-end
        # the PATH environment variable with either the one passed with option to get the version or help, or get
        # the first element in the QT_INSTALLS array.
        [ -n "$QT_SDK_DIR" ] && {
            execute "${QT_SDK_DIR}/MaintenanceTool" -v;
            
            # Only scan the Qt directory if the maintenance tool was successfully run.
            [ $EXIT_CODE -eq 0 ] && {
                do_success "FOUND ${QT_SDK_DIR}/MaintenanceTool"
                do_qtsdk_scanner
                [ ${#QT_INSTALLS[@]} -gt 0 ] && {
                    
                    # If no version number was passed as a parameter; then use the first Qt SDK in the array.
                    [ -z "${QT_SDK_VERSION}" ] && {
                        QT_SELECTED=${QT_INSTALLS[0]}
                        export PATH="${QT_INSTALLS[0]}/bin:$PATH";
                    } || {
                        
                        # Match the version number.
                        for i in "${QT_INSTALLS[@]}"; do
                            [[ $i = *"/$QT_SDK_VERSION/"* ]] && {
                                do_success "FOUND $i"
                                QT_SELECTED=$i
                                break;
                            }
                        done
                        [ -z "$QT_SELECTED" ] && {
                            do_unknown "Unknown Qt $QT_SDK_VERSION\nSelecting any installed from repository.";
                        } || {
                            execute qmake --version
                            [ $EXIT_CODE -eq 0 ] && {
                                echo "REACHED"
                                QT_INSTALLS+=("`which qmake`")
                                QT_SELECTED=${QT_INSTALLS[0]};
                            };
                        };
                    };
                };
            }
        } || {        
            execute qmake --version
            [ $EXIT_CODE -eq 0 ] && {
                QT_INSTALLS+=("`which qmake`");
                QT_SELECTED=${QT_INSTALLS[0]}
            };
        }
    }
    
    return $EXIT_CODE
}

############################
# COMPILER DETECTION
############################
setcompiler() {
    do_header "CHECKING FOR COMPILER INSTALLATION"
    # Test if the specified compier is present.
    if command -v g++-$GCC_VER &> /dev/null; then
        COMPILER="g++-$GCC_VER"
        C_COMPILER="gcc-$GCC_VER"
    else
        COMPILER="g++"
        C_COMPILER="gcc"
        GCC_VER=
    fi

    # General catch all for gcc detections.
    execute $COMPILER -v 2>/dev/null
    [ $EXIT_CODE -eq 0 ] || {
        do_error "NO GCC COMPILER PRESENT";
    }

    return $EXIT_CODE;
}