
#!/bin/bash

####################################################################
# BASIC SETUP
####################################################################
# Global variables
SOURCE_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"
SCRIPT_ROOT=$SOURCE_ROOT/src
ERROR=0

DATE=`date +%F`
TIME=`date +%T`

COMPANYID="dawlane"
QTVER="5.9.2"
QTSDK="$HOME/Qt"

VERSION=$( date '+%Y-%m-%d' )

ERRORCODE=0
BUILD32=0
QTDEPLOY=0
USE_GIT=0
TARGET=""

# This will hold the options to pass to the compilers
# The order is:
#   [0] C/C++ options [1] C/C++ architecture options [2] Transcc architecture options [3] Architecture as a number
COMPILER_OPTS=()

####################################################################
# FUNCTIONS
####################################################################
function ErrorMSG(){
    if [ ! -z "$2" ]; then echo "" ; fi
    if [ $TARGET = "macos" ]; then echo -e "\033[93;41mERROR: $1\033[49;39m"; else echo -e "\e[93;41mERROR: $1\e[49;39m"; fi
    exit 1
}

function WarnMSG(){
    if [ ! -z "$2" ]; then echo "" ; fi
    if [ $TARGET = "macos" ]; then echo -e "\033[103;30mWARNING: $1\033[49;39m"; else echo -e "\e[103;30mWARNING: $1\e[49;39m"; fi
}

function HeaderMSG(){
    if [ ! -z "$2" ]; then echo "" ; fi
    msg=$(echo $1 | awk '{print toupper($0)}')
    if [ $TARGET = "macos" ]; then echo -e "\n\033[102;30m====== $msg =====\033[49;39m"; else echo -e "\e[102;30m====== $msg =====\e[49;39m"; fi
}

function OkMSG(){
    if [ ! -z "$2" ]; then echo "" ; fi
    if [ $TARGET = "macos" ]; then echo -e "\033[92mOK: $1\033[49;39m"; else echo -e "\e[92mOK: $1\e[49;39m"; fi
}

function HighlightMSG(){
    if [ ! -z "$2" ]; then echo "" ; fi
    if [ $TARGET = "macos" ]; then echo -e "\033[93m$1\033[49;39m"; else echo -e "\e[93m$1\e[49;39m"; fi
}

function ExecuteCMD(){ 
    local cmd=$1
    local args=$2
    if [ ! -z "$3" ]; then echo "" ; fi
    execute="$cmd $args"
    if [ $TARGET = "macos" ]; then echo -e "\033[96mExecuting : $execute\033[49;39m"; else echo -e "\e[96mExecuting : $execute\e[49;39m" ; fi
    eval $execute
    ERROR=$?
    if [ $ERROR -ne 0 ]; then ErrorMSG "Failed to exeucte $1; else OkMSG "Executed $execute; fi
}

function ExitOK(){  
    if [ "$TARGET" = "macos" ]; then echo -e "\033[92mOK: Tasks Completed\033[49;39m"; else echo -e "\e[92mOK: Tasks Completed\e[49;39m"; fi
    exit 0
}

function version_gt(){
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

function ctrl_c() {
    echo ""
    HighlightMSG "Trapped CTRL-C. Exiting."
    cd $SCRIPT_ROOT
    exit 1
}

#WIP: Compress files
function Compress(){  
    local str_destination=$1
    local str_source=$2
    local str_pkgName=$3
    local str_fullName=$(basename "$str_destination")
    local str_extension="${str_fullName##*.}"

    #FILENAME="${FULLNAME%.*}"
    case $str_extension in
        "zip" )
            if type zip > /dev/null; then
                # Use temp directory to create the archvie
                pushd "$str_destination" >/dev/null 2>&1
                #zip -r -D "$str_destination" * -x */.DS_Store -x */.git -x */__MACOSX >/dev/null 2>&1
                #if [ $? -ne 0 ]; then
                #    WarnMSG "Failed to Compress $str_destination file."
                #    else
                #    OkMSG "$str_destination files Compress."
                #fi
                popd
            else
                WarnMSG "The program unzip is not installed."
            fi;;
        "gz" )
            if type tar > /dev/null; then              
                tar -zcvf "$str_destination" -C "$str_source" "$str_pkgName"  >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    WarnMSG "Failed to Compress $str_destination file."
                else
                    OkMSG "$str_destination files Compress."
                fi
            else
                WarnMSG "Program tar not installed. Failed to Compress $str_destination"
            fi;;
        * )
            WarnMSG "Unknown file type. Failed to Compress $str_destination"
        ;;
    esac
}

#WIP: Decompress files
function Decompress(){   
    local str_destination=$1
    local str_source=$2
    local str_fullName=$(basename "$str_source")
    local str_extension="${str_fullName##*.}"
    # FILENAME="${FULLNAME%.*}"

    case $str_extension in
        "zip" )
            if type unzip > /dev/null; then
                if [ ! -d "$str_destination" ]; then mkdir -p "$1"; fi
                
                unzip -o "$str_source" -d "$str_destination" >/dev/null 2>&1
                ERROR=$?
            else
                WarnMSG "The program unzip is not installed."
            fi;;
        "gz" )
            if type tar > /dev/null; then
                if [ ! -d "$str_destination" ]; then mkdir -p "$str_destination"; fi
                tar -xzf "$str_source" -C "$str_destination" >/dev/null 2>&1
                ERROR=$?
            else
                WarnMSG "Program tar not installed. Failed to extract $str_source"
            fi;;
        * )
            WarnMSG "Unknown file type. Failed to extract $str_source"
        ;;
    esac

    if [ $ERROR -ne 0 ]; then
        WarnMSG "Failed to extract $str_source file."
    else
        HighlightMSG "$str_source files extracted."
    fi
}

