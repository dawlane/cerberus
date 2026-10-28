cmake_minimum_required(VERSION 3.23)
project(cx_framework_hexagon LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Public framework header
set(CX_FRAMEWORK_PUBLIC_HEADER
    "${CMAKE_CURRENT_SOURCE_DIR}/../include/cx_macos_framework_hexagon.h"
)

# Define the Framework Target
add_library(cx_framework_hexagon SHARED
    cx_macos_framework.cpp
    "${CX_FRAMEWORK_PUBLIC_HEADER}"
)

# Make public header available to the framework source
target_include_directories(cx_framework_hexagon
    PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/../include"
)

# Configure Target Properties for Apple Framework Bundle
set_target_properties(cx_framework_hexagon PROPERTIES
    FRAMEWORK TRUE
    FRAMEWORK_VERSION A
    MACOSX_FRAMEWORK_IDENTIFIER com.example.cx_framework_hexagon
    MACOSX_FRAMEWORK_SHORT_VERSION_STRING "1.0.0"
    MACOSX_FRAMEWORK_BUNDLE_VERSION "1.0.0"
    PUBLIC_HEADER "${CX_FRAMEWORK_PUBLIC_HEADER}"
    OUTPUT_NAME "cx_framework_hexagon"
    INSTALL_RPATH "@executable_path/../Frameworks"
)

# Rule to copy header into the Framework bundle during build
set_source_files_properties(
    "${CX_FRAMEWORK_PUBLIC_HEADER}"
    PROPERTIES
    MACOSX_PACKAGE_LOCATION Headers
)

install(
    TARGETS cx_framework_hexagon
    FRAMEWORK DESTINATION "${CMAKE_INSTALL_PREFIX}"
)