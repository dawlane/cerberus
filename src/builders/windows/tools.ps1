# TOOLS FUNCTIONS
# THE SCRIPT IS PART OF THE CERBERUS X BUILDER TOOL.

#######################################################################################################
#   Build transcc, cserver, makedocs, launcher and the IDE Ted
#######################################################################################################

# TRANSCC
# This function basically just builds from the c++ sources.
# Any new or update version of the transcc c++ source should replace the ones in the src/transcc/transcc.build directory. 

function do_transcc() {

    do_info "BUILDING TransCC"

    # Create a variable to where the project files are located.
    [string]$local:project_dir = "$CERBERUS_SRC_DIR\transcc\transcc.build\cpptool"
    #[string]$local:build_dir

    # Check for an existing transcc and remove it.
    if (Test-Path("$CERBERUS_BIN_DIR\transcc_winnt.exe")) { do_delete "$CERBERUS_BIN_DIR\transcc_winnt.exe" }

    [string[]]$local:arguments=@()
    $local:errCode = -1
    # Build transcc from the c++ source files using the tool chain selected. If it is installed.
    if (($msbuild -eq $true)-and($global:MSVC_SELECTED_IDX -ge 0)) {
        $build_dir = "$project_dir\msvc\Release64"
        $project_dir = "$project_dir\msvc"
        $arguments+= @( "MSBuild.exe",
                        "/p:OutDir=`"$CERBERUS_BIN_DIR\`"",
                        "/p:TargetName=`"transcc_winnt`"",
                        "/p:Configuration=Release64",
                        "/p:Platform=x64",
                        "msvc.sln" )

        Push-Location "$project_dir"
        $errCode = $process.ExecuteWorkaround($arguments)
        Pop-Location

    } else {
        $build_dir = "$project_dir\gcc_winnt\build"
        $project_dir = "$project_dir\gcc_winnt\"
        New-Item "$build_dir" -Type Directory -Force | Out-Null
        $arguments = @( "mingw32-make.exe",
                        "CCOPTS=`"-O3 -DNDEBUG -Wno-free-nonheap-object`"",
                        "OUT_PATH=`"$CERBERUS_BIN_DIR`"",
                        "OUT=`"transcc_winnt`"",
                        "BUILD_DIR=`"$build_dir`"" )

        Push-Location "$project_dir"
        $errCode = $process.Execute($arguments)
        Pop-Location
    }

    if($errCode -eq 0) { 
        do_success "SUCCESSFUL BUILD OF TRANSCC`n"
    } else {
        do_error "FAILED TO BUILD TRANSCC"
    }

    do_delete("$build_dir")

    return $errCode
}

# Build the mini HTML Cerberus server.
function do_cserver() {

    # Set the location of the build directory.
    [string]$local:build_dir="$CERBERUS_SRC_DIR\cserver\cserver.build\"

    # Call transcc to build cserver
    [int]$local:errCode = $(transcc "CServer" "Desktop_Game" "cserver")
    if ($errCode -eq 0) {
         # Set the release directory based on the toolchain
        [string]$local:release_dir = "$build_dir\glfw3\"
        if ($msbuild -eq $true) {
            $release_dir += "msvc\Release64"
        } else {
            $release_dir += "gcc_winnt\Release64"
        }

        # Remove the old version before moving the new one into the cerberus bin directory.
        if (Test-Path("$CERBERUS_BIN_DIR\cserver_winnt.exe")) { do_delete "$CERBERUS_BIN_DIR\cserver_winnt.exe" }
        do_move "$release_dir\CerberusGame.exe" "$CERBERUS_BIN_DIR\cserver_winnt.exe"

        # Check for the data directory and copy over additional files.
        if (-not(Test-Path("$CERBERUS_BIN_DIR\data"))) { do_move "$release_dir\data" "$CERBERUS_BIN_DIR\data" }
        if (-not(Test-Path("$CERBERUS_BIN_DIR\openal32.dll"))) { do_move "$release_dir\openal32.dll" "$CERBERUS_BIN_DIR\OpenAL32.dll" }
        if (-not(Test-Path("$CERBERUS_BIN_DIR\openal32_COPYING"))) { do_move "$release_dir\openal32_COPYING" "$CERBERUS_BIN_DIR\openal32_COPYING" }
        if (-not(Test-Path("$CERBERUS_BIN_DIR\openal32_LICENCE"))) { do_move "$release_dir\openal32_LICENCE" "$CERBERUS_BIN_DIR\openal32_LICENCE" }
    }  
    
    if ($errCode -ne 0) {
        do_error "FAILED TO BUILD CServer`n"
    } else {
        do_success "SUCCESSFUL BUILD OF CServer`n"
    }

    do_delete "$build_dir"
    return $errCode
}

# Build the MakeDocs application
function do_makedocs() {

     # Set the location of the build directory.
    [string]$local:build_dir="$CERBERUS_SRC_DIR\makedocs\makedocs.build"
    [int]$local:errCode = $(transcc "MakeDocs" "C++_Tool" "makedocs" "0")
    if ($errCode -eq 0) {
        if (Test-Path("$CERBERUS_BIN_DIR\makedocs_winnt.exe")) { do_delete "$CERBERUS_BIN_DIR\makedocs_winnt.exe" }
        do_move "$build_dir\cpptool64\main_winnt.exe" "$CERBERUS_BIN_DIR\makedocs_winnt.exe"    
    }

    # Final output depends on the error code returned from tha function call.
    if ($errCode -ne 0) {
        do_error "FAILED TO BUILD MakeDocs`n"
    } else {
        do_success "SUCCESSFUL BUILD OF MakeDocs`n"
    }

    do_delete "$build_dir"
    return $errCode
}

# Build the Cerberus launcher
# Due to some limitations with using the Cerberus launcher source file. The launcher is built from a custom c++ source file.
function do_launcher() {
    do_info "BUILDING Launcher"

    # Create a variable to where the project files are located.
    [string]$local:project_dir = "$CERBERUS_SRC_DIR\launcher\winnt"
    [string]$local:icon = "$CERBERUS_SRC_DIR\launcher\cerberus.ico"
    
    # Remove the previous launcher if detected.
    if (Test-Path("$CERBERUS_ROOT_DIR\Cerberus.exe")) { do_delete "$CERBERUS_ROOT_DIR\Cerberus.exe" }

    [int]$local:errCode = -1
    [string[]]$local:arguments = @()
    # Select the compiler to use if installed.
    if (($msbuild -eq $true)-and($global:MSVC_SELECTED_IDX -ge 0)) {
        [string]$local:build_dir = "$project_dir\Release64"
        $arguments = @("msbuild",
                "/p:OutDir=`"$CERBERUS_ROOT_DIR\`"",
                "/p:ApplicationIcon=`"$icon`"",
                "/p:TargetName=`"Cerberus`"",
                "/p:Configuration=Release64",
                "/p:Platform=x64",
                "msvc.sln"
        )
        Push-Location "$project_dir"
        $errCode = $process.ExecuteWorkaround($arguments)
        Pop-Location
        do_delete "$build_dir"
    } else {

        # Two stage build for MinGW compilers. First the icon, then the application.
        $arguments = @("windres.exe",
                    "`"$CERBERUS_SRC_DIR\launcher\resource.rc`"",
                    "-O coff",
                    "-o `"$CERBERUS_SRC_DIR\launcher\res.o`""
        )
        if ($process.Execute($arguments) -eq 0) {
            # If windres was successful, then build the application.
            $arguments = @("g++.exe",
                    "-Os -DNDEBUG",
                    "-o `"$CERBERUS_ROOT_DIR\Cerberus.exe`"",
                    "`"$project_dir\launcher.cpp`"",
                    "`"$CERBERUS_SRC_DIR\launcher\res.o`"",
                    "-ladvapi32",
                    "-s"
            )
            $errCode =  $process.Execute($arguments)
            do_delete "$CERBERUS_SRC_DIR\launcher\res.o"
        } else {
            do_error "FAILED TO COMPILE ICON FILE`nLauncher not created."
        }
    }

    if ($errCode -ne 0) {
        do_error "FAILED TO BUILD Cerberus Launcher`n"
    } else {
        do_success "SUCCESSFUL BUILD OF Cerberus Launcher`n"
    }
    
    return $errCode
}

