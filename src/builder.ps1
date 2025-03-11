# MAIN MS WINDOWS POWERSHELL SCRIPT FOR BUILDING CERBERUS X TOOLS

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
# TODO: Implement the setting of the Windows SDK and MSVC Tool Set. This is to be down after TransCC has been updated.
[CmdletBinding(PositionalBinding = $False)]
Param(
    [Alias("q")][string]$qtsdk = "C:\Qt",
    [Alias("k")][string]$qtkit = "",
    [Alias("c")][string]$mingw = "C:\TDM-GCC-64",
    [Alias("y")][string]$vsversion = "",
    [Alias("i")][string]$vsinstall = "$([System.Environment]::GetEnvironmentVariable('ProgramFiles(x86)'))\Microsoft Visual Studio\Installer",
    [Alias("m")][switch]$showmenu = $false,
    [Alias("h")][switch]$help = $false,
    [Alias("b")][switch]$msbuild = $false,
    [Alias("d")][string]$deploypath = "",
    #[Alias("w")][string]$winsdk = "10.0",
    #[Alias("t")][string]$toolset = "v142",
    [Alias("n")][switch]$pause = $false,
    [switch]$distclean = $false,
    [switch]$clean = $false
)

Clear-Host

[string]$SCRIPT_VER = "2.0.0"

# Basic variable for common Cerberus directories.
[string]$CERBERUS_SRC_DIR = "$PSScriptRoot"
[string]$CERBERUS_ROOT_DIR = Resolve-Path "$CERBERUS_SRC_DIR\.."
[string]$CERBERUS_BIN_DIR = "$CERBERUS_ROOT_DIR\bin"
[string]$MODULES = "$CERBERUS_SRC_DIR\builders\windows"

# Import the additional scripts that contain core functions
."$MODULES\common.ps1"
."$MODULES\thirdparty.ps1"
."$MODULES\deploy.ps1"
."$MODULES\tools.ps1"

# As running this script can make the PATH environment variable grow excessively. It should be backed up and restored
# each time this script is run.
do_path_check

if ($help -eq $true) {
    do_info "CERBERUS X TOOLS VERSION $SCRIPT_VER"
    Write-Host "USEAGE: ./builder.ps1 [options]`n`t{-m|-showmenu}`t`t`t`t`t- run in menu mode.`n`t{-q|-qtsdk} `"QT_DIR_PATH`"`t`t`t- Set root Qt SDK directory."
    Write-Host "`t{-k|-qtkit} `"DOT.VERSION.NUMBER`"`t`t- Set Qt SDK version.`n`t{-i|-vsinstall} `"VISUAL_INSTALLER_PATH`"`t`t- Set MS Visual Installer directory."
    Write-Host "`t{-y|-vsver} `"PRODUCT_YEAR`"`t`t`t- Set Visual Studio product year`n`t{-c|-mingw} `"MINGW_DIR`"`t`t`t`t- Set MiGW root directory."
    Write-Host "`t{-b|-msbuild}`t`t`t`t`t- Build using MSBuild. Requires Visual Studio."
    Write-Host "`t{-d|-deploypath} `"DEPLOY_DIR`"`t`t`t- Build a deployment archive in the directory passed."
    #Write-Host "`t{-w|-winsdk} `"10.0`"`t`t`t`t- Set the MS Windows SDK to use. Default is 10.0, which means any."
    #Write-Host "`t{-t|-toolset} `"v142`"`t`t`t`t- Set the MSVC tool set to use. Default is v142, which is Visual Studio 2019."
    Write-Host "`t{-p|-pause}`t`t`t`t`t- Pause just before showing the menu to show script configuration setup."
    Write-Host "`t-clean`t`t`t`t`t`t- Removes Cerberus tools and build directories for current operating system."
    Write-Host "`t-distclean`t`t`t`t`t- Removes all previous built binaries of Cerberus within local repository."
    Write-Host "`t{-h|-help}`t`t`t`t`t- Show this quick help`n`nEXAMPLE:`n`te.g: ./builder.ps1 -qtsdk C:\Qt -k 6.8.2"
    Write-Host "`te.g: ./builder.ps1 -qtsdk C:\Qt -qtkit 6.5.3 -vsver `"2019`" -showmenu"
    exit 1
}

# If the clear builds flag is set, then call the function to remove all previously build items.
if($distclean) {
    do_distclean
    do_success "Cerberus X Builder script terminated."
    exit 0
}

# If the clear builds flag is set, then call the function to remove all previously build items.
if($clean) {
    do_clean
    do_success "Cerberus X Builder script terminated."
    exit 0
}

# If the deployment path has been set, the set the BREAK_ON_BUILD_ALL to true.
if(-not([string]::IsNullOrEmpty($deploypath))) { $global:BREAK_ON_BUILD_ALL = $true }

# Check for a git installation. This will set the GIT_INSTALLED variable based on if git is installed.
# As the only file that this script will modify is config.winnt.txt. Then check if that file is safe to update.
# In menu mode, this is ignored to allow the use of the menu to test build individual tools.
if($(do_git_check) -eq 0) {
    do_success "GIT is installed"
    $global:GIT_INSTALLED = $true
    if ((-not([string]::IsNullOrEmpty($deploypath))) -and ($showmenu -eq $false)) {
        do_info "Now checking repository status/"
        if($process.Execute(@("git","diff --exit-code $CERBERUS_BIN_DIR/config.winnt.txt")) -ne 0) {
            do_error "The config.winnt.txt file has been modified.`nYou should commit/amend/stash the changes to the local repository and then rerun this script."
            exit 1
        }
    }
}

