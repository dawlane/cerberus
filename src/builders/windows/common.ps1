# COMMON FUNCTIONS
# THE SCRIPT IS PART OF THE CERBERUS X BUILDER TOOL.

########################################
# COMMON FUNCTION USE BY OTHER SCRIPTS
########################################

# Various flags and variables
[string]$global:VSINSTALLER_PATH = ""           # Holds the path to the Visual Studio installer.
[string[]]$global:MSVC_INSTALLS = @()           # Holds the total number of installed Visual Studio version found.
[string[]]$global:QT_INSTALLS = @()             # Holds the total number of Qt kits installed
[int]$global:QT_SELECTED_IDX = -1               # Used to select a specific Qt kit
[int]$global:MSVC_SELECTED_IDX = -1             # Used to select a specific Visual Studio version.
[bool]$global:COMPILER_INSTALLED = $false       # Flag to indicate that there is a compiler present.
[string]$global:MINGW_STORE = ""                # Holds the original MINGW_PATH value in the config.winnt.txt
[string]$global:MSBUILD_STORE = ""              # Holds the original MSBUILD_PATH value in the config.winnt.txt
[bool]$global:BREAK_ON_BUILD_ALL = 0
[ExecuteProcess]$global:process = [ExecuteProcess]::new()

class ExecuteProcess {
    # Class properties
    [string[]]$_stdout
    [string[]]$_stderr
    [int]$_exitCode

    ExecuteProcess() {}

    [string]StandardError() {
        return $this._stderr
    }

    [string]StandardOut() {
        return $this._stdout
    }

    [int]ExitCode() {
        return $this._exitCode
    }

    # This method doesn't work with TransCC or MSBuild as it just locks up. 
    [int]Execute([string[]]$_arguments) {
        $this._stdout = @()
        $this._stderr = @()
        $this._exitCode = 0
    
        do_build "EXECUTING: $($_arguments[0])`nArguments: $($_arguments[1..$_arguments.count])"
        $local:pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $_arguments[0]
        $pinfo.RedirectStandardError = $true
        $pinfo.RedirectStandardOutput = $true
        $pinfo.UseShellExecute = $false
        $pinfo.WorkingDirectory = $(Get-Location)
        
        if($_arguments.count -gt 1) {
            $pinfo.Arguments = $_arguments[1..($_arguments.count)]
        }

        $local:p = New-Object System.Diagnostics.Process
        try {
            [bool]$local:exception=$false

            $p.StartInfo = $pinfo
            $p.Start() | Out-Null
            while (-not $p.HasExited) {
                if (-not $p.StandardError.EndOfStream) {
                    $this._stderr += @($p.StandardError.ReadLine())
                }

                if (-not $p.StandardOutput.EndOfStream) {
                    $this._stdout += @($p.StandardOutput.ReadLine())
                }
            }
            $err = $p.ExitCode
            if ($p.ExitCode -ne 0) { throw $($this._stderr -join "`n") }
        }
        catch {
            if ($this._stdout.Count -gt 0) { Write-Host $($this._stdout -join "`n") }
            do_error "$_"
            do_error "EXECUTION FAILED: $($_arguments)`n"
            $this._exitCode = -1
            return $this._exitCode
        }
        if ($this._stderr.Count -gt 0) {
            Write-Host $($this._stdout -join "`n")
            do_error $($this._stderr -join "`n")
        }

        do_success "EXECUTION SUCCESS: $($_arguments)`n"
        return $this._exitCode
    }

    [int]ExecuteWorkaround([string[]]$_arguments) {
        [int]$local:errCode = -1

        switch($($_arguments[0].ToLower() | Split-Path -Leaf)) {
            "msbuild.exe" { $errCode = $this.Invoke($_arguments,"MSVC MSBUILD") }
            "transcc_winnt.exe" { $errCode = $this.Invoke($_arguments,"TRANSCC") }
            "git.exe" { $errCode = $this.Invoke($_arguments,"GIT") }
            "nmake.exe" {  $errCode = $this.Invoke($_arguments,"NMAKE") }
            "qmake.exe" { $errCode = $this.Invoke($_arguments,"QMAKE") }
            "builder.ps1" { $errCode = $this.Invoke($_arguments,"POWERSHELL") }
        }
        if ($errCode -ne 0 ) {
            Write-Host $this._stdout
            do_error $this._stderr
        }
        return $errCode
    }

