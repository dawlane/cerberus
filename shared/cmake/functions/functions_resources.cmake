#####################################################################
# Functions to make sure that the resources are correctly added to the sources.


#####################################################################
# Resources: Setup Resources
#####################################################################
function(include_resource_files)

    if("${CX_TARGET_SYSTEM_NAME}" STREQUAL "stdcpp")
        debug_log("function include_resource_files: target system is C++ Tool [stdcpp]")
        return()
    endif()

    # Read the existing SOURCES variable from the parent scope
    set(LOCAL_SOURCES ${SOURCES})

    # Add the resources. In Windows, resources are imported via a resource file.
    # In macOS, resource files are added to a list, and then set in MACOSX_PACKAGE_LOCATION.
    if(WIN32)

        set(RES_FILE "resource.rc")
        debug_log("function include_resource_files: resource file ${RES_FILE}")

    elseif(APPLE)

        set(RES_FILE "app_icon.icns")
        debug_log("function include_resource_files: apple bundle icon ${CX_APP_ICON} > app_icon")

        # Configure CMake to place the icon inside the App Bundle Resources folder
        set_source_files_properties(${RES_FILE} PROPERTIES
            MACOSX_PACKAGE_LOCATION Resources
        )

    endif()

    # Append to our local list
    list(APPEND LOCAL_SOURCES ${RES_FILE})

    # Export the updated list back to the parent scope's SOURCES variable
    set(SOURCES ${LOCAL_SOURCES} PARENT_SCOPE)

endfunction()
