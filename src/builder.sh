#!/bin/bash
# LINUX BASH SCRIPT FOR BUILDING CERBERUS X TOOLS
# THIS IS BASICALLY THE SAME AS THE Z SHELL VERSION, BUT WITH THE MACOS STUFF REMOVED AND EXTRA STUFF TO DEAL WITH LINUX.

# Tried and trusted way to get the absolute path from any bourne type shell.
# $( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )
CERBERUS_ROOT_DIR="$( cd -- "$(dirname "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )")" >/dev/null 2>&1 ; pwd -P )"
CERBERUS_BIN_DIR="$CERBERUS_ROOT_DIR/bin"
CERBERUS_SRC_DIR="$CERBERUS_ROOT_DIR/src"
SCRIPT_VER="2.0.0"      # Version 2. Because it's just about the same as the Linux version.

# Import the dependencies that this script relies on.
source "$CERBERUS_SRC_DIR/builders/linux/common.sh"        # Common functions and variables.

# Only run if running on macOS
[[ ! $(uname -o) == *"Linux"* ]] && {
    do_header "===== Cerberus X Tool Builder Version $SCRIPT_VER ====="
    do_error "This is the Linux version of the builder script. Please use the one meant for your operating system."
    exit 0;
}

source "$CERBERUS_SRC_DIR/builders/linux/thirdparty.sh"    # Third-party functions. Used to get information from compilers and Qt SDKs.
source "$CERBERUS_SRC_DIR/builders/linux/freedesktop.sh"   # Used to install desktop launcher files and setup mime time on the users system. 
source "$CERBERUS_SRC_DIR/builders/linux/deploy.sh"       # Script to create a deployment archive.
source "$CERBERUS_SRC_DIR/builders/linux/tools.sh"         # Functions to build Cerberus.

##################################
# COMMAND LINE ARGUMENT PROCESSING
##################################
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--archiver)
            ARCHIVER="$2"
            shift; shift
        ;;
        --distclean)
            do_header "===== Cerberus X Tool Builder Version $SCRIPT_VER ====="
            do_distclean
            do_success "Cerberus X Builder script terminated."
            exit 0
        ;;
        --clean)
            do_header "===== Cerberus X Tool Builder Version $SCRIPT_VER ====="
            do_clean
            do_success "Cerberus X Builder script terminated."
            exit 0
        ;;
        -p|--pause)
            PAUSE_HALT=1
            shift
        ;;
        -d|--deploypath)
            DEPLOY_PATH="$2"
            BREAK_ON_BUILD_ALL=1
            shift; shift
        ;;
        -q|--qtdir)
            QT_SDK_DIR="$2"
            shift; shift
        ;;
        -k|--qtkit)
            QT_SDK_VERSION="$2"
            shift; shift
        ;;
        -g|--gcc)
            GCC_VER="$2"
        ;;
        -m|--showmenu)
            SHOW_MENU=1
            shift
        ;;
        -i|--icons)
            if [ "$2" != "default" ]; then
                SVG_APP_ICON="$3"
                SVG_MIME_ICON="$4";
                shift; shift
            else
                SVG_APP_ICON=$CERBERUS_ROOT_DIR/share/images/cerberus/svg/Logo.svg
                SVG_MIME_ICON=$CERBERUS_ROOT_DIR/share/images/cerberus/svg/AppIcon.svg
                shift
            fi
            
            # Only generate the icons if both icon files are passed as parameters.
            if [ -f "$SVG_APP_ICON" ] && [ -f "$SVG_MIME_ICON" ]; then
                GEN_ICONS=1
            fi
        ;;
        -h|--help)
            do_info "CERBERUS X TOOLS VERSION $SCRIPT_VER"
            echo "USAGE: ./builder.sh [options]"
            echo -e "\t{-m|--showmenu}\t\t\t\t\t- run in menu mode."
            echo -e "\t{-q|--qtsdk} \"QT_DIR_PATH\"\t\t\t- Set Qt SDK root directory."
            echo -e "\t{-k|--qtkit) \"QT.VERSION.NUM\"\t\t\t- Set Qt SDK version."
            echo -e "\t{-d|--deploypath} \"DEPLOY_DIR\"\t\t\t- Build a deployment archive in the directory passed."
            echo -e "\t{-i|--icons} \"APP_ICON.svg\" \"MIME_ICON.svg\"\t- Generate desktop icons.";
            echo -e "\t{-g|--gcc) \"VERSION\"\t\t\t\t- Set the version of GCC to use."
            echo -e "\t{-p|--pause}\t\t\t\t\t- Pause just before showing the menu to show script configuration setup."
            echo -e "\t--distclean\t\t\t\t\t- Removes all previous built binaries of Cerberus within local repository."
            echo -e "\t--clean\t\t\t\t\t\t- Removes all left over tool build directories."
            echo -e "\t{-h|--help}\t\t\t\t\t- Show usage."
            echo "EXAMPLES:"
            echo -e "\te.g: ./builder.sh -q $HOME/Qt -k 5.14.0 --showmenu --gcc 11"
            echo -e "\te.g: ./builder.sh --qtsdk ~/Qt --qtkit 5.14.0"
            exit 0
        ;;
        -*|--*=) # unsupported flags
            do_error "Error: Unsupported flag $1" >&2
            exit 1
        ;;
        *) # preserve positional arguments
            POSITIONAL_ARGS+=("$1")
            shift
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"  # This should any command line arguments that were not processed

