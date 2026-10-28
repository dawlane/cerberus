#####################################################################
# Dependencies for Linux network clients

# The default network client to use is cURL, so a dedicated function is used to save duplication.
function(dependency_default_network_client)

    debug_log("function dependency_default_network_client: Using cURL")

    find_package(CURL REQUIRED)

    target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE CURL::libcurl)

endfunction(dependency_default_network_client)
