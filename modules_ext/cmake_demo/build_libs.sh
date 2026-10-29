#!/usr/bin/env bash

set -Eeuo pipefail

# =============================================================================
# build_libs.sh
#
# Scan child directories and build/install each CMake library found.
#
# A library directory must contain:
#
#   <library>/src/CMakeLists.txt
#
# Usage:
#
#   ./build_libs.sh -p <preset> [-m <path_or_name>]
#
# Examples:
#
#   ./build_libs.sh -p linux-x64-release
#   ./build_libs.sh -p macos-x64-release -m my_library
#   ./build_libs.sh -p macos-x64-release -m ./my_library
#   ./build_libs.sh -b
#   ./build_libs.sh -r -p linux-x64-release
#   ./build_libs.sh -a
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PRESET=""
CMAKE_PATH=""
NINJA_PATH=""
MODULE_PATH=""

HELP=false
LIST_GENERATORS=false
LIST_DIRS=false
LIST_BUILDERS=false
REMOVE_BUILD=false
CLEAN_ALL=false

# Error handling
error_trap()
{
    local exit_code=$?
    local line_number=$1
    local command="$2"

    echo
    echo "ERROR: Command failed."
    echo "       Line:    $line_number"
    echo "       Command: $command"
    echo "       Status:  $exit_code"
    echo

    exit "$exit_code"
}

trap 'error_trap "$LINENO" "$BASH_COMMAND"' ERR

# Functions
show_help()
{
    echo
    echo "Usage: build_libs.sh [options]"
    echo
    echo "Options:"
    echo "  -p, --preset <name>      Set the CMake build preset."
    echo "  -n, --ninja <path>       Set the Ninja Build installation path."
    echo "  -c, --cmake <path>       Set the CMake installation path."
    echo "  -m, --module <path|name> Target a single module directory."
    echo "  -r, --remove             Remove demo_build directories matching preset."
    echo "  -a, --clean              Remove all demo_build directories."
    echo "  -b, --builders           List available CMake presets for target libraries."
    echo "  -g, --generators         List supported CMake generators."
    echo "  -l, --list               List directories containing a CMakeLists.txt file."
    echo "  -h, --help               Display this help."
    echo
}

# Command-line arguments
while [[ $# -gt 0 ]]; do

    case "$1" in

        -p|--preset)

            if [[ $# -lt 2 ]]; then
                echo "ERROR: --preset requires an argument."
                exit 1
            fi

            PRESET="$2"
            shift 2
            ;;

        -c|--cmake)

            if [[ $# -lt 2 ]]; then
                echo "ERROR: --cmake requires an argument."
                exit 1
            fi

            CMAKE_PATH="$2"
            shift 2
            ;;

        -n|--ninja)

            if [[ $# -lt 2 ]]; then
                echo "ERROR: --ninja requires an argument."
                exit 1
            fi

            NINJA_PATH="$2"
            shift 2
            ;;

        -m|--module)

            if [[ $# -lt 2 ]]; then
                echo "ERROR: --module requires an argument."
                exit 1
            fi

            MODULE_PATH="$2"
            shift 2
            ;;

        -r|--remove)

            REMOVE_BUILD=true
            shift
            ;;

        -a|--clean)

            CLEAN_ALL=true
            shift
            ;;

        -b|--builders)

            LIST_BUILDERS=true
            shift
            ;;

        -g|--generators)

            LIST_GENERATORS=true
            shift
            ;;

        -l|--list)

            LIST_DIRS=true
            shift
            ;;

        -h|--help)

            HELP=true
            shift
            ;;

        *)

            echo "ERROR: Unknown option: $1"
            echo
            show_help
            exit 1
            ;;

    esac

done

# Help
if [[ "$HELP" == true ]]; then
    show_help
    exit 0
fi

