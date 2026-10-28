# Here is a list of CMake cache variable that can be passed to a CMakeLists.txt file.
# 
#   C++ TOOL TARGET
#
#------------------------------------------------------------------------------------------------------------------------------------------------------------
#                                                            |                                             |
#    The Cerberus-X preprocessor variable                    |    CMake Cache variable name or command     |    Description
#    INTERNAL are not preprocessor variables                 |                                             |
#                                                            |                                             |
#------------------------------------------------------------------------------------------------------------------------------------------------------------
#    CMAKE_OUTPUT_PATH                                       |    CX_INSTALL_PREFIX                        |    Final output path
#    CMAKE_USE_PRESET                                        |    CX_PLATFORM                              |    Select the preset to use. See the files in cmake-presets.
#    INTERNAL                                                |    CX_TARGET_TOOL                           |    Use to load the build tool options. See supported_targets in shared/cmake
#    CMAKE_PROJECT_NAME                                      |    CX_PROJECT_NAME                          |    The final output name. Passed as option on the command line.
#                                                            |                                             |
#    CX_PROJECT_VERSION                                      |    CX_PROJECT_VERSION                       |    The version number to use for the project. Passed as option on the command line.
#                                                            |                                             |
#    INTERNAL                                                |    CX_ROOT_DIR                              |      The Cerberus root directory
#    INTERNAL                                                |    CX_LIBS_DIR                              |    The path to Cerberus libs directory
#    INTERNAL                                                |    CX_PROJECT_DIR                           |    The Current project path root
#    INTERNAL                                                |    CX_TARGET_SYSTEM_NAME                    |    The tcc.target.system variable.
#    CMAKE_DEBUG_SHOW_CACHE_VARS                             |    CX_TRIGGER_CMAKE_DEBUG_SHOW_CACHE_VARS   |    Shows CACHE variable, and properties.
#                                                            |                                             |
#    INTERNAL                                                |    CX_PRESET_VAR_NAME                       |    Hold the preset name.
#                                                            |                                             |
#    INTERNAL                                                |    CX_VERBOSE_OUTPUT                        |    Boolean value to show non debug log information 
#                                                            |                                             |
#    INTERNAL                                                |    CX_TRIGGER_WIN_SOCKET2                   |    Boolean value acting as an inclusion guard for win socket 2
#                                                            |                                             |
#    {preset-config}_STATIC_BUILD                            |    CX_TRIGGER_MINGW_STATIC_BUILD            |    Boolean value to link in static runtimes.
#    {preset-config}_WINDOWS_SDK                             |    CX_WINDOWS_SDK                           |    The version of Windows SDK to use.
#    {preset-config}_SET_MSVC_PLATFORM_TOOLSET               |    -T "PLATFORM TOOLSET VERSION"            |    Set the version of the platform toolset to use. Passed as option on the command line.
#                                                            |                                             |
#    {preset-config}_COMPILER                                |    CX_OPTS_COMPILER                         |    The options to pass to the compiler.
#    INTERNAL                                                |    CX_TRIGGER_OPTS_COMPILER                 |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    {preset-config}_DEFINES                                 |    CX_OPTS_DEFINES                          |    Pass defines to the compiler
#    INTERNAL                                                |    CX_TRIGGER_OPTS_DEFINES                  |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    {preset-config}_LINKER                                  |    CX_OPTS_LINKER                           |    Pass options to the linker.
#    INTERNAL                                                |    CX_TRIGGER_OPTS_LINKER                   |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    {preset-config}_SHARED_LIBS                             |    CX_OPTS_SHARED_LIB                       |    Pass shared libraries dll,so,dylib
#    {preset-config}_SHARED_LIB_PATHS                        |    CX_PATHS_SHARED_LIB                      |    Paths to search for shared libraries.
#    INTERNAL                                                |    CX_TRIGGER_SHARED_LIBRARIES              |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    {preset-config}_STATIC_LIBS                             |    CX_OPTS_STATIC_LIB                       |    Pass shared libraries .lib,.a
#    {preset-config}_STATIC_LIB_PATHS                        |    CX_PATHS_STATIC_LIB                      |    Paths to search for static libraries.
#    INTERNAL                                                |    CX_TRIGGER_STATIC_LIBRARIES              |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    {preset-config}_INCLUDE_PATHS                           |    CX_PATHS_INCLUDE                         |    Paths to search for include files.
#    INTERNAL                                                |    CX_TRIGGER_PATHS_INCLUDE                 |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    {preset-config}_AUDIO_DRIVER                            |    CX_AUDIO_DRIVER                          |    Pass the name of the audio library to use
#    INTERNAL                                                |    CX_TRIGGER_AUDIO_DRIVER                  |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    CMAKE_NETWORK_CLIENT                                    |    CX_NETWORK_CLIENT                        |    Pass the name of the network client to use.
#    INTERNAL                                                |    CX_TRIGGER_NETWORK_CLIENT                |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    {preset-config}_FRAMEWORK_PATHS                         |    CX_PATHS_FRAMEWORKS                      |    Apple devices only. Pass search paths for frameworks.
#                                                            |                                             |
#    {preset-config}_FRAMEWORKS                              |    CX_OPTS_FRAMEWORKS                       |    Apple devices only. Pass a list of frameworks.
#    INTERNAL                                                |    CX_TRIGGER_OPTS_FRAMEWORKS               |    Boolean value acting as an inclusion guard
#                                                            |                                             |
#    {preset-config}_SOURCES                                 |    CX_OPTS_SOURCE                           |    Holds the list of additional source files to add. Note full paths.
#    {preset-config}_SOURCES_PATHS                           |    Handled by Cerberus                      |    Used to search for additional source files.
#    INTERNAL                                                |    CX_TRIGGER_OPTS_SOURCE                   |    Boolean value acting as an inclusion guard.
#                                                            |                                             |
#    {preset-config}_APP_BUNDLE_ID                           |    CX_APPLE_APP_BUNDLE_ID                   |    Apple devices only. Sets the apple bundle id
#                                                            |                                             |
#    {preset-config}_ENTITLEMENT_FILE                        |    CX_APPLE_ENTITLEMENTS_FILE               |    Apple devices only. File path for apple entitlements file.
#    INTERNAL                                                |    CX_TRIGGER_APPLE_ENTITLEMENTS_FILE       |    Boolean value acting as an inclusion guard.
#                                                            |                                             |
#    {preset-config}_APPLE_CODESIGN_ID                       |    CX_APPLE_CODESIGN                        |    Apple devices only. Sets the code sign id.
#    {preset_config}_APPLE_CODESIGN_DEVELOPMENT_TEAM         |    CX_APPLE_CODESIGN_DEVELOPMENT_TEAM       |    Apple devices only. Sets the Apple code sign team development id.
#    {preset-config}_APPLE_CODESIGN_STYLE                    |    CX_APPLE_CODESIGN_STYLE                  |    Apple devices only. Set the code singing style. Manual/Automatic
#    INTERNAL                                                |    CX_TRIGGER_APPLE_CODESIGN                |    Boolean value acting as an inclusion guard.
#------------------------------------------------------------------------------------------------------------------------------------------------------------                            
#
# NOTES:
#    Sources and their paths are resolved in the binary, and saved to file as "source-files.cmake" at target root. A CMake function should be used to add this file to the build process.
#
#    The default cmake files are in sub directories in the Cerberus/shared/cmake directory. See: README.txt in Cerberus/shared/cmake for details.
#    CMAKE_IMPORT_DEFAULT_SHARED_LIBRARIES:        Setting this to true will import all files in Cerberus/shared/cmake/shared
#    CMAKE_IMPORT_DEFAULT_STATIC_LIBRARIES:        Setting this to true will import all files in Cerberus/shared/cmake/static
#     
#    Cache variables marked as CX_TRIGGER are used function header guards to prevent empty variables from being processed. CMake may throw an error otherwise.
#    CMAKE_VERBOSE_OUTPUT:                         Cause verbose compiler and linker output for debugging.
#    CMAKE_RECONFIG:                               Used to force copying of all CMake build files, and forces CMake reconfigure.
#    CMAKE_DEBUG_LOG:                              This preprocessor is checked in the cache_resolver.cxs file, and adds this to the the CMake cache variables set(CMAKE_MESSAGE_LOG_LEVEL "DEBUG" CACHE STRING "Log level" FORCE)
#    CMAKE_DEBUG_CACHE_VARS:                       Setting this will build the application and stop, showing all teh cache variables being used.
#    CMAKE_USE_PROJECT_FILES:                      Setting this to true will by-pass the defaults in favour of the projects cmake directory.

