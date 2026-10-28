#################################################
# Install shared libraries for Linux

#################################################
# Install: Copy Linux Shared Libraries
#################################################
function(install_shared_libraries_linux_gcc)

    # Only perform this operation if there is something to link and copy.
    if(NOT DEFINED CX_TRIGGER_SHARED_LIBRARIES)
        debug_log("function install_shared_libraries_linux_gcc: No shared libraries to install")
        return()
    endif()

    debug_log("function install_shared_libraries_linux_gcc: processing share libraries")

    # Iterate over the shared path for the libraries to link and copy.
    foreach(_library IN LISTS CX_OPTS_SHARED_LIB)

        # Search for the shared library (.so) across all registered paths
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

        # Extract information from the verified library catch
        get_filename_component(_found_name "${_shared_library}" NAME)
        get_filename_component(_found_dir "${_shared_library}" DIRECTORY)
        message(DEBUG "    File name components:")
        message(DEBUG "        Found Name: ${_found_name}")
        message(DEBUG "        Found Dir: ${_found_dir}")

        # Follow Linux Symbolic Links safely
        if(IS_SYMLINK "${_shared_library}")

            message(DEBUG "        Is a symbolic link")
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

        # Copy the shared object library
        install(
            FILES "${_real_library_path}" 
            DESTINATION "${CX_INSTALL_PREFIX}/lib"
            RENAME "${_found_name}"
        )

        debug_log("Linux Installer: Unpacked ${_real_library_path} to ${CX_INSTALL_PREFIX}/lib/${_found_name}")

        # Completely flush CMake global memory keys for the next loop run
        unset(_shared_library CACHE)

    endforeach()

endfunction()