# Clean all build directories
if [[ "$CLEAN_ALL" == true ]]; then

    echo
    echo "========================================"
    echo " CLEAN ALL BUILD DIRECTORIES"
    echo "========================================"

    for LIBRARY_DIR in "$SCRIPT_DIR"/*; do
        [[ -d "$LIBRARY_DIR" ]] || continue

        # Check if the directory itself or any subdirectory contains CMakeLists.txt
        if find "$LIBRARY_DIR" -type f -name "CMakeLists.txt" -print -quit | grep -q .; then
            BINARY_DIR="${LIBRARY_DIR}/src/demo_build"
            INSTALL_DIR="${LIBRARY_DIR}/demo_build"

            echo "Library: $(basename "$LIBRARY_DIR")"

            if [[ -d "$BINARY_DIR" || -d "INSTALL_DIR" ]]; then
                if [[ -d "$BINARY_DIR" ]]; then rm -rf "$BINARY_DIR"; fi
                if [[ -d "$INSTALL_DIR" ]]; then rm -rf "$INSTALL_DIR"; fi

                if [[ ! -d "$BINARY_DIR" && ! -d "INSTALL_DIR" ]]; then
                    echo "       Build directories removed"
                else
                    if [[ -d "$BINARY_DIR" ]]; then echo "       Failed to remove build directory"; fi
                    if [[ -d "$INSTALL_DIR" ]]; then echo "       Failed to remove output directory"; fi
                fi
            else
                echo "       Already cleaned"
            fi

            echo

        fi
    done

    echo "Cleaning complete."
    echo
    exit 0
fi

# List directories containing CMakeLists.txt
if [[ "$LIST_DIRS" == true ]]; then

    echo
    echo "Directories containing CMakeLists.txt:"
    echo

    found=0
    for dir in "$SCRIPT_DIR"/*/; do
        [[ -d "$dir" ]] || continue

        # Check if the directory itself or any subdirectory contains CMakeLists.txt
        if find "$dir" -type f -name "CMakeLists.txt" -print -quit | grep -q .; then
            basename "$dir"
            found=1
        fi
    done

    if [[ "$found" -eq 0 ]]; then
        echo "  (No directories with CMakeLists.txt found)"
    fi

    echo
    exit 0

fi

# Configure CMake path
if [[ -n "$CMAKE_PATH" ]]; then

    if [[ ! -d "$CMAKE_PATH" ]]; then
        echo "ERROR: CMake directory does not exist:"
        echo "       $CMAKE_PATH"
        exit 1
    fi

    if [[ ! -x "$CMAKE_PATH/bin/cmake" ]]; then
        echo "ERROR: CMake executable was not found:"
        echo "       $CMAKE_PATH/bin/cmake"
        exit 1
    fi

    export PATH="$CMAKE_PATH/bin:$PATH"

fi

# Configure Ninja Build path
if [[ -n "$NINJA_PATH" ]]; then

    if [[ ! -d "$NINJA_PATH" ]]; then
        echo "ERROR: Ninja Build directory does not exist:"
        echo "       $NINJA_PATH"
        exit 1
    fi

    if [[ ! -x "$NINJA_PATH/ninja" ]]; then
        echo "ERROR: Ninja Build executable was not found:"
        echo "       $NINJA_PATH/ninja"
        exit 1
    fi

    export PATH="$NINJA_PATH/bin:$PATH"

fi

if ! command -v cmake >/dev/null 2>&1; then

    echo "ERROR: CMake could not be found."
    echo
    echo "Install CMake or use --cmake to specify its installation path."
    exit 1

fi

