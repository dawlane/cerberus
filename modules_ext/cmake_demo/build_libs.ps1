# Use this script to build libraries with dynamic environment setup based on preset name.

param(
    [string]$mingw32 = "",
    [string]$mingw64 = "",
    [string]$vsPath = "",
    [Alias("p")][string]$preset = "",
    [Alias("n")][string]$ninja = "",
    [Alias("c")][string]$cmake = "",
    [Alias("m")][string]$module = "",
    [Alias("r")][switch]$remove,
    [Alias("a")][switch]$clean_all,
    [Alias("b")][switch]$list_builders = $false,
    [Alias("g")][switch]$list_generators = $false,
    [Alias("l")][switch]$list_modules = $false,
    [Alias("h")][switch]$help = $false
)

Clear-Host

# Preserve the environment PATH exactly as it was when the script started.
$OriginalPath = $env:PATH

try {

    $ErrorActionPreference = "Stop"

    # Paths
    $rootDir = $PSScriptRoot

    # Set defaults if the user didn't pass them in
    $CerberusRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))

    if ([string]::IsNullOrEmpty($mingw32)) {
        $mingw32 = Join-Path $CerberusRoot "mingw32"
        if(-not(Test-Path("$mingw32\bin\g++.exe"))) {
            Write-Host "Path not set for MinGW 32 bit.`nEither manually edit hte file with a path, or use the generator-tool-links in the src directory to set up links."
            exit 1
        }
    }

    if ([string]::IsNullOrEmpty($mingw64)) {
        $mingw64 = Join-Path $CerberusRoot "mingw64"
        if(-not(Test-Path("$mingw64\bin\g++.exe"))) {
            Write-Host "Path not set for MinGW 64 bit.`nEither manually edit hte file with a path, or use the generator-tool-links in the src directory to set up links."
            exit 1
        }
    }

    if ([string]::IsNullOrEmpty($ninja)) {
        $ninja   = Join-Path $CerberusRoot "Ninja"
        if(-not(Test-Path("$ninja\ninja.exe"))) {
            Write-Host "Path not set for Ninja Build.`nEither manually edit hte file with a path, or use the generator-tool-links in the src directory to set up links."
            exit 1
        }
    }

    if ([string]::IsNullOrEmpty($cmake)) {
        $cmake   = Join-Path $CerberusRoot "CMake"
        if(-not(Test-Path("$cmake\bin\cmake.exe"))) {
            Write-Host "Path not set for CMake.`nEither manually edit hte file with a path, or use the generator-tool-links in the src directory to set up links."
            exit 1
        }
    }

    # Functions
    function Show-Help
    {
        Write-Host ""
        Write-Host "Usage: build_libs.ps1 [options]"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  -p, -preset <name>      Set the CMake build preset. Required unless using -a/--clean."
        Write-Host "  -n, -ninja <path>       Set the path to the ninja build binary."
        Write-Host "  -c, -cmake <path>       Set the CMake installation path."
        Write-Host "  -m, -module <path|name> Build or remove only a single target module directory."
        Write-Host "  -b, --builders          List available CMake presets for target libraries."
        Write-Host "  -r, -remove             Remove all built modules, or single module with option -m."
        Write-Host "  -a, --clean              Remove all demo_build directories."
        Write-Host "  -g, -list_generators    List supported CMake generators."
        Write-Host "  -l, -list               List directories containing a CMakeLists.txt file."
        Write-Host "  -h, -help               Display this help."
        Write-Host "  -mingw32 <path>         Set the MinGW 32-bit compiler path."
        Write-Host "  -mingw64 <path>         Set the MinGW 64-bit compiler path."
        Write-Host "  -vsPath <path>          Set explicit path to Visual Studio installation root."
        Write-Host ""
    }

    function Invoke-CMake
    {
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$Arguments,

            [Parameter(Mandatory = $true)]
            [string]$ErrorMessage
        )

        & cmake @Arguments

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "ERROR: $ErrorMessage"
            Write-Host "       Exit code: $LASTEXITCODE"
            exit $LASTEXITCODE
        }
    }

    function Get-VSInstallationPath
    {
        param(
            [string]$ExplicitPath = "",
            [string]$Year = ""
        )

        # 1. Use explicit path if provided
        if (-not [string]::IsNullOrEmpty($ExplicitPath)) {
            if (Test-Path -LiteralPath $ExplicitPath -PathType Container) {
                return (Get-Item -LiteralPath $ExplicitPath).FullName
            }
            Write-Host "WARNING: Explicitly provided -vsPath does not exist: $ExplicitPath"
        }

        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        
        # Build vswhere arguments based on year requirement
        $versionRange = switch ($Year) {
            "2019" { "[16.0,17.0)" }
            "2022" { "[17.0,18.0)" }
            "2026" { "[18.0,19.0)" }
            Default { "" }
        }

        if (Test-Path $vswhere) {
            # 2. Try vswhere with full VC component requirement
            $args = @("-products", "*", "-property", "installationPath")
            if (-not [string]::IsNullOrEmpty($versionRange)) {
                $args += @("-version", $versionRange)
            } else {
                $args += "-latest"
            }

            $detected = & $vswhere @args -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64
            if (-not [string]::IsNullOrEmpty($detected)) {
                return ($detected -split "`r?\n")[0]
            }

            # 3. Fallback: Query vswhere without strict component constraint
            $detected = & $vswhere @args
            if (-not [string]::IsNullOrEmpty($detected)) {
                return ($detected -split "`r?\n")[0]
            }
        }

        # 4. Fallback: Search common installation directories directly
        $searchYears = if ([string]::IsNullOrEmpty($Year)) { @("2026", "2022", "2019") } else { @($Year) }
        $editions = @("Community", "Professional", "Enterprise", "BuildTools", "Preview")
        $baseDirs = @("${env:ProgramFiles}", "${env:ProgramFiles(x86)}")

        foreach ($base in $baseDirs) {
            foreach ($y in $searchYears) {
                foreach ($ed in $editions) {
                    $candidate = Join-Path $base "Microsoft Visual Studio\$y\$ed"
                    $devShellDll = Join-Path $candidate "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
                    if (Test-Path -LiteralPath $devShellDll -PathType Leaf) {
                        return $candidate
                    }
                }
            }
        }

        return ""
    }

    # Help
    if ($help) {
        Show-Help
        exit 0
    }

    # Clean all build directories
    if ($clean_all) {

        Write-Host "`n========================================"
        Write-Host " CLEAN ALL BUILD DIRECTORIES"
        Write-Host "========================================"

        foreach ($LIBRARY_DIR in Get-ChildItem -LiteralPath $rootDir -Directory) {
            $libraryName = $LIBRARY_DIR.Name
            $binaryDir = Join-Path $LIBRARY_DIR.FullName "src\demo_build"
            $installDir = Join-Path $LIBRARY_DIR.FullName "demo_build"

            Write-Host "Library: $libraryName"

            if (Test-Path -Path $binaryDir) {
                Write-Host "  Removing binary path:  $binaryDir"
                Remove-Item -Path $binaryDir -Recurse -Force
            } else {
                Write-Host "  Binary path not found: $binaryDir"
            }

            if (Test-Path -Path $installDir) {
                Write-Host "  Removing install path: $installDir"
                Remove-Item -Path $installDir -Recurse -Force
            } else {
                Write-Host "  Install path not found: $installDir"
            }
            Write-Host ""
        }

        Write-Host "Cleaning complete.`n"
        exit 0
    }

    # List modules/directories containing CMakeLists.txt
    if ($list_modules) {

        Write-Host ""
        Write-Host "Directories containing CMakeLists.txt:"
        Write-Host ""

        $foundCount = 0
        Get-ChildItem -LiteralPath $rootDir -Directory | ForEach-Object {
            $hasCmake = Get-ChildItem -Path $_.FullName -Filter "CMakeLists.txt" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -ne $hasCmake) {
                Write-Host "  $($_.Name)"
                $foundCount++
            }
        }

        if ($foundCount -eq 0) {
            Write-Host "  (No directories with CMakeLists.txt found)"
        }

        Write-Host ""
        exit 0
    }

    # Check CMake
    if (-not [string]::IsNullOrEmpty($cmake)) {

        if (-not (Test-Path -LiteralPath $cmake -PathType Container)) {
            Write-Host "ERROR: CMake directory does not exist:"
            Write-Host "       $cmake"
            exit 1
        }

        $cmakeExecutable = Join-Path $cmake "bin\cmake.exe"

        if (-not (Test-Path -LiteralPath $cmakeExecutable -PathType Leaf)) {
            Write-Host "ERROR: CMake executable was not found:"
            Write-Host "       $cmakeExecutable"
            exit 1
        }

        Write-Host "Using CMake:"
        Write-Host "  $cmake"

        $env:PATH = "$cmake\bin;$env:PATH"
    }

    if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: CMake could not be found."
        Write-Host ""
        Write-Host "Install CMake or use -c/-cmake to specify its installation path."
        exit 1
    }

    # List available presets across libraries
    if ($list_builders -eq $true) {

        Write-Host
        Write-Host "========================================"
        Write-Host " AVAILABLE CMAKE PRESETS"
        Write-Host "========================================"

        $TARGET_LIBS = @()

        if (-not [string]::IsNullOrEmpty($MODULE_PATH)) {

            $TARGET_DIR = $null
            if (Test-Path -Path $MODULE_PATH -PathType Container) {
                $TARGET_DIR = (Get-Item -Path $MODULE_PATH).FullName
            }
            elseif (Test-Path -Path (Join-Path $SCRIPT_DIR $MODULE_PATH) -PathType Container) {
                $TARGET_DIR = (Get-Item -Path (Join-Path $SCRIPT_DIR $MODULE_PATH)).FullName
            }
            else {
                Write-Error "Specified module directory does not exist: $MODULE_PATH"
                exit 1
            }

            if (Test-Path -Path (Join-Path $TARGET_DIR "src/CMakeLists.txt") -PathType Leaf) {
                $TARGET_LIBS += $TARGET_DIR
            }
            elseif (Test-Path -Path (Join-Path $TARGET_DIR "CMakeLists.txt") -PathType Leaf) {
                $TARGET_LIBS += (Split-Path -Parent $TARGET_DIR)
            }

        }
        else {

            foreach ($LIBRARY_DIR in Get-ChildItem -Path $SCRIPT_DIR -Directory) {
                $libPath = $LIBRARY_DIR.FullName
                if (Test-Path -Path (Join-Path $libPath "src/CMakeLists.txt") -PathType Leaf) {
                    $TARGET_LIBS += $libPath
                }
            }

        }

        if ($TARGET_LIBS.Count -eq 0) {
            Write-Host "No CMake target libraries found."
            Write-Host
            exit 0
        }

        foreach ($LIBRARY_DIR in $TARGET_LIBS) {
            $LIBRARY_NAME = Split-Path -Leaf $LIBRARY_DIR
            $SOURCE_DIR = Join-Path $LIBRARY_DIR "src"

            Write-Host
            Write-Host "[$LIBRARY_NAME]"

            if (Test-Path -Path $SOURCE_DIR -PathType Container) {
                # Run cmake in the source directory (using pushd/popd or scoping to preserve current directory)
                Push-Location $SOURCE_DIR
                try {
                    # 2>&1 redirects standard error to standard output so it prints correctly, 
                    # and $null prevents terminating errors if cmake exits with a non-zero code.
                    cmake --list-presets 2>&1
                }
                catch {
                    # Handled via try/catch equivalent to '|| true'
                }
                Pop-Location
            }
            else {
                Write-Host "  (No src directory found)"
            }
        }

        Write-Host
        exit 0

    }

    # List generators
    if ($list_generators) {

        Write-Host ""
        Write-Host "Supported CMake Generators:"
        Write-Host ""

        try {

            $capabilities = cmake -E capabilities

            if ($LASTEXITCODE -ne 0) {
                Write-Host "ERROR: Unable to query CMake capabilities."
                exit $LASTEXITCODE
            }

            ($capabilities | ConvertFrom-Json).generators.name |
                Where-Object {
                    $_ -eq "MinGW Makefiles" -or
                    $_ -eq "Ninja" -or
                    ($_ -like "Visual Studio *" -and [int]($_ -replace '\D') -ge 162019)
                } |
                Sort-Object

        }
        catch {

            Write-Host ""
            Write-Host "ERROR: Unable to query CMake generators."
            Write-Host $_.Exception.Message
            exit 1
        }

        Write-Host ""
        exit 0
    }

    # Find libraries
    $libraries = @()

    if (-not [string]::IsNullOrEmpty($module)) {

        $targetPath = ""

        if (Test-Path -LiteralPath $module -PathType Container) {
            $targetPath = (Get-Item -LiteralPath $module).FullName
        }
        else {
            $combinedPath = Join-Path $rootDir $module
            if (Test-Path -LiteralPath $combinedPath -PathType Container) {
                $targetPath = (Get-Item -LiteralPath $combinedPath).FullName
            }
            else {
                Write-Host "ERROR: Specified module directory does not exist:"
                Write-Host "       $module"
                exit 1
            }
        }

        # Check for structure (<module>\src\CMakeLists.txt or <module>\CMakeLists.txt)
        if (Test-Path -LiteralPath (Join-Path $targetPath "src\CMakeLists.txt") -PathType Leaf) {
            $libraries = @(Get-Item -LiteralPath $targetPath)
        }
        elseif (Test-Path -LiteralPath (Join-Path $targetPath "CMakeLists.txt") -PathType Leaf) {
            $parentPath = Split-Path $targetPath -Parent
            $libraries = @(Get-Item -LiteralPath $parentPath)
        }
        else {
            Write-Host "ERROR: Target module is missing CMakeLists.txt in either:"
            Write-Host "       $targetPath\src\CMakeLists.txt"
            Write-Host "   or  $targetPath\CMakeLists.txt"
            exit 1
        }

    }
    else {

        $libraries = @(
            Get-ChildItem -LiteralPath $rootDir -Directory |
            Where-Object {
                Test-Path -LiteralPath (Join-Path $_.FullName "src\CMakeLists.txt") -PathType Leaf
            }
        )

    }

    if ($libraries.Count -eq 0) {

        Write-Host "ERROR: No CMake libraries were found."
        Write-Host ""
        Write-Host "Expected directories containing:"
        Write-Host "  <library>\src\CMakeLists.txt"
        Write-Host ""
        exit 1
    }

    # Remove build directory for preset
    if ($remove) {
        Write-Host "`n========================================"
        Write-Host " REMOVE BUILD PRESET DIRECTORIES"
        Write-Host "========================================"
        Write-Host "Preset: $Preset`n"

        foreach ($libDir in $Libraries) {
            $libraryName = Split-Path $libDir -Leaf
            $binaryDir = Join-Path $libDir "src\demo_build\$Preset"
            $installDir = Join-Path $libDir "demo_build\$Preset"

            Write-Host "Library: $libraryName"

            if (Test-Path -Path $binaryDir) {
                Write-Host "  Removing binary path:  $binaryDir"
                Remove-Item -Path $binaryDir -Recurse -Force
            } else {
                Write-Host "  Binary path not found: $binaryDir"
            }

            if (Test-Path -Path $installDir) {
                Write-Host "  Removing install path: $installDir"
                Remove-Item -Path $installDir -Recurse -Force
            } else {
                Write-Host "  Install path not found: $installDir"
            }
            Write-Host ""
        }

        Write-Host "Removal complete.`n"
        exit 0
    }

    # Validate preset
    if ([string]::IsNullOrEmpty($preset) -and -not $clean_all) {

        Write-Host "ERROR: A preset is required unless using -a/--clean."
        Write-Host ""
        Write-Host "Use -p/-preset with one of the available build presets:"
        Write-Host ""

        foreach ($library in $libraries) {

            $libraryName = $library.Name
            $sourceDir = Join-Path $library.FullName "src"

            Write-Host "[$libraryName]"

            Push-Location $sourceDir

            try {
                cmake --build --list-presets |
                    Sort-Object
            }
            finally {
                Pop-Location
            }

            Write-Host ""
        }

        exit 1
    }

    # Determine architecture
    if ($preset -match "x86") {
        $architecture = "x86"
    }
    elseif ($preset -match "x64") {
        $architecture = "x64"
    }
    else {
        Write-Host "ERROR: Unable to determine architecture from preset:"
        Write-Host "       $preset"
        Write-Host ""
        Write-Host "The preset must contain either 'x86' or 'x64'."
        exit 1
    }

    # Setup Ninja Environment
    if ($preset -match "^ninja") {
        if ([string]::IsNullOrEmpty($ninja) -or -not (Test-Path -LiteralPath $ninja -PathType Container)) {
            Write-Host "ERROR: Path to ninja build directory is invalid or empty:"
            Write-Host "       $ninja"
            exit 1
        }

        $ninjaExecutable = Join-Path $ninja "ninja.exe"
        if (-not (Test-Path -LiteralPath $ninjaExecutable -PathType Leaf)) {
            Write-Host "ERROR: Ninja executable was not found:"
            Write-Host "       $ninjaExecutable"
            exit 1
        }

        Write-Host "Using Ninja Build:"
        Write-Host "  $ninja"

        $env:PATH = "$ninja;$env:PATH"
    }

    # Setup MinGW Environment
    if ($preset -match "^(ninja-)?mingw") {

        if ($architecture -eq "x86") {
            if (-not (Test-Path -LiteralPath $mingw32 -PathType Container)) {
                Write-Host "ERROR: MinGW 32-bit directory does not exist:"
                Write-Host "       $mingw32"
                exit 1
            }

            $mingwExecutable = Join-Path $mingw32 "bin\g++.exe"

            if (-not (Test-Path -LiteralPath $mingwExecutable -PathType Leaf)) {
                Write-Host "ERROR: MinGW 32-bit compiler was not found:"
                Write-Host "       $mingwExecutable"
                exit 1
            }

            Write-Host "Using MinGW 32-bit:"
            Write-Host "  $mingw32"

            $env:PATH = "$mingw32\bin;$env:PATH"
        }
        else {
            if (-not (Test-Path -LiteralPath $mingw64 -PathType Container)) {
                Write-Host "ERROR: MinGW 64-bit directory does not exist:"
                Write-Host "       $mingw64"
                exit 1
            }

            $mingwExecutable = Join-Path $mingw64 "bin\g++.exe"

            if (-not (Test-Path -LiteralPath $mingwExecutable -PathType Leaf)) {
                Write-Host "ERROR: MinGW 64-bit compiler was not found:"
                Write-Host "       $mingwExecutable"
                exit 1
            }

            Write-Host "Using MinGW 64-bit:"
            Write-Host "  $mingw64"

            $env:PATH = "$mingw64\bin;$env:PATH"
        }

    } elseif ($preset -match "^vs(\d{4})") {

        # Setup Specific Visual Studio Environment (vsXXXX)
        $year = $Matches[1]
        $resolvedVsPath = Get-VSInstallationPath -ExplicitPath $vsPath -Year $year

        if ([string]::IsNullOrEmpty($resolvedVsPath) -or -not (Test-Path $resolvedVsPath)) {
            Write-Host "ERROR: Visual Studio $year was not found."
            Write-Host "       Please ensure Visual Studio $year is installed or specify -vsPath."
            exit 1
        }

        $vsDevShellModule = Join-Path $resolvedVsPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
        if (Test-Path $vsDevShellModule) {
            Import-Module $vsDevShellModule
            Enter-VsDevShell -VsInstallPath $resolvedVsPath -SkipAutomaticLocation -DevCmdArguments "-arch=$architecture"
            Write-Host "Initialized Visual Studio $year Environment ($architecture) from:"
            Write-Host "  $resolvedVsPath"
        }
        else {
            Write-Host "ERROR: Could not locate Microsoft.VisualStudio.DevShell.dll at:"
            Write-Host "       $vsDevShellModule"
            exit 1
        }

    } elseif ($preset -match "^ninja-msvc") {
        # Setup MSVC Environment (Latest available VS)

        $resolvedVsPath = Get-VSInstallationPath -ExplicitPath $vsPath

        if ([string]::IsNullOrEmpty($resolvedVsPath) -or -not (Test-Path $resolvedVsPath)) {
            Write-Host "ERROR: Visual Studio with C++ build tools was not found."
            Write-Host "       Please install Visual Studio C++ build tools or specify -vsPath."
            exit 1
        }

        $vsDevShellModule = Join-Path $resolvedVsPath "Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
        if (Test-Path $vsDevShellModule) {
            Import-Module $vsDevShellModule
            Enter-VsDevShell -VsInstallPath $resolvedVsPath -SkipAutomaticLocation -DevCmdArguments "-arch=$architecture"
            Write-Host "Initialized MSVC Environment ($architecture) from:"
            Write-Host "  $resolvedVsPath"
        }
        else {
            Write-Host "ERROR: Could not locate Microsoft.VisualStudio.DevShell.dll at:"
            Write-Host "       $vsDevShellModule"
            exit 1
        }
    }

    # Build configuration
    $buildConfig = @()

    if ($preset -match "^vs\d+-" -or $preset -match "msvc") {
        $buildConfig = @("--config", "Release")
    }

    # Display build information
    Write-Host ""
    Write-Host "========================================"
    Write-Host " BUILD LIBRARIES"
    Write-Host "========================================"
    Write-Host "Preset:       $preset"
    Write-Host "Architecture: $architecture"
    Write-Host "Root:         $rootDir"
    Write-Host "Libraries:    $($libraries.Count)"
    if (($cmakeVersion -ge [Version]"3.24.0")) {
        Write-Host "CMake:  $cmakeVersion"
    } else {
        Write-Host "CMake:  $cmakeVersion (does note support vs2026)"
    }
    Write-Host "========================================"
    Write-Host ""

    $builtLibraries = @()
    $skippedLibraries = @()

    # Build each library
    foreach ($library in $libraries) {

        $libraryName = $library.Name

        $sourceDir = Join-Path $library.FullName "src"
        $binaryDir = Join-Path $sourceDir "demo_build\$preset"
        $installDir = Join-Path $library.FullName "demo_build\$preset"

        Write-Host ""
        Write-Host "========================================"
        Write-Host " BUILD: $libraryName"
        Write-Host "========================================"
        Write-Host "Source:       $sourceDir"
        Write-Host "Build:        $binaryDir"
        Write-Host "Install:      $installDir"
        Write-Host "========================================"
        Write-Host ""

        # Validate source
        if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) {

            Write-Host "ERROR: Source directory does not exist:"
            Write-Host "       $sourceDir"
            exit 1

        }

        $cmakeLists = Join-Path $sourceDir "CMakeLists.txt"

        if (-not (Test-Path -LiteralPath $cmakeLists -PathType Leaf)) {

            Write-Host "ERROR: CMakeLists.txt was not found:"
            Write-Host "       $cmakeLists"
            exit 1

        }

        # Validate preset for this library
        Push-Location $sourceDir

        $PresetOutput = $null

        try {

            # Capture CMake presets output safely
            $PresetOutput = & cmake --list-presets 2>&1
            if ($LASTEXITCODE -ne 0) { 
                Write-Host "WARNING: Unable to list CMake presets for: $libraryName"
                Write-Host "         Skipping build for this module."
                $skippedLibraries += $libraryName
                continue
            }

            Write-Host "Available configure presets:"

            # Process each line of the output
            foreach ($Line in $PresetOutput) {
                # Match the preset pattern: "name" - description
                if ($Line.Trim() -match '"([^"]+)"\s*-\s*(.*)') {
                    $Name = $Matches[1].Trim()
                    $Description = $Matches[2].Trim()
                    Write-Host ('  "{0}" - {1}' -f $Name, $Description)
                }
            }

        }
        finally {

            Pop-Location

        }

        # Check if the preset name exists in double quotes anywhere in the CMake output
        $presetFound = [bool]($PresetOutput | Where-Object { $_ -match "`"$([regex]::Escape($preset))`"" })

        if (-not $presetFound) {

            Write-Host "WARNING: CMake preset '$preset' was not found for: $libraryName"
            Write-Host "         Skipping build for this module."
            $skippedLibraries += $libraryName
            continue

        }

        # Configure
        Write-Host "Configuring..."
        Write-Host ""

        Push-Location $sourceDir

        try {
            # The fresh option was only introduced in 3.24.0
            if ($cmakeVersion -ge [Version]"3.24.0") {
                Invoke-CMake `
                    -Arguments @(
                        "--fresh",
                        "--preset", $preset,
                        "-DCMAKE_INSTALL_PREFIX=$installDir"
                    ) `
                    -ErrorMessage "CMake configuration failed for '$libraryName'."

            } else {
               
                # Emulate --fresh for CMake versions older than 3.24.0
                if (Test-Path -LiteralPath $binaryDir -PathType Container) {
                    Remove-Item -LiteralPath (Join-Path $binaryDir "CMakeCache.txt") -Force
                    Remove-Item -LiteralPath (Join-Path $binaryDir "CMakeFiles") -Recurse
                }

                Invoke-CMake `
                    -Arguments @(
                        "--preset", $preset,
                        "-DCMAKE_INSTALL_PREFIX=$installDir"
                    ) `
                    -ErrorMessage "CMake configuration failed for '$libraryName'."
            
            }
        }
        finally {

            Pop-Location

        }

        # Verify build directory

        if (-not (Test-Path -LiteralPath $binaryDir -PathType Container)) {

            Write-Host ""
            Write-Host "ERROR: CMake did not create the expected build directory:"
            Write-Host "       $binaryDir"
            exit 1

        }

        # Build
        Write-Host ""
        Write-Host "Building..."
        Write-Host ""

        Invoke-CMake `
            -Arguments (@(
                "--build",
                $binaryDir
            ) + $buildConfig) `
            -ErrorMessage "Build failed for '$libraryName'."

        # Install
        Write-Host ""
        Write-Host "Installing..."
        Write-Host ""

        Invoke-CMake `
            -Arguments (@(
                "--install",
                $binaryDir
            ) + $buildConfig) `
            -ErrorMessage "Installation failed for '$libraryName'."

        # Verify installation
        if (-not (Test-Path -LiteralPath $installDir -PathType Container)) {

            Write-Host ""
            Write-Host "ERROR: Installation completed but the install directory was not found:"
            Write-Host "       $installDir"
            exit 1

        }

        Write-Host ""
        Write-Host "BUILD COMPLETE: $libraryName"
        $builtLibraries += $libraryName
    }

    # Complete
    Write-Host ""
    Write-Host "========================================"
    Write-Host " PROCESS COMPLETE"
    Write-Host "========================================"
    Write-Host ""

    if ($builtLibraries.Count -gt 0) {
        Write-Host "Built libraries:"
        foreach ($lib in $builtLibraries) {
            Write-Host "  $lib"
        }
    } else {
        Write-Host "No libraries were built."
    }

    if ($skippedLibraries.Count -gt 0) {
        Write-Host ""
        Write-Host "Skipped libraries (Preset '$preset' not found):"
        foreach ($lib in $skippedLibraries) {
            Write-Host "  $lib"
        }
    }

    Write-Host ""

}
catch {
    $line = $_.InvocationInfo.ScriptLineNumber
    $file = $_.InvocationInfo.ScriptName
    
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error occurred at line $line in $file" -ForegroundColor Red
    Write-Host ""
    exit 1
}
finally {
    # Always restore the original PATH, including when an error occurs.
    $env:PATH = $OriginalPath
}
