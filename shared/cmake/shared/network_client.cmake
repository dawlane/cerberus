if(WIN32)
    debug_log("network_client.cmake: importing winnt supported network_client driver functions")
    include(network_client_winnt)
elseif(UNIX AND NOT APPLE)
    debug_log("network_client.cmake: importing linux supported network_client driver functions")
    include(network_client_linux)
elseif(APPLE)
    debug_log("network_client.cmake: importing macos supported network_client driver functions")
    include(network_client_macos)
else()
    message(FATAL_ERROR "network.cmake: Unknown host OS")
endif()

# Network client selection
function(dependency_network_client _network_client)

    # Get the network client driver name
    if(ARGC GREATER_EQUAL 1)
        set(_audio_driver "${ARGV0}")
    endif()

    # Get the directory
    if(ARGC GREATER_EQUAL 2)
        set(_lib_dir "${ARGV1}")
    endif()

    if(NOT DEFINED CX_TRIGGER_NETWORK_CLIENT)
        debug_log("function dependency_network_client: network client dependency not included")
        return()
    endif()

    if("${_network_client}" STREQUAL "")
        message(STATUS "${CX_PRETTY_PRESET} Network Client not set, falling back to the default dependency network client[cURL].")
    else()
        message(STATUS "${CX_PRETTY_PRESET} Selected network client[${_network_client}] to use")
    endif()

    debug_log("function dependency_audio_winnt: parameters")
    message(DEBUG "    Network Client: ${_network_client}")
    message(DEBUG "    Library Dir: ${_lib_dir}")
    message(DEBUG "    CX Lib Dir: ${CX_LIBS_DIR}")
    message(DEBUG "    Install Dir: ${CX_INSTALL_PREFIX}")

    string(TOLOWER "${_network_client}" network_client_option)
    
    if("${network_client_option}" STREQUAL "curl")

        debug_log("function dependency_network_client: Using cURL")
        dependency_default_network_client(${_lib_dir})

    # TODO: Add other network clients. NOTE: other network clients need to be placed before the dependency_network_client function,
    # or through the use of CMake's include functions at the top of this file. 
    #elseif("${network_client_option}"" STREQUAL "other_network_client")

    #    debug_log("function dependency_network_client: other_network_client")

    elseif("${network_client_option}" STREQUAL "")
        message(STATUS "${CX_PRETTY_PRESET} Network Client not set, falling back to the default dependency network client[cURL].")
        dependency_default_network_client(${_lib_dir})

    else()

        message(FATAL_ERROR "${CX_PRETTY_PRESET} dependency_network_client: Unknown network client[${_network_client}]")

    endif()

endfunction()