    [int]Invoke([string[]]$_arguments,[string]$_compiler) {
        $this._stderr=@()
        $this._stdout=@()
        $this._exitCode = 0

        $local:cmd = $_arguments[0]
        $local:arguments = @()
        if ($_arguments.Count -gt 1) {
            $arguments = $_arguments[1..$($_arguments.Count)]
        }

        do_build "EXECUTING $_compiler : $cmd"
        if ($_arguments.Count -gt 1) {
            do_build "Arguments: $arguments"
        }
        $local:expr = "& `"$cmd`" $arguments"
        try {
            $local:output = Invoke-Expression $expr 2>($tmpFile=New-TemporaryFile)
            $this._stderr = Get-Content $tmpFile; Remove-Item $tmpFile

            # Parse the output of any kind of error triggers. 
            $output | ForEach-Object {
                [string]$local:line = $_
                if ($($line | Select-String -Pattern ('(Error :|: Error|Error:|:Error|error :|: error|error:|:error)'))) {
                    $this._stderr += @($line)
                } else {
                    $this._stdout += @($line)
                }
            }
            if ($this._stderr.Count -gt 0) { throw $this._stderr }
        }
        catch {
            $this._stdout = $this._stdout -join "`n"
            if ($this._stderr -lt 1) { $this._stderr = $_ }
            $this._stderr = $this._stderr -join "`n"
            do_error "$_compiler EXECUTION FAILED: $cmd`nArguments: $arguments`n"
            $this._exitCode = -1
            return $this.ExitCode()
        }
        if ($this._stdout -gt 0) { Write-Host $($this._stdout -join "`n") }
        if ($this._stderr -gt 0) { do_error$($this._stderr -join "`n") }
        $this._exitCode = 0
        do_success "$_compiler EXECUTION SUCCESS: $cmd`nArguments: $arguments`n"
        return $this.ExitCode()
    }
}

#########################################
# Display colourised information
#########################################
function do_info([string]$_msg) {
    Write-Host $_msg -ForegroundColor Cyan
}

function do_header([string]$_msg) {
    Write-Host $_msg -ForegroundColor Yellow
}

function do_build([string]$_msg) {
    Write-Host $_msg -ForegroundColor Blue
}

function do_error([string]$_msg) {
    Write-Host $_msg -ForegroundColor Red
}

function do_success([string]$_msg) {
    Write-Host $_msg -ForegroundColor Green
}

function do_unknown([string]$_msg) {
    Write-Host $_msg -ForegroundColor Magenta
}

function do_warning([string]$_msg){
    Write-Host "$([char]27)[93;5m$_msg$([char]27)[0m"
}

################################################
#  Function to preserve the current session path
################################################
function do_path_check() {
    do_info "PREFORMING BACKUP OR RESTORE OF PATH VARIABLE"
    # As the PATH environment variable can get too big. It should be stashed on the first run in another.
    $thisPath = Get-Item -Path "ENV:STORED_PATH" -ErrorAction SilentlyContinue
    if(-not($thisPath)) {
        $thisPath = Get-Item -Path "ENV:PATH"
        Set-Item -Path "ENV:STORED_PATH" -Value $thisPath
        do_info "Storing current PATH variable."
    } else {
        Set-Item -Path "ENV:PATH" -Value $thisPath -Force
        do_info "Reset the PATH variable."
    }
}

