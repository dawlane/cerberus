#####################################################################
# Internal Helper: Build STB for Linux Hosts
function(_compile_stb_linux SRC_DIR CACHE_DIR IMAGE_LIB VORBIS_LIB PRESET_NAME)
    message(STATUS "Compiling STB libraries from source for Linux preset [${PRESET_NAME}]...")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    set(STB_FLAGS "")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(STB_FLAGS "-O0" "-g")
    else()
        set(STB_FLAGS "-O3")
    endif()

    execute_process(COMMAND ${CMAKE_C_COMPILER} ${STB_FLAGS} -I"${SRC_DIR}" -c "${SRC_DIR}/stb_image.c" -o "${CACHE_DIR}/stb_image.o" WORKING_DIRECTORY "${CACHE_DIR}" RESULT_VARIABLE RES1)
    execute_process(COMMAND ${CMAKE_C_COMPILER} ${STB_FLAGS} -I"${SRC_DIR}" -c "${SRC_DIR}/stb_vorbis.c" -o "${CACHE_DIR}/stb_vorbis.o" WORKING_DIRECTORY "${CACHE_DIR}" RESULT_VARIABLE RES2)

    execute_process(COMMAND ar rcs "${IMAGE_LIB}" "${CACHE_DIR}/stb_image.o" RESULT_VARIABLE AR1)
    execute_process(COMMAND ar rcs "${VORBIS_LIB}" "${CACHE_DIR}/stb_vorbis.o" RESULT_VARIABLE AR2)

    if(NOT RES1 EQUAL 0 OR NOT RES2 EQUAL 0 OR NOT AR1 EQUAL 0 OR NOT AR2 EQUAL 0)
        message(FATAL_ERROR "Failed to build static STB dependency libraries via Linux GCC.")
    endif()
endfunction(_compile_stb_linux)