# Build the IDE Ted
function do_ted() {
    do_info "BUILDING THE IDE TED"

    [string]$local:project_dir = "$CERBERUS_SRC_DIR\build-ted-Desktop-Release"
    # If present, remove any previous build directory before creating a new one.
    if (Test-Path("$project_dir")) { do_delete "$project_dir" }
    New-Item "$project_dir" -Type Directory | Out-Null

    # Set the arguments to build Ted.
    [string[]]$local:arguments = @("$($global:QT_INSTALLS[$global:QT_SELECTED_IDX])\bin\qmake.exe",
                        "-config release",
                        "$CERBERUS_SRC_DIR\ted\ted.pro"
    )   

    # Store the current directory and switch to the new build directory
    Push-Location "$project_dir"
    $local:errCode = $process.ExecuteWorkaround($arguments)
    if ($errCode -ne 0) {
        Pop-Location
        do_delete "$project_dir"
        do_error "FAILED TO BUILD THE IDE TED`nQMake failed to execute."
        return -1
    }

   # QMake succeeded, so now try to run NMake to build Ted.
   $errCode = $process.ExecuteWorkaround(@("nmake.exe","-f Makefile.Release"))
   if ($errCode -ne 0 -ne 0) {
        Pop-Location
        do_delete "$project_dir"
        do_error "FAILED TO BUILD THE IDE TED`nNMake failed to execute."
        return -1
    }

    Pop-Location
    do_delete "$project_dir"

    do_success "BUILD SUCCESSFUL`n"
    return $errCode
}

