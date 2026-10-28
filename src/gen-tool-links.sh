#!/usr/bin/env bash

# Little developer tool to create links to CMake, Ninja Build, JDK, and Android SDK

CMAKE=""
NINJA=""
JDK=""
ANDROID=""

show_help() {
    echo "Usage: $(basename "$0") {options}"
    echo -e "\t-c, --cmake\tSet the root path for the CMake installation."
    echo -e "\t-n, --ninja\tSet the root path for the Ninja Build binary or directory."
    echo -e "\t-j, --jdk\tSet the root path for the JDK installation."
    echo -e "\t-a, --android\tSet the root path for the Android SDK installation."
    echo -e "\t-h, --help\tShow this help information"
    echo ""
    echo "Known Default Paths Reference:"
    echo "  - macOS JDK:                /Library/Java/JavaVirtualMachines/<version>.jdk/Contents/Home"
    echo "  - Linux JDK:                /usr/lib/jvm/<version>, or /usr/lib/jvm/default-java, or /usr/lib/jvm/default"
    echo "  - macOS Android:            ~/Library/Android/sdk"
    echo "  - Linux Android:            ~/Android/Sdk"
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--cmake) CMAKE="$2"; shift ;;
        -n|--ninja) NINJA="$2"; shift ;;
        -j|--jdk) JDK="$2"; shift ;;
        -a|--android) ANDROID="$2"; shift ;;
        -h|--help) show_help ;;
        *) echo "Unknown parameter: $1"; echo "Use -h or --help for usage."; exit 1 ;;
    esac
    shift
done

# Show help if no arguments are provided
if [ -z "$CMAKE" ] && [ -z "$NINJA" ] && [ -z "$JDK" ] && [ -z "$ANDROID" ]; then
    show_help
fi

# Define paths relative to the script location
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SRC")"

# Link to CMake
if [ -n "$CMAKE" ]; then
    if [ -f "$CMAKE/bin/cmake" ] || [ -f "$CMAKE/cmake" ]; then
        LINK_PATH="$ROOT/CMake"
        if [ -L "$LINK_PATH" ] || [ -d "$LINK_PATH" ]; then
            rm -rf "$LINK_PATH"
            echo "Removed existing link $LINK_PATH"
            echo ""
        fi
        ln -s "$CMAKE" "$LINK_PATH"
        if [ -L "$LINK_PATH" ]; then
            echo "Target: $CMAKE"
            echo "Link: $LINK_PATH"
            echo ""
        fi
    else
        echo "Invalid path to CMake: $CMAKE"
        echo ""
    fi
fi

# Link to Ninja
if [ -n "$NINJA" ]; then
    if [ -f "$NINJA/ninja" ] || [ -f "$NINJA" ]; then
        LINK_PATH="$ROOT/Ninja"
        if [ -L "$LINK_PATH" ] || [ -d "$LINK_PATH" ]; then
            rm -rf "$LINK_PATH"
            echo "Removed existing link $LINK_PATH"
            echo ""
        fi
        ln -s "$NINJA" "$LINK_PATH"
        if [ -L "$LINK_PATH" ]; then
            echo "Target: $NINJA"
            echo "Link: $LINK_PATH"
            echo ""
        fi
    else
        echo "Invalid path to Ninja: $NINJA"
        echo ""
    fi
fi

# Link to JDK
if [ -n "$JDK" ]; then
    JDK="${JDK/#\~/$HOME}"
    if [ -d "$JDK/Contents/Home" ] && [ -f "$JDK/Contents/Home/bin/javac" ]; then
        JDK="$JDK/Contents/Home"
    fi

    if [ -f "$JDK/bin/javac" ] || [ -f "$JDK/bin/java" ]; then
        LINK_PATH="$ROOT/JDK"
        if [ -L "$LINK_PATH" ] || [ -d "$LINK_PATH" ]; then
            rm -rf "$LINK_PATH"
            echo "Removed existing link $LINK_PATH"
            echo ""
        fi
        ln -s "$JDK" "$LINK_PATH"
        if [ -L "$LINK_PATH" ]; then
            echo "Target: $JDK"
            echo "Link: $LINK_PATH"
            echo ""
        fi
    else
        echo "Invalid path to JDK: $JDK"
        echo ""
    fi
fi

# Link to Android SDK (Ensures structure: $ROOT/Android/Sdk)
if [ -n "$ANDROID" ]; then
    ANDROID="${ANDROID/#\~/$HOME}"

    if [ -d "$ANDROID/Sdk/platforms" ] || [ -d "$ANDROID/Sdk/platform-tools" ] || [ -d "$ANDROID/Sdk/cmdline-tools" ] || [ -d "$ANDROID/Sdk/build-tools" ]; then
        LINK_PATH="$ROOT/Android"
 
        if [ -L "$LINK_PATH" ] || [ -d "$LINK_PATH" ]; then
            rm -rf "$LINK_PATH"
            echo "Removed existing link $LINK_PATH"
            echo ""
        fi

        ln -s "$ANDROID" "$LINK_PATH"
        if [ -L "$LINK_PATH" ]; then
            echo "Target: $ANDROID"
            echo "Link: $LINK_PATH"
            echo ""
        fi
    else
        echo "Invalid path to Android SDK: $ANDROID"
        echo "Tip: Make sure it points directly to the SDK folder containing platforms/ and build-tools/."
        echo ""
    fi
fi