#####################################################################
# Install shared libraries for Visual Studio / MSVC

#####################################################################
# Install: Copy MSVC Shared Libraries
#####################################################################
function(install_shared_libraries_msvc)

    if(NOT DEFINED CX_TRIGGER_SHARED_LIBRARIES)
        debug_log("function install_shared_libraries_msvc: No shared libraries to install")
        return()
    endif()

    # MSVC LINKER RULES: 
    # 1. We prioritize '.lib' because MSVC requires it for standard linking.
    # 2. We append '.dll' as a fallback to support pure runtime-only directory test contexts.
    set(CMAKE_FIND_LIBRARY_SUFFIXES_BACKUP ${CMAKE_FIND_LIBRARY_SUFFIXES})
    list(APPEND CMAKE_FIND_LIBRARY_SUFFIXES ".lib" ".dll")

    debug_log("function install_shared_libraries_msvc: processing share libraries")
    foreach(_library IN LISTS CX_OPTS_SHARED_LIB)

        # Search for the library target handle across all registered paths
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
        message(DEBUG "    File name components:")
        get_filename_component(_found_name "${_shared_library}" NAME)
        get_filename_component(_found_dir "${_shared_library}" DIRECTORY)
        message(DEBUG "        Found Name: ${_found_name}")
        message(DEBUG "        Found Dir: ${_found_dir}")

        # Convert the link-time filename (.lib) to the runtime deployment filename (.dll) [1]
        if(_found_name MATCHES "\\.lib$")
            string(REGEX REPLACE "\\.lib$" ".dll" _dll_name "${_found_name}")
        else()
            # If it found a raw .dll because no .lib import library exists in the paths
            set(_dll_name "${_found_name}")
        endif()

        # COMPREHENSIVE MULTI-PATH ENGINE FOR MSVC:
        set(_real_library_path "")
        set(_all_possible_dirs "${_found_dir}" ${CX_PATHS_SHARED_LIB})
        
        # Account for multi-configuration subdirectories common in MSVC build layouts
        foreach(_dir IN LISTS CX_PATHS_SHARED_LIB)
            list(APPEND _all_possible_dirs "${_dir}/Debug" "${_dir}/Release" "${_dir}/MinSizeRel" "${_dir}/RelWithDebInfo")
        endforeach()
        list(REMOVE_DUPLICATES _all_possible_dirs)

        foreach(_scan_dir IN LISTS _all_possible_dirs)
            set(_candidate_file "${_scan_dir}/${_dll_name}")

            message(DEBUG "        Candidate file: ${_candidate_file}")

            if(EXISTS "${_candidate_file}" OR IS_SYMLINK "${_candidate_file}")
                
                # Check for symlink layers (Handles developer environments sharing windows mounts)
                if(IS_SYMLINK "${_candidate_file}")

                     message(DEBUG "        Is a symbolic link")
                     
                    file(READ_SYMLINK "${_candidate_file}" _symlink_target)
                    if(NOT IS_ABSOLUTE "${_symlink_target}")
                        set(_real_library_path "${_scan_dir}/${_symlink_target}")
                    else()
                        set(_real_library_path "${_symlink_target}")
                    endif()
                else()
                    set(_real_library_path "${_candidate_file}")
                endif()

                # Canonicalize down to a true absolute physical layout path
                file(REAL_PATH "${_real_library_path}" _real_library_path)
                break() 
            endif()
        endforeach()

        # Final validation check
        if(NOT _real_library_path OR NOT EXISTS "${_real_library_path}")
            message(FATAL_ERROR
                "Found link library asset '${_found_name}' at:\n"
                "    ${_shared_library}\n"
                "But failed to resolve or follow a companion MSVC runtime binary named '${_dll_name}' within any checked layout directory:\n"
                "    ${_all_possible_dirs}"
            )
        endif()

        # Pack and deploy the true binary runtime DLL asset
        install(
            FILES "${_real_library_path}" 
            DESTINATION "${CX_INSTALL_PREFIX}"
            RENAME "${_dll_name}"
        )

        debug_log("MSVC Installer: Unpacked ${_real_library_path} to ${CX_INSTALL_PREFIX}/${_dll_name}")

        # Completely flush CMake global memory keys for the next loop run
        unset(_shared_library CACHE)

    endforeach()

    # Revert suffixes to preserve build cleanliness
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES_BACKUP})

endfunction()