function ShowHelp(){
    HighlightMSG "Usage:" $1
    HighlightMSG "./rebuildall.sh [-option,--option {path}] [-option,--option {path}]" $1
    echo "        -t | --transcc .................. Build the transcc from Cerberus source."
    echo "        -b | --boot ..................... Build transcc (if not already built)."
    echo "        -l | --launcher ................. Build the cerberus launcher."
    echo "        -d | --makedocs ................. Build the makedocs."
    echo "        -c | --cserver .................. Build the cserver."
    echo "        -e | --ted ...................... Build the Ted IDE."
    echo "        -a | --archives ................. Extract archives."
    echo "        -u | --unsetmods ................ Unset execute permissions for certain files. Mostly added for working with git."
    echo "        --build32 ....................... Build only 32 bit versions of tools."
    echo "        -s | --sharedtrans .............. Build shartrans from source."
    echo "        --dbg ........................... Pass either debug or release as a parameter."
    echo "                                          The default is to build a release binary."
    echo "        --qtsdk \"path_to_tool_chain\" .. This is optional on Linux as you would"
    echo "                                          normally install the repository packages."
    echo "        --qtdeploy ...................... Only for use with Linux to build standalone versions of Ted."
    echo "        --qtversion \"version\".......... Set the version number for the Qt SDK to use. Default is 5.9.2."
    echo "        -g | --git ...................... For use with option -p. Calls git to clone the package and build."
    echo "        -p | --package .................. Create a deployment package. Standard copy for testing."
    echo "        -i | --companyid ................ For Mac OS flat packaging. (default is dawlane)"
    echo "        -h,--help ....................... Show this usage information."
    exit $2
}

function DeleteItem(){
    local str_source=$1

    if [[ -d $str_source ]] || [[ -f $str_source ]]; then
        rm -rf "$str_source"
        ERROR=$?
        if [ $ERROR -eq 0 ]; then OkMSG "Deleted $str_source"; else ErrorMSG "Failed to delete $str_source. Are any files open or permission locked?"; fi
    fi
}

function MoveItem(){
    local str_source=$1
    local str_destination=$2

    if [[ -d $str_source ]] || [[ -f $str_source ]]; then     # check if the source file exists
        if [[ -d $str_destination ]] || [[ -f $str_destination ]]; then DeleteItem "$str_destination"; fi # remove desitnation item
        mv "$str_source" "$str_destination"
        ERROR=$?
        if [ $ERROR -eq 0 ]; then OkMSG "Moved $str_source"; else ErrorMSG "Failed to move $str_source. Are any files open or permission locked?"; fi
    else
        ErrorMSG "$str_source does not exist."
    fi
}

function CopyItem(){ 
    local str_source=$1
    local str_destination=$2

    if [[ -d $str_source ]] || [[ -f $str_source ]]; then     # check if the source file exists
        if [[ -d $str_destination ]] || [[ -f $str_destination ]]; then DeleteItem "$str_destination"; fi # remove destination item
        cp -p "$str_source" "$str_destination"
        ERROR=$?
        if [ $ERROR -eq 0 ]; then OkMSG "Copied $str_source to $str_destination"; else ErrorMSG "Failed to copy $str_source to $str_destination. Are any files open or permission locked?"; fi
    else
        ErrorMSG "$str_source does not exist."
    fi
}

# WIP: Experimental and not implemented, but left here just in case.
function LinuxConfig()
{
    # Detect jdk installation if possible and set the file path
    x="h"
    {
        x=$(type -p javac)
    } >&-
    if [ -n "$x" ]; then
        HighlightMSG "javac detected in system paths"
        _javac=javac
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/javac" ]];  then
        HighlightMSG "javac detected at JAVA_HOME"
        _javac="$JAVA_HOME/bin/javac"
    fi
    if [[ "$_javac" ]]; then
        JDK_VERSION=$("$_javac" -version 2>&1 | awk -F ' ' '/javac/ {print $2}')
        HighlightMSG "JDK $JDK_VERSION"
        ExecuteCMD "$SOURCE_ROOT/src/archives/configs/config.linux.sh" "--jdk_path '${HOME}/jdk'$JDK_VERSION"
        MoveItem "$SOURCE_ROOT/src/config.linux.txt" "$SOURCE_ROOT/bin/config.linux.txt"
    else
        WarnMSG "JDK not found"
        ExecuteCMD "$SOURCE_ROOT/src/archives/configs/config.linux.sh"
        MoveItem "$SOURCE_ROOT/src/config.linux.txt" "$SOURCE_ROOT/bin/config.linux.txt"
    fi
}

# Determine the system and Architecture.
# Positionals params are: target, build 32 bit (Linux only if 64 bit is set up correctly for it)
function Architecture(){ 
    local str_build32=$1
    local str_ccopts=""
    local msize=""
    local msize_opt=""
    local str_arch=""
    local str_nopie=""
    
    case $TARGET in
        "macos" )
            str_ccopts="-Wno-parentheses -Wno-dangling-else -mmacosx-version-min=10.9 -std=gnu++0x -stdlib=libc++";;
        "linux" )
            local str_arch=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
            case $str_build32 in
                1 )
                    echo "This script is running on a $str_arch bit host operating system. The --build32 argument use, so building 32 bit binaries."
                    msize_opt="-m32"; msize=("-msize=32");;
                * )
                    echo "This script is running on a $str_arch bit host operating system, so building $str_arch bit binaries."
                    msize_opt="-m$str_arch"; msize=("-msize=$str_arch");;
            esac

            # Determine the current version of GCC installed.
            local gcc=$(expr `gcc -dumpversion | cut -f1 -d.`)
            if [ $gcc -gt 5 ]; then
                str_nopie="-no-pie"
                HighlightMSG "GCC 6+ detected. Passing the no pie option to GCC."
            fi
            str_ccopts=" $msize_opt $str_nopie -Wno-unused-result";;
    esac
    # Set the global variable to hold the options.
    COMPILER_OPTS=("$str_ccopts" "$msize_opt" "$msize" "$str_arch")
}

