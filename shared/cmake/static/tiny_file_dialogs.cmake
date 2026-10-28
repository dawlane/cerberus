#####################################################################
# Internal Helper: Build Tiny File Dialogs for Linux Hosts
function(_compile_tinyfd_linux SRC_DIR CACHE_DIR FINAL_LIB PRESET_NAME)
    message(STATUS "Compiling Tiny File Dialogs from source for Linux preset [${PRESET_NAME}]...")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    set(TINYFD_FLAGS "")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(TINYFD_FLAGS "-O0" "-g")
    else()
        set(TINYFD_FLAGS "-O3")
    endif()

    execute_process(COMMAND ${CMAKE_C_COMPILER} ${TINYFD_FLAGS} -I"${SRC_DIR}" -c "${SRC_DIR}/tinyfiledialogs.c" -o "${CACHE_DIR}/tinyfiledialogs.o" WORKING_DIRECTORY "${CACHE_DIR}" RESULT_VARIABLE RES1)
    execute_process(COMMAND ar rcs "${FINAL_LIB}" "${CACHE_DIR}/tinyfiledialogs.o" RESULT_VARIABLE AR1)

    if(NOT RES1 EQUAL 0 OR NOT AR1 EQUAL 0)
        message(FATAL_ERROR "Failed to build static Tiny File Dialogs dependency library via Linux GCC.")
    endif()
endfunction(_compile_tinyfd_linux)

