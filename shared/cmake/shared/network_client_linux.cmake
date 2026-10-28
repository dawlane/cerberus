#####################################################################
# Dependencies for Linux network clients

# The default network client to use is cURL, so a dedicated function is used to save duplication.
function(dependency_default_network_client)

    debug_log("function dependency_default_network_client: Using cURL")

    find_package(CURL REQUIRED)

    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE CURL::libcurl)

endfunction(dependency_default_network_client)

# Network client selection
function(dependency_network_client _network_client)

    if(NOT DEFINED CX_TRIGGER_NETWORK_CLIENT)
        debug_log("function dependency_network_client: Network client dependency not included")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Including dependency network client driver[${_network_client}]")

    string(TOLOWER "${_network_client}" network_client_option)
    
    if(${network_client_option} STREQUAL "curl")

        dependency_default_network_client()

    # TODO: Add other network clients. NOTE: other network clients need to be placed before the dependency_network_client function,
    # or through the use of CMake's include functions at the top of this file. 
    #elseif(${network_client_option} STREQUAL "other_network_client")

        # Add other audio drivers.
    #    debug_log("function dependency_network_client: other_network_client")

    elseif(${network_client_option} STREQUAL "")

        dependency_default_network_client()

    else()

        message(FATAL_ERROR "${CX_PRETTY_PRESET} dependency_network_client: Unknown network client driver[${_network_client}]")

    endif()

endfunction()