# Check that there is a valid compiler present
setcompiler
[ $EXIT_CODE -eq 1 ] && { exit 1; }

# Check for a Qt installation. Ted will only become a build option if Qt is installed.
do_qtsdk_check

###############
# MENU/DISPLAY
###############
# Set up the menu items. The array DISPLAY_ITEMS, holds the human readable menu items.
# The array MENU_ITEMS, holds the function names to call.
do_items(){
    DISPLAY_ITEMS=("All" "Transcc")
    MENU_ITEMS=("do_all" "do_transcc")
    [ $TRANSCC_EXE -eq 1 ] && {
        DISPLAY_ITEMS+=("CServer" "Makedocs" "Launcher")
        MENU_ITEMS+=("do_cserver" "do_makedocs" "do_launcher")
        DISPLAY_ITEMS+=("Generate Free Desktop Launcher" "Clean tool build directories")
        MENU_ITEMS+=("do_freedesktop" "do_clean");
    }
    [ ${#QT_INSTALLS[@]} -gt 0 ] && {
        DISPLAY_ITEMS+=("IDE Ted")
        MENU_ITEMS+=("do_ted");
    }
    [ -n "$DEPLOY_PATH" ] && {
        DISPLAY_ITEMS+=("Deploy: $DEPLOY_PATH")
        MENU_ITEMS+=("do_deploy");
    }
    DISPLAY_ITEMS+=("Quit")
    MENU_ITEMS+=("do_quit")
}

do_show_deps() {
    [ ${#QT_INSTALLS[@]} -gt 0 ] && {
        do_info "QMAKE Location: $QT_SELECTED";
    } || {
        do_unknown "Qt SDK is not installed.";
    }
    [ -n "$GCC_VER" ] && { do_info "GCC Version: $GCC_VER"; } || { do_info "GCC Standard"; };
}

do_title() {
    clear
    do_header "===== Cerberus X Tool Builder Version $SCRIPT_VER ====="
    do_show_deps
    
    for i in "${!DISPLAY_ITEMS[@]}"; do
        echo "$(($i+1)): ${DISPLAY_ITEMS[$i]}"
    done
}

# Loop for selecting menu options.
[ $SHOW_MENU -eq 1 ] && {

    [[ "$PAUSE_HALT" -eq 1 ]] && {
        read -p "Press any key to continue... " -n1 -s;
    }

    while true; do
        BREAK_ON_BUILD_ALL=0        # In menu mode. This flag needs to be cleared to stop a deployment build when the build menu item is selected.
        # Test to see if transcc has been built.
        [ -f "$CERBERUS_BIN_DIR/transcc_linux" ] && {
            execute $CERBERUS_BIN_DIR/transcc_linux
            [ $EXIT_CODE -eq 0 ] && { TRANSCC_EXE=1; } || { TRANSCC_EXE=0; };
        }
        
        # update the menu and wait for selection.
        do_items
        do_title
        read -p "Select application to build: "
        
        # Only process numbers
        [ -z "${REPLY##*[!0-9]*}" ] || {
            
            # If the value passed is greater than the total size of the selection array; then skip.
            [ $REPLY -gt $((${#MENU_ITEMS[@]})) ] && { continue; }
            
            # Call the required functions based on the option selected.
            [ $REPLY -eq $((${#MENU_ITEMS[@]})) ] && { break; } || {
                do_info "BUILDING ${DISPLAY_ITEMS[$(($REPLY-1))]}"
                ${MENU_ITEMS[$(($REPLY-1))]}
                read -p "Press any key to continue... " -n1 -s;
            }
        }
    done
    
    clear
    do_success "Cerberus X Builder script terminated."
} || {
    do_info "MENU MODE OFF"
    do_show_deps
    do_all
}
