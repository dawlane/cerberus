# This script is used to generate mingw .dll.a import libraries.
# Remember that libraries that export C++ mangled function names will not work.
# A lot of libraries that are written for multiple compiler will export C style function names.

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
    [string]$mingw = "",
    [string]$dir =""
)

if([string]::IsNullOrEmpty($mingw)){
    write-host "Set the mingw32 path to use -mingw path_to_mingw"
    exit 1
}

if([string]::IsNullOrEmpty($dir)){
    write-host "Set the root path to where the msvc compiled libraries are."
    exit 1
}

$env:PATH="$mingw\bin;${env:PATH}"

$dllArray = @(Get-ChildItem -Path $dir -Filter *.dll -Recurse)

# Process the dll's
foreach ($dll in $dllArray) {
    # Get the directory path and the base name (filename without extension)
    $dir  = $dll.DirectoryName
    $name = $dll.BaseName

    # Define the temporary .def file and final .dll.a output paths
    $defFile = Join-Path $dir "$name.def"
    $libName = if ($name -like 'lib*') { $name } else { "lib$name" }
    $libFile = Join-Path $dir "${libName}.dll.a"

    Write-Host "Processing: $($dll.Name)..." -ForegroundColor Cyan

    # Generate the definition (.def) file from the DLL
    gendef $dll.FullName

    # 4. Generate the MinGW import library (.dll.a) from the .def file
    dlltool -d $defFile -l $libFile -D $dll.FullName

    # Clean up the temporary .def file
    if (Test-Path $defFile) { Remove-Item $defFile }
}

Write-Host "All MinGW import libraries (.dll.a) generated successfully!" -ForegroundColor Green