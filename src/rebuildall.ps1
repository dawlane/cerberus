# Windows Powershell build script. Requires .NET Frame Work 4.0+ and Powershell 5+
# NOTICE FOR WINDOWS 64 BIT USERS:
# There are usually two versions of power-shell installed:
# One is a 64 bit native version and will create 32/64 bit executables provided that a compatible version of MinGW installed e.g. TDM-64.
# And the other is a 32 bit executable version and will create 32 bit executables only.

# NOTE: This script requires that the execution policy for the current user be set to unrestricted.
# Open power shell as administrator and use:
#    get-executionpolicy -list
#    set-executionpolicy -scope currentuser unrestricted
# if the file is still blocked use:
#    unblock-file -path "full_path_to_this_script"
# You should reset the execution policy back to it's original state when finised e.g.:
#    set-executionpolicy -scope currentuser undefined

# NOTICE:
# USE THIS SCRIPT AT YOUR OWN RISK. IT'S STILL A WORK IN PROGRESS
$error.clear() # Force the auto error variable to null to stop accumulative error reporting on each script re-run.

Clear-Host
#########################################################################
# STANDARD KNOWN PATHS TO THE BUILD TOOLS
#########################################################################
# TODO: Check install locations
[string]$global:str_mingwPath = "C:\Mingw" # MinGW path
[string]$global:str_jdkPath = "C:\Program Files\Java\jdk1.8.0_151" # Java Development Kit path
[string]$global:str_androidsdkPath = "$env:USERPROFILE\appdata\local\android\sdk" # Android SDK path
[string]$global:str_androidndkPath = "$env:USERPROFILE\appdata\local\android\sdk" # Android NDK path
[string]$global:str_antPath = "C:\Ant" # Apache Ant
[string]$global:str_flexPath = "C:\Flex" # Apache Flex SDK (Flash Player)
[string]$global:str_flashPath = "C:\" # Flash Player debugger
[string]$global:str_agkPath = "" # App Game Kit path
# TO DO. DETECT MSBUILD PATHS - SUBJECT TO CHANGE
[string]$global:str_vswhere = "$env:ProgramFiles (x86)\Microsoft Visual Studio\Installer" # Current default path of vswhere

# Ted was written using QtWebKit, which is no longer available after Qt 5.5.1. Unfortunately Qt 5.5.1 wan't compiled for any compiler after Visual Studio 2013
[string]$global:str_qtsdk = "C:\Qt" # Qt SDK path for VS2015
[string]$global:str_qtversion = "5.9.2"
[string]$global:str_qtsdkPath  = $null
#[string]$global:str_qtsdkPath = "C:\Qt\5.9.2\msvc2017_64" # Qt SDK path for VS2017
[string]$global:str_visualstudioPath = "$env:ProgramFiles (x86)\Microsoft Visual Studio 14.0\VC" # Path to Visual Studio 2013
#[string]$global:str_visualstudioPath = "$env:ProgramFiles (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build" # Path to Visual Studio 2017

# SCRIPT PATHS AND DEPLOYMENT
[string]$global:str_srcRoot = Resolve-Path -Path "$PSScriptRoot\.."  # Get the path to the Cerberus root directory from this scripts location.
[string]$global:str_deployRoot = [Environment]::GetFolderPath('MyDocuments') + "\cerbdeploy" # Store the path to the location of where the final delpoyment will be.
[string]$global:pkgName = Split-Path $global:str_srcRoot -Leaf # Get the directory name of the cerberus root.
[string]$global:cerbRoot = "$global:str_deployRoot\build\$global:pkgName" # The final output of where the Cerberus files will be sent for compressing into an archive.

[bool]$global:os_type = [Environment]::Is64BitOperatingSystem # This checks to see if the operating system is 64 bit.
[bool]$global:bitprocess = [Environment]::Is64BitProcess      # This should check if the current running process is 32 or 64 bit

# Miscellaneous
[int32]$global:errorcode = $null  # Use for detecting errors
$DATE = Get-Date # Get the date and convert it into YYYY-MM-DD
$global:VERSION = $Date.ToString("yyyy-MM-dd")

# Custom data type for holding two values
class CToolPath {
    [ValidateNotNullOrEmpty()][string]$_confvar
    [ValidateNotNullOrEmpty()][string]$_confpath

    # Constructor
    CToolPath( [String]$_confvar, [String]$_confpath ) {
        $this._confvar = $_confvar
        $this._confpath = $_confpath
    }

    [string]PathGet($_str_var) {
        if ($_str_var -eq $this._confvar) { return $this._confpath }
        return ""
    }

    [string]GetVar() {
        return $this._confvar
    }
}

#########################################################################
# FUNCTIONS
#########################################################################
# Message functions
# FUNCTION: ErrorMSG([string]$msg, [bool]$spacer = $false) - Output a coloured error message and stop.
Function ErrorMSG([string]$msg, [bool]$spacer = $false) {
    if ($spacer) { Write-Host "" }
    Write-Host "ERROR: $msg" -BackgroundColor Red -ForegroundColor Yellow
    Set-location $PSScriptRoot
    $error.Clear()
    exit 1
}

# FUNCTION: WarnMSG([string]$msg,[bool]$spacer = $false) - Output a coloured warning message.
Function WarnMSG([string]$msg, [bool]$spacer = $false) {
    if ($spacer) { Write-Host "" }
    Write-Host "WARNING: $msg" -BackgroundColor Yellow -ForegroundColor Black
}

# FUNCTION: HeaderMSG([string]$msg, [bool]$spacer = $true) - Output a coloured header message.
Function HeaderMSG([string]$msg, [bool]$spacer = $true) {
    if ($spacer) { Write-Host "" }
    Write-Host "========= $msg =========" -BackgroundColor Green -ForegroundColor Black
}

# FUNCTION: OkMSG([string]$msg, [bool]$spacer = $false) - Output a coloured OK message.
Function OkMSG([string]$msg, [bool]$spacer = $false) {
    if ($spacer) { Write-Host "" }
    Write-Host "OK: $msg"  -BackgroundColor Black -ForegroundColor Green
}

# FUNCTION: HighlightMSG([string]$msg, [bool]$spacer = $false) - Output a coloured gerneral message.
Function HighlightMSG([string]$msg, [bool]$spacer = $false) {
    if ($spacer) { Write-Host "" }
    Write-Host $msg  -ForegroundColor Yellow -BackgroundColor Black
}

