# Little developer tool to create links to mingw32, mingw64, Ninja Build, CMake, JDK, and Android SDK

# NOTES:
# This script requires that the execution policy for the current user be set to unrestricted.
# Open power shell as administrator and use:
#    get-executionpolicy -list
#    set-executionpolicy -scope currentuser unrestricted
# If the file is still blocked use:
#    unblock-file -path "full_path_to_this_script"
# You should reset the execution policy back to it's original state e.g.:
#    set-executionpolicy -scope currentuser undefined
#

param(
    [string]$mingw64 = "",
    [string]$mingw32 = "",
    [string]$cmake = "",
    [string]$ninja = "",
    [string]$vendor = "mingw",
    [string]$android = "",
    [string]$jdk = "",
    [Alias("h")][switch]$help = $false 
)

if(($help)-or($PSBoundParameters.Count -eq 0)){
    write-host "Usage: gen-tool-links.ps1 {options}"
    write-host "`t-mingw32`t- Set the root path for the MinGW 32 bit installation."
    write-host "`t-mingw64`t- Set the root path for the MinGW 64 bit installation."
    write-host "`t-cmake`t`t- Set the root path for the CMake installation."
    write-host "`t-ninja`t`t- Set the root path for the Ninja Build binary."
    write-host "`t-androidSdk`t`t- Set the root path for Android Sdk."
    write-host "`t-openJdk`t`t- Set the root path for JDK."
    write-host "`t-vendor`t`t- Set the prefix name for the MinGW vendor. Default is mingw"
    write-host "`t{-h|-help}`t- Show this help information"
    exit 0
}

[string]$SRC = "$PSScriptRoot"
[string]$ROOT = Resolve-Path "$SRC\.."

# Link to a MinGW x64 compiler
if(-not([string]::IsNullOrEmpty($mingw64))){
    
    # Check that the compiler points to known file in a MinGW installation.
    if(Test-Path("$mingw64\bin\mingw32-make.exe")){

        # Check if there is already a link. And if so, delete it.
        if(Test-Path("$ROOT\${vendor}64")){
            cmd /c rmdir "$ROOT\${vendor}64"
            write-host "Removed link $ROOT\${vendor}64"
            write-host ""
        }

        # Create the symbolic link
        cmd /c mklink /d "$ROOT\${vendor}64" "$mingw64"

        if(Test-Path("$ROOT\${vendor}64")){
            write-host "Target: $mingw64"
            write-host "Link: $ROOT\${vendor}64"
            write-host ""
        }
 

    } else {

        write-host "Invalid path to $mingw64"
        write-host ""

    }

}

# Link to a MinGW x86 compiler
if(-not([string]::IsNullOrEmpty($mingw32))){
    
    # Check that the compiler points to known file in a MinGW installation.
    if(Test-Path("$mingw32\bin\mingw32-make.exe")){

        # Check if there is already a link. And if so, delete it.
        if(Test-Path("$ROOT\${vendor}32")){
            cmd /c rmdir "$ROOT\${vendor}32"
            write-host "Removed link $ROOT\${vendor}32"
            write-host ""
        }

        # Create the symbolic link
        cmd /c mklink /d "$ROOT\${vendor}32" "$mingw32"

        if(Test-Path("$ROOT\${vendor}32")){
            write-host "Target: $mingw32"
            write-host "Link: $ROOT\${vendor}32"
            write-host ""
        }
        

    } else {

        write-host "Invalid path to $mingw32"
        write-host ""

    }
}

# Link to CMake
if(-not([string]::IsNullOrEmpty($cmake))){
    
    # Check that the compiler points to known file in a MinGW installation.
    if(Test-Path("$cmake\bin\cmake.exe")){

        # Check if there is already a link. And if so, delete it.
        if(Test-Path("$ROOT\CMake")){
            cmd /c rmdir "$ROOT\CMake"
            write-host "Removed link $ROOT\CMake"
            write-host ""
        }

        # Create the symbolic link
        cmd /c mklink /d "$ROOT\CMake" "$cmake"

        if(Test-Path("$ROOT\CMake")){
            write-host "Target: $cmake"
            write-host "Link: $ROOT\CMake"
            write-host ""
        }

        write-host "Target: $cmake"
        write-host "Link: $ROOT\CMake"
        write-host ""
    } else {

        write-host "Invalid path to $cmake"
        write-host ""
    }

}

# Link to CMake
if(-not([string]::IsNullOrEmpty($ninja))){
    
    # Check that the compiler points to known file in a MinGW installation.
    if(Test-Path("$ninja\ninja.exe")){

        # Check if there is already a link. And if so, delete it.
        if(Test-Path("$ROOT\Ninja")){
            cmd /c rmdir "$ROOT\CMake"
            write-host "Removed link $ROOT\Ninja"
            write-host ""
        }

        # Create the symbolic link
        cmd /c mklink /d "$ROOT\Ninja" "$ninja"

        if(Test-Path("$ROOT\Ninja")){
            write-host "Target: $ninja"
            write-host "Link: $ROOT\Ninja"
            write-host ""
        }

        write-host "Target: $ninja"
        write-host "Link: $ROOT\Ninja"
        write-host ""
    } else {

        write-host "Invalid path to $ninja"
        write-host ""
    }

}

# Link to Android SDK Root
if(-not([string]::IsNullOrEmpty($android))){
    
    # Check that the path is a valid Android SDK root by looking for core subdirectories
    if((Test-Path("$android\Sdk\platform-tools")) -or (Test-Path("$android\Sdk\platforms"))){

        # Check if there is already a link, and if so, delete it
        if(Test-Path("$ROOT\Android")){
            cmd /c rmdir "$ROOT\Android"
            write-host "Removed existing link: $ROOT\Android"
            write-host ""
        }

        # Create the symbolic link for the SDK root
        cmd /c mklink /d "$ROOT\Android" "$android"

        if(Test-Path("$ROOT\Android")){
            write-host "Target: $android"
            write-host "Link: $ROOT\Android"
            write-host ""
        }
        
    } else {
        write-host "Invalid Android SDK path: $Android"
        write-host ""
    }
}

# Link to JDK Root
if(-not([string]::IsNullOrEmpty($jdk))){
    
    # Check that the path is a valid JDK root by looking for javac or the release file
    if((Test-Path("$jdk\bin\javac.exe")) -or (Test-Path("$jdk\release"))){

        # Check if there is already a link, and if so, delete it
        if(Test-Path("$ROOT\JDK")){
            cmd /c rmdir "$ROOT\JDK"
            write-host "Removed existing link: $ROOT\JDK"
            write-host ""
        }

        # Create the symbolic link for the JDK root
        cmd /c mklink /d "$ROOT\JDK" "$jdk"

        if(Test-Path("$ROOT\JDK")){
            write-host "Target: $jdk"
            write-host "Link: $ROOT\JDK"
            write-host ""
        }
        
    } else {
        write-host "Invalid JDK path: $jdk"
        write-host ""
    }
}
