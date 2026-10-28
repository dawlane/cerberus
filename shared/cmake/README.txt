This directory contains the default cmake files for all of the current CMake for Cerberus-X targets.

The directories:
functions: 				All the cmake files that are common to all targets.
presets:				Contains the default CMakePresets.json file and a sub directory called presets that contains JSON imported by CMakePresets.json.
shared:					Contains the current cmake files to handle linking and installing external shared libraries and frameworks.
static:					Contains the current cmake files link into that main program.
supported_targets:		Contains sub directories for currently supported targets.
						Each sub directory has a CMakeLists.txt files and a sub directory called targets, which contains cmake files with name that matches the CX_PLATFORM cache variable.