# The base requirements for building Cerberus is that a GCC compiler is present. But is not a fatal error, as Visual Studio can be used.
switch($(do_mingw($mingw)) ) {
    "0" {
        $global:COMPILER_INSTALLED = $true
        do_success "MINGW IS INSTALLED"
        $global:MINGW_STORE = do_get_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MINGW_PATH"
        do_set_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MINGW_PATH" "$mingw"
    }
    "-2" {
        $global:COMPILER_INSTALLED = $true
        do_success "MINGW IS INSTALLED ON SYSTEM PATH VARIABLE"
        $mingw = $((Get-Command g++.exe).Path).Replace("\bin\g++.exe","")
        $global:MINGW_STORE = do_get_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MINGW_PATH"
        do_set_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MINGW_PATH" "$mingw"
    }
    "-1" {
        $global:COMPILER_INSTALLED = $false
        $mingw = "NOT INSTALLED"

        # Mingw isn't installed, so set the build chain to that of MSBuild.
        $msbuild = $true
    }
}

# Now get the Visual Studio installs and store them in an array.
# Any error here will not stop the build tool. It just means that the IDE Ted will not be an option.
switch($(do_msvc "$vsversion" "$vsinstall") ) {
    "0" {
        do_success "MSVC ENVIRONMENT SETUP COMPLETE"
        $global:MSBUILD_STORE = do_get_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MSBUILD_PATH"
        do_set_config_var "$CERBERUS_BIN_DIR/config.winnt.txt" "MSBUILD_PATH" "$($global:MSVC_INSTALLS[$global:MSVC_SELECTED_IDX])\MSBuild\Current\Bin\MSBuild.exe"

        # If there is a MSVC compiler present, then check for a Qt SDK installation.
        if ($(do_qtsdk_check "$qtkit" "$qtsdk") -eq 0) {
            do_success "Qt SDK installation detected. The IDE Ted can be built."
        } else {
            do_warning "No Qt SDK installations detected. The IDE Ted will not be built."
        }
    }
    "-1" {
        do_warning "NO VISUAL STUDIO INSTALLATION SET UP.`nThe IDE Ted cannot be built, nor creation of MSVC version of Cerberus-X tools."
    }
}

# If the value of $global:COMPILER_INSTALLED is $false, then stop the script.
if ($global:COMPILER_INSTALLED -eq $false) {
    do_error "THERE ARE NO COMPILERS PRESENT"
    exit 1
}