# FUNCTION: ExecuteCMD([String]$_cmd, [string[]]$_argList, [bool]$_spacer = $false) - Run external application.
Function ExecuteCMD([String]$_cmd, [string[]]$_argList, [bool]$_spacer = $false) {
    $global:errorcode = 0
    if ($_spacer) { Write-Host "" }
    Write-Host "EXECUTING: $_cmd $_argList"  -ForegroundColor Cyan
    $expr = "& `"$_cmd`" $_argList"
    try {
        Invoke-Expression "$expr 2>&1" -ErrorAction Stop
        if (-not($LASTEXITCODE -eq 0)) { throw $expr }
        OkMSG "Executed $cmd"
    }
    catch {
        #$_ contains the error record
        Write-Host "$_"
        $global:errorcode = 1
        $error.clear()
    }
}

# FUNCTION: ExitScriptOK() - Output message when finished running the script.
Function ExitScriptOK() {
    OkMSG "Task successful. Exiting."
    Exit 0
}

# FUNCTION: GetRegKeyVal( $_hkey, $_property, $_key ) - Get a registry key value.
Function GetRegKeyVal( $_hkey, $_property, $_key ) {
    $hkey = $_hkey
    $property = (Get-ItemProperty $hkey).$_property
    $key = (Get-ItemProperty $hkey/$property).$_key
    return $key
}

# FUNCTION: ShowHelp([Int]$exit=0) - Displays general options help.
Function ShowHelp([Int]$exit = 0) {

    HighlightMSG "Usage:"
    HighlightMSG ".\rebuildall.ps1 [-option,--option {path}] [-option,--option {path}]"
    Write-Host "        -t | --transcc .................. build transcc from source."
    Write-Host "        -b | --boot ..................... build transcc if not aready built."
    Write-Host "        -l | --launcher ................. build cerberus launcher only."
    Write-Host "        -d | --makedocs ................. build makedocs only."
    Write-Host "        -c | --cserver .................. build cserver only."
    Write-Host "        -e | --ted ...................... build Ted IDE only."
    Write-Host "        -a | --archives ................. extract archives only."
    Write-Host "        -q | --qtsdk `"path`" ........... path to Qt SDK Visual Studio installation."
    Write-Host "        -m | --mingw `"path`"............ path to MinGW installation."
    Write-Host "        -v | --visualstudio `"path`" .... Path to Visual Studio."
    Write-Host "        -p | --package `"name`" ......... Create a package for comparing/testing."
    Write-Host "        -g | --git ...................... Use with the -p option to build a package to deploy."
    Write-Host "        -r | -runtime ................... Use this if building with MinGW-w64 non static."
    Write-Host "                                     .... Requires sharedtrans to be build first."
    Write-Host "        --confpath `"path_variable`" `"path`""
    Write-Host "                                     .... Set a path variable in config.winnt.txt."
    Write-Host "        -confauto ....................... Set all path variable in config.winnt.txt to the default in this script."
    Write-Host "        -build32 ........................ build only 32 bit versions of tools."
    Write-Host "        -msbuild ........................ setting this will build a pure windows binary of transcc."
    Write-Host "        -vsversion VERSION .............. set the version of Visual Studio to use. The default is 2015."
    Write-Host "        -qtversion VERSION .............. set the version of the Qt SDK to use."
    Write-Host "        -s | sharedtrans .................... build shartrans from source."
    Write-Host "        -mingw-static ................... build with static libraries instead of needing dlls."
    Write-Host "        -dbg ............................ build debug versions of all tools."
    Write-Host "        -h,--help ....................... show this usage information."
    exit $exit
}

# FUNCTION InfoGeneral([string]$_str_w64static, [bool]$_bool_msbuild, [bool]$_bool_build32) - Displays general information.
Function InfoGeneral([string]$_str_w64static, [bool]$_bool_msbuild, [bool]$_bool_build32) {
    HeaderMSG "CERBERUS BUILD SCRIPT" $false
    HeaderMSG "NO WARRANTIES. USE AT OWN RISK" $false
    HeaderMSG "STARTED: $DATE" $false
    HeaderMSG "Current parameters"
    Write-Host "This script is at $PSScriptRoot."
    Write-Host "The Cerberus root directory is at $global:str_srcRoot."
    Write-Host "MinGw is set to $global:str_mingwPath."
    Write-Host "Qt SDK is set to $global:str_qtsdkPath\$global:str_qtversion\msvc$global:str_vs_version."
    Write-Host "Visual Studio is at $global:str_visualstudioPath."
    Write-Host "w64 Static build switch is set to $_str_w64static."
    Write-Host "MSBuild switch is set to $_bool_msbuild."
    Write-Host "32/64 build swith is set to $_bool_build32."
}

# FUCNTION: Architecture([bool]$_bool_build32) - Determines the binary architecture to build.
Function Architecture([bool]$_bool_build32) {
    [string]$local:str_arch = $null
    if ($os_type) {
        if (-not($bitprocess)) {
            HighlightMSG "This script is running on a 64 bit operating system, but under a 32 bit version of Power-Shell. So 32 bit binaries will be built."
            $str_arch = "32"
        }
        else {
            if ($_bool_build32) {
                HighlightMSG "This script is running on a 64 bit operating system, -build32 argument used. Therefore 32 bit binaries will be built."
                $str_arch = "32"
            }
            else {
                HighlightMSG "This script is running on a 64 bit operating system. Therefore 64 bit binaries will be built."
                $str_arch = "64"
                # Append _64 to set the tool chain to look in the location for qt 64 bit compiler tool chains. Could be risky doing this without proper checking of the string.
                if (-not("$str_vs_version" -match "_64")) {
                    $local:oldqt = "$str_vs_version"
                    $local:newqt = "$str_vs_version"+"_64"
                    $str_vs_version = $newqt
                    HighlightMSG "QtSDK tools changed from $global:str_qtsdkPath\$str_qtversion\msvc$oldqt to $global:str_qtsdkPath\$str_qtversion\msvc$newqt"
                }
            }
        }
    }
    else {
        HighlightMSG "This script is running on a 32 bit operating system."
        HighlightMSG "Therefore the binaries being built wil be 32 bit."
        $str_arch = "32"
    }
    $global:str_qtsdkPath = "$str_qtsdk\$global:str_qtversion\msvc$str_vs_version"
    Return $str_arch
}

# FUCNTION: SetConfigVars($_str_var, $_str_path) - Writes a value to the config.winnt.txt file.
Function SetConfigVars([string]$_str_var, [string]$_str_path) {
    # Before continuing, fix the location of any _PATH in \bin\config.winnt.txt to the local
    $file = "$global:str_srcRoot\bin\config.winnt.txt"
    $regex = '(?<=^' + $_str_var + '=")[^"]*'
    switch ($_str_var) {
        default {
            (Get-Content $file) | ForEach-Object {
                if ($_ -match $regex) {
                    $_str_var + '="{0}"' -f $_str_path
                }
                else {
                    $_
                }
            } | Set-Content $file
        }
    }
}