# List available presets across libraries
if [[ "$LIST_BUILDERS" == true ]]; then

    echo
    echo "========================================"
    echo " AVAILABLE CMAKE PRESETS"
    echo "========================================"

    TARGET_LIBS=()

    if [[ -n "$MODULE_PATH" ]]; then

        TARGET_DIR=""
        if [[ -d "$MODULE_PATH" ]]; then
            TARGET_DIR="$(cd "$MODULE_PATH" && pwd)"
        elif [[ -d "$SCRIPT_DIR/$MODULE_PATH" ]]; then
            TARGET_DIR="$(cd "$SCRIPT_DIR/$MODULE_PATH" && pwd)"
        else
            echo "ERROR: Specified module directory does not exist: $MODULE_PATH"
            exit 1
        fi

        if [[ -f "$TARGET_DIR/src/CMakeLists.txt" ]]; then
            TARGET_LIBS+=("$TARGET_DIR")
        elif [[ -f "$TARGET_DIR/CMakeLists.txt" ]]; then
            TARGET_LIBS+=("$(dirname "$TARGET_DIR")")
        fi

    else

        for LIBRARY_DIR in "$SCRIPT_DIR"/*; do
            [[ -d "$LIBRARY_DIR" ]] || continue
            if [[ -f "${LIBRARY_DIR}/src/CMakeLists.txt" ]]; then
                TARGET_LIBS+=("$LIBRARY_DIR")
            fi
        done

    fi

    if [[ ${#TARGET_LIBS[@]} -eq 0 ]]; then
        echo "No CMake target libraries found."
        echo
        exit 0
    fi

    for LIBRARY_DIR in "${TARGET_LIBS[@]}"; do
        LIBRARY_NAME="$(basename "$LIBRARY_DIR")"
        SOURCE_DIR="${LIBRARY_DIR}/src"

        echo
        echo "[$LIBRARY_NAME]"

        if [[ -d "$SOURCE_DIR" ]]; then
            (
                cd "$SOURCE_DIR"
                cmake --list-presets 2>&1 || true
            )
        else
            echo "  (No src directory found)"
        fi
    done

    echo
    exit 0

fi

# List generators
if [[ "$LIST_GENERATORS" == true ]]; then

    echo
    echo "Supported CMake Generators:"
    echo

    if ! cmake_help=$(cmake --help 2>&1); then
        echo
        echo "ERROR: Unable to query CMake generators."
        exit 1
    fi

    host_os=$(uname -s)
    allowed_generators=()

    # Define exact allowed generators per host OS
    case "$host_os" in
        Linux)
            allowed_generators=("Ninja" "Unix Makefiles")
            ;;
        Darwin)
            allowed_generators=("Ninja" "Xcode")
            ;;
        *)
            # Fallback for Windows environments
            allowed_generators=("Ninja" "Unix Makefiles" "NMake Makefiles")
            ;;
    esac

    in_generators=0

    while IFS= read -r line; do
        # Detect start of Generators section
        if [[ "$line" == "Generators"* ]]; then
            in_generators=1
            continue
        fi

        if (( in_generators )); then
            if [[ "$line" == *"="* ]]; then
                # Extract generator name (everything before '=')
                gen_name="${line%%=*}"

                # Trim leading spaces and asterisks
                gen_name="${gen_name#"${gen_name%%[! *]*}"}"
                # Trim trailing spaces
                gen_name="${gen_name%"${gen_name##*[! ]}"}"

                # Exact match check against allowed lookup array
                for allowed in "${allowed_generators[@]}"; do
                    if [[ "$gen_name" == "$allowed" ]]; then
                        echo "$gen_name"
                        break
                    fi
                done
            fi
        fi
    done <<< "$cmake_help" | sort -u

    echo
    exit 0

fi

# Validate preset
if [[ -z "$PRESET" && "$CLEAN_ALL" == false ]]; then

    echo "ERROR: A preset is required unless using --clean."
    echo
    echo "Use -p/--preset with one of the available build presets."
    exit 1

fi

# Resolve target libraries
LIBRARIES=()

if [[ -n "$MODULE_PATH" ]]; then

    TARGET_DIR=""

    # 1. Direct path check (absolute or relative path passed)
    if [[ -d "$MODULE_PATH" ]]; then
        TARGET_DIR="$(cd "$MODULE_PATH" && pwd)"
    # 2. Name check relative to SCRIPT_DIR
    elif [[ -d "$SCRIPT_DIR/$MODULE_PATH" ]]; then
        TARGET_DIR="$(cd "$SCRIPT_DIR/$MODULE_PATH" && pwd)"
    else
        echo "ERROR: Specified module directory does not exist:"
        echo "       $MODULE_PATH"
        exit 1
    fi

    # Check for expected structure (<module>/src/CMakeLists.txt)
    if [[ -f "$TARGET_DIR/src/CMakeLists.txt" ]]; then
        LIBRARIES+=("$TARGET_DIR")
    # Alternate check if path directly points to the folder containing CMakeLists.txt
    elif [[ -f "$TARGET_DIR/CMakeLists.txt" ]]; then
        TARGET_DIR="$(dirname "$TARGET_DIR")"
        LIBRARIES+=("$TARGET_DIR")
    else
        echo "ERROR: Target module is missing CMakeLists.txt in either:"
        echo "       $TARGET_DIR/src/CMakeLists.txt"
        echo "   or  $TARGET_DIR/CMakeLists.txt"
        exit 1
    fi

else

    for LIBRARY_DIR in "$SCRIPT_DIR"/*; do

        [[ -d "$LIBRARY_DIR" ]] || continue

        SOURCE_DIR="${LIBRARY_DIR}/src"

        if [[ -f "$SOURCE_DIR/CMakeLists.txt" ]]; then
            LIBRARIES+=("$LIBRARY_DIR")
        fi

    done

fi

if [[ ${#LIBRARIES[@]} -eq 0 ]]; then

    echo "ERROR: No CMake libraries were found."
    echo
    echo "Expected:"
    echo "  <library>/src/CMakeLists.txt"
    echo
    exit 1

fi

# Remove build directory for preset
if [[ "$REMOVE_BUILD" == true ]]; then

    echo
    echo "========================================"
    echo " REMOVE BUILD PRESET DIRECTORIES"
    echo "========================================"
    echo "Preset: $PRESET"
    echo

    for LIBRARY_DIR in "${LIBRARIES[@]}"; do
        LIBRARY_NAME="$(basename "$LIBRARY_DIR")"
        BINARY_DIR="${LIBRARY_DIR}/src/demo_build/${PRESET}"
        INSTALL_DIR="${LIBRARY_DIR}/demo_build/${PRESET}"

        echo "Library: $LIBRARY_NAME"

        if [[ -d "$BINARY_DIR" ]]; then
            echo "  Removing binary path:  $BINARY_DIR"
            rm -rf "$BINARY_DIR"
        else
            echo "  Binary path not found: $BINARY_DIR"
        fi

        if [[ -d "$INSTALL_DIR" ]]; then
            echo "  Removing install path: $INSTALL_DIR"
            rm -rf "$INSTALL_DIR"
        else
            echo "  Install path not found: $INSTALL_DIR"
        fi

        echo
    done

    echo "Removal complete."
    echo
    exit 0

fi

# Determine architecture
HOST_OS=$(uname -s)

if [[ "$HOST_OS" == "Linux" ]]; then
    if [[ "$PRESET" == *"-x86-"* ]]; then

        ARCHITECTURE="x86"

    elif [[ "$PRESET" == *"-x64-"* ]]; then

        ARCHITECTURE="x64"

    else

        echo "ERROR: Unable to determine architecture from preset:"
        echo "       $PRESET"
        echo
        echo "The preset must contain either '-x86-' or '-x64-'."
        exit 1

    fi
else
   if [[ "$PRESET" == *"-arm64-"* ]]; then

        ARCHITECTURE="arm64"

    elif [[ "$PRESET" == *"-intel-"* ]]; then

        ARCHITECTURE="intel"
    
    elif [[ "$PRESET" == *"-universal-"* ]]; then

        ARCHITECTURE="intel"

    else

        echo "ERROR: Unable to determine architecture from preset:"
        echo "       $PRESET"
        echo
        echo "The preset must contain either '-arm64-', or '-intel-', or '-universal-'."
        exit 1

    fi
fi

# Build configuration
BUILD_CONFIG=()

if [[ "$PRESET" =~ ^vs[0-9]+- ]]; then
    BUILD_CONFIG=(--config Release)
fi

# Display build information
echo
echo "========================================"
echo " BUILD LIBRARIES"
echo "========================================"
echo "Preset:       $PRESET"
echo "Architecture: $ARCHITECTURE"
echo "Root:         $SCRIPT_DIR"
echo "Libraries:    ${#LIBRARIES[@]}"
echo "========================================"
echo

BUILT_LIBRARIES=()
SKIPPED_LIBRARIES=()

# Build libraries
for LIBRARY_DIR in "${LIBRARIES[@]}"; do

    LIBRARY_NAME="$(basename "$LIBRARY_DIR")"
    SOURCE_DIR="${LIBRARY_DIR}/src"
    BINARY_DIR="${SOURCE_DIR}/demo_build/${PRESET}"
    INSTALL_DIR="${LIBRARY_DIR}/demo_build/${PRESET}"

    echo
    echo "========================================"
    echo " BUILD: $LIBRARY_NAME"
    echo "========================================"
    echo "Source:       $SOURCE_DIR"
    echo "Build:        $BINARY_DIR"
    echo "Install:      $INSTALL_DIR"
    echo "========================================"
    echo

    # Validate source directory
    if [[ ! -d "$SOURCE_DIR" ]]; then

        echo "ERROR: Source directory does not exist:"
        echo "       $SOURCE_DIR"
        exit 1

    fi

    if [[ ! -f "$SOURCE_DIR/CMakeLists.txt" ]]; then

        echo "ERROR: CMakeLists.txt was not found:"
        echo "       $SOURCE_DIR/CMakeLists.txt"
        exit 1

    fi

    # Validate CMake preset
    PRESET_LIST=""

    if ! PRESET_LIST="$(cd "$SOURCE_DIR" && cmake --list-presets 2>&1)"; then

        echo "WARNING: Unable to list CMake presets for: $LIBRARY_NAME"
        echo "         Skipping build for this module."
        SKIPPED_LIBRARIES+=("$LIBRARY_NAME")
        continue

    fi

    if ! grep -Eq "(^|[[:space:]\"'])${PRESET}([\"']|[[:space:],}]|$)" <<< "$PRESET_LIST"; then

        echo "WARNING: CMake preset '$PRESET' was not found for: $LIBRARY_NAME"
        echo "         Skipping build for this module."
        SKIPPED_LIBRARIES+=("$LIBRARY_NAME")
        continue

    fi

    # Configure
    echo "Configuring..."
    echo

    if ! (
        cd "$SOURCE_DIR"

        cmake \
            --fresh \
            --preset "$PRESET" \
            "-DCMAKE_INSTALL_PREFIX=$INSTALL_DIR"
    ); then

        echo
        echo "ERROR: CMake configuration failed."
        echo "       Library: $LIBRARY_NAME"
        echo "       Preset:  $PRESET"
        echo
        exit 1

    fi

    # Check that the build directory was created
    if [[ ! -d "$BINARY_DIR" ]]; then

        echo
        echo "ERROR: CMake did not create the expected build directory:"
        echo "       $BINARY_DIR"
        exit 1

    fi

    # Build
    echo
    echo "Building..."
    echo

    if ! cmake \
        --build "$BINARY_DIR" \
        "${BUILD_CONFIG[@]}"; then

        echo
        echo "ERROR: Build failed."
        echo "       Library: $LIBRARY_NAME"
        echo "       Preset:  $PRESET"
        echo
        exit 1

    fi

    # Install
    echo
    echo "Installing..."
    echo

    if ! cmake \
        --install "$BINARY_DIR" \
        "${BUILD_CONFIG[@]}"; then

        echo
        echo "ERROR: Installation failed."
        echo "       Library: $LIBRARY_NAME"
        echo "       Preset:  $PRESET"
        echo
        exit 1

    fi

    # Verify installation directory
    if [[ ! -d "$INSTALL_DIR" ]]; then

        echo
        echo "ERROR: Installation completed but the install directory was not found:"
        echo "       $INSTALL_DIR"
        exit 1

    fi

    echo
    echo "BUILD COMPLETE: $LIBRARY_NAME"
    BUILT_LIBRARIES+=("$LIBRARY_NAME")

done

# Complete
echo
echo "========================================"
echo " PROCESS COMPLETE"
echo "========================================"
echo

if [[ ${#BUILT_LIBRARIES[@]} -gt 0 ]]; then
    echo "Built libraries:"
    for lib in "${BUILT_LIBRARIES[@]}"; do
        echo "  $lib"
    done
else
    echo "No libraries were built."
fi

if [[ ${#SKIPPED_LIBRARIES[@]} -gt 0 ]]; then
    echo
    echo "Skipped libraries (Preset '$PRESET' not found):"
    for lib in "${SKIPPED_LIBRARIES[@]}"; do
        echo "  $lib"
    done
fi

echo