# BUILD ALL
# Builds all the above tools.
function do_all() {
    if ($global:BREAK_ON_BUILD_ALL -eq $true) {
        if(-not([string]::IsNullOrEmpty($deploypath))) { 
            return $(do_deploy)
        }
    }

    do_header "`n====== BUILDING ALL TOOLS ======"
    [int]$local:errCode = do_transcc
    if ($errCode -eq 0) { $errCode = do_cserver }
    if ($errCode -eq 0) { $errCode = do_makedocs }
    if ($errCode -eq 0) { $errCode = do_launcher }

    if ($errCode -eq 0) {

        # Check that there is an MSVC tool chain and Qt Kit present before building. Else issue warning message and skip building. 
        if (($global:MSVC_INSTALLS.Count -gt 0) -and ($global:QT_INSTALLS.Count -gt 0)) {
            $errCode = $(do_ted)
        }
        else {
            $local:message = "The IDE Ted requires"
            if (($global:QT_SELECTED_IDX -lt 0) -and ($global:MSVC_SELECTED_IDX -lt 0)) {
                $message += " both a Visual Studio MSVC and a Qt SDK kit"
            }
            elseif ($global:QT_SELECTED_IDX -lt 0) {
                $message += " that a Qt SDK kit"
            }
            elseif ($global:MSVC_SELECTED_IDX -lt 0) {
                $message += " that a version of Visual Studio MSVC"
            }
            $message += " be installed."
            do_error "$message"
        }
    }
    return $errCode
}

################################################
# CLEAN THE WORK REPOSITORY OF BUILT FILES
################################################
function do_clean() {
    do_info "CHECKING AND REMOVING ANY LEFT OVER TOOL BUILD DIRECTORIES"
    # The move the launcher
    if(Test-Path("$CERBERUS_ROOT_DIR\Cerberus.exe")) { Remove-Item "$CERBERUS_ROOT_DIR\Cerberus.exe" -Force -ErrorAction SilentlyContinue }

    # Remove transcc winnt
    Remove-Item "$CERBERUS_BIN_DIR\transcc_winnt.exe" -Force -ErrorAction SilentlyContinue

    # Remove CServer winnt.
    Remove-Item "$CERBERUS_BIN_DIR\cserver_winnt.exe" -Force -ErrorAction SilentlyContinue

    # Remove makedocs winnt.
    Remove-Item "$CERBERUS_BIN_DIR\makedocs_winnt.exe" -Force -ErrorAction SilentlyContinue

    # Remove Ted and Qt stuff
    if(Test-Path("$CERBERUS_BIN_DIR\Ted.exe")) { Remove-Item "$CERBERUS_BIN_DIR\Ted.exe" -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\platforms")) { Remove-Item "$CERBERUS_BIN_DIR\platforms" -Recurse -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\qml")) { Remove-Item "$CERBERUS_BIN_DIR\qml" -Recurse -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\plugins")) { Remove-Item "$CERBERUS_BIN_DIR\plugins" -Recurse -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\qt.conf")) { Remove-Item "$CERBERUS_BIN_DIR\qt.conf" -Force -ErrorAction SilentlyContinue }
    Remove-Item "$CERBERUS_BIN_DIR\*.dll" -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_BIN_DIR\*.exe" -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_BIN_DIR\*.ilk" -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_BIN_DIR\*.pdb" -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_BIN_DIR\openal32_*" -Force -ErrorAction SilentlyContinue

    # Remove any leftover build files.
    Remove-Item "$CERBERUS_SRC_DIR/transcc/transcc.build/cpptool/gcc_winn/Release64" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_SRC_DIR/cserver/csrever.build" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_SRC_DIR/launcher/launcher.build" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_SRC_DIR/makedocs/makedocs.build" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_SRC_DIR//build-ted-Desktop-Release" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_SRC_DIR/ted/build" -Recurse -Force -ErrorAction SilentlyContinue
}

