# THIRD-PARTY FUNCTIONS
# THE SCRIPT IS PART OF THE CERBERUS X BUILDER TOOL.

#######################################################################################################
#   DETECTION AND SET UP OF THIRD PARTY TOOLS, FRAME WORKS AND COMPILER TOOL CHAINS
#######################################################################################################

############################
# VISUAL STUDIO DETECTION
############################
# NOTE: Due to how a MSVC tool chain works. It is necessary to set the environment up correctly.
# As this can be an issue if the script is run multiple times. Then it is necessary to set an
# environment variable to indicate that the current session has already done this.
function do_msvc_env() {
    do_info "SETTING UP MSVC BUILD ENVIRONMENT"

    # Save the current directory and switch to where the MSVC tools set batch file is located.
    Push-Location "$($global:MSVC_INSTALLS[$global:MSVC_SELECTED_IDX] + "\VC\Auxiliary\Build")"

    $check_env_tools_version = Get-Item -Path "ENV:\VCToolsVersion" -ErrorAction SilentlyContinue
    if($check_env_tools_version) {
        Remove-Item -Path "ENV:\VCToolsVersion" -ErrorAction SilentlyContinue
    }
    
    # Parse the vcvarsall.bat to get the values and set the appropriate environment variables.
    # TODO: Figure out a way to start cmd without inheriting previous environment variables.
    cmd "/c" "vcvarsall.bat x86_amd64&set" | 
    ForEach-Object {
        if ($_ -match "=") {
            $v = $_.Split("=",2)
            Set-Item -Force -Path "ENV:\$($v[0])" -Value "$($v[1])"
        }
    } 
    Pop-Location

    Set-Item -PATH "ENV:VS_VARIABLES" -Value $($vars -join ';')

    # A final check to see that there wasn't an issue with running the vcvarsall.bat file.
    $check_env_tools_version = Get-Item -Path "ENV:\VCToolsVersion" -ErrorAction SilentlyContinue
    if(-Not($check_env_tools_version)) {
        do_warning "Failed to successfully set the MSVC build environment set up."
        return -2
    }
    return 0
}

# To confirm the installation of a MS Visual Studio install. The script relies on the presence of the MS Visual Studio
# installer, specifically vswhere.
function do_check_vswhere([string]$_vsi) {

    # If the path passed doesn't lead to where vswhere should be, then try the default.
    if (-not(Test-Path($_vsi + "\vswhere.exe"))) {
        do_warning "INVALID PATH TO VSWHERE: $_vis"
        $_vsi = "$([System.Environment]::GetEnvironmentVariable('ProgramFiles'))\Microsoft Visual Studio\Installer"
        do_warning "Trying path: $_vis"
    }

    # If vswhere was unable to run, then issue a warning. An error isn't thrown, as MinGW may be the preferred compiler.
    if ($process.Execute( @("$_vsi\vswhere.exe","-h")) -eq 0) {
        if(-not($process.StandardOut().Contains("Visual Studio Locator version"))) { return -2 }
    } else { return -1 }

    # If this point is reached, then the path is valid and vswhere will be used to get the information about the MS
    # Visual Studio locations.
    $global:VSINSTALLER_PATH = $_vsi

    return $process.ExitCode()
}

