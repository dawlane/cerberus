# TODO: Merge shared library search paths and shared library options

########################################################
# Trigger: macOS Static Libraries
########################################################
function(linker_static_library_linux_trigger)

    #f(NOT APPLE)
    #    debug_log(
    #        "function linker_static_library_macos_trigger: "
    #        "static ignored on non-Apple platform"
    #    )
    #    return()
    #endif()

    if(NOT DEFINED CX_TRIGGER_STATIC_LIBRARIES)
        debug_log("function linker_static_library_options_trigger: No static library options passed")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Processing linker static libraries")

    # Handle standard link directories for all generators (including Ninja)
    target_link_directories(
        ${CMAKE_PROJECT_NAME}
        PRIVATE
        ${CX_PATHS_STATIC_LIB}
    )

    # Handle single Ninja generator specifics
    if(CMAKE_GENERATOR STREQUAL "Ninja")
        debug_log("function linker_static_library_macos_trigger: Applying Ninja single-generator specific linker adjustments")
        
        # When using Ninja on macOS, explicitly pass link directories via driver options 
        # to ensure static search paths resolve cleanly across Ninja build nodes.
        foreach(path IN LISTS CX_PATHS_STATIC_LIB)
            target_link_options(
                ${CMAKE_PROJECT_NAME}
                PRIVATE
                "LINKER:-L${path}"
            )
        endforeach()
    endif()

    target_link_libraries(
        ${CMAKE_PROJECT_NAME}
        PRIVATE
        ${CX_OPTS_STATIC_LIB}
    )

    if(CX_VERBOSE_OUTPUT)
        debug_show_target_properties(LINK_DIRECTORIES)
        debug_show_target_properties(LINK_LIBRARIES)
    endif()

endfunction()

function(linker_shared_library_linux_trigger)

    # Require trigger variable to be defined
    if(NOT DEFINED CX_TRIGGER_SHARED_LIBRARIES)
        debug_log("function linker_shared_library_linux_trigger: Shared library paths or options missing")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Processing linker shared libraries")
    target_link_directories(
        ${CMAKE_PROJECT_NAME}
        PRIVATE
        ${CX_PATHS_SHARED_LIB}
    )

    # Handle single Ninja generator specifics
    if(CMAKE_GENERATOR STREQUAL "Ninja")
        debug_log("function linker_shared_library_linux_trigger: Applying Ninja single-generator specific linker adjustments")
        
        foreach(path IN LISTS CX_PATHS_SHARED_LIB)
            target_link_options(
                ${CMAKE_PROJECT_NAME}
                PRIVATE
                "LINKER:-L${path}"
            )
        endforeach()
    endif()

    target_link_libraries(
        ${CMAKE_PROJECT_NAME}
        PRIVATE
        ${CX_OPTS_SHARED_LIB}
    )

    debug_log("function linker_shared_library_linux_trigger: Setting \$ORIGIN/lib")
    set_target_properties(
        ${CMAKE_PROJECT_NAME}
        PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        BUILD_RPATH "\$ORIGIN/lib"
        INSTALL_RPATH "\$ORIGIN/lib"
        INSTALL_RPATH_USE_LINK_PATH FALSE
    )

    if(CX_VERBOSE_OUTPUT)
        debug_show_target_properties(LINK_DIRECTORIES)
        debug_show_target_properties(LINK_LIBRARIES)
    endif()

endfunction()