# If the config was accidentally deleted
function CheckConfig(){
    local str_srcRoot=$1
    local str_scriptRoot=$2

    if [ ! -f "$str_srcRoot/bin/config.$TARGET.txt" ]; then
        # if [ $TARGET = "linux" ]; then LinuxConfig ; fi
        "$str_scriptRoot"/archives/scripts/configs/config.$TARGET.sh
        WarnMSG "Missing config.$TARGET.txt. A new one was created." "true"
    else
        OkMSG "Found config.$TARGET.txt"
    fi
}

function GeneralInfo(){ 
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local str_config=$3
    local arch=""

    Architecture $TARGET $BUILD32
    HeaderMSG "CERBERUS BUILD SCRIPT" "true"
    HeaderMSG "NO WARRANTIES. USE AT OWN RISK"
    HeaderMSG "STARTED $DATE:$TIME"
    echo "This script is at $str_scriptRoot"
    echo "The Cerberus root directory is at $str_srcRoot"
    if [ ! -z "$QTSDK" ]; then echo "The current path of the Qt SDK is set to: $QTSDK."; fi
    if [ $TARGET = "linux" ]; then
        if [ $BUILD32 -eq 1 ]; then echo "Building 32 bit flag is set."; fi
        if [ $QTDEPLOY -eq 1 ]; then echo "Deploying QT SDK Libraries flag is set."; fi
    fi
    echo "Set to build $str_config versions."
    HeaderMSG "Building for target: $TARGET$ARCH" "true"
}

