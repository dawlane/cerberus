#####################################################################
# Internal Helper: Compile GLFW for Linux Hosts
function(_compile_glfw_linux SRC_DIR WORK_DIR CACHE_DIR OUTPUT_LIB FINAL_LIB PRESET_NAME)
    message(STATUS "Compiling GLFW dependency from source for Linux preset [${PRESET_NAME}]...")

    if(NOT CMAKE_BUILD_TYPE)
        set(CURRENT_BUILD_TYPE "Release")
    else()
        set(CURRENT_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    endif()

    file(MAKE_DIRECTORY "${WORK_DIR}")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    execute_process(
        COMMAND ${CMAKE_COMMAND} 
            "-G${CMAKE_GENERATOR}"
            "-DCMAKE_BUILD_TYPE=${CURRENT_BUILD_TYPE}"
            "-DBUILD_SHARED_LIBS=OFF"
            "-DGLFW_BUILD_DOCS=OFF"
            "-DGLFW_BUILD_TESTS=OFF"
            "-DGLFW_BUILD_EXAMPLES=OFF"
            "-DGLFW_INSTALL=OFF"
            "-DGLFW_BUILD_WAYLAND=OFF"
            "${SRC_DIR}"
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE CONFIG_RESULT
    )

    if(NOT CONFIG_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to configure GLFW dependency for Linux preset ${PRESET_NAME}.")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build . --config ${CURRENT_BUILD_TYPE}
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE BUILD_RESULT
    )

    if(NOT BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to compile GLFW dependency for Linux preset ${PRESET_NAME}.")
    endif()

    file(COPY "${OUTPUT_LIB}" DESTINATION "${CACHE_DIR}")
endfunction(_compile_glfw_linux)

#####################################################################
# Internal Helper: Compile GLFW for macOS Hosts
function(_compile_glfw_macos SRC_DIR WORK_DIR CACHE_DIR OUTPUT_LIB FINAL_LIB PRESET_NAME)
    message(STATUS "Compiling GLFW dependency from source for macOS preset [${PRESET_NAME}]...")

    if(NOT CMAKE_BUILD_TYPE)
        set(CURRENT_BUILD_TYPE "Release")
    else()
        set(CURRENT_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    endif()

    file(MAKE_DIRECTORY "${WORK_DIR}")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    # Start constructing base arguments
    set(CONFIG_CMD
        "${CMAKE_COMMAND}"
        "-G${CMAKE_GENERATOR}"
        "-DCMAKE_BUILD_TYPE=${CURRENT_BUILD_TYPE}"
        "-DBUILD_SHARED_LIBS=OFF"
        "-DGLFW_BUILD_DOCS=OFF"
        "-DGLFW_BUILD_TESTS=OFF"
        "-DGLFW_BUILD_EXAMPLES=OFF"
        "-DGLFW_INSTALL=OFF"
        "-DGLFW_BUILD_COCOA=ON"
    )

    # Escape semicolons in CMAKE_OSX_ARCHITECTURES so execute_process treats it as one string
    if(CMAKE_OSX_ARCHITECTURES)
        string(REPLACE ";" "\\;" ESCAPED_ARCHS "${CMAKE_OSX_ARCHITECTURES}")
        list(APPEND CONFIG_CMD "-DCMAKE_OSX_ARCHITECTURES=${ESCAPED_ARCHS}")
    endif()

    if(CMAKE_OSX_DEPLOYMENT_TARGET)
        list(APPEND CONFIG_CMD "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}")
    endif()

    # Append source directory as final parameter
    list(APPEND CONFIG_CMD "${SRC_DIR}")

    execute_process(
        COMMAND ${CONFIG_CMD}
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE CONFIG_RESULT
    )

    if(NOT CONFIG_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to configure GLFW dependency for macOS preset ${PRESET_NAME}.")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build . --config ${CURRENT_BUILD_TYPE}
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE BUILD_RESULT
    )

    if(NOT BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to compile GLFW dependency for macOS preset ${PRESET_NAME}.")
    endif()

    # Handle single-config vs multi-config (Xcode/Ninja Multi-Config) output paths
    if(EXISTS "${WORK_DIR}/src/${CURRENT_BUILD_TYPE}/libglfw3.a")
        set(ACTUAL_OUTPUT "${WORK_DIR}/src/${CURRENT_BUILD_TYPE}/libglfw3.a")
    elseif(EXISTS "${WORK_DIR}/src/libglfw3.a")
        set(ACTUAL_OUTPUT "${WORK_DIR}/src/libglfw3.a")
    else()
        message(FATAL_ERROR "GLFW build succeeded, but libglfw3.a was not found in ${WORK_DIR}/src/")
    endif()

    file(COPY "${ACTUAL_OUTPUT}" DESTINATION "${CACHE_DIR}")
endfunction(_compile_glfw_macos)

#####################################################################
# Internal Helper: Compile GLFW for Windows MinGW Targets
function(_compile_glfw_windows_mingw SRC_DIR WORK_DIR CACHE_DIR OUTPUT_LIB FINAL_LIB PRESET_NAME)

    message(STATUS "Compiling GLFW dependency from source for MinGW preset [${PRESET_NAME}]...")

    if(NOT CMAKE_BUILD_TYPE)
        set(CURRENT_BUILD_TYPE "Release")
    else()
        set(CURRENT_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    endif()

    file(MAKE_DIRECTORY "${WORK_DIR}")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    execute_process(
        COMMAND ${CMAKE_COMMAND} 
            "-G${CMAKE_GENERATOR}"
            "-DCMAKE_BUILD_TYPE=${CURRENT_BUILD_TYPE}"
            "-DBUILD_SHARED_LIBS=OFF"
            "-DGLFW_BUILD_DOCS=OFF"
            "-DGLFW_BUILD_TESTS=OFF"
            "-DGLFW_BUILD_EXAMPLES=OFF"
            "-DGLFW_INSTALL=OFF"
            "${SRC_DIR}"
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE CONFIG_RESULT
    )

    if(NOT CONFIG_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to configure GLFW dependency for MinGW preset ${PRESET_NAME}.")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build . --config ${CURRENT_BUILD_TYPE}
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE BUILD_RESULT
    )

    if(NOT BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to compile GLFW dependency for MinGW preset ${PRESET_NAME}.")
    endif()

    file(COPY "${OUTPUT_LIB}" DESTINATION "${CACHE_DIR}")
endfunction(_compile_glfw_windows_mingw)

#####################################################################
# Internal Helper: Compile GLFW for Windows MSVC Targets
function(_compile_glfw_windows_msvc SRC_DIR WORK_DIR CACHE_DIR OUTPUT_LIB FINAL_LIB PRESET_NAME)
    message(STATUS "Compiling GLFW dependency from source for MSVC preset [${PRESET_NAME}]...")

    if(NOT CMAKE_BUILD_TYPE)
        set(CURRENT_BUILD_TYPE "Release")
    else()
        set(CURRENT_BUILD_TYPE ${CMAKE_BUILD_TYPE})
    endif()

    file(MAKE_DIRECTORY "${WORK_DIR}")
    file(MAKE_DIRECTORY "${CACHE_DIR}")

    execute_process(
        COMMAND ${CMAKE_COMMAND} 
            "-G${CMAKE_GENERATOR}"
            "-A${CMAKE_GENERATOR_PLATFORM}" # Forwards Win32/x64 architecture context flags if present
            "-DCMAKE_BUILD_TYPE=${CURRENT_BUILD_TYPE}"
            "-DBUILD_SHARED_LIBS=OFF"
            "-DGLFW_BUILD_DOCS=OFF"
            "-DGLFW_BUILD_TESTS=OFF"
            "-DGLFW_BUILD_EXAMPLES=OFF"
            "-DGLFW_INSTALL=OFF"
            "${SRC_DIR}"
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE CONFIG_RESULT
    )

    if(NOT CONFIG_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to configure GLFW dependency for MSVC preset ${PRESET_NAME}.")
    endif()

    execute_process(
        COMMAND ${CMAKE_COMMAND} --build . --config ${CURRENT_BUILD_TYPE}
        WORKING_DIRECTORY "${WORK_DIR}"
        RESULT_VARIABLE BUILD_RESULT
    )

    if(NOT BUILD_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to compile GLFW dependency for MSVC preset ${PRESET_NAME}.")
    endif()

    file(COPY "${OUTPUT_LIB}" DESTINATION "${CACHE_DIR}")
endfunction(_compile_glfw_windows_msvc)

#####################################################################
# Dependencies for GLFW
function(dependency_library_glfw)
    if(NOT TARGET glfw)
        cmake_path(GET CMAKE_BINARY_DIR FILENAME PRESET_NAME)
        message(STATUS "${CX_PRETTY_PRESET} Including dependency GLFW (Isolated Preset Cache: ${PRESET_NAME})")

        set(GLFW_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/src/glfw")
        set(GLFW_CACHE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/.glfw_cache/${PRESET_NAME}")
        set(GLFW_WORK_DIR "${CMAKE_BINARY_DIR}/external/glfw_isolated")

        # Set fallback build type text variable
        if(NOT CMAKE_BUILD_TYPE)
            set(CURRENT_BUILD_TYPE "Release")
        else()
            set(CURRENT_BUILD_TYPE ${CMAKE_BUILD_TYPE})
        endif()

        # 1. Platform routing matching architectural configurations
        if(CMAKE_HOST_UNIX AND NOT CMAKE_HOST_APPLE)
            # --- LINUX SPECIFIC PATHS ---
            set(FINAL_STATIC_LIB "${GLFW_CACHE_DIR}/libglfw3.a")
            set(GLFW_INTERNAL_OUTPUT "${GLFW_WORK_DIR}/src/libglfw3.a")
            set(PRESET_STATIC_LIB "${CMAKE_BINARY_DIR}/libglfw3.a")

            if(NOT EXISTS "${FINAL_STATIC_LIB}")
                _compile_glfw_linux("${GLFW_SRC_DIR}" "${GLFW_WORK_DIR}" "${GLFW_CACHE_DIR}" "${GLFW_INTERNAL_OUTPUT}" "${FINAL_STATIC_LIB}" "${PRESET_NAME}")
            else()
                message(STATUS "${CX_PRETTY_PRESET} Using pre-built GLFW Linux cache for [${PRESET_NAME}]")
            endif()

        elseif(CMAKE_HOST_WIN32)
            if(CMAKE_CXX_COMPILER_ID MATCHES "GNU" OR CMAKE_C_COMPILER_ID MATCHES "GNU" OR CMAKE_GENERATOR MATCHES "MinGW")
                # --- WINDOWS MINGW SPECIFIC PATHS ---
                set(FINAL_STATIC_LIB "${GLFW_CACHE_DIR}/libglfw3.a")
                set(GLFW_INTERNAL_OUTPUT "${GLFW_WORK_DIR}/src/libglfw3.a")
                set(PRESET_STATIC_LIB "${CMAKE_BINARY_DIR}/libglfw3.a")

                if(NOT EXISTS "${FINAL_STATIC_LIB}")
                    _compile_glfw_windows_mingw("${GLFW_SRC_DIR}" "${GLFW_WORK_DIR}" "${GLFW_CACHE_DIR}" "${GLFW_INTERNAL_OUTPUT}" "${FINAL_STATIC_LIB}" "${PRESET_NAME}")
                else()
                    message(STATUS "${CX_PRETTY_PRESET} Using pre-built GLFW MinGW cache for [${PRESET_NAME}]")
                endif()
            else()
                # --- WINDOWS MSVC SPECIFIC PATHS ---
                set(FINAL_STATIC_LIB "${GLFW_CACHE_DIR}/glfw3.lib")
                set(GLFW_INTERNAL_OUTPUT "${GLFW_WORK_DIR}/src/${CURRENT_BUILD_TYPE}/glfw3.lib")
                set(PRESET_STATIC_LIB "${CMAKE_BINARY_DIR}/glfw3.lib")

                if(NOT EXISTS "${FINAL_STATIC_LIB}")
                    _compile_glfw_windows_msvc("${GLFW_SRC_DIR}" "${GLFW_WORK_DIR}" "${GLFW_CACHE_DIR}" "${GLFW_INTERNAL_OUTPUT}" "${FINAL_STATIC_LIB}" "${PRESET_NAME}")
                else()
                    message(STATUS "${CX_PRETTY_PRESET} Using pre-built GLFW MSVC cache for [${PRESET_NAME}]")
                endif()
            endif()

        elseif(CMAKE_HOST_APPLE)
            # --- MACOS SPECIFIC PATHS ---
            set(FINAL_STATIC_LIB "${GLFW_CACHE_DIR}/libglfw3.a")
            set(GLFW_INTERNAL_OUTPUT "${GLFW_WORK_DIR}/src/libglfw3.a")
            set(PRESET_STATIC_LIB "${CMAKE_BINARY_DIR}/libglfw3.a")

            if(NOT EXISTS "${FINAL_STATIC_LIB}")
                _compile_glfw_macos("${GLFW_SRC_DIR}" "${GLFW_WORK_DIR}" "${GLFW_CACHE_DIR}" "${GLFW_INTERNAL_OUTPUT}" "${FINAL_STATIC_LIB}" "${PRESET_NAME}")
            else()
                message(STATUS "${CX_PRETTY_PRESET} Using pre-built GLFW macOS cache for [${PRESET_NAME}]")
            endif()
        endif()

        # 2. Mirror layout matching preset output mapping rules
        file(COPY "${FINAL_STATIC_LIB}" DESTINATION "${CMAKE_BINARY_DIR}")

        # 3. Create global reference target points
        add_library(glfw STATIC IMPORTED GLOBAL)
        set_target_properties(glfw PROPERTIES
            IMPORTED_LOCATION "${PRESET_STATIC_LIB}"
            INTERFACE_INCLUDE_DIRECTORIES "${GLFW_SRC_DIR}/include"
        )

        find_package(OpenGL REQUIRED)
        if(TARGET OpenGL::GL)
            set_target_properties(OpenGL::GL PROPERTIES IMPORTED_GLOBAL TRUE)
            debug_log("function dependency_library_glfw: TARGET GL SELECTED")
        endif()

        if(TARGET OpenGL::GLU)
            set_target_properties(OpenGL::GLU PROPERTIES IMPORTED_GLOBAL TRUE)
            debug_log("function dependency_library_glfw: TARGET GLU SELECTED")
        endif()
    endif()

    if(APPLE)
        find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
        find_library(IOKIT_FRAMEWORK IOKit REQUIRED)
        find_library(COREVIDEO_FRAMEWORK CoreVideo REQUIRED)
        find_library(QUARTZCORE_FRAMEWORK QuartzCore REQUIRED)

        target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE 
            glfw 
            OpenGL::GL 
            ${COCOA_FRAMEWORK} 
            ${IOKIT_FRAMEWORK} 
            ${COREVIDEO_FRAMEWORK}
            ${QUARTZCORE_FRAMEWORK}
        )
    else()
        target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE glfw OpenGL::GL)
    endif()

endfunction(dependency_library_glfw)