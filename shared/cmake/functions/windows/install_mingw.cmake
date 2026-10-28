#################################################
# Install shared libraries for MinGW

#################################################
# Install: Copy MinGW Shared Libraries
#################################################
function(install_shared_libraries_mingw)

    # Only proceed if CX_OPTS_SHARED_LIBS is available.
    if(NOT DEFINED CX_TRIGGER_SHARED_LIBRARIES)
        debug_log("function install_shared_libraries_mingw: No shared libraries to install")
        return()
    endif()

    # For find_library to work correctly with dynamic link libraries and any associated link files.
    # We have to add the suffixes for find_library to use; it's default is to look for .a first. 
    set(CMAKE_FIND_LIBRARY_SUFFIXES_BACKUP ${CMAKE_FIND_LIBRARY_SUFFIXES})
    list(APPEND CMAKE_FIND_LIBRARY_SUFFIXES ".dll.a" ".dll" ".a")

    debug_log("function install_shared_libraries_mingw: processing share libraries")
    foreach(_library IN LISTS CX_OPTS_SHARED_LIB)
        message(DEBUG "    Library: ${_library}")

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

        # Standardise our target binary deployment naming patterns
        if(_found_name MATCHES "\\.dll\\.a$")
            string(REGEX REPLACE "\\.dll\\.a$" ".dll" _dll_name "${_found_name}")
        elseif(_found_name MATCHES "\\.a$")
            string(REGEX REPLACE "\\.a$" ".dll" _dll_name "${_found_name}")
        else()
            set(_dll_name "${_found_name}")
        endif()
        message(DEBUG "        Standardise naming pattern: ${_dll_name}")
        
        # COMPREHENSIVE MULTI-PATH SYMLINK ENGINE
        # We search for our computed '_dll_name' across ALL paths provided in CX_PATHS_SHARED_LIB.
        # This fixes setups where the .dll.a is in one folder, but the symlinked .dll is in another.
        set(_real_library_path "")
        set(_all_possible_dirs "${_found_dir}" ${CX_PATHS_SHARED_LIB})
        list(REMOVE_DUPLICATES _all_possible_dirs)

        message(DEBUG "    System link checking:")
        foreach(_scan_dir IN LISTS _all_possible_dirs)
            set(_candidate_file "${_scan_dir}/${_dll_name}")

            message(DEBUG "        Candidate file: ${_candidate_file}")

            if(EXISTS "${_candidate_file}" OR IS_SYMLINK "${_candidate_file}")
                
                # Check if this exact target layout matching our pattern is a symlink
                if(IS_SYMLINK "${_candidate_file}")

                    message(DEBUG "        Is a symbolic link")

                    file(READ_SYMLINK "${_candidate_file}" _symlink_target)
                    
                    # Resolve relative symlinks (e.g. '../bin/foo.dll') relative to the folder it sits in
                    if(NOT IS_ABSOLUTE "${_symlink_target}")
                        set(_real_library_path "${_scan_dir}/${_symlink_target}")
                    else()
                        set(_real_library_path "${_symlink_target}")
                    endif()
                else()

                    # It's a standard standalone file
                    set(_real_library_path "${_candidate_file}")
                    
                endif()

                # Canonicalize the resolved target down to a physical absolute path
                file(REAL_PATH "${_real_library_path}" _real_library_path)

                break() # Match found successfully, drop out of path evaluation loop

            endif()
            
        endforeach()

        # Final validation check
        if(NOT _real_library_path OR NOT EXISTS "${_real_library_path}")
            message(FATAL_ERROR
                "Found link anchor target '${_found_name}' at:\n"
                "    ${_shared_library}\n"
                "But failed to resolve or follow a companion runtime binary named '${_dll_name}' within any structural layout directory:\n"
                "    ${_all_possible_dirs}"
            )
        endif()

        # Copy the dynamic link library
        install(
            FILES "${_real_library_path}" 
            DESTINATION "${CX_INSTALL_PREFIX}"
            RENAME "${_dll_name}"
        )

        debug_log("MinGW Installer: Unpacked ${_real_library_path} to ${CX_INSTALL_PREFIX}/${_dll_name}")

        # Completely flush CMake global memory keys for the next loop run
        unset(_shared_library CACHE)

    endforeach()

    # Revert suffixes to preserve build cleanliness
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES_BACKUP})

endfunction()