# Extract back up archive files. Note that files already extracted will be over written.
function Archives(){
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local isStatic=""

    HeaderMSG "Extracting Archive files if any" "true"
    mkdir -p "$str_srcRoot/libs/shared"
    if [ $TARGET = "macos" ]; then mkdir -p "$str_srcRoot/libs/shared/MacOS"; fi
    while read -r -d $'\0'; do
        isStatic=("$REPLY")
        if [[ $isStatic = *"static"* ]]; then
            Decompress "$str_srcRoot/libs/static" "$isStatic"
        else
            Decompress "$str_srcRoot/libs/shared" "$isStatic"
        fi
    done < <(find $str_scriptRoot/archives/libs/$TARGET/*.tar.gz -print0)
    Decompress "$str_srcRoot/libs" "$str_scriptRoot/archives/licences.zip"
    Decompress "$str_srcRoot/src/archives" "$str_scriptRoot/archives/icons.zip"
}

# Initial build from the transcc.build directory
function BootBuild(){  
    local str_srcRoot=$1
    local str_config=$2
    local str_ccopts=${COMPILER_OPTS[0]}
    local str_msize_opt=${COMPILER_OPTS[1]}
    local str_no_pie=${COMPILER[4]}
    local config=""
    if [ $str_config = "release" ]; then
        config="-O3 -DNDEBUG"
        if [ $TARGET = "linux" ]; then config="-s $config"; fi
    else
        config="-g"
    fi

    HeaderMSG "Building boot transcc" "true"
    echo "Please wait"
    if [ $TARGET = "macos" ]; then
        ExecuteCMD "clang++" " $config $str_ccopts -o \"$str_srcRoot/bin/transcc_$TARGET\" transcc/transcc.build/cpptool/main.cpp"
    else
        ExecuteCMD "g++" " $config $str_ccopts $str_msize_opt -o \"$str_srcRoot/bin/transcc_$TARGET\" transcc/transcc.build/cpptool/main.cpp -lpthread"
    fi
}

# Build from Cerberus Source into a transcc.build_new directory.
function BuildTranscc(){ 
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local str_config=$3
    local str_msize=${COMPILER_OPTS[2]}

    ExecuteCMD "$str_srcRoot/bin/transcc_$TARGET" "$str_msize -target=\"C++_Tool\" -builddir=\"transcc.build_new\" -clean -config=\"$str_config\" +CPP_GC_MODE=1 \"transcc/transcc.cxs\""
    if [ -f "$str_scriptRoot/transcc/transcc.build_new/cpptool/main_$TARGET" ]; then
        DeleteItem "$str_srcRoot/bin/transcc_$TARGET"
        MoveItem "$str_scriptRoot/transcc/transcc.build_new/cpptool/main_$TARGET" "$str_srcRoot/bin/transcc_$TARGET"
    else
        ErrorMSG "Failed to build transcc from source."
    fi
}

# Main control for selecting the version of transcc to build. It will always check for a back up and ask if you wish to use it.
function TransccCheck(){
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local str_config=$3

    if [ ! -f "$str_srcRoot/bin/transcc_$TARGET" ]; then
        BootBuild $str_srcRoot $str_config
    else
        HeaderMSG "Building transcc from source" "true"
        echo "Please wait"
        if [ -f "$str_srcRoot/bin/transcc_$TARGET.bak" ]; then
            HighlightMSG "A backup of transcc_$TARGET has been detected. Do you wish to restore to rebuild transcc? Yes/No"
            HighlightMSG "Answering No will replace the backup with the current version of transcc_$TARGET."
            select yn in "Yes" "No"; do
                case $yn in
                    Yes )
                        DeleteItem "$str_srcRoot/bin/transcc_$TARGET"
                        MoveItem "$str_srcRoot/bin/transcc_$TARGET.bak" "$str_srcRoot/bin/transcc_$TARGET"
                        break;;
                    No )
                        DeleteItem "$str_srcRoot/bin/transcc_$TARGET.bak"; break;;
                esac
            done
        fi
        if [ ! -f "$str_srcRoot/bin/transcc_$TARGET.bak" ] && [ -f "$str_srcRoot/bin/transcc_$TARGET" ]; then
            CopyItem "$str_srcRoot/bin/transcc_$TARGET" "$str_srcRoot/bin/transcc_$TARGET.bak"
        fi
        BuildTranscc $str_srcRoot $str_scriptRoot $str_config
        chmod 0775 "$str_srcRoot/bin/transcc_$TARGET"
    fi
}

function BuildMakedocs(){
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local str_config=$3
    local str_msize=${COMPILER_OPTS[2]}

    HeaderMSG "Building makedocs" "true"
    DeleteItem "$str_scriptRoot/makedocs/makedocs.build"
    ExecuteCMD "$str_srcRoot/bin/transcc_$TARGET" "$str_msize -target=C++_Tool -builddir=\"makedocs.build\"  -clean -config=$str_config +CPP_GC_MODE=1 \"$str_scriptRoot/makedocs/makedocs.cxs\""
    # If all went OK, then move the result over to the bin directory
    MoveItem  "$str_scriptRoot/makedocs/makedocs.build/cpptool/main_$TARGET" "$str_srcRoot/bin/makedocs_$TARGET"
    chmod 0775 "$str_srcRoot/bin/makedocs_$TARGET"
    DeleteItem "$str_scriptRoot/makedocs/makedocs.build"
}

function BuildSharedtrans(){ 
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local str_config=$3
    
    local str_msize=${COMPILER_OPTS[2]}

    HeaderMSG "Building sharedtrans" "true"
    DeleteItem "$str_scriptRoot/sharedtrans/sharedtrans.build"
    ExecuteCMD "$str_srcRoot/bin/transcc_$TARGET" "$str_msize -target=C++_Tool -builddir=\"sharedtrans.build\"  -clean -config=$str_config +CPP_GC_MODE=0 \"$str_scriptRoot/sharedtrans/sharedtrans.cxs\""
    # If all went OK, then move the result over to the bin directory
    MoveItem  "$str_scriptRoot/sharedtrans/sharedtrans.build/cpptool/sharedtrans_$TARGET" "$str_srcRoot/bin/sharedtrans_$TARGET"
    chmod 0775 "$str_srcRoot/bin/sharedtrans_$TARGET"
    DeleteItem "$str_scriptRoot/sharedtrans/sharedtrans.build"
}

function BuildCServer(){   
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local str_config=$3
    local str_msize=${COMPILER_OPTS[2]}
    local str_arch=${COMPILER_OPTS[3]}

    HeaderMSG "Building cserver" "true"
    DeleteItem "$str_scriptRoot/cserver/cserver.build"
    ExecuteCMD "$str_srcRoot/bin/transcc_$TARGET" "$str_msize -target=\"Desktop_Game_(Glfw3)\" -builddir=\"cserver.build\" -clean -config=$str_config +CPP_GC_MODE=1 \"$str_scriptRoot/cserver/cserver.cxs\""

    # Copy over to the bin directory
    if [ $TARGET = "macos" ]; then
    # MAC OS Checks
        # Clear out the old and in with the new
        DeleteItem "$str_srcRoot/bin/cserver_$TARGET.app"
        MoveItem  "$str_scriptRoot/cserver/cserver.build/glfw3/xcode/build/Release/cserver_$TARGET.app" "$str_srcRoot/bin/cserver_$TARGET.app"
        chmod 0775 -R "$str_srcRoot/bin/cserver_$TARGET.app" # lazy way of changing the file mode
    else
    # LINUX Checks
        if [ ! -f "$str_scriptRoot/cserver/cserver.build/glfw3/gcc_$TARGET/Release$str_arch/cserver_$TARGET" ]; then ErrorMSG "Failed to build cserver!"; fi

        # If all went OK, then move the result over to the bin directory
        DeleteItem "$str_srcRoot/bin/cserver_$TARGET"
        MoveItem  "$str_scriptRoot/cserver/cserver.build/glfw3/gcc_$TARGET/Release$str_arch/cserver_$TARGET" "$str_srcRoot/bin/cserver_$TARGET"
        chmod 0775 "$str_srcRoot/bin/cserver_$TARGET"

        # Make sure that there is a data directory that contains the mojo_font.png
        mkdir -p "$str_srcRoot/bin/data"
        CopyItem "$str_scriptRoot/cserver/cserver.build/glfw3/gcc_$TARGET/Release$str_arch/data/mojo_font.png" "$str_srcRoot/bin/data/mojo_font.png"
    fi

     # Clean up
    DeleteItem "$str_scriptRoot/cserver/cserver.build"
}

function BuildLauncher(){ 
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local str_config=$3
    local str_msize=${COMPILER_OPTS[2]}

    HeaderMSG "Building application launcher" "true"
    DeleteItem "$str_scriptRoot/launcher/launcher.build"
    
           
    # Copy over to the bin directory
    if [ $TARGET = "macos" ]; then
    # MAC OS Checks

        # Create an Apple OS X Application Bundle
        HeaderMSG "Making OS X bundle"
        ExecuteCMD "xcodebuild" "-project \"$str_scriptRoot/launcher/xcode/cerberus-launcher/Cerberus.xcodeproj\" -configuration Release"
        DeleteItem "$str_srcRoot/Cerberus.app"
        MoveItem "$str_scriptRoot/launcher/xcode/cerberus-launcher/Build/Release/Cerberus.app" "$str_srcRoot/Cerberus.app"
        DeleteItem "$str_scriptRoot/launcher/xcode/cerberus-launcher/Build"
        chmod 0775 -R "$str_srcRoot/Cerberus.app"
    else
        # LINUX CHECK Checks
        ExecuteCMD "$str_srcRoot/bin/transcc_$TARGET" "$str_msize -target=C++_Tool -builddir=launcher.build -clean -config=$str_config +CPP_GC_MODE=1 \"$str_scriptRoot/launcher/launcher.cxs\""
        DeleteItem "$str_srcRoot/Cerberus"
        MoveItem "$str_scriptRoot/launcher/launcher.build/cpptool/main_$TARGET" "$str_srcRoot/Cerberus"
        chmod 0775 "$str_srcRoot/Cerberus"
    fi

    # Clean up
    DeleteItem "$str_scriptRoot/launcher/launcher.build"
}

function BuildTed(){ 
    local str_srcRoot=$1
    local str_scriptRoot=$2
    local str_config=$3
    local str_msize=${COMPILER_OPTS[3]}

    HeaderMSG "Building TED as configuration of $str_config" "true"
    if [ qmake 2>/dev/null ];then
        QMAKE_VERSION=`qmake --version | sed -n 2p | awk '{ print $4 }'`
        HighlightMSG "Current version of Qt is $QMAKE_VERSION."
       # if [ $TARGET = "linux" ]; then HighlightMSG "Ted requires a version of Qt with webkit. The last version to support it was Qt 5.5.1."; fi
    else
        ErrorMSG "Unable to locate qmake. Is Qt installed and the paths correctly set."
    fi

    if [ -d "$str_scriptRoot/build-ted-Desktop" ]; then rm -rf "$str_scriptRoot/build-ted-Desktop"; fi
    mkdir -p "$str_scriptRoot/build-ted-Desktop"
    cd "$str_scriptRoot/build-ted-Desktop"

    if [ $TARGET = "macos" ]; then
    # MAC OS
        DeleteItem "$str_srcRoot/bin/Ted.app"
        HighlightMSG "Running QMake...."
        ExecuteCMD "qmake" "CONFIG+=$str_config $str_scriptRoot/ted/ted.pro"
        HighlightMSG "Building....."
        ExecuteCMD "make"

        # Deploy
        HeaderMSG "Deploying Qt Dependencies" "true"
        ExecuteCMD "macdeployqt" "$str_srcRoot/bin/Ted.app -verbose=2 -always-overwrite"
        declare -a qtdylib=('audio' 'bearer' 'imageformats' 'mediaservice' 'printsupport' 'sqldrivers')
        for i in "${qtdylib[@]}"
        do
            rm -rf "$str_srcRoot/bin/Ted.app/Contents/PlugIns/$i"
        done
        chmod 0775 -r "$str_srcRoot/bin/Ted.app"
    else
    # LINUX
        HighlightMSG "Running QMake...."
        ExecuteCMD "qmake" "CONFIG+=$str_config $str_scriptRoot/ted/ted.pro"
        HighlightMSG "Building....."
        ExecuteCMD "make"
        # Deploy packages to make as standalone. See Ted project file (Ted.pro)
        HeaderMSG "Deploying Qt libraries" "true"
        if [ $QTDEPLOY -eq 1 ]; then
            ExecuteCMD "make" "install"
        fi
        chmod 0775 "$str_srcRoot/bin/Ted"
        if [ -f "$str_srcRoot/bin/libexec/QtWebEngineProcess" ]; then chmod 0775 "$str_srcRoot/bin/libexec/QtWebEngineProcess"; fi
    fi
    cd "$str_scriptRoot"
    DeleteItem "$str_scriptRoot/build-ted-Desktop"
}

# Make sure that file permissions are set
function SetMods(){
    local str_srcRoot=$1
    chmod 0775 $str_srcRoot/targets/android/template/gradletemplate/gradlew
    find $str_srcRoot/src/archives/scripts/configs -name '*.sh' -exec chmod 775 {} \;
    find $str_srcRoot/src/archives/scripts/macos_install -type f -exec chmod 775 {} \;
}

# unset execution file permissions
function UnsetMods(){
    local str_srcRoot=$1
    chmod -x $str_srcRoot/targets/android/template/gradletemplate/gradlew
    chmod -x $str_srcRoot/src/rebuildall.sh
    find $str_srcRoot/src/archives/scripts/configs -name '*.sh' -exec chmod 644 {} \;
    find $str_srcRoot/src/archives/scripts/macos_install -type f -exec chmod 644 {} \;
}

function PkgCopy(){
    local str_source=$1
    local str_destination=$2

    if [ $TARGET == "macos" ]; then
        type rsync >/dev/null 2>&1 || { echo >&2 "The application rsync is not installed. Install either macports, fink or homebrew.  Aborting."; exit 1; }
    else
        type rsync >/dev/null 2>&1 || { echo >&2 "The application rsync in not installed. Use your package manager to install.  Aborting."; exit 1; }
    fi

    SWITCH="aqog"
    if [ $TARGET = "macos" ]; then
        EXCLUDE_LIBS_LINUX=("--exclude=*static/Linux*" "--exclude=*shared/Linux*")
        EXCLUDE_BIN=("--exclude=*.dSYM --exclude=Ted" "--exclude=qt.conf" "--exclude=*.bak" "--exclude=*.txt" "--exclude=*_linux" "--exclude=*.exe" "--exclude=*.dll" "--exclude=*.ini" "--exclude=*plugins" "--exclude=*platforms" "--exclude=*libexec" "--exclude=*lib" "--exclude=*resources" "--exclude=*translations" "--exclude=*data")
    else
        EXCLUDE_LIBS_MACOS=("--exclude=*/shared/MacOS" "--exclude=*static/macos*")
        EXCLUDE_BIN=("--exclude=*.dSYM --exclude=*.exe" "--exclude=*.dll" "--exclude=*.app" "--exclude=*.ini")
    fi
    EXCLUDE_COMMON=("--exclude=.*" "--exclude=.*/" "--exclude=ted*.ini")
    EXCLUDE_BUILDS=("--exclude=*/obj" "--exclude=*obj" "--exclude=*.bak" "--exclude=Release32" "--exclude=Release64" "--exclude=*.buildv20*")
    EXCLUDE_PRJ=("--exclude=*.depend" "--exclude=*.layout" "--exclude=*.pro.user*")
    EXCLUDE_WIN=("--exclude=*.suo" "--exclude=*.VC.db" "--exclude=*.vcxproj.user" "--exclude=*.ikl" "--exclude=*.pbd" "--exclude=*.aps")
    EXCLUDE_LIBS_WIN=("--exclude=*static/Mingw*" "--exclude=*static/VisualStudio*" "--exclude=*shared/Win*")

    # Copy over the normal standard stuff. Use rsync as it should update files on the fly if they need updating.
    HighlightMSG "Copying over common files."
    rsync -$SWITCH "$str_source"/*.TXT "$str_destination"
    rsync -$SWITCH "$str_source"/UPDATE.TXT "$str_destination"/UPDATE.TXT
    rsync -$SWITCH "$str_source"/*.md "$str_destination"
    rsync -$SWITCH "$str_source"/bin/themes "$str_destination"/bin
    rsync -$SWITCH "$str_source"/bin/templates "$str_destination"/bin

    # docs
    HighlightMSG "Copying over documentation files."
    rsync -$SWITCH ${EXCLUDE_COMMON[*]} --exclude=*/html "$str_source"/docs "$str_destination"

    # modules
    HighlightMSG "Copying over modules_ext files."
    rsync -$SWITCH ${EXCLUDE_COMMON[*]} ${EXCLUDE_PRJ[*]} ${EXCLUDE_BUILDS[*]} "$str_source"/modules_ext "$str_destination"
    HighlightMSG "Copying over modules files."
    rsync -$SWITCH ${EXCLUDE_COMMON[*]} ${EXCLUDE_PRJ[*]} ${EXCLUDE_BUILDS[*]} "$str_source"/modules "$str_destination"

    # targets
    HighlightMSG "Copying over targets files."
    rsync -$SWITCH ${EXCLUDE_COMMON[*]} ${EXCLUDE_PRJ[*]} ${EXCLUDE_BUILDS[*]} ${EXCLUDE_WIN[*]} "$str_source"/targets "$str_destination"

    # examples
    HighlightMSG "Copying over example files."
    rsync -$SWITCH ${EXCLUDE_COMMON[*]} ${EXCLUDE_PRJ[*]} ${EXCLUDE_BUILDS[*]} ${EXCLUDE_WIN[*]} "$str_source"/examples "$str_destination"

    # src --exclude="*pkg.plist"
    HighlightMSG "Copying over source files."
    rsync -$SWITCH ${EXCLUDE_COMMON[*]} ${EXCLUDE_PRJ[*]} ${EXCLUDE_BUILDS[*]} ${EXCLUDE_WIN[*]} "$str_source"/src "$str_destination"

    # OS specific stuff in the bin directory
    case $TARGET in
        "macos" )
            # libs
            HighlightMSG "Copying over library files."
            rsync -$SWITCH ${EXCLUDE_COMMON[*]} ${EXCLUDE_LIBS_LINUX[*]} ${EXCLUDE_LIBS_WIN[*]} --exclude=*/obj ${EXCLUDE_WIN[*]} "$str_source"/libs "$str_destination"
            
            # bin
            HighlightMSG "Copying over binraries files."
            rsync -$SWITCH --include=*_$TARGET --include=*.$TARGET.txt --include=docstyle.txt ${EXCLUDE_BIN[*]} "$str_source"/bin "$str_destination"
            # Put back missing stuff.
            rsync -$SWITCH "$str_source"/bin/Ted.app/Contents/MacOS/Ted "$str_destination"/bin/Ted.app/Contents/MacOS
            rsync -$SWITCH "$str_source"/bin/Ted.app/Contents/Plugins "$str_destination"/bin/Ted.app/Contents
            rsync -$SWITCH "$str_source"/bin/Ted.app/Contents/Resources/qt.conf "$str_destination"/bin/Ted.app/Contents/Resources
            rsync -$SWITCH "$str_source"/bin/cserver_macos.app/Contents/Resources/data "$str_destination"/bin/cserver_macos.app/Contents/Resources
            rsync -$SWITCH "$str_source"/Cerberus.app "$str_destination"
            ;;
        "linux" )
            # libs
            HighlightMSG "Copying over library files."
            rsync -$SWITCH ${EXCLUDE_COMMON[*]} ${EXCLUDE_LIBS_MACOS[*]} ${EXCLUDE_LIBS_WIN[*]} --exclude=*/obj ${EXCLUDE_WIN[*]}  "$str_source"/libs "$str_destination"
            
            # bin
            HighlightMSG "Copying over binraries files."
            rsync -$SWITCH --include="*_$TARGET" --include=*.$TARGET.txt ${EXCLUDE_BIN[*]} --include=docstyle.txt --include=*/ --exclude=* "$str_source"/bin "$str_destination"
            rsync -$SWITCH "$str_source"/bin/data "$str_destination"/bin
            if [ $QTDEPLOY -eq 1 ]; then
                rsync -$SWITCH "$str_source"/bin/lib "$str_destination"/bin
                rsync -$SWITCH --exclude=*.dll --exclude=*.DLL --include=*.so "$str_source"/bin/plugins "$str_destination"/bin
                rsync -$SWITCH "$str_source"/bin/libexec "$str_destination"/bin
                rsync -$SWITCH "$str_source"/bin/resources "$str_destination"/bin
                rsync -$SWITCH "$str_source"/bin/translations "$str_destination"/bin
                rsync -$SWITCH "$str_source"/bin/qt.conf "$str_destination"/bin
            else
                rm -rf "$str_destination"/bin/lib
                rm -rf "$str_destination"/bin/libexec
                rm -rf "$str_destination"/bin/resources
                rm -rf "$str_destination"/bin/translations
                rm -rf "$str_destination"/bin/qt.conf
                rm -rf "$str_destination"/bin/platforms
                rm -rf "$str_destination"/bin/plugins
            fi
            rsync -$SWITCH "$str_source"/bin/Ted "$str_destination"/bin
            rsync -$SWITCH "$str_source"/bin/data "$str_destination"/bin
            rsync -$SWITCH "$str_source"/Cerberus "$str_destination"
            ;;
    esac
}