#####################################################################
# Internal Helper: Build STB for macOS Hosts
function(_compile_stb_macos SRC_DIR WORK_DIR CACHE_DIR PRESET_NAME)
    message(STATUS "Compiling STB libraries from source for macOS preset [${PRESET_NAME}]...")
    
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
        project(stb_micro_build C)
        add_library(stb_image STATIC \"${SRC_DIR}/stb_image.c\")
        add_library(stb_vorbis STATIC \"${SRC_DIR}/stb_vorbis.c\")
        target_include_directories(stb_image PUBLIC \"${SRC_DIR}\")
        target_include_directories(stb_vorbis PUBLIC \"${SRC_DIR}\")
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
        message(FATAL_ERROR "Failed to compile STB via macOS micro-build for preset [${PRESET_NAME}].")
    endif()

    # Determine multi-config vs single-config output path locations
    if(EXISTS "${WORK_DIR}/${CURRENT_BUILD_TYPE}/libstb_image.a")
        file(COPY "${WORK_DIR}/${CURRENT_BUILD_TYPE}/libstb_image.a" DESTINATION "${CACHE_DIR}")
        file(COPY "${WORK_DIR}/${CURRENT_BUILD_TYPE}/libstb_vorbis.a" DESTINATION "${CACHE_DIR}")
    else()
        file(COPY "${WORK_DIR}/libstb_image.a" DESTINATION "${CACHE_DIR}")
        file(COPY "${WORK_DIR}/libstb_vorbis.a" DESTINATION "${CACHE_DIR}")
    endif()
endfunction(_compile_stb_macos)

#####################################################################
# Internal Helper: Build STB for Windows MinGW Targets
function(_compile_stb_windows_mingw SRC_DIR CACHE_DIR IMAGE_LIB VORBIS_LIB PRESET_NAME)
    message(STATUS "Compiling STB libraries from source for MinGW preset [${PRESET_NAME}]...")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    set(STB_FLAGS "")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(STB_FLAGS "-O0" "-g")
    else()
        set(STB_FLAGS "-O3")
    endif()

    execute_process(COMMAND ${CMAKE_C_COMPILER} ${STB_FLAGS} -I"${SRC_DIR}" -c "${SRC_DIR}/stb_image.c" -o "${CACHE_DIR}/stb_image.o" WORKING_DIRECTORY "${CACHE_DIR}" RESULT_VARIABLE RES1)
    execute_process(COMMAND ${CMAKE_C_COMPILER} ${STB_FLAGS} -I"${SRC_DIR}" -c "${SRC_DIR}/stb_vorbis.c" -o "${CACHE_DIR}/stb_vorbis.o" WORKING_DIRECTORY "${CACHE_DIR}" RESULT_VARIABLE RES2)

    execute_process(COMMAND ar rcs "${IMAGE_LIB}" "${CACHE_DIR}/stb_image.o" RESULT_VARIABLE AR1)
    execute_process(COMMAND ar rcs "${VORBIS_LIB}" "${CACHE_DIR}/stb_vorbis.o" RESULT_VARIABLE AR2)

    if(NOT RES1 EQUAL 0 OR NOT RES2 EQUAL 0 OR NOT AR1 EQUAL 0 OR NOT AR2 EQUAL 0)
        message(FATAL_ERROR "Failed to build static STB dependency libraries via MinGW.")
    endif()
endfunction(_compile_stb_windows_mingw)

#####################################################################
# Internal Helper: Build STB for Visual Studio / MSVC Targets
function(_compile_stb_windows_msvc SRC_DIR WORK_DIR CACHE_DIR PRESET_NAME)
    message(STATUS "Compiling STB libraries from source for MSVC preset [${PRESET_NAME}]...")
    
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
        project(stb_micro_build C)
        add_library(stb_image STATIC \"${SRC_DIR}/stb_image.c\")
        add_library(stb_vorbis STATIC \"${SRC_DIR}/stb_vorbis.c\")
        target_include_directories(stb_image PUBLIC \"${SRC_DIR}\")
        target_include_directories(stb_vorbis PUBLIC \"${SRC_DIR}\")
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
        message(FATAL_ERROR "Failed to compile STB via Visual Studio micro-build.")
    endif()

    file(COPY "${WORK_DIR}/${CURRENT_BUILD_TYPE}/stb_image.lib" DESTINATION "${CACHE_DIR}")
    file(COPY "${WORK_DIR}/${CURRENT_BUILD_TYPE}/stb_vorbis.lib" DESTINATION "${CACHE_DIR}")
endfunction(_compile_stb_windows_msvc)

#####################################################################
# Main Entry Point Function
function(dependency_library_stb)
    if(NOT TARGET stb_image AND NOT TARGET stb_vorbis)
        cmake_path(GET CMAKE_BINARY_DIR FILENAME PRESET_NAME)
        message(STATUS "${CX_PRETTY_PRESET} Including dependency STB libraries (Isolated Preset Cache: ${PRESET_NAME})")

        set(STB_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/src/stb")
        set(STB_CACHE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/.stb_cache/${PRESET_NAME}")

        # Determine target static output strings per environment wrapper
        if(CMAKE_HOST_WIN32 AND NOT (CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES "GNU" OR CMAKE_GENERATOR MATCHES "MinGW"))
            set(FINAL_STB_IMAGE_LIB "${STB_CACHE_DIR}/stb_image.lib")
            set(FINAL_STB_VORBIS_LIB "${STB_CACHE_DIR}/stb_vorbis.lib")
            set(PRESET_STB_IMAGE "${CMAKE_BINARY_DIR}/stb_image.lib")
            set(PRESET_STB_VORBIS "${CMAKE_BINARY_DIR}/stb_vorbis.lib")
        else()
            set(FINAL_STB_IMAGE_LIB "${STB_CACHE_DIR}/libstb_image.a")
            set(FINAL_STB_VORBIS_LIB "${STB_CACHE_DIR}/libstb_vorbis.a")
            set(PRESET_STB_IMAGE "${CMAKE_BINARY_DIR}/libstb_image.a")
            set(PRESET_STB_VORBIS "${CMAKE_BINARY_DIR}/libstb_vorbis.a")
        endif()

        # Run compilation blocks conditionally per host layout environment
        if(NOT EXISTS "${FINAL_STB_IMAGE_LIB}" OR NOT EXISTS "${FINAL_STB_VORBIS_LIB}")
            if(CMAKE_HOST_UNIX AND NOT CMAKE_HOST_APPLE)
                # --- LINUX ---
                _compile_stb_linux("${STB_SRC_DIR}" "${STB_CACHE_DIR}" "${FINAL_STB_IMAGE_LIB}" "${FINAL_STB_VORBIS_LIB}" "${PRESET_NAME}")
            elseif(CMAKE_HOST_APPLE)
                # --- MACOS ---
                set(STB_WORK_DIR "${CMAKE_BINARY_DIR}/external/stb_isolated")
                _compile_stb_macos("${STB_SRC_DIR}" "${STB_WORK_DIR}" "${STB_CACHE_DIR}" "${PRESET_NAME}")
            elseif(CMAKE_HOST_WIN32)
                if(CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES "GNU" OR CMAKE_GENERATOR MATCHES "MinGW")
                    # --- WINDOWS MINGW ---
                    _compile_stb_windows_mingw("${STB_SRC_DIR}" "${STB_CACHE_DIR}" "${FINAL_STB_IMAGE_LIB}" "${FINAL_STB_VORBIS_LIB}" "${PRESET_NAME}")
                else()
                    # --- WINDOWS VISUAL STUDIO / MSVC ---
                    set(STB_WORK_DIR "${CMAKE_BINARY_DIR}/external/stb_isolated")
                    _compile_stb_windows_msvc("${STB_SRC_DIR}" "${STB_WORK_DIR}" "${STB_CACHE_DIR}" "${PRESET_NAME}")
                endif()
            endif()
        else()
            message(STATUS "${CX_PRETTY_PRESET} Using pre-built STB cache for [${PRESET_NAME}]")
        endif()

        # Copy archives directly out to match preset layout schemas
        file(COPY "${FINAL_STB_IMAGE_LIB}" DESTINATION "${CMAKE_BINARY_DIR}")
        file(COPY "${FINAL_STB_VORBIS_LIB}" DESTINATION "${CMAKE_BINARY_DIR}")

        # Declare the targets cleanly in project memory mappings
        add_library(stb_image STATIC IMPORTED GLOBAL)
        set_target_properties(stb_image PROPERTIES
            IMPORTED_LOCATION "${PRESET_STB_IMAGE}"
            INTERFACE_INCLUDE_DIRECTORIES "${STB_SRC_DIR}"
        )

        add_library(stb_vorbis STATIC IMPORTED GLOBAL)
        set_target_properties(stb_vorbis PROPERTIES
            IMPORTED_LOCATION "${PRESET_STB_VORBIS}"
            INTERFACE_INCLUDE_DIRECTORIES "${STB_SRC_DIR}"
        )
    endif()

    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE stb_image stb_vorbis)
    target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE "${STB_SRC_DIR}")
endfunction(dependency_library_stb)