# FUNCTION: ([string]$_str_mingw, [string]$_str_qtsdk, [string]$_str_visualstudio, [bool]$_bool_msbuild) - Set up the shell environment.
Function EnviromentSetup([string]$_str_mingw, [string]$_str_qtsdk, [string]$_str_visualstudio, [bool]$_bool_msbuild) {
    HeaderMSG "Testing build environment"
    # MSBUILD 2017 update 2+ uses vswhere
    if([int]$global:str_vs_version -gt 2015){
        [string]$local:str_path_msbuild = ""
        if (Test-Path("$global:str_vswhere\vswhere.exe")) {
            [string]$local:str_msbuildPath = & $global:str_vswhere\vswhere.exe -latest -products * -requires Microsoft.Component.MSBuild -property installationPath
            if ($str_msbuildPath) {
                $str_path_msbuild = join-path $str_msbuildPath 'MSBuild\15.0\Bin;'
            }
        }
    }
    
    # MinGW, QtSDK paths
    [string]$local:str_path_mingw = $_str_mingw + ";" + $_str_mingw + "\bin;" + $_str_mingw + "\include;" + $_str_mingw + "\lib;"
    [string]$local:str_path_qtsdk = $_str_qtsdk + ";" + $_str_qtsdk + "\bin;" + $_str_qtsdk + "\include;" + $_str_qtsdk + "\lib;" + $_str_qtsdk + "\plugins;"
    if (-not($env:Path.Contains($str_path_qtsdk + $str_path_mingw + $str_path_msbuild))) {
        $env:Path = $str_path_msbuild + $str_path_qtsdk + $str_path_mingw + [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        HighlightMSG "Added $_str_mingw, $_str_qtsdk and $str_path_msbuild to current shell environment path."
    }

    # Check to see if MinGW is installed
    if (-not($true -eq $_bool_msbuild)) {
        HighlightMSG "Testing for g++"
        # if we didn't capture the output from the command here the function returns a full object and not a boolean value.
        $capture = ExecuteCMD "g++" "-v" $false $false
        Write-Host "$capture`n"
        if ("$global:errorcode" -eq 1) {
            $_bool_msbuild = $true
            HighlightMSG "MinGW compiler failed to start. Falling back to MSBuild."
        }
        else {
            # SetConfigVars "MINGW_PATH"?
        }
    }

    # Check to see if the QtSDK is set up
    HighlightMSG "Testing for qmake"
    # if we didn't capture the output from the command here the function returns a full object and not a boolean value.
    $capture = ExecuteCMD "qmake" "-v" $false
    Write-Host "$capture`n"
    if ("$global:errorcode" -eq 1) {
        ErrorMSG "Faild to run qmake. Is the QtSDK installed and the paths set correctly?"
    }

    # Test and set up the Visual Studio build environment
    HighlightMSG "Testing for Visual Studio VC"
    if (-not(Test-Path env:VS_SETUP)) {
        # Set an environment variable to stop accumulative variable over-flow.
        $env:VS_SETUP = 'VS_SETUP'
        Push-Location "$_str_visualstudio"
        if (Test-Path "vcvarsall.bat") {
            if ("$global:arch" -eq "32") {
                # 32 bit builds should use the x86 VCTools environment
                cmd /c "vcvarsall.bat x86&set" |
                    ForEach-Object {
                    if ($_ -match "=") {
                        $v = $_.split("=")
                        set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
                    }
                }
                HighlightMSG "32 bit VC Tool chain environment selected."
            }
            else {
                # Use the VC VCTools x86_amd64 environment for 64 bit builds. You could just as easily used the x64/amd64 for this. But it's the 32 bit tool to build 64 bit binaries.
                cmd /c "vcvarsall.bat x86_amd64&set" |
                    ForEach-Object {
                    if ($_ -match "=") {
                        $v = $_.split("=")
                        set-item -force -path "ENV:\$($v[0])" -value "$($v[1])"
                    }
                }
                HighlightMSG "64 bit VC Tool chain environment selected."
            }
        }
        else {
            ErrorMSG "Failed to find vcvarsall.bat. Is the Visual Studio VC path set correctly?"
        }
        Pop-Location
    }
    else {
        HighlightMSG "VC Tool chain enviroment already initialised."
    }

    Return $_bool_msbuild
}

# FUCNTION: ConfigCheck() - Check that there is a config.winnt.txt file. And if not, create one.
Function ConfigCheck() {
    HeaderMSG "Checking for config.winnt,txt"
    if (-not (Test-Path "$global:str_srcRoot\bin\config.winnt.txt" )) {
        & "$global:str_srcRoot\src\archives\scripts\configs\config.winnt.ps1" # Run an external script to build a new config.winnt.txt
        if (Test-Path "$global:str_srcRoot\bin\config.winnt.txt") {
            WarnMSG "The config.winnt.txt file was missing. A new one was created."
        }
        else {
            ErrorMSG "Failed to create new config.winnt.txt."
        }
    }
    else {
        OkMSG "Found config.winnt.txt"
    }
}

Function ExtractZip([string]$_str_srcPath, [string]$_str_dstPath) {
    HighlightMSG "Extracting $_str_srcPath to $_str_dstPath"
    Expand-Archive "$_str_srcPath" -DestinationPath "$_str_dstPath" -Force
}

# FUCNTION: ArchiveCheck() - Extract the backup archives over the the ones already there.
#NOTE THAT THIS WILL OVER WRITE THE CURRENT VERSIONS. TODO: TRAP ERRORS
Function ArchiveCheck() {
    HeaderMSG "Extracting archives if any"
    $local:filelist = Get-ChildItem -Path "$global:str_srcRoot\src\archives\libs\winnt" -Recurse -Filter "*.zip"
    foreach ($i in $filelist) {
        if ($i -like "*shared*") {
            ExtractZip "$global:str_srcRoot\src\archives\libs\winnt\$i" "$global:str_srcRoot\libs\shared"
        }
        if ($i -like "*static*") {
            ExtractZip "$global:str_srcRoot\src\archives\libs\winnt\$i" "$global:str_srcRoot\libs\static"
        }
    }
    if (Test-Path("$global:str_srcRoot\src\archives\licences.zip")) { ExtractZip "$global:str_srcRoot\src\archives\licences.zip" "$global:str_srcRoot\libs\" }
    if (Test-Path("$global:str_srcRoot\src\archives\icons.zip")) { ExtractZip "$global:str_srcRoot\src\archives\icons.zip" "$global:str_srcRoot\src\archives\" }
}

# FUCNTION: DeleteItem([string]$_item_path, [string]$_item) - Check and delete a file/folder.
Function DeleteItem([string]$_item_path, [string]$_item) {
    if (Test-Path "$_item_path\$_item") {
        if ((Get-Item "$_item_path\$_item") -is [System.IO.DirectoryInfo]) {
            try {
                remove-item "$_item_path\$_item" -force -Recurse -ErrorAction Stop
                if (-not($LASTEXITCODE -eq 0)) { throw }
                OkMSG "Deleted $_item_path\$_item"
            }
            catch {
                WarnMSG "Failed to delete $_item_path\$_item"
            }
        }
        else {
            try {
                remove-item "$_item_path\$_item" -force -ErrorAction Stop
                if (-not($LASTEXITCODE -eq 0)) { throw }
                OkMSG "Deleted $_item_path\$_item"
            }
            catch {
                WarnMSG "Failed to delete $_item_path\$_item"
            }
        }
    }
}

# FUNCTION: CheckItem([string]$_item_path, [string]$_item) - Check to see if a file or folder exists.
Function CheckItem([string]$_item_path, [string]$_item) {
    Write-Host "Checking for $_item_path\$_item"
    if (Test-Path "$_item_path\$_item") { OkMSG "$_item_path\$_item located." } else { ErrorMSG "$_item_path\$_item missing." }
}

# FUNCTION: MoveItem([string]$_src_path, [string]$_dst_path, [string]$_item, $_rename) - Move a file or folde with renaming.
Function MoveItem([string]$_src_path, [string]$_dst_path, [string]$_item, $_rename) {
    # Rename on move.
    if (-not([string]::IsNullOrEmpty($_rename))) {
        $name = $_rename
    }
    else {
        $name = $_item
    }

    # Test and delete in necessary.
    if (Test-Path("$_dst_path\$name")) {
        DeleteItem "$_dst_path" "$name"
        try {
            move-item "$_src_path\$_item" -Destination "$_dst_path\$name" -Force -ErrorAction Stop
            if (-not($LASTEXITCODE -eq 0)) { throw }
            OkMSG "Moved $_src_path\$_item to $_dst_path\$name"
        }
        catch {
            ErrorMSG "Failed to move $_src_path\$_item to $_dst_path\$name"
        }
    }
    else {
        try {
            move-item "$_src_path\$_item" -Destination "$_dst_path\$name" -Force -ErrorAction Stop
            if (-not($LASTEXITCODE -eq 0)) { throw }
            OkMSG "Moved $_src_path\$_item to $_dst_path\$name"
        }
        catch {
            ErrorMSG "Failed to move $_src_path\$_item to $_dst_path\$name"
        }
    }
}

# FUNCTION: CopyItem([string]$_src_path, [string]$_dst_path, [string]$_item, $_rename) - Copy a file or folder with renaming.
Function CopyItem([string]$_src_path, [string]$_dst_path, [string]$_item, $_rename) {
    # Rename on copy.
    if (-not([string]::IsNullOrEmpty($_rename))) {
        $name = $_rename
    }
    else {
        $name = $_item
    }

    # Test and delete in necessary.
    if (Test-Path "$_dst_path\$name") {
        RemoveItem "$_dst_path\$name"
        try {
            copy-item "$_src_path\$_item" -Destination "$_dst_path\$name" -ErrorAction Stop -Force
            if (-not($LASTEXITCODE -eq 0)) { throw }
            OkMSG "Copied $_src_path\$_item to $_dst_path\$name" 
        }
        catch {
            ErrorMSG "Failed to copy $_src_path\$_item to $_dst_path\$name"
        }
    }
    else {
        try {
            copy-item "$_src_path\$_item" -Destination "$_dst_path\$name" -ErrorAction Stop -Force
            if (-not($LASTEXITCODE -eq 0)) { throw }
            OkMSG "Copied $_src_path\$_item to $_dst_path\$name" 
        }
        catch {
            ErrorMSG "Failed to copy $_src_path\$_item to $_dst_path\$name"
        }
    }
}

# FUNCTION: BuildBoot([string]$_str_arch, [string]$_str_w64_static, [bool]$_bool_msbuild, [string]$_str_config) - Build transcc - Initial boot in case the Cerberus source differes.
Function BuildBoot([string]$_str_arch, [string]$_str_w64_static, [bool]$_bool_msbuild, [string]$_str_config) {
    HeaderMSG "Building boot transcc"
    Write-Host "Please wait"

    # MinGW only
    if (($_bool_msbuild -eq $false)) {
        if ($_str_config -eq "Release") {
            $opt_conf = "-O3 -DNDEBUG"
        }
        else {
            $opt_conf = "-g "
        }
        ExecuteCMD "g++" "-m$_str_arch $opt_conf -o `"$global:str_srcRoot\bin\transcc_winnt`" `"transcc\transcc.build\cpptool\main.cpp`" -s  $_str_w64_static"
    }
    else {
        # Visual Studio
        [string]$dir = Get-Location
        Set-Location "$global:str_srcRoot\src\transcc\transcc.build\cpptool\msvc$str_vs_version"
        ExecuteCMD "msbuild" "/p:Configuration=$_str_config$_str_arch /p:projectname=`"main_winnt`" /p:CerberusPath=`"$global:str_srcRoot`""
        Set-Location $dir
    }
    if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build boot version of transcc" }
    if ($_bool_msbuild) {
        MoveItem "$global:str_srcRoot\src\transcc\transcc.build\cpptool" "$global:str_srcRoot\bin" "main_winnt.exe" "transcc_winnt.exe"
    }
    CheckItem "$global:str_srcRoot\bin" "transcc_winnt.exe"
}

# FUCNTION: BuildTranscc([string]$_str_arch, [string]$_str_transcc_w64_switch, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, [string]$_str_config) - Build transcc from source. See TransCheck
Function BuildTranscc([string]$_str_arch, [string]$_str_transcc_w64_switch, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, [string]$_str_config) {
    ExecuteCMD "$global:str_srcRoot\bin\transcc_winnt.exe" "-msize=$_str_arch $_str_transcc_w64_switch $_str_msbuild_switch $_str_vsversion_switch -target=`"C++_Tool`" -builddir=`"transcc.build_new`" -clean -config=`"$_str_config`" `"transcc\transcc.cxs`""
    if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build transcc" }
    if (Test-Path("$global:str_srcRoot\bin\transcc_winnt.exe")) {
        DeleteItem "$global:str_srcRoot\bin" "transcc_winnt.exe"
    }
    CheckItem "$global:str_srcRoot\src\transcc\transcc.build_new\cpptool" "main_winnt.exe"
    MoveItem "$global:str_srcRoot\src\transcc\transcc.build_new\cpptool" "$global:str_srcRoot\bin" "main_winnt.exe" "transcc_winnt.exe"
    CheckItem "$global:str_srcRoot\bin" "transcc_winnt.exe"
}

# FUCNTION: TransCheck([string]$_str_arch, [string]$_str_static_w64, [string]$_str_transcc_w64_switch, [bool]$_bool_msbuild, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, [string]$_str_config) - Build either a boot or Transcc compiler verion of transcc.
# Building from source will back up the current version of transcc, create a known named build directory and then build and replace transcc in the bin directory.
# It check to see if there is a back up of transcc and asks if you want to use it if for some reason the last build of transscc breaks due to a change.
Function TransCheck([string]$_str_arch, [string]$_str_static_w64, [string]$_str_transcc_w64_switch, [bool]$_bool_msbuild, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, [string]$_str_config) {
    if (-not(Test-Path("$global:str_srcRoot\bin\transcc_winnt.exe"))) {
        BuildBoot $str_arch $_str_static_w64 $_bool_msbuild $_str_config
    }
    else {
        HeaderMSG "Building transcc from Cerberus Source"
        Write-Host "Please wait"
        if (Test-Path "$global:str_srcRoot\bin\transcc_winnt.exe.bak") {
            HighlightMSG "A backup of transcc_winnt has been detected. Do you wish to restore to rebuild transcc? (Y)es/(N)o"
            HighlightMSG "Answering No will replace the backup with the current version of transcc_winnt."
            $local:response = $null
            While ($response -notmatch '^(Y|N)$') {
                $response = Read-Host "Answer Y/N"
            }
            if (($response = "y") -or ($responce = "Y")) {
                Remove-Item "$global:str_srcRoot\bin\transcc_winnt.exe"
                MoveItem "$global:str_srcRoot\bin" "$global:str_srcRoot\bin" "transcc_winnt.exe.bak" "transcc_winnt.exe"
            }
            else {
                Remove-Item "$global:str_srcRoot\bin\transcc_winnt.exe.bak"
            }
        }
        if ((-not(Test-Path("$global:str_srcRoot\bin\transcc_winnt.exe.bak"))) -and ((Test-Path("$global:str_srcRoot\bin\transcc_winnt.exe")))) {
            CopyItem "$global:str_srcRoot\bin" "$global:str_srcRoot\bin" "transcc_winnt.exe" "transcc_winnt.exe.bak"
        }
        BuildTranscc $_str_arch $_str_transcc_w64_switch $_str_msbuild_switch $_str_vsversion_switch $_str_config
    }
}

# FUNCTION: BuildLauncher([string]$_str_arch, [string]$_str_static_w64, [bool]$_bool_msbuild, [string]$_str_config) - Build the Cerberus launch application.
# On Windows there is a codeblocks template and a Visual Studio solution file.
Function BuildLauncher([string]$_str_arch, [string]$_str_static_w64, [bool]$_bool_msbuild, [string]$_str_config) {
    HeaderMSG "Building launcher"
    Write-Host "Creating resource files."

    # MinGw
    if ($_bool_msbuild -eq $false) {
        if ($_str_arch -eq "32") { $windres = "pe-i386" } else { $windres = "pe-x86-64" }
        ExecuteCMD "windres" "--target $windres `"launcher\codeblocks\resource.rc`" -O coff -o `"launcher\codeblocks\resource_$_str_arch.o`""
        CheckItem "launcher\codeblocks" "resource_$_str_arch.o"
        if ($_str_config -eq "Release") {
            $opt_conf = "-Os -DNDEBUG"
        }
        else {
            $opt_conf = "-g "
        }
        ExecuteCMD "g++" "-m$_str_arch $_str_static_w64 $opt_conf -o `"$global:str_srcRoot\Cerberus.exe`" `"launcher\codeblocks\launcher.cpp`" `"launcher\codeblocks\resource_$_str_arch.o`" -ladvapi32 -s"
        if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build launcher" }
    }
    else {
        # Visual Studio
        [string]$dir = Get-Location
        Set-Location "$global:str_srcRoot\src\launcher\msvc$str_vs_version\launcher"
        ExecuteCMD "msbuild" "/p:Configuration=$_str_config$_str_arch  /p:projectname=`"Cerberus`" /p:CerberusPath=`"$global:str_srcRoot`""
        if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build launcher" }
        Set-Location $dir
    }
    CheckItem "$global:str_srcRoot" "Cerberus.exe"
}

# FUCNTION: BuildMakedocs([string]$_str_arch, [string]$_str_w64_static_switch, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, $_str_config) - Build the makedoc application.
Function BuildMakedocs([string]$_str_arch, [string]$_str_w64_static_switch, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, $_str_config) {
    HeaderMSG "Building makedocs"
    ExecuteCMD "$global:str_srcRoot\bin\transcc_winnt.exe" "-msize=$_str_arch $_str_w64_static_switch $_str_msbuild_switch $_str_vsversion_switch -target=`"C++_Tool`" -builddir=`"makedocs.build`" -clean -config=`"$_str_config`" `"makedocs\makedocs.cxs`""
    if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build makedocs" }
    MoveItem "$global:str_srcRoot\src\makedocs\makedocs.build\cpptool" "$global:str_srcRoot\bin" "main_winnt.exe" "makedocs_winnt.exe"
    remove-item makedocs\makedocs.build -force -recurse
    CheckItem "$global:str_srcRoot\bin" "makedocs_winnt.exe"
}

# FUCNTION: BuildCServer([string]$_str_arch, [string]$_str_w64_static_switch, [bool]$_bool_msbuild, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, [string]$_str_config) - Build the mini server.
Function BuildCServer([string]$_str_arch, [string]$_str_w64_static_switch, [bool]$_bool_msbuild, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, [string]$_str_config) {
    HeaderMSG "Building cserver"
    #DeleteItem "$global:str_srcRoot\bin" "cserver_winnt.exe"
    ExecuteCMD "$global:str_srcRoot\bin\transcc_winnt.exe" "-msize=$_str_arch $_str_w64_static_switch $_str_msbuild_switch $_str_vsversion_switch -target=`"Desktop_Game_(Glfw3)`" -builddir=`"cserver.build`" -clean -config=`"$_str_config`" +CPP_GC_MODE=1 `"cserver\cserver.cxs`""
    if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build cserver" }
    if ($_bool_msbuild -eq $true) { $dir = "msvc$global:str_vs_version" } else { $dir = "gcc_winnt" }
    MoveItem "$global:str_srcRoot\src\cserver\cserver.build\glfw3\$dir\$_str_config$_str_arch" "$global:str_srcRoot\bin" "cserver_winnt.exe" ""
    MoveItem "$global:str_srcRoot\src\cserver\cserver.build\glfw3\$dir\$_str_config$_str_arch" "$global:str_srcRoot\bin" "data" ""
    DeleteItem "$global:str_srcRoot\src\cserver\cserver.build" -force -recurse
    CheckItem "$global:str_srcRoot\bin" "cserver_winnt.exe"
}

# FUNCTION: BuildTed([string]$_str_config) - Build the IDE Ted.
Function BuildTed([string]$_str_config) {
    #Make ted
    HeaderMSG "Building ted"
    if (Test-Path("$global:str_srcRoot\bin\Ted.exe")) { Remove-Item "$global:str_srcRoot\bin\Ted.exe" -Force }
    if (Test-Path("$global:str_srcRoot\bin\platforms")) { Remove-Item "$global:str_srcRoot\bin\platforms" -Force -Recurse }
    Remove-Item "$global:str_srcRoot\bin\*Qt*.dll" -Force

    if (Test-Path("$global:str_srcRoot\src\build-ted-Desktop-$_str_config")) {
        Remove-Item "$global:str_srcRoot\src\build-ted-Desktop-$_str_config" -force -recurse
    }

    New-Item "$global:str_srcRoot\src\build-ted-Desktop-$_str_config" -type directory | Out-Null
    Set-Location "$global:str_srcRoot\src\build-ted-Desktop-$_str_config"

    ExecuteCMD "qmake" "`"$global:str_srcRoot\src\ted\ted.pro`" -spec win32-msvc"
    if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build Ted" }

    ExecuteCMD "nmake" "-f Makefile.$_str_config"
    if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build Ted" }
    Set-Location ..
    Remove-Item "$global:str_srcRoot\src\build-ted-Desktop-$_str_config" -force -recurse
    HeaderMSG "Deploying Qt Shared dynamic libraries"
    ExecuteCMD "windeployqt" "--$($_str_config.ToLower()) --no-svg --no-angle --no-compiler-runtime --no-system-d3d-compiler --no-quick-import --no-translations --core `"$global:str_srcRoot\bin\Ted.exe`""
    if ($global:errorcode -eq 1) { ErrorMSG "Failed execute windeployqt" }
    $folders = "audio", "bearer", "imageformats", "mediaservice", "playlistformats", "position", "printsupport", "sensors", "sensorgestures", "sqldrivers", "opengl32sw.dll"
    foreach ($folder in $folders) {
        if (Test-Path("$global:str_srcRoot\bin\$folder")) { Remove-Item "$global:str_srcRoot\bin\$folder" -Force -Recurse }
    }
}

# FUNCTION: BuildShareTranscc([string]$_str_arch, [string]$_str_w64_static_switch, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, [string]$_str_config) - Build the shared transfer helper application.
Function BuildShareTranscc([string]$_str_arch, [string]$_str_w64_static_switch, [string]$_str_msbuild_switch, [string]$_str_vsversion_switch, [string]$_str_config) {
    HeaderMSG "Building sharedtrans"
    ExecuteCMD "$global:str_srcRoot\bin\transcc_winnt.exe" "-msize=$_str_arch $_str_w64_static_switch $_str_msbuild_switch $_str_vsversion_switch -target=`"C++_Tool`" -builddir=`"sharedtrans.build`" -clean -config=`"$_str_config`" +CPP_GC_MODE=1 `"sharedtrans\sharedtrans.cxs`""
    if ($global:errorcode -eq 1) { ErrorMSG "Failed execute build sharedtrans" }
    MoveItem "$global:str_srcRoot\src\sharedtrans\sharedtrans.build\cpptool" "$global:str_srcRoot\bin" "sharedtrans_winnt.exe" ""
    remove-item sharedtrans\sharedtrans.build -force -recurse
    CheckItem "$global:str_srcRoot\bin" "sharedtrans_winnt.exe"
}

# FUCNTION: CopyPackage([string]$_str_deployRoot, [string]$_str_srcRoot, [string]$_str_cerbRoot) - Copy the Cerberus directory as a clean directory to compare against.
# The function should remove all the files not required required for distribution.
# You should use a diff tool such a Meld to compare against to original directory tree to make sure that there are no unwanted file being copied.
Function CopyPackage([string]$_str_deployRoot, [string]$_str_srcRoot, [string]$_str_cerbRoot) {
    # Clean the old deployment out
    if (-not (Test-Path "$_str_deployRoot")) {
        New-Item "$_str_cerbRoot" -type directory
    }
    else {
        DeleteItem "$_str_deployRoot"
        New-Item "$_str_cerbRoot" -type directory
    }

    # General
    HighlightMSG "Copying over common files."
    RoboCopy    "$_str_srcRoot" "$_str_cerbRoot" "Cerberus.exe" /njh /njs /ndl /nfl /nfl | Out-Null
    RoboCopy    "$_str_srcRoot" "$_str_cerbRoot" "*.TXT" /njh /njs /ndl /nfl | Out-Null
    RoboCopy    "$_str_srcRoot" "$_str_cerbRoot" "README.md" /njh /njs /ndl /nfl | Out-Null
    RoboCopy    "$_str_srcRoot" "$_str_cerbRoot" "*.dll" /njh /njs /ndl /nfl | Out-Null
    HighlightMSG "Copying over documentation files."
    RoboCopy    "$_str_srcRoot\docs" "$_str_cerbRoot\docs" "*.*" /njh /njs /ndl /nfl /E /XF ".*" /XD "*html" | Out-Null
    HighlightMSG "Copying over module_ext files."
    RoboCopy    "$_str_srcRoot\modules_ext" "$_str_cerbRoot\modules_ext" "*.*" /njh /njs /ndl /nfl /E /XF ".*" | Out-Null
    HighlightMSG "Copying over modules files."
    RoboCopy    "$_str_srcRoot\modules" "$_str_cerbRoot\modules" "*.*" /njh /njs /ndl /nfl /E /XF ".*" | Out-Null
    HighlightMSG "Copying over targets files."
    RoboCopy    "$_str_srcRoot\targets" "$_str_cerbRoot\targets" `
        "*.*" /njh /njs /ndl /nfl /E /XF ".*" /XF "*.bak" /XD "*.bak" /XF "*.suo" /XF "*.VC.db" /XD ".*" /XF "*.vcxproj.user" /XF "*.aps" | Out-Null
    HighlightMSG "Copying over example files."
    RoboCopy    "$_str_srcRoot\examples" "$_str_cerbRoot\examples" `
        "*.*" /njh /njs /ndl /nfl /E /XF ".*" /XD "*.buildv20*" /XD "*Release32" `
        /XD "*Release64" /XF "*.suo" /XF "*.VC.db" /XD ".*" /XF "*.vcxproj.user" /XF "*.ikl" /XF "*.pbd" /XF "*.aps" | Out-Null
    HighlightMSG "Copying over src files."
    RoboCopy    "$_str_srcRoot\src" "$_str_cerbRoot\src" `
        "*.*" /njh /njs /ndl /nfl /E /XF ".*" /XD "*.build_new" /XF "*.bak" `
        /XD "*.bak" /XF "*.buildv20*" /XD "*build-ted-*" `
        /XF "*.bak" /XF "*.pro.user" /XD ".*" /XF "*.VC.db" `
        /XD "*deployment" /XD "*.bak" /XF "*.bak" /XF "*.pbd" `
        /XF "*.aps" /XF "*pkg.plist" /XD "*Release32" /XD "*Release64" | Out-Null
    HighlightMSG "Copying over libs files."
    RoboCopy    "$_str_srcRoot\libs" "$_str_cerbRoot\libs" "*.*" /njh /njs /ndl /nfl /E /XF ".*" /XD "*MacOS*" /XD "*Linux*" /XF "*.bak" /XD "*.bak" | Out-Null

    # Bin directory
    HighlightMSG "Copying over bin files."
    RoboCopy "$_str_srcRoot\bin" "$_str_cerbRoot\bin" "*.exe" /njh /njs /ndl /nfl /E /XF "*.bak" /XD "ted*.ini" /XD "lib" /XD "plugins" /XD "libexec" /XD "*.app" /XF ".*" | Out-Null
    RoboCopy "$_str_srcRoot\bin" "$_str_cerbRoot\bin" "config.winnt.txt" /njh /njs /ndl /nfl | Out-Null
    RoboCopy "$_str_srcRoot\bin" "$_str_cerbRoot\bin" "docstyle.txt" /njh /njs /ndl /nfl | Out-Null
    RoboCopy "$_str_srcRoot\bin" "$_str_cerbRoot\bin" "*.dll" /njh /njs /ndl /nfl | Out-Null
    RoboCopy "$_str_srcRoot\bin\data" "$_str_cerbRoot\bin\data" "*.*" /njh /njs /ndl /nfl /E /XF ".*" | Out-Null
    RoboCopy "$_str_srcRoot\bin\platforms" "$_str_cerbRoot\bin\platforms" "*.*" /njh /njs /ndl /nfl /E /XF ".*" | Out-Null
    RoboCopy "$_str_srcRoot\bin\resources" "$_str_cerbRoot\bin\resources" "*.*" /njh /njs /ndl /nfl /E /XF ".*" | Out-Null
    RoboCopy "$_str_srcRoot\bin\translations" "$_str_cerbRoot\bin\translations" "*.*" /njh /njs /ndl /nfl /E /XF ".*" | Out-Null
    RoboCopy "$_str_srcRoot\bin\templates" "$_str_cerbRoot\bin\templates" "*.*" /njh /njs /ndl /nfl /E /XF ".*" | Out-Null
    RoboCopy "$_str_srcRoot\bin\themes" "$_str_cerbRoot\bin\themes" "*.*" /njh /njs /ndl /nfl /E /XF ".*" | Out-Null
}

# FUNCTION: Runtimes() - Deploy MinGW-w64 shared libraries.
Function Runtimes([string]$_str_arch) {
    if (-not(Test-Path("..\bin\sharedtrans_winnt.exe"))) {
        ErrorMSG "Sharedtrans is missing. Has it been built?"
    }
    ExecuteCMD "$global:str_srcRoot\bin\sharedtrans_winnt.exe" "-srcdirs=`"$global:str_mingwPath`" -dst=`"$global:str_srcRoot\bin`" -libs=`"dummy`" -toolchain=`"mingw`" -toolpath=`"$global:str_mingwPath`" -arch=`"$_str_arch`""
    ExecuteCMD "$global:str_srcRoot\bin\sharedtrans_winnt.exe" "-srcdirs=`"$global:str_mingwPath`" -dst=`"$global:str_srcRoot`" -libs=`"dummy`" -toolchain=`"mingw`" -toolpath=`"$global:str_mingwPath`" -arch=`"$_str_arch`""

}

# FUNCTION: GitBuild([string]$_deployRoot, [string]$_str_cerbRoot, [string]$_pkgName) - Build a deployment package using github.
Function GitBuild([string]$_deployRoot, [string]$_str_cerbRoot, [string]$str_pkgName, [string[]]$_array_cmdline) {
    #git_build "$global:str_srcRoot" "$PACKAGEROOT" "$PKGNAME"
    HeaderMSG "CHECKING REPOSITORY STATE"
    $local:output = $(git status --porcelain)
    if ([string]::IsNullOrEmpty($output)) {
        OkMSG "Repostiory is clean."
    }
    else {
        ErrorMSG "Uncommited changes in repository. Use you favourite git to to check."
    }

    $clone = [Environment]::GetFolderPath('MyDocuments') + "\cerbclone"
    HeaderMSG "CLONING TO $clone"
    $cwd = Get-Location
    if (Test-Path("$clone")) { DeleteItem "$clone" }
    New-Item -ItemType Directory "$clone"
    Set-Location "$clone"     # change into the cloning directory
    ExecuteCMD "git" "clone `"$global:str_srcRoot\`" `"$str_pkgName`""
    # Building all, but still need the qt sdk, name, build32 and msbuild options
    Set-Location "$clone/$str_pkgName/src"
    HeaderMSG "ENTERING $clone/$str_pkgName/src AND BUILDING" $true
    Remove-Item env:VS_SETUP
    .\rebuildall.ps1 @_array_cmdline
    if (-not($LASTEXITCODE -eq 0)) { ErrorMSG "Failed to excute depolyment rebuilding." }
    & .\rebuildall.ps1 --package $str_pkgName
    if (-not($LASTEXITCODE -eq 0)) { ErrorMSG "Failed to excute depolyment packaging." }
    Set-Location "$cwd"
}

# FUNCTION: BuildPackage([string]$_str_deployRoot, [string]$_str_cerbRoot, [string]$_pkgName, [string[]]$_array_cmdline) - Build either a test directory or a full deployment.
Function BuildPackage([string]$_str_deployRoot, [string]$_str_cerbRoot, [string]$_pkgName, [string[]]$_array_cmdline) {
    HeaderMSG "Creating distribution package"

    if ($global:bool_usegit -eq 1) {
        GitBuild "$_str_deployRoot" "$_str_cerbRoot" "$_pkgName" $_array_cmdline
        # Package as zip file
        if (Test-Path "$_str_deployRoot\$_pkgName-win-$VERSION.zip") {
            RemoveItem "$_str_deployRoot\$_pkgName-win-$VERSION.zip"
            HeaderMSG "CREATING DEPLOYMENT ARCHIVE $_pkgName-win-$VERSION.zip"
            Compress-Archive -Path "$_str_deployRoot\build\*" -CompressionLevel Optimal -DestinationPath "$_str_deployRoot\$_pkgName-win-$VERSION.zip"
        }
        else {
            HeaderMSG "CREATING DEPLOYMENT ARCHIVE $_pkgName-win-$VERSION.zip"
            Compress-Archive -Path "$_str_deployRoot\build\*" -CompressionLevel Optimal -DestinationPath "$_str_deployRoot\$_pkgName-win-$VERSION.zip"
        }
        Return
    }
    else {
        CopyPackage "$_str_deployRoot" "$global:str_srcRoot" "$_str_cerbRoot"
    }
}

# FUCNTION: ConfAutoPath() - Automaticall fix the config.winnt.txt with known values.
Function ConfAutoPath() {
    # Set JDK. Use the registry to get the installed location
    SetConfigVars "JDK_PATH" "$(GetRegKeyVal 'HKLM:\SOFTWARE\JavaSoft\Java Development Kit' 'CurrentVersion' 'JavaHome')"
    SetConfigVars "ANDROID_PATH" "$global:str_androidsdkPath"
    SetConfigVars "ANDROID_NDK_PATH" "$global:str_androidndkPath"
    SetConfigVars "ANT_PATH" "$global:str_antPath"
    SetConfigVars "FLEX_PATH" "$global:str_flexPath"
    SetConfigVars "FLASH_PLAYER" "$global:str_flashPath"
    SetConfigVars "AGK_PATH" "$global:str_agkPath"
    SetConfigVars "MSBUILD_PATH" "$(GetRegKeyVal 'HKLM:\SOFTWARE\Microsoft\MSBuild\14.0' '14.0' 'MSBuildOverrideTasksPath')"
}

# FUNCTION: ProcessCMDS() - Process the command line.
Function ProcessCMDS($_args) {
    [String]$local:str_arch = $null                 # The binary architecture output
    [string]$local:str_config = "Release"           # The default string to use build configuration. Setting dbg to true will change this to "Debug"
    [bool]$local:bool_confautopath = $false         # When set to true to try to create a pre-filled config.winnt.txt file.
    [bool]$local:bool_msbuild = $false              # if MinGW is installed a long side Visual Studio, then this has to be set to use VS to build.
    [bool]$local:bool_w64static = $false            # As it's posible to use MinGW-w64 that needs shared run-time libraries to work. Setting this will statically link the run-times.
    [bool]$local:bool_build32 = $false              # When set to true it will try to builds a 32 bit version on a 64 bit OS.

    # Main entry. Test for any arguments
    # COMMAND LINE PARSER: Start
    [int]$local:int_index = 0
    [string]$local:str_unknown = $null
    $local:list_exec_cmd = New-Object System.Collections.Generic.List[string]
    [string[]]$local:array_confpaths = @()
    [string[]]$local:array_args=@($_args)

    # COMMAND LINE PARSER: Read CMD Line
    while ($int_index -lt $array_args.Count) {
        switch ($array_args[$int_index]) {
            # Build commands. Put them into a string to process later
            { "-t", "--transcc" -contains $_ } {
                if (-not($list_exec_cmd -contains '2transcc' )) { $list_exec_cmd.Add('2transcc') }
                $int_index++
            }
            { "-b", "--boot" -contains $_ } {
                if (-not($list_exec_cmd -contains '2boot' )) { $list_exec_cmd.Add('2boot') }
                $int_index++
            }
            { "-l", "--launcher" -contains $_ } {
                if (-not($list_exec_cmd -contains '6launcher' )) { $list_exec_cmd.Add('6launcher') }
                $int_index++
            }
            { "-d", "--makedocs" -contains $_ } {
                if (-not($list_exec_cmd -contains '4makedocs' )) { $list_exec_cmd.Add('4makedocs') }
                $int_index++
            }
            { "-c", "--cserver" -contains $_  } {
                if (-not($list_exec_cmd -contains '5cserver' )) { $list_exec_cmd.Add('5cserver') }
                $int_index++
            }
            { "-e", "--ted" -contains $_ } {
                if (-not($list_exec_cmd -contains '7ted' )) { $list_exec_cmd.Add('7ted') }
                $int_index++
            }
            { "-a", "--archives" -contains $_  } {
                if (-not($list_exec_cmd -contains '1archives' )) { $list_exec_cmd.Add('1archives') }
                $int_index++
            }
            { "-s", "--sharedtrans" -contains $_  } {
                if (-not($list_exec_cmd -contains '3sharedtrans' )) { $list_exec_cmd.Add('3sharedtrans') }
                $int_index++
            }
            { "-p", "--package" -contains $_ } {
                if (-not($list_exec_cmd -contains '9package' )) {
                    $list_exec_cmd.Add('9package')
                    $int_index++
                    if ([string]::IsNullOrEmpty($array_args[$int_index])) { ErrorMSG "Deployment name is empty!." }
                    [string]$global:cerbRoot = "$global:str_deployRoot\build\" + $($array_args[$int_index])
                    $list_exec_cmd.Add($($array_args[$int_index]))
                    $int_index++
                }
                else { $int_index++; $int_index++ }
            }
            "-vsversion" {
                $int_index++
                $global:str_vs_version = $array_args[$int_index]
                $int_index++
            }
            "-qtversion" {
                $int_index++
                $global:str_qtversion = $array_args[$int_index]
                $int_index++
            }
            { "-r", "--runtime" -contains $_ } {
                if (-not($list_exec_cmd -contains '8runtime' )) { $list_exec_cmd.Add('8runtime') }
                $global:bool_runtime = $true
                $int_index++
            }

            # Switches. Need to be global scope.
            "-confauto" { $global:bool_confautopath = $true; $int_index++; }
            { "-g", "--git" -contains $_ } { $global:bool_usegit = $true; $int_index++ }
            "-build32" {
                $bool_build32 = $true;
                $int_index++
            }
            "-mingw-static" {
                $str_static_w64 = "-Wl','-Bstatic -static-libgcc -static-libstdc++ -Wl','-Bstatic','--whole-archive -lwinpthread -Wl','--no-whole-archive -Wl','-Bdynamic"
                $str_transcc_w64 = "-mingw-static"
                $int_index++
            }
            "-msbuild" {
                $str_msbuild_switch = "-msbuild"
                $bool_msbuild = $true
                $int_index++
            }
            "-dbg" { $str_config = "Debug"; $int_index++ }

            # TODO: Chech that what we have in mingw, qtsdk and visualstudio a directory!
            { "-m", "--mingw" -contains $_ } {
                $int_index++
                $global:str_mingwPath = $($array_args[$int_index])
                if (-not(Test-Path -Path $global:str_mingwPath -PathType Container)) { ErrorMSG "Invalid path to MinGW!" }
                if ([string]::IsNullOrEmpty($global:str_mingwPath)) { ErrorMSG "MinGW path not defined!" }
                $int_index++
            }
            { "-v", "--visualstudio" -contains $_ } {
                $int_index++
                $global:str_visualstudioPath = $($array_args[$int_index])
                if (-not(Test-Path -Path $global:str_visualstudioPath -PathType Container)) { ErrorMSG "Invalid path to Visual Studio!" }
                if ([string]::IsNullOrEmpty($global:str_visualstudioPath)) { ErrorMSG "Visual Studio VC path not defined!" }
                $int_index++
            }
            { "-q", "--qtsdk" -contains $_ } {
                $int_index++
                $global:str_qtsdkPath = $($array_args[$int_index])
                if (-not(Test-Path -Path $global:str_qtsdkPath -PathType Container)) { ErrorMSG "Invalid path to Qt SDK!" }
                if ([string]::IsNullOrEmpty($global:str_qtsdkPath)) { ErrorMSG "QtSDK path not defined!" }
                $int_index++
            }
            { "--confpath" -contains $_ } {
                $int_index++
                $arg1 = $($array_args[$int_index])
                if ([string]::IsNullOrEmpty($arg1)) { ErrorMSG "--confpath arg1 is invalid!" }
                $int_index++
                $arg2 = $($array_args[$int_index])
                if ([string]::IsNullOrEmpty($arg2)) { ErrorMSG "--confpath arg2 is invalid!" }
                $array_confpaths += New-Object CToolPath -ArgumentList $arg1, $arg2
                $array_confpaths
                $int_index++
            }
            { "-h", "--help" -contains $_ } { ShowHelp 1 }
            default {
                if (-not($null -eq $array_args[$int_index])) { $str_unknown += $array_args[$int_index] + " " }
                $int_index++
            }
        }
    }

    InfoGeneral $bool_w64static $local:bool_msbuild $bool_build32                                                              # Output general information
    $str_arch = Architecture $bool_build32                                                                                     # Detect and set the build architecture
    $bool_msbuild = (EnviromentSetup $global:str_mingwPath $global:str_qtsdkPath $global:str_visualstudioPath $bool_msbuild)   # Initialise the build environment
    ConfigCheck                                                                                                                # Check that there is a config.winnt.txt file present

    # Stop if there are any arguments that are not recognised
    if (-not([string]::IsNullOrEmpty($str_unknown))) {
        Write-Host "Invalid arguments passed: $str_unknown" -ForegroundColor Yellow -BackgroundColor Red
        ShowHelp 1
    }

    # Check for Variable paths
    if ($bool_confautopath -eq $true) {
        ConfAutoPath
    }
    else {
        if ($array_confpaths.Count -gt 0) {
            Foreach ($p in $array_confpaths) {
                $_str_var = $p.GetVar()
                $_str_path = $p.PathGet($_str_var)
                SetConfigVars $_str_var $_str_path
            }
        }
    }

    # COMMAND LINE PARSER: Process commands.
    # Process commands to execute.
    if ($bool_msbuild -eq 1) {
        $str_msbuild_switch = "-msbuild"
        [string]$str_vsversion_switch = "-vsversion=`"$global:str_vs_version`""
    }

    if ($list_exec_cmd.Count -eq 0) {
        # No commands passed, build the standard stuff
        ArchiveCheck
        TransCheck $str_arch $str_static_w64 $str_transcc_w64 $bool_msbuild $str_msbuild_switch $str_vsversion_switch $str_config
        BuildShareTranscc $str_arch $str_transcc_w64 $str_msbuild_switch $str_vsversion_switch $str_config
        BuildMakedocs $str_arch $str_transcc_w64 $str_msbuild_switch $str_vsversion_switch $str_config
        BuildCServer $str_arch $str_transcc_w64 $bool_msbuild $str_msbuild_switch $str_vsversion_switch $str_config
        BuildLauncher $str_arch $str_static_w64 $bool_msbuild $str_config
        BuildTed $str_config
    }
    else {

        # COMMAND LINE PARSER: Loop commands
        # Process commands to execute
        $int_index = 0
        if($list_exec_cmd.Count -gt 1){ $list_exec_cmd = $list_exec_cmd | Sort-Object}
        while ($int_index -lt $list_exec_cmd.Count) {
            switch ($list_exec_cmd[$int_index]) {
                "2transcc" {
                    TransCheck $str_arch $str_static_w64 $str_transcc_w64 $bool_msbuild $str_msbuild_switch $str_vsversion_switch $str_config
                    $int_index++
                }
                "3sharedtrans" {
                    if (-not(Test-Path("..\bin\transcc_winnt.exe"))) {
                        ErrorMSG "Cannot build sharedtrans. Not transcc compiler."
                    }
                    BuildShareTranscc $str_arch $str_transcc_w64 $str_msbuild_switch $str_vsversion_switch $str_config
                    $int_index++
                }
                "2boot" {
                    if (-not($str_exec -contains 'transcc')) {
                        BuildBoot $str_arch $str_static_w64 $bool_msbuild $str_config
                    }
                    $int_index++
                }
                "6launcher" {
                    BuildLauncher $str_arch $str_static_w64 $bool_msbuild $str_config
                    $int_index++
                }
                "4makedocs" {
                    if (-not(Test-Path("..\bin\transcc_winnt.exe"))) {
                        ErrorMSG "Cannot build makedocs. Not transcc compiler."
                    }
                    BuildMakedocs $str_arch $str_transcc_w64 $str_msbuild_switch $str_vsversion_switch $str_config
                    $int_index++
                }
                "5cserver" {
                    if (-not(Test-Path("..\bin\transcc_winnt.exe"))) {
                        ErrorMSG "Cannot build cserver. Not transcc compiler."
                    }
                    BuildCServer $str_arch $str_transcc_w64 $bool_msbuild $str_msbuild_switch $str_vsversion_switch $str_config
                    $int_index++
                }
                "7ted" {
                    BuildTed $str_config
                    $int_index++
                }
                "1archives" {
                    ArchiveCheck
                    $int_index++
                }
                "9package" {
                    [string[]]$local:array_cmdline = @()
                    # Always start with a boot build and sharedtrans
                    $array_cmdline += ("--archives", "--boot", "--sharedtrans", "--makedocs", "--launcher", "--cserver", "--ted" )
                    if ($global:bool_runtime -eq $true) { $array_cmdline += ("--runtime") }

                    # Compiler control flags
                    if ($true -eq $bool_build32) { $array_cmdline += ("-build32") }
                    if ($true -eq $bool_w64static) { $array_cmdline += ("-mingw-static") }
                    if ($true -eq $bool_msbuild) { $array_cmdline += ("-msbuild") }

                    # Paths
                    if (-not($global:str_visualstudioPath -eq "")) { $array_cmdline += ("--visualstudio", "$global:str_visualstudioPath") }
                    if (-not($global:str_mingwPath -eq "")) { $array_cmdline += ("--mingw", "$global:str_mingwPath") }
                    if (-not($global:str_qtsdkPath -eq "")) { $array_cmdline += ("--qtsdk", "$global:str_qtsdkPath") }
                    $array_cmdline += ("-vsversion", "$global:str_vs_version")
                    $int_index++

                    # The actual nname to use
                    $local:name = $list_exec_cmd[$int_index]
                    BuildPackage "$global:str_deployRoot" "$global:cerbRoot" "$name" $array_cmdline
                    $int_index = $list_exec_cmd.Count    # Nothing more to do after a packaging, so set the index to the end.
                }
                "8runtime" {
                    Runtimes $str_arch
                    $int_index++
                }
            }
        }
    }
}

#########################################################################
# MAIN CONTROL - Execution begins here.
#########################################################################
[string]$global:str_vs_version = "2015"         # Note that this is use to select the directory for the Visual Studio soultion file.
[bool]$global:bool_usegit = $false              # If set, use git to clone, build and package.
[bool]$global:bool_runtime = $false             # If set will add MinGW runtime libraries. Only for use with MinGW-w64 non static builds.
$a = $args                                     # Fixes an odd quirk when passing arguments to a script that's been call from within a function.
Write-Host $a
ProcessCMDS $a

ExitScriptOK