function Package(){
    local str_srcRoot=$1
    local str_pkgName=$2
    local str_deployRoot="$HOME/Documents/cerbdeploy"
    local str_pkgApple="$str_deployRoot/Applications"
    local pkgName=""

    HeaderMSG "CREATING DEPLOYMENT PACKAGE FOR $TARGET" "true"
    
    # Clear out the old cerbdeploy of it exists.
    if [ -d "$str_deployRoot" ]; then DeleteItem "$str_deployRoot"; fi

    if [ $TARGET = "macos" ]; then
        
        # Get the actual directory name for Cerberus if one wasn't passed
        if [ -z "$str_pkgName" ]; then pkgName=`basename $str_srcRoot`; else pkgName=$str_pkgName; fi

        # First thing to do is to create a root directory and copy over the files
        mkdir -p "$str_pkgApple/$pkgName"
        PkgCopy $str_srcRoot "$str_pkgApple/$pkgName"
        
        # Change the PKGID to suit you own needs
        local str_pkgID="com.$COMPANYID.$pkgName"

        # Copy and edit a post install script.
        mkdir -p "$str_deployRoot/scripts"
        CopyItem "$str_srcRoot/src/archives/scripts/macos_install/postinstall.sh" "$str_deployRoot/scripts/postinstall"
        sed -i -e "s#{FOLDER}#$pkgName#g" "$str_deployRoot/scripts/postinstall"
        DeleteItem "$str_deployRoot/scripts/postinstall-e"

        # Analyze the files.
        pkgbuild --analyze --identifier $str_pkgID --ownership preserve --root "$str_deployRoot" pkg.plist
        plutil -replace BundleIsRelocatable -bool false pkg.plist
        pkgbuild --scripts "$str_deployRoot/scripts" --component-plist pkg.plist --version $VERSION --identifier $str_pkgID --ownership preserve --root "$str_deployRoot" "$str_deployRoot"/"$pkgName"-"$TARGET"-$VERSION.pkg
        #DeleteItem "$PACKAGEROOT"
        DeleteItem "pkg.plist"
    else

        # Get the actual directory name for Cerberus if one wasn't passed
        if [ -z "$str_pkgName" ]; then pkgName=`basename $str_srcRoot`; else pkgName=$str_pkgName; fi
        # First thing to do is to create a root directory and copy over the files
        mkdir -p "$str_deployRoot/build/$pkgName"
        PkgCopy "$str_srcRoot" "$str_deployRoot/build/$str_pkgName"
        Compress "$str_deployRoot/$pkgName-$TARGET-$VERSION.tar.gz" "$str_deployRoot/build" "$pkgName"
    fi
}

