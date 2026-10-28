cmake_minimum_required(VERSION 3.23)

project(
    cx_static_library_message
    VERSION 1.0.0
    LANGUAGES CXX
)

# Source / include directories
set(
    CX_SOURCE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

set(
    CX_INCLUDE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/../include"
)

add_library(
    cx_static_library_message
    STATIC
    "${CX_SOURCE_DIR}/cx_static_library.cpp"
)

# Public headers
target_include_directories(
    cx_static_library_message
    PUBLIC
        "${CX_INCLUDE_DIR}"
)

set(
    CX_INSTALL_LIB_DIR
    "lib"
)

install(
    TARGETS
        cx_static_library_message
)