###############
# MENU/DISPLAY
###############
# Set up the menu items. The array DISPLAY_ITEMS, holds the human readable menu items.
# The array MENU_ITEMS, holds the function names to call.
function do_items() {
    $global:display_items = @("All", "Transcc")
    $global:menu_items = @("do_all", "do_transcc")
    if ($global:TRANSCC_EXE -eq $true) {
        $global:display_items += @("CServer", "Makedocs", "Launcher")
        $global:menu_items += @("do_cserver", "do_makedocs", "do_launcher")
    }
    if (($global:MSVC_INSTALLS.Count -gt 0) -and ($global:QT_INSTALLS.Count -gt 0)) {
        $global:display_items += "Ted"
        $global:menu_items += "do_ted"
    }
    if (-not([string]::IsNullOrEmpty($deploypath))) {
        $global:display_items += "Deploy: $deploypath"
        $global:menu_items += "do_deploy"
    }
    $global:display_items += ("Quit")
    $global:menu_items += ("do_quit")
}


function do_show_deps() {
    # Display the path to MinGW compiler to be used.
    if (-not($mingw.Contains("INSTALLED"))) {
        do_success "MINGW: $mingw"
    } else {
        do_unknown "MINGW: $mingw"
    }

    # Display The MSVC compiler being used.
    if ($global:MSVC_SELECTED_IDX -ge 0) {
        do_success "MSVC: $($global:MSVC_INSTALLS[$global:MSVC_SELECTED_IDX])"
    } else {
        do_unknown "MSVC: NOT INSTALLED"
    }

    # Display The Qt SDK kit being used.
    if ($global:QT_SELECTED_IDX -ge 0) {
        do_success "Qt SDK: $($global:QT_INSTALLS[$global:QT_SELECTED_IDX])"
    } else {
        do_unknown "Qt SDK: NOT INSTALLED"
    }

    # Display if git is installed
    if ($global:GIT_INSTALLED) {
        do_success "GIT: INSTALLED"
    } else {
        do_unknown "GIT: NOT INSTALLED"
    }

    # The tool chain that's being use.
    if ($msbuild -eq $true) {
        do_info "Toolchain: MSBuild"
    } else {
        do_info "Toolchain: MinGW"
    }
}
function do_title() {
    Clear-Host
    do_header "===== Cerberus X Tool Builder Version $SCRIPT_VER ====="
    do_show_deps
    for ( $index = 0; $index -lt $global:display_items.Count; $index++) {
        [int]$s = [int]$index + 1
        "${s}: {0}" -f $global:display_items[$index]
    }
}

# Only show the menu if the showmenu option was set. Else, do a normal build all.
if ($showmenu -eq $true) {
    $global:BREAK_ON_BUILD_ALL = $false
    # Pause so the output from the setup can be checked.
    if ($pause) { Pause }

    [bool]$loop = $true
    do {
        $global:TRANSCC_EXE = 0

        # Test to see if transcc has been built.
        if ($process.Execute(@("$CERBERUS_BIN_DIR/transcc_winnt.exe")) -eq 0) {
            $global:TRANSCC_EXE = 1
        }
        
        # update the menu and wait for selection.
        do_items
        do_title
        $in = Read-Host "Select application to build"

        # Only allow numbers
        if (-not(($in -ge "0") -and ($in -le "9"))) { continue }

        # Cast the value into an integer and then subtract one.
        # All functions are stored in an array and arrays start at zero.
        [int]$i = $in - 1

        # Get the function to call. If the function name is do_quit, then exit the script.
        [string]$call = $global:menu_items[$i]
        if ($call -eq "do_quit") {
            $loop = $false
        } else {
            $e = & $call
            pause
        }
    }
    until ($loop -eq $false)
} else {
    do_info "`nBUILD TOOLS INSTALLED"
    do_show_deps
    do_all | Out-Null
}

do_config_txt_reset