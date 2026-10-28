#####################################################################
# Dependencies for Visual Studio network clients
include(zlib_winnt)
include(nghttp_winnt)
include(openssl_winnt)

# The default network client to use is cURL, so a dedicated function is used to save duplication.
function(dependency_default_network_client _lib_dir)

    # cURL was build against MSVC, and so the directory to the shared libraries are in the msvc directory.
    set(CURL_DLL_DIR "${CX_LIBS_DIR}/${_lib_dir}/msvc")
    set(CURL_DLL_PATH "${CURL_DLL_DIR}/libcurl.dll")

    debug_log("function dependency_network_client: Using cURL")
    debug_log("function dependency_default_network_client: local variable CURL_DLL_DIR\n    ${CURL_DLL_DIR} ")

    # If libcurl hasn't been defined yet, create a SHARED IMPORTED target wrapper.
    if(NOT TARGET CURL::Imported)

        debug_log("function dependency_default_network_client: setting up cURL import library paths")
        
        add_library(CURL::Imported SHARED IMPORTED)
        
        # Check which compiler/toolchain is being used
        if(MSVC)

            # MSVC Toolchain configuration (.lib)
            set_target_properties(CURL::Imported PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/libcurl.lib"
                IMPORTED_LOCATION "${CURL_DLL_PATH}"
            )

        else()

            # MinGW Toolchain configuration (.dll.a)
            set_target_properties(CURL::Imported PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/libcurl.dll.a"
                IMPORTED_LOCATION "${CURL_DLL_PATH}"
            )

        endif()

        # Apply shared properties common to both toolchains
        set_target_properties(CURL::Imported PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/include/curl"
        )
        
        debug_log("CURL imported target configuration complete")

        dependency_openssl(${_lib_dir} NO_LINK)

    endif()

    # Automatically defers the linking of dependencies to the end of the directory
    # evaluation, ensuring the target exists before target_link_libraries is executed.
    cmake_language(DEFER CALL target_link_libraries ${CMAKE_PROJECT_NAME} PRIVATE CURL::Imported)

    # Store libcurl asset paths inside custom target properties, then defer the 
    # installation commands to the end of the file so they resolve during the install phase.
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        CX_INTERNAL_CURL_DLL "${CURL_DLL_PATH}"
        CX_INTERNAL_CURL_LICENCES "${CX_LIBS_DIR}/licences/curl"
        CX_INTERNAL_CURL_PREFIX "${CX_INSTALL_PREFIX}"
    )

    cmake_language(DEFER CALL install
        FILES "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_CURL_DLL>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_CURL_PREFIX>"
    )

    cmake_language(DEFER CALL install
        DIRECTORY "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_CURL_LICENCES>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_CURL_PREFIX>/licences"
    )
    
endfunction(dependency_default_network_client _lib_dir)

# Network client selection
function(dependency_network_client _network_client _lib_dir)

    # Guard. Only use
    if(NOT DEFINED CX_TRIGGER_NETWORK_CLIENT)
        debug_log("function dependency_network_client: network client import is disabled.")
        return()
    endif()

    if(${_network_client} STREQUAL "")
        message(STATUS "${CX_PRETTY_PRESET} Network client not set, falling back to the default dependency network client cURL")
    else()
        message(STATUS "${CX_PRETTY_PRESET} Selected network client[${_network_client}] to use")
    endif()

    string(TOLOWER "${_network_client}" network_client_option)
    
    if(${network_client_option} STREQUAL "curl")

        dependency_default_network_client(${_lib_dir})

    # TODO: Add other network clients. NOTE: other network clients need to be placed before the dependency_network_client function,
    # or through the use of CMake's include functions at the top of this file. 
    #elseif(${network_client_option} STREQUAL "other_network_client")

        # Add other audio drivers.
    #    debug_log("function dependency_network_client: other_network_client")

    elseif(${network_client_option} STREQUAL "")

        dependency_default_network_client(${_lib_dir})
        
    else()

        message(FATAL_ERROR "${CX_PRETTY_PRESET} dependency_network_client: Unknown network client driver[${_network_client}]")

    endif()

endfunction()