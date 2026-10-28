
########################################################
# Trigger: Enable Win Sockets 2 (MS Windows only)
########################################################
function(linker_winsocket2_trigger)

    if(NOT DEFINED CX_TRIGGER_WIN_SOCKET2)
        debug_log("function linker_winsocket2_trigger: skipping win socket 2")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Enabling win socket 2")

    if(MSVC)
        target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ws2_32)
    else()

        # -Wl,--start-group and -Wl,--end-group:
        # Forces the GNU linker (ld/MinGW) to recursively rescan the libraries 
        # wrapped inside the group. 
        #
        # By default, MinGW uses a single-pass, left-to-right linking strategy 
        # which discards libraries if no active symbols need them yet. The group 
        # wrapper overrides this, forcing the linker to repeatedly loop through 
        # the enclosed libraries until all unresolved references (such as 
        # deferred or circular dependencies) are completely satisfied.
        target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE 
            -Wl,--start-group
            ws2_32
            -Wl,--end-group
        )
        
    endif()

endfunction(linker_winsocket2_trigger)


function(linker_static_library_windows_trigger)

    if(NOT WIN32)
        debug_log("function linker_static_library_trigger: static ignored on non windows")
        return()
    endif()

    if(NOT DEFINED CX_TRIGGER_STATIC_LIBRARIES)
        debug_log("function linker_static_library_trigger: No static library options passed")
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


function(linker_shared_library_windows_trigger)

    # Require BOTH trigger variables to be defined
    if(NOT DEFINED CX_TRIGGER_SHARED_LIBRARIES)
        debug_log("function linker_shared_libraries_trigger: Shared library paths or options missing")
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
        debug_log("function linker_shared_libraries_trigger: Applying Ninja single-generator specific linker adjustments")
        
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

    if(CX_VERBOSE_OUTPUT)
        debug_show_target_properties(LINK_DIRECTORIES)
        debug_show_target_properties(LINK_LIBRARIES)
    endif()

endfunction()