cmake_minimum_required(VERSION 3.23)

# Include all functions.
list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/functions"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/functions/macos"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/functions/linux"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/functions/windows"
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/target_systems"
)

include(functions_common)
include(functions_triggers)

# Convert the contents of CX_PLATFORM e.g. CX_LINUX_X64 into [Linux x64]
# file functions_common.cmake: Pretty Platform Printer
pretty_platform_string("${CX_PLATFORM}" CX_PRETTY_PRESET)

#################################################
# Project Setup
project(
  ${CX_PROJECT_NAME}_project
  VERSION ${CX_PROJECT_VERSION}
  LANGUAGES C CXX
)

#################################################
# Compiler Standards
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

#################################################
# Normalise the paths into CMake format
# file functions_common.cmake: Path to Posix Path
path_to_posix(CX_PATHS_INCLUDE CX_PATHS_INCLUDE)
path_to_posix(CX_PATHS_SHARED_LIB CX_PATHS_SHARED_LIB)
path_to_posix(CX_PATHS_STATIC_LIB CX_PATHS_STATIC_LIB)
path_to_posix(CX_PATHS_FRAMEWORKS CX_PATHS_FRAMEWORKS)
path_to_posix(CX_ROOT_DIR CX_ROOT_DIR)
path_to_posix(CX_LIBS_DIR CX_LIBS_DIR)