###############################################
# Function to clean up after transcc builds.
###############################################
function do_delete([string]$_fpath) {
    if([String]::IsNullOrEmpty("$_fpath")) {
        do_warning "EMPTY PATH NAME PASSED AS PARAMETER`n"
        return $EXIT_CODE
    }

    If (-not(Test-Path("$_fpath"))) {
        do_warning "PARAMETER PASSED IS NOT A VALID FILE OR DIRECTORY:`n$_fpath"
    }

    if (Test-Path -Path "$_fpath" -PathType Leaf){
        Remove-Item -Force -Recurse "$_fpath" -ErrorAction SilentlyContinue
        if(-not $?){
            do_warning "FAILED TO DELETE FILE:`n$_fpath"
        } else {
            do_success "DELETED FILE:`n$_fpath"
        }
    }

    if (Test-Path -Path "$_fpath" -PathType Container){
        Remove-Item -Force -Recurse "$_fpath" -ErrorAction SilentlyContinue
        if(-not $?){
            do_warning "FAILED TO DIRECTORY:`n$_fpath"
        } else {
            do_success "DELETED DIRECTORY:`n$_fpath"
        }
    }
}

######################################
# Function to move a file or directory
######################################
function do_move([string]$src,[string]$dst){
    do_info "MOVING:"
    do_info "SOURCE: $src"
    do_info "DESTINATION: $dst"
    Move-Item -Path $src -Destination $dst -Force -ErrorAction SilentlyContinue
    if (-not $?) {
        do_warning "FAILED TO MOVE:"
        do_warning "SOURCE: $src"
        do_warning "DESTINATION: $dst`n"
    }
    do_success "SUCCESSFULLY MOVED:"
    do_success "SOURCE: $src"
    do_success "DESTINATION: $dst`n"
}


function transcc([string]$_name, [string]$_target, [string]$_srcfile, [string]$_gc_mode = "1") {
    $global:EXITCODE = -1

    [string]$srcpath = "$CERBERUS_SRC_DIR\$_srcfile"
    # Only proceed if transcc has been built.
    if($process.Execute(@("$CERBERUS_BIN_DIR\transcc_winnt.exe")) -ne 0) {
        do_error "NO TRANSCC PRESENT"
        return -1
    }

    do_info "BUILDING $_name"

    # Set the toolchain based upon the target and msbuild.
    [string]$toolchain = ""
    if ($msbuild -eq $true) {
        if ($_target -eq "C++_Tool") {
            $toolchain = "+CC_USE_MINGW=0"
        } else {
            $toolchain = "+GLFW_USE_MINGW=0"
        }
    }
    $local:arguments = @("$CERBERUS_BIN_DIR\transcc_winnt.exe",
        "-target=$_target",
        "-builddir=`"$_srcfile.build`"",
        "-clean",
        "-config=release",
        "+CPP_GC_MODE=$_gc_mode" )

    if(-not([string]::IsNullOrEmpty($toolchain))) {
        $arguments += @("$toolchain")
    }                     
    $arguments += @("`"$srcpath\$_srcfile.cxs`"")

    # Cannot call $process.Execute as it causes transcc to lockup. So have to use another method.
    return $process.ExecuteWorkaround($arguments)
}

####################################################
#  Functions to work with the first key/value pairs.
####################################################
# This is for working with the config.winnt.txt file.
# NOTE: Only the first non commented key is detected. 
function do_set_config_var([string]$_path, [string]$_key, [string]$_value) {
    do_info "MODIFYING: $_path"
  
    # Update the config file with the
    $edits = (Get-Content -Path $_path) |
    ForEach-Object {
        if ($_ -match '^' + $_key + '=\".*\"' ) {
            $_ -replace "($_key=)`".*`"", "`$1`"$_value`""
        }
        else {
            $_
        }
    }
    
    $edits -join "`n" | Out-File $_path -Encoding ascii

}

# Gets the first key=value pair from a config file that matches the key.
function do_get_config_var([string]$_path, [string]$_key) {
    $value = switch -Regex -File $_path { "^$_key=`"(.*)`"" { $Matches[1]; break } }
    return $value
}