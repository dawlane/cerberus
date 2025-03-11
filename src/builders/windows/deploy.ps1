# DEPLOYMENT BUILDER FUNCTIONS
# THE SCRIPT IS PART OF THE CERBERUS X BUILDER TOOL.

#############################################
# BUILD A DEPLOYMENT ARCHIVE
#############################################
# This function requires that git be installed.
# It works by cloning the the current repository, removing any git related items from the clone, and then running the 
# builder script in the clone with the basic set of parameters that were passed. After the cloned builder script has
# finished and control is returned to this function. A archive is generated from the freshly built files in the clone.
function do_deploy() {
    # Set some local variables. Just to make it a bit easier to follow.
    [String]$local:DEPLOYMENT_ROOT_DIR = "$deploypath\cx_deploy_root"
    [string]$local:DEPLOYMENT_BUILD_DIR = "$DEPLOYMENT_ROOT_DIR\build"
    [string]$local:DEPLOYMENT_TARGET_DIR = "$DEPLOYMENT_BUILD_DIR\Cerberus"
    [String]$local:DEPLOYMENT_TARGET_BIN_DIR = "$DEPLOYMENT_TARGET_DIR\bin"
    [String]$local:DEPLOYMENT_TARGET_SRC_DIR = "$DEPLOYMENT_TARGET_DIR\src"

    # Test for a .git folder. If there isn't one, then it must be a normal set of sources files.
    if (-not(Test-Path("$CERBERUS_ROOT_DIR\.git"))) {
        do_error "Deployment requires that the sources contains in a git repository."
        return -1
    }

     # Only do a deployment build if git is installed.
     if(-not($global:GIT_INSTALLED)) {
        do_error "git is required to build a deployment package."
        return -1
    }

    # Restore the config.winnt.txt file back from the cached version.
    # As this function will return back to the menu. Any modifications to the config variables will need to be restored
    # for the builder script to build any of the other tools.
    if ($($process.Execute(@("git.exe","restore $CERBERUS_BIN_DIR/config.winnt.txt"))) -ne 0) {
        do_error "FAILED TO RESTORE THE ORIGINAL WINDOWS CONFIG FILE."
        return -1
    }

    # Test if the git repository is in a clean state. Else issue a error message and return back
    # to the menu.
    $process.ExecuteWorkaround(@("git.exe","status"))
    if (-not($process.StandardOut().Contains("nothing to commit, working tree clean"))) {
        do_error "Repository is not clean. Check for untracked and uncommitted files."
        return
    }


    # Set up the deploy directories
    If (Test-Path("$DEPLOYMENT_ROOT_DIR")) { do_delete "$DEPLOYMENT_ROOT_DIR" }
    if (-not(New-Item "$DEPLOYMENT_BUILD_DIR" -Type Directory -Force)) {
        do_error "Failed to create deploy directory: $DEPLOYMENT_BUILD_DIR"
        return -1
    }

    # Test if the git repository is in a clean state. Else issue a error message and return back to the menu.
    if ($($process.Execute(@("git.exe","-C","`"$DEPLOYMENT_BUILD_DIR`"","clone","$CERBERUS_ROOT_DIR","Cerberus"))) -ne 0) {
        do_error "FAILED TO CLONE TO DIRECTORY: $deploypath"
        do_error "If the $DEPLOYMENT_ROOT_DIR directory exists, then delete it manually."
        return -1
    }

     # Clean up any git related items in the clone.
    @("$DEPLOYMENT_TARGET_DIR\.git","$DEPLOYMENT_TARGET_DIR\.gitignore","$DEPLOYMENT_TARGET_DIR\.gitattributes") |
    ForEach-Object {
        if (Test-Path($_)) { do_delete($_) }
    }

    # Generate parameters to pass on to the cloned builder script.
    # Only the basic parameters need to be passed on.
    [string]$buildtype = "mingw"    # Used from part of the final archive name
    $local:arguments = @("$DEPLOYMENT_TARGET_SRC_DIR/builder.ps1","-q `"$qtsdk`"", "-c `"$mingw`"", "-i `"$vsinstall`"")
    if (-not([string]::IsNullOrEmpty($qtkit))) { $arguments += @(" -k $qtkit") }
    if (-not([string]::IsNullOrEmpty($vsver))) { $arguments += @(" -y $vsver") }
    if ($msbuild -eq $true) {
        $arguments += " -b"
        $buildtype = "msvc"
    }

    # Start the cloned builder script with the parameter that were passed to the main builder script.
    if ($process.ExecuteWorkaround($arguments) -ne 0) {
        do_error "Failed deployment build of Cerberus-X"
        do_error "If the $DEPLOYMENT_ROOT_DIR directory exists, then delete it manually."
        return -1
    }

    # Check that the default files have been created before compressing to an archive. NOTE: Qt SDK's are not included in the check.
    [int]$local:filecount = 0
    $local:filelist = @("$DEPLOYMENT_TARGET_BIN_DIR\transcc_winnt.exe",
        "$DEPLOYMENT_TARGET_BIN_DIR\makedocs_winnt.exe",
        "$DEPLOYMENT_TARGET_BIN_DIR\cserver_winnt.exe",
        "$DEPLOYMENT_TARGET_BIN_DIR\Ted.exe",
        "$DEPLOYMENT_TARGET_DIR\Cerberus.exe"
    )

    $filelist | ForEach-Object {
                    do_info "CHECKING FOR: $_"
                    if (Test-Path($_)) {
                        $filecount +=1
                        do_success "Found: $_"
                    }
    }

    # Only compress if the file count match that of the array.
    if ($filecount -ne $filelist.Count) {
        do_error "Deployment file error."
        do_error "If the $cx_deploy_build directory exists, then delete it manually."
        return -1
    }

     # Get what should be the first line in the VERSION.TXT file to retrieve the version number.
     [string]$local:cx_version = $(Get-Content "$DEPLOYMENT_TARGET_DIR\VERSIONS.TXT") | ForEach-Object {
        if($_.ToString().Substring(0,1)) {
           $_.ToString() -Replace '[*v ]', ''
        }
    } | Select-Object -First 1

     # Clear out any old compressed files and recompress.
     if (Test-Path("$DEPLOYMENT_ROOT_DIR\Cerberus_$cx_version-$buildtype-qt$qtkit-winnt.zip")) { 
        Remove-Item -Force "$$DEPLOYMENT_ROOT_DIR\Cerberus_$cx_version-$buildtype-qt$qtkit-winnt.zip" -ErrorAction SilentlyContinue
    }
     Compress-Archive -Path "$DEPLOYMENT_TARGET_DIR" -DestinationPath "$DEPLOYMENT_ROOT_DIR\Cerberus_$cx_version-$buildtype-qt$qtkit-winnt.zip" -CompressionLevel Optimal
 
    do_config_txt_reset
}
