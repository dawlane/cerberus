########################################################
# Trigger: macOS Static Libraries
########################################################
function(linker_static_library_macos_trigger)

    if(NOT APPLE)
        debug_log(
            "function linker_static_library_macos_trigger: "
            "static ignored on non-Apple platform"
        )
        return()
    endif()

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

########################################################
# Trigger: macOS Shared Libraries
########################################################
function(linker_shared_library_macos_trigger)

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

    debug_log("function linker_shared_libraries_trigger: Setting @loader_path/lib")
    set_target_properties(
        ${CMAKE_PROJECT_NAME}
        PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        BUILD_RPATH "@loader_path/lib"
        INSTALL_RPATH "@loader_path/lib"
        INSTALL_RPATH_USE_LINK_PATH FALSE
        MACOSX_RPATH TRUE
    )

    if(CX_VERBOSE_OUTPUT)
        debug_show_target_properties(LINK_DIRECTORIES)
        debug_show_target_properties(LINK_LIBRARIES)
    endif()

endfunction()


########################################################
# Trigger: macOS Frameworks
########################################################
function(linker_frameworks_macos_trigger)

    if(NOT APPLE)
        debug_log(
            "function linker_frameworks_macos_trigger: "
            "Frameworks ignored on non-Apple platform"
        )
        return()
    endif()

    if(NOT CX_TRIGGER_OPTS_FRAMEWORKS)
        debug_log(
            "function linker_frameworks_macos_trigger: "
            "No frameworks requested"
        )
        return()
    endif()

    if(NOT CX_PATHS_FRAMEWORKS)
        message(FATAL_ERROR
            "${CX_PRETTY_PRESET} Linker: Framework processing failed: "
            "'${CX_PRESET_VAR_NAME}_FRAMEWORK_SEARCH_PATHS' is required but not set."
        )
        return()
    endif()

    message(STATUS
        "${CX_PRETTY_PRESET} Processing macOS frameworks"
    )

    # --------------------------------------------------
    # Set search paths on target to prevent duplicate -F
    # --------------------------------------------------
    set_property(
        TARGET ${CMAKE_PROJECT_NAME}
        APPEND PROPERTY FRAMEWORK_SEARCH_PATHS ${CX_PATHS_FRAMEWORKS}
    )
    foreach(_framework IN LISTS CX_OPTS_FRAMEWORKS)

        string(
            REGEX REPLACE
            "\\.framework$"
            ""
            _framework_name
            "${_framework}"
        )

        unset(_found_framework CACHE)
        unset(_found_framework)

        find_library(
            _found_framework
            NAMES "${_framework_name}"
            PATHS ${CX_PATHS_FRAMEWORKS}
            NO_DEFAULT_PATH
        )

        if(NOT _found_framework)
            message(FATAL_ERROR
                "${CX_PRETTY_PRESET} Linker: Unable to locate framework "
                "'${_framework_name}.framework' in:\n"
                "    ${CX_PATHS_FRAMEWORKS}"
            )
        endif()

        if(CX_VERBOSE_OUTPUT)
            message(STATUS
                "    Framework: ${_framework_name}"
            )

            message(STATUS
                "        Located: ${_found_framework}"
            )
        endif()

        target_link_libraries(
            ${CMAKE_PROJECT_NAME}
            PRIVATE
            "${_found_framework}"
        )

    endforeach()

    # --------------------------------------------------
    # Runtime search paths
    # --------------------------------------------------

    get_main_project_bundle_dir(_bundle_dir)

    if(_bundle_dir)
        set(_framework_rpath
            "@executable_path/../Frameworks"
        )
    else()
        set(_framework_rpath
            "@loader_path/lib"
        )
    endif()

    get_target_property(
        _current_install_rpath
        ${CMAKE_PROJECT_NAME}
        INSTALL_RPATH
    )

    get_target_property(
        _current_build_rpath
        ${CMAKE_PROJECT_NAME}
        BUILD_RPATH
    )

    if(NOT _current_install_rpath OR
       _current_install_rpath MATCHES "-NOTFOUND$")
        set(_current_install_rpath "")
    endif()

    if(NOT _current_build_rpath OR
       _current_build_rpath MATCHES "-NOTFOUND$")
        set(_current_build_rpath "")
    endif()

    list(APPEND
        _current_install_rpath
        "${_framework_rpath}"
    )

    list(APPEND
        _current_build_rpath
        "${_framework_rpath}"
    )

    list(REMOVE_DUPLICATES
        _current_install_rpath
    )

    list(REMOVE_DUPLICATES
        _current_build_rpath
    )

    set_target_properties(
        ${CMAKE_PROJECT_NAME}
        PROPERTIES
            BUILD_WITH_INSTALL_RPATH TRUE
            BUILD_RPATH "${_current_build_rpath}"
            INSTALL_RPATH "${_current_install_rpath}"
            INSTALL_RPATH_USE_LINK_PATH FALSE
            MACOSX_RPATH TRUE
    )

    if(CX_VERBOSE_OUTPUT)
        debug_log(
            "Framework RPATH: ${_framework_rpath}"
        )

        debug_log(
            "Framework build RPATH: ${_current_build_rpath}"
        )

        debug_log(
            "Framework install RPATH: ${_current_install_rpath}"
        )
    endif()

endfunction()