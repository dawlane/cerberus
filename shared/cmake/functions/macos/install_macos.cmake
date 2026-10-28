#################################################
# Install: Copy macOS Shared Libraries
#################################################
function(install_shared_libraries_macos)

    # Only perform this operation if there is something to link and copy.
    if(NOT DEFINED CX_TRIGGER_SHARED_LIBRARIES)
        debug_log("function install_shared_libraries_macos: No shared libraries to install")
        return()
    endif()

    debug_log("function install_shared_libraries_macos: processing shared libraries")

    # Determine destination relative to CX_INSTALL_PREFIX
    get_main_project_bundle_dir(_bundle_dir)

    if(_bundle_dir)
        if(CX_VERBOSE_OUTPUT)
            message(STATUS "    Apple app bundle target detected (${_bundle_dir})")
        endif()
        set(_lib_destination_dir "${_bundle_dir}/Contents/Frameworks")
    else()
        if(CX_VERBOSE_OUTPUT)
            message(STATUS "    Not an application bundle, so placing frameworks into 'lib'")
        endif()
        set(_lib_destination_dir "lib")
    endif()

    # Iterate over the shared path for the libraries to link and copy.
    foreach(_library IN LISTS CX_OPTS_SHARED_LIB)

        # Search for the shared library (.dylib) across all registered paths
        find_library(
            _shared_library
            NAMES ${_library}
            PATHS ${CX_PATHS_SHARED_LIB}
            NO_DEFAULT_PATH
        )

        if(NOT _shared_library)
            message(FATAL_ERROR
                "Unable to find shared library '${_library}' in:\n"
                "    ${CX_PATHS_SHARED_LIB}"
            )
        endif()

        # Extract information from the verified library cache
        get_filename_component(_found_name "${_shared_library}" NAME)
        get_filename_component(_found_dir "${_shared_library}" DIRECTORY)

        if(CX_VERBOSE_OUTPUT)
            message(STATUS "    File name components:")
            message(STATUS "        Found Name: ${_found_name}")
            message(STATUS "        Found Dir: ${_found_dir}")
        endif()

        # Follow macOS Symbolic Links safely
        if(IS_SYMLINK "${_shared_library}")
            if(CX_VERSBOSE_OUTPUT)
                message(STATUS "        Is a symbolic link to ${_found_name}")
            endif()
            file(READ_SYMLINK "${_shared_library}" _symlink_target)
            
            if(NOT IS_ABSOLUTE "${_symlink_target}")
                set(_real_library_path "${_found_dir}/${_symlink_target}")
            else()
                set(_real_library_path "${_symlink_target}")
            endif()
            
            file(REAL_PATH "${_real_library_path}" _real_library_path)
        else()
            set(_real_library_path "${_shared_library}")
        endif()

        # Final validation check
        if(NOT EXISTS "${_real_library_path}")
            message(FATAL_ERROR
                "Resolved structural path pointer to '${_real_library_path}', but the file does not exist on disk."
            )
        endif()

        set(_target_install_path "${CX_INSTALL_PREFIX}/${_lib_destination_dir}/${_found_name}")

        # Copy the .dylib library file
        install(
            FILES "${_real_library_path}" 
            DESTINATION "${CX_INSTALL_PREFIX}/${_lib_destination_dir}"
            RENAME "${_found_name}"
        )

        # Set library install name ID to @rpath/<lib_name>
        install(CODE "
            message(STATUS \"Fixing macOS install name for: ${_target_install_path}\")
            execute_process(
                COMMAND install_name_tool -id \"@rpath/${_found_name}\" \"${_target_install_path}\"
                RESULT_VARIABLE _res
                ERROR_VARIABLE _err
            )
            if(NOT _res EQUAL 0)
                message(FATAL_ERROR \"Failed to set install name for ${_target_install_path}: \${_err}\")
            endif()
        ")

        debug_log("function install_shared_libraries_macos: unpack :\n   src ${_real_library_path}\n    ${_target_install_path}")

        # Completely flush CMake global memory keys for the next loop run
        unset(_shared_library CACHE)

    endforeach()

endfunction()


#################################################
# Install: Copy macOS Frameworks
function(install_frameworks_macos)

    # Only perform this operation if frameworks have been requested.
    if(NOT DEFINED CX_TRIGGER_OPTS_FRAMEWORKS)
        debug_log("function install_frameworks_macos: No frameworks to install")
        return()
    endif()

    message(STATUS
        "${CX_PRETTY_PRESET} Installing Frameworks"
    )

    # Determine whether the main target is an application bundle.
    get_main_project_bundle_dir(_bundle_dir)

    # Application bundles store frameworks in Contents/Frameworks.
    # Command-line applications store frameworks in the lib directory.
    if(_bundle_dir)

        if(CX_VERBOSE_OUTPUT)
            message(STATUS
                "    Framework installation target is application bundle."
            )
            message(STATUS "")
        endif()

        set(_framework_destination_dir
            "${_bundle_dir}/Contents/Frameworks"
        )

    else()

        if(CX_VERBOSE_OUTPUT)
            message(STATUS
                "    Not an application bundle, so placing frameworks into 'lib'"
            )
            message(STATUS "")
        endif()

        set(_framework_destination_dir "lib")

    endif()

    # Process each requested framework independently.
    foreach(_framework IN LISTS CX_OPTS_FRAMEWORKS)

        # Reset per-framework state so values from the previous iteration
        # cannot affect the current framework.
        unset(_version_rel_path)
        unset(_version_name)
        unset(_version_dir)
        unset(_framework_dir)
        unset(_target_binary_path)
        unset(_framework_install_name)

        # Remove the .framework suffix if the caller supplied it.
        string(
            REGEX REPLACE
            "\\.framework$"
            ""
            _framework_stem
            "${_framework}"
        )

        # Construct the framework bundle name.
        set(_framework_name "${_framework_stem}.framework")

        debug_log(
            "function install_frameworks_macos: searching for framework ${_framework_name}"
        )

        #######################################################################
        # Locate the framework
        #######################################################################

        # IMPORTANT:
        # find_library() caches its result using the variable name.
        #
        # Clear both the normal and cache variables before searching.
        # Otherwise, a previous framework lookup can return the wrong bundle.
        unset(_found_framework CACHE)
        unset(_found_framework)

        find_library(
            _found_framework
            NAMES "${_framework_stem}"
            PATHS ${CX_PATHS_FRAMEWORKS}
            NO_DEFAULT_PATH
        )

        # Stop configuration if the requested framework cannot be found.
        if(NOT _found_framework)
            message(FATAL_ERROR
                "Install Framework: Unable to find framework '${_framework_name}' in:\n"
                "    ${CX_PATHS_FRAMEWORKS}"
            )
        else()
            if(CX_VERBOSE_OUTPUT)
                message(STATUS "    Found framework ${_framework_name}")
            endif()
        endif()

        #######################################################################
        # Determine the framework bundle directory
        #######################################################################

        # find_library() may return the framework binary path rather than
        # the framework directory itself.
        #
        # Extract the enclosing .framework path when present.
        string(
            REGEX MATCH
            "^(.+\\.framework)"
            _framework_match
            "${_found_framework}"
        )

        if(_framework_match)

            set(_framework_dir "${CMAKE_MATCH_1}")

            debug_log(
                "function install_frameworks_macos: framework match ${_framework_name}"
            )

        # Handle a result that points to the framework's parent directory.
        elseif(IS_DIRECTORY "${_found_framework}.framework")

            set(_framework_dir "${_found_framework}.framework")

            debug_log(
                "function install_frameworks_macos: framework match directory ${_framework_name}"
            )

        else()

            message(FATAL_ERROR
                "Install Framework: Located framework '${_framework_name}', but could not determine "
                "its framework directory:\n"
                "    ${_found_framework}"
            )

        endif()

        # Final destination of this framework bundle.
        set(_target_dest
            "${CX_INSTALL_PREFIX}/${_framework_destination_dir}/${_framework_name}"
        )

        #######################################################################
        # Determine whether this is a versioned framework
        #######################################################################

        debug_log(
            "function install_frameworks_macos: Checking to see if framework ${_framework_name} is versioned"
        )

        if(IS_DIRECTORY "${_framework_dir}/Versions")

            if(CX_VERBOSE_OUTPUT)
                message(STATUS "    Framework has version information")
            endif()

            ###################################################################
            # Resolve the framework's current version directory
            ###################################################################

            # Prefer the framework's Versions/Current symlink.
            if(IS_SYMLINK "${_framework_dir}/Versions/Current")

                debug_log(
                    "function install_frameworks_macos: symbolic link ${_framework_dir}/Versions/Current"
                )

                file(
                    REAL_PATH
                    "${_framework_dir}/Versions/Current"
                    _version_dir
                )

            # Also handle Current if it exists as a real directory.
            elseif(EXISTS "${_framework_dir}/Versions/Current")

                debug_log(
                    "function install_frameworks_macos: real path ${_framework_dir}/Versions/Current"
                )

                file(
                    REAL_PATH
                    "${_framework_dir}/Versions/Current"
                    _version_dir
                )

            else()

                # If Current is missing, locate a version directory.
                debug_log(
                    "function install_frameworks_macos: search for any version"
                )

                file(
                    GLOB _version_dirs
                    LIST_DIRECTORIES true
                    "${_framework_dir}/Versions/*"
                )

                if(NOT _version_dirs)
                    message(FATAL_ERROR
                        "Install Frameworks: Framework '${_framework_name}' contains an empty Versions directory"
                    )
                endif()

                # Use the first discovered version directory.
                list(GET _version_dirs 0 _version_dir)

            endif()

            # Extract the version name, for example "A".
            get_filename_component(
                _version_name
                "${_version_dir}"
                NAME
            )

            # Relative path used inside the installed framework.
            # Example: Versions/A
            set(_version_rel_path
                "Versions/${_version_name}"
            )

            ###################################################################
            # Install the framework runtime binary
            ###################################################################

            # The framework's executable has the same stem as the framework.
            set(_source_binary
                "${_version_dir}/${_framework_stem}"
            )

            # Fail early if the expected runtime binary is missing.
            if(NOT EXISTS "${_source_binary}")
                message(FATAL_ERROR
                    "Install Frameworks: Framework runtime binary not found:\n"
                    "    ${_source_binary}"
                )
            endif()

            # Install only the runtime executable, not the entire framework
            # development tree.
            install(
                FILES "${_source_binary}"
                DESTINATION
                    "${_target_dest}/${_version_rel_path}"
                PERMISSIONS
                    OWNER_READ
                    OWNER_WRITE
                    OWNER_EXECUTE
                    GROUP_READ
                    GROUP_EXECUTE
                    WORLD_READ
                    WORLD_EXECUTE
            )

            ###################################################################
            # Install framework runtime resources
            ###################################################################

            # Resources may contain runtime assets, such as plist files,
            # images, or other files required by the framework.
            if(IS_DIRECTORY "${_version_dir}/Resources")

                if(CX_VERBOSE_OUTPUT)
                    message(STATUS "    Framework has resources")
                endif()

                install(
                    DIRECTORY "${_version_dir}/Resources"
                    DESTINATION
                        "${_target_dest}/${_version_rel_path}"
                )

            endif()

            ###################################################################
            # Recreate framework runtime symlinks
            ###################################################################

            # Recreate the standard versioned framework layout:
            #
            # Framework.framework/
            #   Versions/
            #     Current -> A
            #     A/
            #       Framework
            #       Resources/
            #   Framework -> Versions/Current/Framework
            #   Resources -> Versions/Current/Resources
            #
            # These commands execute during installation, not configuration.
            install(CODE "
                # Ensure the Versions directory exists.
                file(MAKE_DIRECTORY
                    \"${_target_dest}/Versions\"
                )

                # Point Versions/Current at the selected version.
                execute_process(
                    COMMAND
                        \"\${CMAKE_COMMAND}\"
                        -E create_symlink
                        \"${_version_name}\"
                        \"${_target_dest}/Versions/Current\"
                )

                # Create the top-level executable symlink.
                execute_process(
                    COMMAND
                        \"\${CMAKE_COMMAND}\"
                        -E create_symlink
                        \"Versions/Current/${_framework_stem}\"
                        \"${_target_dest}/${_framework_stem}\"
                )

                # Create the top-level Resources symlink only when resources
                # were installed for this framework version.
                if(EXISTS
                    \"${_target_dest}/${_version_rel_path}/Resources\"
                )
                    execute_process(
                        COMMAND
                            \"\${CMAKE_COMMAND}\"
                            -E create_symlink
                            \"Versions/Current/Resources\"
                            \"${_target_dest}/Resources\"
                    )
                endif()
            ")

            # Full path to the installed framework executable.
            set(_target_binary_path
                "${_target_dest}/${_version_rel_path}/${_framework_stem}"
            )

        else()

            ###################################################################
            # Non-versioned framework
            ###################################################################

            if(CX_VERBOSE_OUTPUT)
                message(STATUS "    Framework has no version information")
            endif()

            # For a non-versioned framework, the executable is directly
            # inside the framework bundle.
            set(_source_binary
                "${_framework_dir}/${_framework_stem}"
            )

            # Fail early if the expected runtime binary is missing.
            if(NOT EXISTS "${_source_binary}")
                message(FATAL_ERROR
                    "Install Framework: Framework runtime binary not found:\n"
                    "    ${_source_binary}"
                )
            endif()

            ###################################################################
            # Install the framework runtime binary
            ###################################################################

            install(
                FILES "${_source_binary}"
                DESTINATION "${_target_dest}"
                PERMISSIONS
                    OWNER_READ
                    OWNER_WRITE
                    OWNER_EXECUTE
                    GROUP_READ
                    GROUP_EXECUTE
                    WORLD_READ
                    WORLD_EXECUTE
            )

            ###################################################################
            # Install framework runtime resources
            ###################################################################

            if(IS_DIRECTORY "${_framework_dir}/Resources")

                if(CX_VERBOSE_OUTPUT)
                    message(STATUS "    Framework has resources")
                endif()

                install(
                    DIRECTORY "${_framework_dir}/Resources"
                    DESTINATION "${_target_dest}"
                )

            endif()

            # Full path to the installed framework executable.
            set(_target_binary_path
                "${_target_dest}/${_framework_stem}"
            )

        endif()

        #######################################################################
        # Set the framework's runtime install name
        #######################################################################

        # Versioned frameworks include the version directory in their
        # install name. Non-versioned frameworks do not.
        if(_version_rel_path)

            set(_framework_install_name
                "@rpath/${_framework_name}/${_version_rel_path}/${_framework_stem}"
            )

        else()

            set(_framework_install_name
                "@rpath/${_framework_name}/${_framework_stem}"
            )

        endif()

        if(CX_VERBOSE_OUTPUT)
            message(STATUS "    Setting framework runtime paths")
            message(STATUS "        ${_framework_install_name}")
            message(STATUS "")
        endif()

        #######################################################################
        # Update the installed framework binary's install name
        #######################################################################

        # install(CODE) runs at install time.
        # Escape CMAKE_COMMAND and the install-time result variables so they
        # are evaluated when the install script executes.
        install(CODE "
            message(STATUS
                \"Fixing macOS framework install name for: ${_target_binary_path}\"
            )

            execute_process(
                COMMAND
                    install_name_tool
                    -id
                    \"${_framework_install_name}\"
                    \"${_target_binary_path}\"
                RESULT_VARIABLE _res
                ERROR_VARIABLE _err
            )

            # Stop installation if install_name_tool reports an error.
            if(NOT _res EQUAL 0)
                message(FATAL_ERROR
                    \"Failed to set install name for ${_target_binary_path}: \${_err}\"
                )
            endif()
        ")

        #######################################################################
        # Clean up before processing the next framework
        #######################################################################

        # Remove the cached find_library result so it cannot be reused
        # accidentally by a later framework lookup.
        unset(_found_framework CACHE)
        unset(_found_framework)

    endforeach()

endfunction()