# Check the passed parameters for valid MS Visual Studio installations.
# All detected MS Visual Studio installations will be placed the MSVC_INSTALLS array and the one
# selected will depend on either the version passed on as a parameter, or the highest version found.
function do_msvc([string]$_vsver, [string]$_vsi) {

    do_info "`nCHECKING FOR VISUAL STUDIO INSTALLATIONS"

    # Before executing any applications. The paths need to be checked.
    # If there is no MS Visual Studio installer installation; then ignore MS Visual Studio detections.
    if (-not((Test-Path($_vsi)) -or (Test-Path("$([System.Environment]::GetEnvironmentVariable('ProgramFiles'))\Microsoft Visual Studio\Installer")))) {
        return -1
    }

    # The Visual Studio installer will have a tool where the selected Visual Studio's path can be retrieved;. This tools is vswhere.
    # NOTE: The do_check_vswhere will set messages if failed.
    switch($(do_check_vswhere("$_vsi"))) {
        "-1" {
            do_warning "Failed to execute vswhere in directory`n$_vsi"
            return -1 
        }
        "-2" {
            do_warning "Not a valid vswhere in directory`n$_vsi"
            return -1
        }
    }

    # If the vswhere check has passed, then it's time to get all Visual Studio installs and paths.
    # vswhere has a handy option to sort all retrieved information from latest to oldest.
    # If the vsversions array is empty, then there are no Visual Studio installs.
    [string[]]$local:arguments = @( "$global:VSINSTALLER_PATH\vswhere.exe","-sort","-property catalog_productLineVersion" )
    if ($process.Execute($arguments) -ne 0) {
        do_error "Something went wrong getting the version numbers of the Visual Studio installations on the system."
        return -1
    }

    # The standard output should have information on the number of installations present.
    [string[]]$local:vsversions = $process.StandardOut().Split("`n") | ForEach-Object { "$_".Trim() }
    $local:vsversions = $local:vsversions.Where({ $_ -ne "" })

    # Check the value of vsversions. If this is empty, then there are no installations present.
    if($vsversions.Count -lt 1) {
        do_warning "Visual Studio is not installed on this system."
        return -1
    }
    
    # Now do the same to get installation paths.
    $arguments = @( "$global:VSINSTALLER_PATH\vswhere.exe", "-sort -property installationPath" )
    if ($process.Execute($arguments) -ne 0) {
        do_error "Something went wrong getting the paths of the Visual Studio installations on the system."
        return -1
    }

    $vsversions |
        ForEach-Object {
            do_info "Found installation of Visual Studio $($_)"
        }

    # Store the paths for detected installs and remove empty items.
    $global:MSVC_INSTALLS = $process.StandardOut().Split("`n") | ForEach-Object { "$_".Trim() }
    $global:MSVC_INSTALLS = $global:MSVC_INSTALLS.Where({ $_ -ne "" })

    # Now check if the the MS Visual Studio matches the passed parameter.
    # If it does, then set the variable MSVC_SELECTED_IDX to it's index, else set it to the 
    $global:MSVC_SELECTED_IDX = [int]$vsversions.IndexOf($_vsver)
    if ($global:MSVC_SELECTED_IDX -lt 0) {
        if(-not([string]::IsNullOrEmpty($_vsver))) {
            do_warning "The chosen version of Visual Studio $_vsver is not installed on this system."
            do_warning "Selecting the highest installation found: Visual Studio $($vsversions[0])"
        } else {
            do_warning "No Visual Studio version set."
            do_warning "Selecting the highest installation found: Visual Studio $($vsversions[0])"
        }
        $global:MSVC_SELECTED_IDX = 0
    }

    # If vcvarsall.bat is not present, then set MSVC_SELECTED_IDX to minus one to indicate that there is no Visual Studio that can be used.
    if (-not(Test-Path($global:MSVC_INSTALLS[$global:MSVC_SELECTED_IDX] + "\VC\Auxiliary\Build\vcvarsall.bat"))) {
        $global:MSVC_SELECTED_IDX = -1
        return -1
    }

    # Set up the MSVC environment. If all is well, then set the compiler installed flag to true.
    if(($(do_msvc_env) -ne 0)) {
        return -1
    }

    # If the script reaches here, then all went well, so set the compiler installed flag to true. 
    $global:COMPILER_INSTALLED = $true
    do_success "Using Visual Studio $($vsversions[$global:MSVC_SELECTED_IDX])"
    return 0
}

############################
# MINGW DETECTION
############################
# Check if the passed parameter is a valid MinGW installation.
# This function will set the compiler installed flag and return the path of the MinGW installation.
# NOTE: GCC will output version info either in stderr or stdout depending on the version option passed.
# As this is a test and not compiling, then the --version option must be used, else an error could be thrown.
function do_mingw([string]$_mingw) {

    do_info "`nCHECKING FOR A MINGW INSTALLATION"
    # First check to see if MinGW is installed via just executing it.
    do_info "Checking for a system wide installation of MinGW."
    if ($process.Execute(@("g++.exe","--version")) -eq 0) {
        $global:COMPILER_INSTALLED = $true
        return -2   # Return a negative number here, as it's needed to differentiate between a global and a path install. 
    } else {
        do_warning "MinGW is not installed on the system path.`nTrying path: $_mingw"
    }

    # If the above failed, then check the path passed to the script.
    if (-not(Test-Path("$_mingw"))) {
        do_error "THE PATH TO MINGW IS INVALID:`n$_mingw"
        $global:COMPILER_INSTALLED = $false
        return -1
    }

    # If the path checks out, then set it and try to running MinGw again.
    [string]$path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    [Environment]::SetEnvironmentVariable('PATH', $_mingw + "\bin;" + $path)

    return $process.Execute(@("g++.exe","--version"))

}

