#####################################################################
# OpenSSL dependency for MS Windows
# Imports crypto-3, ssl-3
include(zlib_winnt)
include(nghttp_winnt)

# libcrypto
function(dependency_crypto _lib_dir)

    # Parse optional flags (ARGN captures anything after _lib_dir)
    set(options NO_LINK)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(CRYPTO "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    debug_log("function dependency_crypto: Using OpenSSL libcrypto")

    # Get suffix for 64-bit runtime environments
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(_suffix "-x64")
    else()
        set(_suffix "")
    endif()

    set(CRYPTO_DLL_DIR "${CX_LIBS_DIR}/${_lib_dir}/msvc")
    set(CRYPTO_DLL_PATH "${CRYPTO_DLL_DIR}/libcrypto-3${_suffix}.dll")

    debug_log("function dependency_crypto: local variable CRYPTO_DLL_DIR\n    ${CRYPTO_DLL_DIR} ")
    debug_log("function dependency_crypto: local variable CRYPTO_DLL_PATH\n    ${CRYPTO_DLL_PATH} ")

    # If libcrypto hasn't been defined yet, create a SHARED IMPORTED target wrapper.
    if(NOT TARGET OpenSSL::Crypto)

        debug_log("function dependency_crypto: setting up libcrypto import library paths")
        add_library(OpenSSL::Crypto SHARED IMPORTED)
        
        if(MSVC)
            set_target_properties(OpenSSL::Crypto PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/libcrypto.lib"
                IMPORTED_LOCATION "${CRYPTO_DLL_PATH}"
            )
        else()
            set_target_properties(OpenSSL::Crypto PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/libcrypto.dll.a"
                IMPORTED_LOCATION "${CRYPTO_DLL_PATH}"
            )
        endif()

        set_target_properties(OpenSSL::Crypto PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/include"
        )
        
        debug_log("libcrypto imported target configuration complete")

    endif()

    # Automatically defers the linking of dependencies to the end of the directory evaluation.
    if(NOT CRYPTO_NO_LINK)
        cmake_language(DEFER CALL target_link_libraries ${CMAKE_PROJECT_NAME} PRIVATE OpenSSL::Crypto)
    else()
        debug_log("function dependency_crypto: Bypassing linking stage due to NO_LINK flag")
    endif()

    # Store libcrypto asset paths inside custom target properties, then defer the installation commands.
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        CX_INTERNAL_CRYPTO_DLL "${CRYPTO_DLL_PATH}"
        CX_INTERNAL_CRYPTO_LICENCES "${CX_LIBS_DIR}/licences/openssl"
        CX_INTERNAL_CRYPTO_PREFIX "${CX_INSTALL_PREFIX}"
    )

    cmake_language(DEFER CALL install
        FILES "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_CRYPTO_DLL>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_CRYPTO_PREFIX>"
    )

    cmake_language(DEFER CALL install
        DIRECTORY "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_CRYPTO_LICENCES>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_CRYPTO_PREFIX>/licences"
    )

endfunction(dependency_crypto _lib_dir)

# libssl
function(dependency_ssl _lib_dir)

    # Parse optional flags (ARGN captures anything after _lib_dir)
    set(options NO_LINK)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(SSL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    debug_log("function dependency_ssl: Using OpenSSL libssl")

    # Get suffix for 64-bit runtime environments
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(_suffix "-x64")
    else()
        set(_suffix "")
    endif()

    set(SSL_DLL_DIR "${CX_LIBS_DIR}/${_lib_dir}/msvc")
    set(SSL_DLL_PATH "${SSL_DLL_DIR}/libssl-3${_suffix}.dll")

    debug_log("function dependency_ssl: local variable SSL_DLL_DIR\n    ${SSL_DLL_DIR} ")
    debug_log("function dependency_ssl: local variable SSL_DLL_PATH\n    ${SSL_DLL_PATH} ")

    # If libssl hasn't been defined yet, create a SHARED IMPORTED target wrapper.
    if(NOT TARGET OpenSSL::SSL)

        debug_log("function dependency_ssl: setting up libssl import library paths")
        add_library(OpenSSL::SSL SHARED IMPORTED)
        
        if(MSVC)
            set_target_properties(OpenSSL::SSL PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/libssl${_suffix}.lib"
                IMPORTED_LOCATION "${SSL_DLL_PATH}"
            )
        else()
            set_target_properties(OpenSSL::SSL PROPERTIES 
                IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/libssl${_suffix}.dll.a"
                IMPORTED_LOCATION "${SSL_DLL_PATH}"
            )
        endif()

        # Link to OpenSSL::Crypto if target exists, establishing clear header requirements
        set_target_properties(OpenSSL::SSL PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/include"
        )
        if(TARGET OpenSSL::Crypto)
            set_target_properties(OpenSSL::SSL PROPERTIES INTERFACE_LINK_LIBRARIES OpenSSL::Crypto)
        endif()
        
        debug_log("libssl imported target configuration complete")
    endif()

    # Automatically defers the linking of dependencies to the end of the directory evaluation.
    if(NOT SSL_NO_LINK)
        cmake_language(DEFER CALL target_link_libraries ${CMAKE_PROJECT_NAME} PRIVATE OpenSSL::SSL)
    else()
        debug_log("function dependency_ssl: Bypassing linking stage due to NO_LINK flag")
    endif()

    # Store libssl asset paths inside custom target properties, then defer the installation commands.
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        CX_INTERNAL_SSL_DLL "${SSL_DLL_PATH}"
        CX_INTERNAL_SSL_LICENCES "${CX_LIBS_DIR}/licences/openssl"
        CX_INTERNAL_SSL_PREFIX "${CX_INSTALL_PREFIX}"
    )

    cmake_language(DEFER CALL install
        FILES "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_SSL_DLL>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_SSL_PREFIX>"
    )

    # Note: If dependency_crypto is also evaluated, this directory call will gracefully 
    # merge into the same destination directory without collision errors.
    cmake_language(DEFER CALL install
        DIRECTORY "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_SSL_LICENCES>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_SSL_PREFIX>/licences"
    )

endfunction(dependency_ssl _lib_dir)

#####################################################################
# Master Wrapper for OpenSSL 3
function(dependency_openssl _lib_dir)

    # Parse optional flags passed to the master function
    set(options NO_LINK)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(OPENSSL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    debug_log("function dependency_openssl: Initialising OpenSSL master setup wrapper")

    # Reconstruct the pass-through arguments dynamically
    set(_forward_args)
    if(OPENSSL_NO_LINK)
        list(APPEND _forward_args NO_LINK)
    endif()

    # Call the decoupled sub-functions sequentially
    dependency_crypto("${_lib_dir}" ${_forward_args})
    dependency_ssl("${_lib_dir}" ${_forward_args})
    dependency_zlib("${_lib_dir}" ${_forward_args})
    dependency_ng_http("${_lib_dir}" ${_forward_args})

    debug_log("function dependency_openssl: OpenSSL master setup wrapper completed successfully")

endfunction(dependency_openssl _lib_dir)