function GitBuild(){ 
    local str_srcRoot=$1
    local str_pkgName=$2
    local args=("${@:3}")   # To get the parameters that we need do a bit of arrary slicing.
    local output=""
    local cloneDir="$HOME/Documents/cerbclone"
    local cmdline=""

    HeaderMSG "CHECKING REPOSITORY STATE" "true"
    if output=$(git status --porcelain) && [ -z "$output" ]; then
        OkMSG "Repostiory is clean."
    else 
        ErrorMSG "Uncommited changes in repository. Use you favourite git to to check."
    fi

    HeaderMSG "CLONING TO $cloneDir"
    cwd=$(pwd)                                      # Save the current directory
    DeleteItem $cloneDir                # Remove any old clone directory before making a new one.
    mkdir -p "$cloneDir"
    cd "$cloneDir"                                  # change into the cloning directory
    git clone $str_srcRoot $str_pkgName
    cd "$cloneDir/$str_pkgName/src"                 # Change into the clones src directory

    HeaderMSG "Switched in to $cloneDir"
    chmod 0775 rebuildall.sh
    ./rebuildall.sh ${args[@]}
    if [ ! $? -eq 0 ]; then ErrorMSG "Failed to builld clone."; fi
    cd $cwd
    Package "$cloneDir/$str_pkgName" $str_pkgName
    HeaderMSG "Switched back to $SOURCE_ROOT" "true"
}

