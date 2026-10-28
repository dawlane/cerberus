cmake_minimum_required(VERSION 3.23)

project(cx_shared_library_upper
    VERSION 1.0.0
    LANGUAGES CXX
)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CX_SOURCE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}"
)

set(CX_INCLUDE_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/../include"
)

add_library(
    cx_shared_library_upper
    SHARED
    "${CX_SOURCE_DIR}/cx_shared_library_upper.cpp"
)

target_compile_definitions(
    cx_shared_library_upper
    PRIVATE 
        CX_LIBRARY_BUILD
)

target_include_directories(
    cx_shared_library_upper
    PUBLIC
        $<BUILD_INTERFACE:${CX_INCLUDE_DIR}>
        $<INSTALL_INTERFACE:include>
)

include(GNUInstallDirs)

install(
    TARGETS cx_shared_library_upper
    LIBRARY DESTINATION bin
)

install(
    CODE "
        file(MAKE_DIRECTORY
            \"\${CMAKE_INSTALL_PREFIX}/lib\"
        )

        execute_process(
            COMMAND
                \"\${CMAKE_COMMAND}\"
                -E create_symlink
                \"../bin/$<TARGET_FILE_NAME:cx_shared_library_upper>\"
                \"\${CMAKE_INSTALL_PREFIX}/lib/$<TARGET_FILE_NAME:cx_shared_library_upper>\"
        )
    "
)