#####################################################################
# Internal Helper: Build Tiny File Dialogs for macOS Hosts
function(_compile_tinyfd_macos SRC_DIR WORK_DIR CACHE_DIR PRESET_NAME)
    message(STATUS "Compiling Tiny File Dialogs from source for macOS preset [${PRESET_NAME}]...")
    
    file(MAKE_DIRECTORY "${WORK_DIR}")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    if(NOT CMAKE_BUILD_TYPE)
        set(CURRENT_BUILD_TYPE "Release")
    else()
        set(CURRENT_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    endif()

    # Create micro-CMakeLists.txt dynamically
    file(WRITE "${WORK_DIR}/CMakeLists.txt" "
        cmake_minimum_required(VERSION 3.23)
        project(tinyfd_micro_build C)
        add_library(tinyfiledialogs STATIC \"${SRC_DIR}/tinyfiledialogs.c\")
        target_include_directories(tinyfiledialogs PUBLIC \"${SRC_DIR}\")
    ")

    # Build the configure command list safely
    set(CONFIG_CMD
        "${CMAKE_COMMAND}"
        "-G${CMAKE_GENERATOR}"
        "-DCMAKE_BUILD_TYPE=${CURRENT_BUILD_TYPE}"
    )

    # Safely escape multi-architecture lists (e.g., x86_64;arm64) for universal builds
    if(CMAKE_OSX_ARCHITECTURES)
        string(REPLACE ";" "\\;" ESCAPED_ARCHS "${CMAKE_OSX_ARCHITECTURES}")
        list(APPEND CONFIG_CMD "-DCMAKE_OSX_ARCHITECTURES=${ESCAPED_ARCHS}")
    endif()

    if(CMAKE_OSX_DEPLOYMENT_TARGET)
        list(APPEND CONFIG_CMD "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}")
    endif()

    list(APPEND CONFIG_CMD ".")

    execute_process(
        COMMAND ${CONFIG_CMD}
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE RES_CONF
    )

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build . --config ${CURRENT_BUILD_TYPE}
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE RES_BLD
    )

    if(NOT RES_CONF EQUAL 0 OR NOT RES_BLD EQUAL 0)
        message(FATAL_ERROR "Failed to compile Tiny File Dialogs via macOS micro-build for preset [${PRESET_NAME}].")
    endif()

    # Determine multi-config vs single-config output path locations
    if(EXISTS "${WORK_DIR}/${CURRENT_BUILD_TYPE}/libtinyfiledialogs.a")
        file(COPY "${WORK_DIR}/${CURRENT_BUILD_TYPE}/libtinyfiledialogs.a" DESTINATION "${CACHE_DIR}")
    elseif(EXISTS "${WORK_DIR}/libtinyfiledialogs.a")
        file(COPY "${WORK_DIR}/libtinyfiledialogs.a" DESTINATION "${CACHE_DIR}")
    else()
        message(FATAL_ERROR "Tiny File Dialogs build succeeded, but libtinyfiledialogs.a was not found in ${WORK_DIR}")
    endif()
endfunction(_compile_tinyfd_macos)

#####################################################################
# Internal Helper: Build Tiny File Dialogs for Windows MinGW Targets
function(_compile_tinyfd_windows_mingw SRC_DIR CACHE_DIR FINAL_LIB PRESET_NAME)
    message(STATUS "Compiling Tiny File Dialogs from source for MinGW preset [${PRESET_NAME}]...")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    set(TINYFD_FLAGS "")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(TINYFD_FLAGS "-O0" "-g")
    else()
        set(TINYFD_FLAGS "-O3")
    endif()

    execute_process(COMMAND ${CMAKE_C_COMPILER} ${TINYFD_FLAGS} -I"${SRC_DIR}" -c "${SRC_DIR}/tinyfiledialogs.c" -o "${CACHE_DIR}/tinyfiledialogs.o" WORKING_DIRECTORY "${CACHE_DIR}" RESULT_VARIABLE RES1)
    execute_process(COMMAND ar rcs "${FINAL_LIB}" "${CACHE_DIR}/tinyfiledialogs.o" RESULT_VARIABLE AR1)

    if(NOT RES1 EQUAL 0 OR NOT AR1 EQUAL 0)
        message(FATAL_ERROR "Failed to build static Tiny File Dialogs dependency library via MinGW.")
    endif()
endfunction(_compile_tinyfd_windows_mingw)

#####################################################################
# Internal Helper: Build Tiny File Dialogs for Visual Studio / MSVC Targets
function(_compile_tinyfd_windows_msvc SRC_DIR WORK_DIR CACHE_DIR PRESET_NAME)
    message(STATUS "Compiling Tiny File Dialogs from source for MSVC preset [${PRESET_NAME}]...")
    
    file(MAKE_DIRECTORY "${WORK_DIR}")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    if(NOT CMAKE_BUILD_TYPE)
        set(CURRENT_BUILD_TYPE "Release")
    else()
        set(CURRENT_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    endif()

    # Create micro-CMakeLists.txt dynamically
    file(WRITE "${WORK_DIR}/CMakeLists.txt" "
        cmake_minimum_required(VERSION 3.23)
        project(tinyfd_micro_build C)
        add_library(tinyfiledialogs STATIC \"${SRC_DIR}/tinyfiledialogs.c\")
        target_include_directories(tinyfiledialogs PUBLIC \"${SRC_DIR}\")
    ")

    # Pass "." explicitly to identify the source path and suppress the warning
    execute_process(
        COMMAND ${CMAKE_COMMAND} 
            "-G${CMAKE_GENERATOR}"
            "-A${CMAKE_GENERATOR_PLATFORM}"
            "-DCMAKE_BUILD_TYPE=${CURRENT_BUILD_TYPE}"
            "." 
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE RES_CONF
    )

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build . --config ${CURRENT_BUILD_TYPE}
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE RES_BLD
    )

    if(NOT RES_CONF EQUAL 0 OR NOT RES_BLD EQUAL 0)
        message(FATAL_ERROR "Failed to compile Tiny File Dialogs via Visual Studio micro-build.")
    endif()

    file(COPY "${WORK_DIR}/${CURRENT_BUILD_TYPE}/tinyfiledialogs.lib" DESTINATION "${CACHE_DIR}")
endfunction(_compile_tinyfd_windows_msvc)

#####################################################################
# Main Entry Point Function
function(dependency_library_tiny_file_dialogs)
    # Check if the global target has already been created in memory
    if(NOT TARGET tinyfiledialogs)
        # 1. Dynamically extract the exact Preset Directory Name (e.g., "linux-x64-debug")
        cmake_path(GET CMAKE_BINARY_DIR FILENAME PRESET_NAME)
        message(STATUS "${CX_PRETTY_PRESET} Including dependency Tiny Files Dialogs library (Isolated Preset Cache: ${PRESET_NAME})")

        # 2. Paths to files and cache target directories
        set(TINYFD_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/src/tinyfiledialogs")
        set(TINYFD_CACHE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/.tinyfd_cache/${PRESET_NAME}")

        # Determine target static output strings per environment wrapper
        if(CMAKE_HOST_WIN32 AND NOT (CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES "GNU" OR CMAKE_GENERATOR MATCHES "MinGW"))
            set(FINAL_TINYFD_LIB "${TINYFD_CACHE_DIR}/tinyfiledialogs.lib")
            set(PRESET_TINYFD "${CMAKE_BINARY_DIR}/tinyfiledialogs.lib")
        else()
            set(FINAL_TINYFD_LIB "${TINYFD_CACHE_DIR}/libtinyfiledialogs.a")
            set(PRESET_TINYFD "${CMAKE_BINARY_DIR}/libtinyfiledialogs.a")
        endif()

        # Run compilation blocks conditionally per host layout environment
        if(NOT EXISTS "${FINAL_TINYFD_LIB}")
            if(CMAKE_HOST_UNIX AND NOT CMAKE_HOST_APPLE)
                # --- LINUX ---
                _compile_tinyfd_linux("${TINYFD_SRC_DIR}" "${TINYFD_CACHE_DIR}" "${FINAL_TINYFD_LIB}" "${PRESET_NAME}")
            elseif(CMAKE_HOST_APPLE)
                # --- MACOS ---
                set(TINYFD_WORK_DIR "${CMAKE_BINARY_DIR}/external/tinyfd_isolated")
                _compile_tinyfd_macos("${TINYFD_SRC_DIR}" "${TINYFD_WORK_DIR}" "${TINYFD_CACHE_DIR}" "${PRESET_NAME}")
            elseif(CMAKE_HOST_WIN32)
                if(CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES "GNU" OR CMAKE_GENERATOR MATCHES "MinGW")
                    # --- WINDOWS MINGW ---
                    _compile_tinyfd_windows_mingw("${TINYFD_SRC_DIR}" "${TINYFD_CACHE_DIR}" "${FINAL_TINYFD_LIB}" "${PRESET_NAME}")
                else()
                    # --- WINDOWS VISUAL STUDIO / MSVC ---
                    set(TINYFD_WORK_DIR "${CMAKE_BINARY_DIR}/external/tinyfd_isolated")
                    _compile_tinyfd_windows_msvc("${TINYFD_SRC_DIR}" "${TINYFD_WORK_DIR}" "${TINYFD_CACHE_DIR}" "${PRESET_NAME}")
                endif()
            endif()
        else()
            message(STATUS "${CX_PRETTY_PRESET} Using pre-built Tiny File Dialogs cache for [${PRESET_NAME}]")
        endif()

        # Copy archive directly out to match preset layout schemas
        file(COPY "${FINAL_TINYFD_LIB}" DESTINATION "${CMAKE_BINARY_DIR}")

        # Declare the target cleanly in project memory mappings
        add_library(tinyfiledialogs STATIC IMPORTED GLOBAL)
        set_target_properties(tinyfiledialogs PROPERTIES
            IMPORTED_LOCATION "${PRESET_TINYFD}"
            INTERFACE_INCLUDE_DIRECTORIES "${TINYFD_SRC_DIR}"
        )
    endif()

    # Link immediately (Removes deferred timing bugs completely)
    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE tinyfiledialogs)
    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE "${TINYFD_SRC_DIR}")

endfunction(dependency_library_tiny_file_dialogs)