############################
# QT FRAME WORK DETECTION
############################
# Scan the passed parameters for valid Qt SDK installations.
function do_qtsdk_check([string]$_qtver, [string]$_qtsdk) {
    do_info "`nCHECKING FOR QT SDK INSTALLATIONS"

    # Check that there is a Qt path before trying to execute any applications.
    # If it does't exist; then ignore Qt detection.
    if (-not(Test-Path($_qtsdk))) {
        do_error "NO DIRECTORY NOT SET FOR QT CHECK"
        return -1
    }

    # Check that the Qt SDK's main path is valid by querying the maintenance tool.
    if ($process.Execute(@("$_qtsdk\MaintenanceTool.exe","-v")) -eq 0) {
        if (-not($process.StandardOut().Contains("IFW Version:"))) {
            do_warning "Not a valid Qt maintenance tool in directory`n$_qtsdk`nIs this a valid Qt SDK?"
            return -1
        }
        do_success "Found MaintenanceTool"
    } else {
        do_warning "Failed to execute Qt Maintenance tool in directory`n$_qtsdk`nIs Qt installed?"
        return -1
    }

    # Okay if the script has made it this far, then the Qt SDK directory needs to be scanned for valid MSVC qmake installations.
    # This will store all MSVC paths into the QT_INSTALLS array and sort them in descending  order.
    $global:QT_INSTALLS = Get-ChildItem $_qtsdk |
    Where-Object { $_.PSIsContainer } |
    Foreach-Object {
        if ($_.Name.Contains(".")) {
            Get-ChildItem $_qtsdk\$_ |
            Where-Object { $_.PSIsContainer } |
            ForEach-Object {
                if ($_.Name.Contains("msvc")) {
                    if ($($process.Execute(@("$($_.FullName.Trim()+"\bin\qmake.exe")","-v"))) -eq 0) {
                        $_.FullName
                        do_success "Found Qt install: $($_.FullName)"
                    }
                }
            }
        }
    } |
    Sort-Object -Descending { 
        [Version] $(if ($_ -match "[\d\.]+") { 
                $matches[0] -replace "_", "."
            }
        )
    } 

    # Now check if the the MS Visual Studio matches the passed parameter. If it does, then set the variable MSVC_SELECTED_IDX to it's index.
    $global:QT_SELECTED_IDX = -1
    $global:QT_INSTALLS | ForEach-Object {
        if ("$_".Contains("`\$_qtver`\")) {
            $global:QT_SELECTED_IDX = [int]$global:QT_INSTALLS.IndexOf($_)
            do_success "Found Qt $_qtver"
            return 0
        }
    }
    
    # If the variable QT_SELECTED_IDX is less than zero, and the QT_INSTALLS array count is greater than zero. Then select the first element in the QT_INSTALL array.
    # If not; then there are no kits installed.
    if (($global:QT_SELECTED_IDX -lt 0) -and ($global:QT_INSTALLS.Count -gt 0)) {
        $global:QT_SELECTED_IDX = 0
        if([string]::IsNullOrEmpty("$_qtver")) {
            do_unknown "No Qt Kit selected. Selecting highest version detected.`n$($global:QT_INSTALLS[0])"
        } else {
            do_unknown "Unknown Qt $_qtver`nSelecting highest version detected."
        }
    }
    else {
        $global:QT_SELECTED_IDX = -1
        do_error = "No Qt SDK kits detected."
        return -1
    }

    return 0
}

############################
# GIT DETECTION
############################
# Check if git is installed system wide and valid. If it is, then set the git installed flag.
function do_git_check() {
    do_info "CHECKING FOR GIT"
    [string]$local:GIT_PATH = $(get-command git.exe).Path
    if([String]::IsNullOrEmpty($GIT_PATH)) { return -1 }

    $process.Execute(@("git","--version"))
    return $process.ExitCode()
}