# file function_common.cmake: Show Basic Start Information
show_start_up_info()

#################################################
# Main source file and additional source files
# file functions_triggers.cmake
set(SOURCES
	main.cpp
)

source_file_trigger(SOURCES)

#################################################
# Setup main target
add_executable(${CMAKE_PROJECT_NAME} ${SOURCES})

# Set the output name for the application
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES 
    OUTPUT_NAME "${CX_PROJECT_NAME}"
)

# Pass an option to set the project version number.
# Usage example in you code: std::cout << "Version: " << APP_VERSION << endl;
target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE 
    APP_VERSION="${PROJECT_VERSION}"
)

# ==============================================================================
# Build Output Directories Configuration
# ==============================================================================
# Directs all compiled artifacts (executables, shared/static libraries, and import
# libraries) into a single unified directory defined by CX_INSTALL_PREFIX.
#
# Target Categories:
#   - RUNTIME: Executables (.exe, binaries) and Windows DLLs (.dll)
#   - LIBRARY: Shared libraries (.so, .dylib)
#   - ARCHIVE: Static libraries (.a, .lib) and Windows import libraries (.lib)
#
# Note on Multi-Config Generators (Visual Studio, Xcode):
#   Explicitly setting the _<CONFIG> variants forces CMake to output directly to
#   CX_INSTALL_PREFIX without automatically appending Debug/Release subfolders.
# ==============================================================================
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CX_INSTALL_PREFIX}"
    LIBRARY_OUTPUT_DIRECTORY "${CX_INSTALL_PREFIX}"
    ARCHIVE_OUTPUT_DIRECTORY "${CX_INSTALL_PREFIX}"

    RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CX_INSTALL_PREFIX}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CX_INSTALL_PREFIX}"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CX_INSTALL_PREFIX}"
    RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${CX_INSTALL_PREFIX}"

    LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CX_INSTALL_PREFIX}"
    LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CX_INSTALL_PREFIX}"
    LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CX_INSTALL_PREFIX}"
    LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL "${CX_INSTALL_PREFIX}"

    ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CX_INSTALL_PREFIX}"
    ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CX_INSTALL_PREFIX}"
    ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CX_INSTALL_PREFIX}"
    ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CX_INSTALL_PREFIX}"
)

# Load tool chain specific options. Doing this way allows for easy addition of other toolchains.
# These files then handle their own targets properties etc.
#include(${CX_PLATFORM})
include(${CX_TARGET_TOOL})
load_options()

#################################################
# Setup optional parameters. As these are common, there's no need to include them to the CX_PLATFORM.cmake files.
# file functions_trigger.cmake: See that file
compiler_options_trigger()
compiler_defines_trigger()
compiler_header_paths_trigger()

linker_options_trigger()

link_externals()

# file install_linux.cmake: Show CACHE Variable and Properties
show_properties_and_cache()