function do_distclean() {
    do_info "CLEARING OUT PREVIOUS BUILDS"

    # Remove all macOS applications. Ted and CServer
    Remove-Item "$CERBERUS_BIN_DIR\*.app" -Recurse -Force  -ErrorAction SilentlyContinue

    # Remove transcc linux, macos winnt
    Remove-Item "$CERBERUS_BIN_DIR\transcc_*" -Force -ErrorAction SilentlyContinue

    # Remove the launchers linux, macOS and winnt.
    if(Test-Path("$CERBERUS_ROOT_DIR\Cerberus")) { Remove-Item "$CERBERUS_ROOT_DIR\Cerberus" -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_ROOT_DIR\Cerberus.exe")) { Remove-Item "$CERBERUS_ROOT_DIR\Cerberus.exe" -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_ROOT_DIR\Cerberus.app")) { Remove-Item "$CERBERUS_ROOT_DIR\Cerberus.app" -Recurse -Force -ErrorAction SilentlyContinue }
    Remove-Item "$CERBERUS_ROOT_DIR\*.desktop" -ErrorAction SilentlyContinue

    # Remove CServer linux and winnt.
    Remove-Item "$CERBERUS_BIN_DIR\cserver_*" -Force -ErrorAction SilentlyContinue

    # Remove makedocs linux and winnt.
    Remove-Item "$CERBERUS_BIN_DIR\makedocs_*" -Force -ErrorAction SilentlyContinue

    # Remove Ted linus and winnt
    if(Test-Path("$CERBERUS_BIN_DIR\Ted")) { Remove-Item "$CERBERUS_BIN_DIR\Ted" -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\Ted.exe")) { Remove-Item "$CERBERUS_BIN_DIR\Ted.exe" -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\qml")) { Remove-Item "$CERBERUS_BIN_DIR\qml" -Recurse -Force -ErrorAction SilentlyContinue }

    # Remove Qt Linux support files and directories.
    Remove-Item "$CERBERUS_BIN_DIR\lib*" -Recurse -Force -ErrorAction SilentlyContinue
    if(Test-Path("$CERBERUS_BIN_DIR\plugins")) { Remove-Item "$CERBERUS_BIN_DIR\plugins" -Recurse -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\resources")) { Remove-Item "$CERBERUS_BIN_DIR\resources" -Recurse -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\translations")) { Remove-Item "$CERBERUS_BIN_DIR\translations" -Recurse -Force -ErrorAction SilentlyContinue }

    # Remove Qt WinNT support files and directories.
    if(Test-Path("$CERBERUS_BIN_DIR\platforms")) { Remove-Item "$CERBERUS_BIN_DIR\platforms" -Recurse -Force -ErrorAction SilentlyContinue }
    if(Test-Path("$CERBERUS_BIN_DIR\qt.conf")) { Remove-Item "$CERBERUS_BIN_DIR\qt.conf" -Force -ErrorAction SilentlyContinue }
    Remove-Item "$CERBERUS_BIN_DIR\*.dll" -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_BIN_DIR\*.exe" -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_BIN_DIR\*.ilk" -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_BIN_DIR\*.pdb" -Force -ErrorAction SilentlyContinue
    Remove-Item "$CERBERUS_BIN_DIR\openal32_*" -Force -ErrorAction SilentlyContinue

    # Remove HTML help
    Remove-Item "$CERBERUS_ROOT_DIR\docs\html" -Recurse -Force -ErrorAction SilentlyContinue

    # Remove ted ini data
    Remove-Item "$CERBERUS_BIN_DIR\ted_*.ini" -Recurse -Force -ErrorAction SilentlyContinue

    Get-ChildItem -Path "$CERBERUS_ROOT_DIR\*\*.buildv20*" -Recurse -Force | Remove-Item -Recurse -Force

    do_clean
}

function do_config_txt_reset(){
    # From this point on. Any changes to config files that should not be part of the deployment should be restored.
    if(Test-Path("$CERBERUS_ROOT_DIR/.git")) {
        if($global:GIT_INSTALLED) {
            if ($($process.Execute(@("git.exe","restore $CERBERUS_BIN_DIR/config.winnt.txt"))) -ne 0) {
                do_error "FAILED TO RESTORE THE ORIGINAL WINDOWS CONFIG FILE."
                return -1
            }
        } else {
            do_set_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MINGW_PATH" "$global:MINGW_STORE"
            do_set_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MSBUILD_PATH" "$global:MSBUILD_STORE"
        }
    } else {
        do_set_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MINGW_PATH" "$global:MINGW_STORE"
        do_set_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MSBUILD_PATH" "$global:MSBUILD_STORE"
    }
}