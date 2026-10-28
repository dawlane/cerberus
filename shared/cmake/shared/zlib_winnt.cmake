#####################################################################
# Zlib dependency for MS Windows 
function(dependency_zlib _lib_dir)

    # Parse optional flags (ARGN captures anything after _lib_dir)
    set(options NO_LINK)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(ZLIB "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    debug_log("function dependency_zlib: Using zlib")

    # zlib was build against MSVC, and so the directory to the shared libraries are in the msvc directory.
    set(ZLIB_DLL_DIR "${CX_LIBS_DIR}/${_lib_dir}/msvc")
    set(ZLIB_DLL_PATH "${ZLIB_DLL_DIR}/z.dll")

    debug_log("function dependency_zlib: local variable ZLIB_DLL_DIR\n    ${ZLIB_DLL_DIR} ")
    debug_log("function dependency_zlib: local variable ZLIB_DLL_PATH\n    ${ZLIB_DLL_PATH} ") # Fixed log variable from _DLL_DIR to _DLL_PATH

    # If zlib hasn't been defined yet, create a SHARED IMPORTED target wrapper.
    if(NOT TARGET ZLIB::Imported)

        debug_log("function dependency_default_network_client: setting up zlib import library paths")
        
        add_library(ZLIB::Imported SHARED IMPORTED)
        
        # Check which compiler/toolchain is being used
        if(MSVC)

            # MSVC Toolchain configuration (.lib)
            set_target_properties(ZLIB::Imported PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/z.lib"
                IMPORTED_LOCATION "${ZLIB_DLL_PATH}"
            )

        else()

            # MinGW Toolchain configuration (.dll.a)
            set_target_properties(ZLIB::Imported PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/libz.dll.a"
                IMPORTED_LOCATION "${ZLIB_DLL_PATH}"
            )

        endif()

        # Apply shared properties common to both toolchains
        set_target_properties(ZLIB::Imported PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/include"
        )
        
        debug_log("zlib imported target configuration complete")

    endif()

    # Automatically defers the linking of dependencies to the end of the directory
    # evaluation, ensuring the target exists before target_link_libraries is executed.
    # Bypassed if NO_LINK is specified.
    if(NOT ZLIB_NO_LINK)
        cmake_language(DEFER CALL target_link_libraries ${CMAKE_PROJECT_NAME} PRIVATE ZLIB::Imported)
    else()
        debug_log("function dependency_zlib: Bypassing linking stage due to NO_LINK flag")
    endif()

    # Store zlib asset paths inside custom target properties, then defer the 
    # installation commands to the end of the file so they resolve during the install phase.
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        CX_INTERNAL_ZLIB_DLL "${ZLIB_DLL_PATH}"
        CX_INTERNAL_ZLIB_LICENCES "${CX_LIBS_DIR}/licences/zlib"
        CX_INTERNAL_ZLIB_PREFIX "${CX_INSTALL_PREFIX}"
    )

    cmake_language(DEFER CALL install
        FILES "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_ZLIB_DLL>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_ZLIB_PREFIX>"
    )

    cmake_language(DEFER CALL install
        DIRECTORY "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_ZLIB_LICENCES>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_ZLIB_PREFIX>/licences"
    )

endfunction(dependency_zlib _lib_dir)
