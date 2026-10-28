#####################################################################
# NG HTTP2 dependency for MS Windows 
function(dependency_ng_http _lib_dir)

    # Parse optional flags (ARGN captures anything after _lib_dir)
    set(options NO_LINK)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(NG_HTTP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    debug_log("function dependency_ng_http: Using OpenAL")

    # nghttp2 was build against MSVC, and so the directory to the shared libraries are in the msvc directory.
    set(NG_HTTP_DLL_DIR "${CX_LIBS_DIR}/${_lib_dir}/msvc")
    set(NG_HTTP_DLL_PATH "${NG_HTTP_DLL_DIR}/nghttp2.dll")

    debug_log("function dependency_ng_http: local variable NG_HTTP_DLL_DIR\n    ${NG_HTTP_DLL_DIR} ")
    debug_log("function dependency_ng_http: local variable NG_HTTP_DLL_PATH\n    ${NG_HTTP_DLL_PATH} ") # Fixed log variable from _DLL_DIR to _DLL_PATH

    # If nghttp2 hasn't been defined yet, create a SHARED IMPORTED target wrapper.
    if(NOT TARGET NG_HTTP::Imported)

        debug_log("function dependency_default_network_client: setting up nghttp2 import library paths")
        
        add_library(NG_HTTP::Imported SHARED IMPORTED)
        
        # Check which compiler/toolchain is being used
        if(MSVC)

            # MSVC Toolchain configuration (.lib)
            set_target_properties(NG_HTTP::Imported PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/nghttp2.lib"
                IMPORTED_LOCATION "${NG_HTTP_DLL_PATH}"
            )

        else()

            # MinGW Toolchain configuration (.dll.a)
            set_target_properties(NG_HTTP::Imported PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/libnghttp2.dll.a"
                IMPORTED_LOCATION "${NG_HTTP_DLL_PATH}"
            )

        endif()

        # Apply shared properties common to both toolchains
        set_target_properties(NG_HTTP::Imported PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/include/nghttp2"
        )
        
        debug_log("nghttp2 imported target configuration complete")

    endif()

    # Automatically defers the linking of dependencies to the end of the directory
    # evaluation, ensuring the target exists before target_link_libraries is executed.
    # Bypassed if NO_LINK is specified.
    if(NOT NG_HTTP_NO_LINK)
        cmake_language(DEFER CALL target_link_libraries ${CMAKE_PROJECT_NAME} PRIVATE NG_HTTP::Imported)
    else()
        debug_log("function dependency_ng_http: Bypassing linking stage due to NO_LINK flag")
    endif()

    # Store nghttp2 asset paths inside custom target properties, then defer the 
    # installation commands to the end of the file so they resolve during the install phase.
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        CX_INTERNAL_NG_HTTP_DLL "${NG_HTTP_DLL_PATH}"
        CX_INTERNAL_NG_HTTP_LICENCES "${CX_LIBS_DIR}/licences/nghttp2"
        CX_INTERNAL_NG_HTTP_PREFIX "${CX_INSTALL_PREFIX}"
    )

    cmake_language(DEFER CALL install
        FILES "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_NG_HTTP_DLL>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_NG_HTTP_PREFIX>"
    )

    cmake_language(DEFER CALL install
        DIRECTORY "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_NG_HTTP_LICENCES>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_NG_HTTP_PREFIX>/licences"
    )

endfunction(dependency_ng_http _lib_dir)