# Create a back  distribution package.
function BuildPackage(){ 
    local str_srcRoot=$1
    local str_pkgName=$2
    local args=("${@:3}")   # To get the parameters that we need do a bit of arrary slicing.
    local pkgName=""
    local str_deployRoot="$HOME/Documents/cerbdeploy"
    
    # Get the actual directory name for Cerberus if one wasn't passed
    if [ -z "$str_pkgName" ]; then pkgName=`basename "$str_srcRoot"`; else pkgName="$str_pkgName"; fi

    # First thing to do is to create a root directory and copy over the files
    if [ $USE_GIT -eq 1 ]; then
        GitBuild "$str_srcRoot" $pkgName ${args[@]}
    else
        HeaderMSG "Creating test package" "true"
        if [ -d "$str_deployRoot" ]; then DeleteItem "$str_deployRoot"; fi
        mkdir -p "$str_deployRoot/$pkgName"
        HighlightMSG "Created at $str_deployRoot/$pkgName"
        PkgCopy "$str_srcRoot" "$str_deployRoot/$pkgName"
    fi
}

function CheckQtSDK(){
    # Set the location for the Qt SDK
    if [ ! -z "$QTSDK" ]; then
        if [ ! -f "$QTSDK/qmake" ]; then
            # Default loactions for Qt5
            if [ $TARGET = "macos" ]; then
                QTSDK="$QTSDK/$QTVER/clang_64"
            else
                QTSDK="$QTSDK/$QTVER/gcc_64"
            fi
        fi
        export PATH="$QTSDK:$QTSDK/bin:$PATH"
    else
        # The default location of where Qt is usually suggested on MacOSX
        if [ -d "$HOME/Qt/$QTVER" ]; then QTSDK=$HOME/Qt/$QTVER; fi
        if [ $TARGET = "macos" ]; then
            if [ -z "$QTSDK" ]; then ErrorMSG "A Qt SDK path must be be entered for building Ted."; fi
            QTSDK="$QTSDK/clang_64"
            export QTDIR=$QTSDK
            export PATH="$QTSDK:$QTSDK/bin:$PATH"
        else
            if [ ! -z "$QTSDK" ]; then
                QTSDK="$QTSDK/gcc_64"
                export QTDIR=$QTSDK
                export PATH="$QTSDK:$QTSDK/bin:$PATH"
            else
                WarnMSG "A Qt SDK not set. Falling back to system systems default for building Ted."
            fi
        fi
    fi
}

