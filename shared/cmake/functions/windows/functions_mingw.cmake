#################################################
# Common functions for MinGW builds

# Depending on the vendor. MinGW may or may not be set up to build stand alone binaries.
# The functions here are used to either statically link, or distribute the runtime libraries.
# NOTE: There are certain licence issues that MUST be adhered to.

#################################################
# MinGW: Set Static Build
#################################################
function(set_static_linking)

    if(NOT DEFINED CX_TRIGGER_MINGW_STATIC_BUILD)
        debug_log("function set_static_linking: Setting static linking of runtimes disabled")
        return()
    endif()

    target_link_options(${CMAKE_PROJECT_NAME} PRIVATE 
        -static-libgcc 
        -static-libstdc++
    )

    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
        -Wl,-Bstatic
        stdc++
        pthread
        winpthread   # Added safely inside the static block for MinGW
        -Wl,-Bdynamic
    )

    message(STATUS "${CX_PRETTY_PRESET} Static linking of GCC runtimes enabled")

endfunction(set_static_linking)


#################################################
# MinGW: Copy GCC Runtime Libraries
#################################################
function(install_mingw_runtimes)

    if(DEFINED CX_TRIGGER_MINGW_STATIC_BUILD)
        debug_log("function install_mingw_runtimes: Static linking of runtimes set. Skipping")
        return()
    endif()

    debug_log("function install_mingw_runtimes: Setting up GCC shared runtime libraries")

    get_filename_component(MINGW_BIN_DIR
        "${CMAKE_CXX_COMPILER}"
        DIRECTORY
    )

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)

        install(
            FILES
                "${MINGW_BIN_DIR}/libgcc_s_seh-1.dll"
                "${MINGW_BIN_DIR}/libstdc++-6.dll"
                "${MINGW_BIN_DIR}/libwinpthread-1.dll"
            DESTINATION ${CX_INSTALL_PREFIX}
        )

    elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)

        install(
            FILES
                "${MINGW_BIN_DIR}/libgcc_s_dw2-1.dll"
                "${MINGW_BIN_DIR}/libstdc++-6.dll"
                "${MINGW_BIN_DIR}/libwinpthread-1.dll"
            DESTINATION ${CX_INSTALL_PREFIX}
        )

    endif()

    message(STATUS "${CX_PRETTY_PRESET} Installing GNU runtime libraries")
    message(STATUS "    Source directory is\n    ${MINGW_BIN_DIR}")
    message(STATUS "")

endfunction(install_mingw_runtimes)