# Parse command line arguments.
function ParseCMDLine(){
    declare -a EXEC_CMDS                                            # Empty array to hold all commands
    local str_config="release"
    local cmd=$*

    # Process command line
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            "-t" | "--transcc")
                if [[ ! "${EXEC_CMDS[@]}" =~ '2transcc' ]]; then EXEC_CMDS+=('2transcc'); fi
                shift;;
            "-b" | "--boot")
                if [[ ! "${EXEC_CMDS[@]}" =~ '2boot' ]]; then EXEC_CMDS+=('2boot'); fi
                shift;;
            "-d" | "--makedocs")
                if [[ ! "${EXEC_CMDS[@]}" =~ '4makedocs' ]]; then EXEC_CMDS+=('4makedocs'); fi
                shift;;
            "-c" | "--cserver")
                if [[ ! "${EXEC_CMDS[@]}" =~ '5cserver' ]]; then EXEC_CMDS+=('5cserver'); fi
                shift;;
            "-e" | "--ted")
                if [[ ! "${EXEC_CMDS[@]}" =~ '7ted' ]]; then EXEC_CMDS+=('7ted'); fi
                shift;;
            "-l" | "--launcher")
                if [[ ! "${EXEC_CMDS[@]}" =~ '6launcher' ]]; then EXEC_CMDS+=('6launcher'); fi
                shift;;
            "-a" | "--archives" )
                if [[ ! "${EXEC_CMDS[@]}" =~ '1archives' ]]; then EXEC_CMDS+=('1archives'); fi
                shift;;
            "-q" | "--qtsdk" )
                QTSDK=$2
                if [ -z "$QTSDK" ]; then ErrorMSG "QtSDK path not defined!"; fi
                shift; shift;;
            "--qtversion" )
                QTVER=$2
                shift;shift;;
            "--build32" )
                BUILD32=1
                shift;;
            "-s" | "--sharedtrans" )
                if [[ ! "${EXEC_CMDS[@]}" =~ '3sharedtrans' ]]; then EXEC_CMDS+=('3sharedtrans'); fi
                shift;;
            "--dbg" )
                str_config="debug"
                shift;;
            "--qtdeploy" )
                QTDEPLOY=1
                shift;;
            "-g" | "--usegit" )
                USE_GIT=1
                shift;;
            "-p" | "--package" )
                if [[ ! "${EXEC_CMDS[@]}" =~ '8package' ]]; then EXEC_CMDS+=('8package' "$2"); fi
                shift; shift;;
            "-h" | "--help" )
                ShowHelp $TARGET
                exit 1;;
            "-u" | "--unsetmods" )
                UnsetMods "$SOURCE_ROOT"
                exit 0;;
            "-i" | "--companyid" )
                COMPANYID=$2
                if [ -z "$COMPANYID" ]; then ErrorMSG "A company name is required as part of the flat package bundle id."; fi
                shift; shift;;
            * )
                ErrorMSG "Invalid parameter passed $key" 0
                shift;;
        esac
    done

    CheckQtSDK
    GeneralInfo "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
    HighlightMSG "Command line ./rebuildall.sh $cmd"
    CheckConfig "$SOURCE_ROOT" "$SCRIPT_ROOT"

    # sort the build order.
    IFS=$'\n' EXEC_CMDS=($(sort <<<"${EXEC_CMDS[*]}"))
    unset IFS
    if [ ${#EXEC_CMDS[@]} -gt 0 ]; then
        local index=0
        while [ $index -lt ${#EXEC_CMDS[@]} ] 
        do
            case ${EXEC_CMDS[$index]} in
                "2transcc")
                    TransccCheck "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
                    index=$[$index+1];;
                "2boot")
                    BootBuild "$SOURCE_ROOT" "$str_config"
                    index=$[$index+1];;
                "4makedocs")
                    BuildMakedocs "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
                    index=$[$index+1];;
                "5cserver")
                    BuildCServer "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
                    index=$[$index+1];;
                "6launcher")
                    BuildLauncher "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
                    index=$[$index+1];;
                "7ted")
                    BuildTed "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
                    index=$[$index+1];;
                "1archives")
                    Archives "$SOURCE_ROOT" "$SCRIPT_ROOT"
                    index=$[$index+1];;
                "8package")
                    local cmdline=('--archives' '--transcc' '--sharedtrans' '--makedocs'  '--cserver' '--launcher' '--ted' '--qtsdk' "$QTSDK" '--qtversion' "$QTVER"  )
                    if [ $BUILD32 -eq 1 ]; then cmdline+=("--build32"); fi
                    if [ $QTDEPLOY -eq 1 ]; then cmdline+=("--qtdeploy"); fi
                    if [ $TARGET = "macos" ]; then cmdline+=('--companyid' "$COMPANYID"); fi
                    index=$[$index+1]
                    BuildPackage "$SOURCE_ROOT" "${EXEC_CMDS[$index]}" ${cmdline[@]}
                    index=${#EXEC_CMDS[@]};;
                "3sharedtrans")
                    BuildSharedtrans "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
                    index=$[$index+1];;
            esac
        done
    else
        Archives "$SOURCE_ROOT" "$SCRIPT_ROOT"
        TransccCheck "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
        BuildSharedtrans "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
        BuildMakedocs "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
        BuildCServer "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
        BuildLauncher "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
        BuildTed "$SOURCE_ROOT" "$SCRIPT_ROOT" "$str_config"
    fi
    ExitOK
}
############################################################
# MAIN CONTROL
############################################################
trap ctrl_c INT

TARGET=$(uname -s | awk '{print tolower($0)}')        # Workout what system this script is running on.
if [ $TARGET = "darwin" ]; then TARGET="macos"; printf '\033\143'; else echo -e '\0033\0143'; fi    # If it's MacOS X, then set then name to macos
SetMods "$SOURCE_ROOT"
ParseCMDLine "$@"

exit 0
