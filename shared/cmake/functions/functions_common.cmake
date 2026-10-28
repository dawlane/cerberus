#################################################
# Miscellaneous Functions


#################################################
# Common: Debug Log
#################################################
function(debug_log _input_var)
    message(DEBUG "DEBUG LOG ${CX_PRETTY_PRESET}: ${_input_var}")
endfunction(debug_log _input_var)

#################################################
# Show the PATH environment variable
#################################################
function(show_env _env)

    if(NOT CX_VERBOSE_OUTPUT)
        return()
    endif()

    # Fixed: Use DEFINED ENV{${_env}} to check if the dynamic env var exists
    if(NOT DEFINED ENV{${_env}})
        message(STATUS "${CX_PRETTY_PRESET} Environment variable not defined [${_env}]")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Environment variable: ${_env}")

    # Fixed: Use $ENV{${_env}} to properly retrieve the value of the dynamic env var
    cmake_path(CONVERT "$ENV{${_env}}" TO_CMAKE_PATH_LIST cmake_path_list)
    foreach(_item IN LISTS cmake_path_list)
        message(STATUS "    ${_item}")
    endforeach()

    message(STATUS "")

endfunction()



#################################################
# Common: Debug Show Target Properties
#################################################
function(debug_show_target_properties)

    foreach(_property IN LISTS ARGN)

        get_property(
            _is_set
            TARGET "${CMAKE_PROJECT_NAME}"
            PROPERTY "${_property}"
            SET
        )

        get_target_property(
            _value
            "${CMAKE_PROJECT_NAME}"
            "${_property}"
        )

        if(_is_set)
            if("${_value}" STREQUAL "")
                message(STATUS "${CX_PRETTY_PRESET}: ${_property} is Empty")
            else()
                message(STATUS "${CX_PRETTY_PRESET}: ${_property}")

                foreach(_item IN LISTS _value)
                    message(STATUS "    ${_item}")
                endforeach()

            endif()

        else()
            message(STATUS "${CX_PRETTY_PRESET}: ${_property} is not set")
        endif()

    endforeach()

    message(STATUS "")

endfunction()



#################################################
# Common: Pretty Platform Printer
#################################################
function(pretty_platform_string _input_string _output_var)
    debug_log("function pretty_platform_string: ${_input_string}")
    string(REGEX REPLACE "^[Cc][Xx]_" "" _clean_string "${_input_string}")
    
    string(FIND "${_clean_string}" "_" _last_underscore_idx REVERSE)
    
    if(_last_underscore_idx EQUAL -1)
        string(TOUPPER "${_clean_string}" _fallback_str)
        set(${_output_var} "[${_fallback_str} UNKNOWN]" PARENT_SCOPE)
        return()
    endif()
    
    string(SUBSTRING "${_clean_string}" 0 ${_last_underscore_idx} _name_part)
    
    math(EXPR _arch_start_idx "${_last_underscore_idx} + 1")
    string(SUBSTRING "${_clean_string}" ${_arch_start_idx} -1 _arch_part)
    
    string(REPLACE "_" ";" _name_words "${_name_part}")
    
    set(_name_title_list "")
    foreach(_word IN LISTS _name_words)
        string(TOLOWER "${_word}" _word_lower)
        string(SUBSTRING "${_word_lower}" 0 1 _first_letter)
        string(SUBSTRING "${_word_lower}" 1 -1 _rest_of_word)
        string(TOUPPER "${_first_letter}" _first_letter_upper)
        
        list(APPEND _name_title_list "${_first_letter_upper}${_rest_of_word}")
    endforeach()
    
    string(REPLACE ";" " " _name_title "${_name_title_list}")
    
    string(REPLACE "Macos" "macOS" _name_title "${_name_title}")
    string(REPLACE "Vs" "VS" _name_title "${_name_title}")
    
    string(TOLOWER "${_arch_part}" _arch_lower)
    if(_arch_lower STREQUAL "x64" OR _arch_lower STREQUAL "x86")
        set(_arch_formatted "${_arch_lower}")
    else()
        string(TOUPPER "${_arch_part}" _arch_formatted)
    endif()
    
    debug_log("Converted platform string ${_input_string} into [${_name_title} ${_arch_formatted}]")
    set(${_output_var} "[${_name_title} ${_arch_formatted}]" PARENT_SCOPE)

endfunction(pretty_platform_string _input_string _output_var)


#################################################
# Common: Path to Posix Path
#################################################
function(path_to_posix _input_var _output_var)

    if(NOT ${_input_var})
        debug_log("function path_to_posix: Input ${_input_var} is empty. Exiting early.")
        set(${_output_var} "" PARENT_SCOPE)
        return()
    endif()

    set(processed_list "")

    foreach(raw_path IN LISTS ${_input_var})
        string(REPLACE "\\" "/" standardized_path "${raw_path}")
        cmake_path(NORMAL_PATH standardized_path)
        list(APPEND processed_list "${standardized_path}")
    endforeach()

    set(${_output_var} "${processed_list}" PARENT_SCOPE)

    debug_log("function path_to_posix: Input ${_input_var}\n    ${_input_var}=${${_input_var}}\n    ${_output_var}=${${_output_var}}\n")

endfunction(path_to_posix _input_var _output_var)


#################################################
# Helper: Apple Bundle Checker
#################################################
# Function to install the data directories.
# Helper function to get the actual .app bundle folder name for the main project target
function(get_main_project_bundle_dir _out_dir_var)

    if(TARGET "${CMAKE_PROJECT_NAME}")

        get_target_property(_is_bundle "${CMAKE_PROJECT_NAME}" MACOSX_BUNDLE)

        if(_is_bundle AND NOT _is_bundle STREQUAL "_is_bundle-NOTFOUND" AND _is_bundle)
            
            # Check if an explicit OUTPUT_NAME property was set on the target
            get_target_property(_custom_output_name "${CMAKE_PROJECT_NAME}" OUTPUT_NAME)
            
            if(_custom_output_name AND NOT _custom_output_name STREQUAL "_custom_output_name-NOTFOUND")
                set(_app_name "${_custom_output_name}")
            else()
                set(_app_name "${CMAKE_PROJECT_NAME}")
            endif()

            set(${_out_dir_var} "${_app_name}.app" PARENT_SCOPE)

            return()
        endif()

    endif()
    
    # Not an app bundle
    set(${_out_dir_var} "" PARENT_SCOPE)
    
endfunction(get_main_project_bundle_dir _out_dir_var)



#################################################
# Common: Copy Cerberus Data Folders
#################################################
function(install_cerberus_data_directories)

    get_main_project_bundle_dir(_bundle_dir)
    debug_log("function install_cerberus_data_directories")

    if(_bundle_dir)
        message(DEBUG "    Apple app bundle target detected (${_bundle_dir})")
        set(_data_base_dest "${CX_INSTALL_PREFIX}/${_bundle_dir}/Contents/Resources")
    else()
        message(DEBUG "    Standard data copy")
        set(_data_base_dest "${CX_INSTALL_PREFIX}")
    endif()

    install(
        DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/data/"
        DESTINATION "${_data_base_dest}/data"
    )

    install(
        DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/internal/"
        DESTINATION "${_data_base_dest}/internal"
    )
    
    install(
        DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/external/"
        DESTINATION "${_data_base_dest}/external"
    )

endfunction(install_cerberus_data_directories)


#################################################
# Common: Set Application Bundle Options
#################################################
function(set_macos_apple_bundle)

    if("${CX_TARGET_SYSTEM_NAME}" STREQUAL "stdcpp")
        debug_log("function include_resource_files: target system is C++ Tool [stdcpp]")
        return()
    endif()

    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "${CMAKE_PROJECT_NAME}"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${CX_APPLE_APP_BUNDLE_ID}"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${CX_APPLE_APP_BUNDLE_ID}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_ICON_FILE app_icon.icns
    )

    set_source_files_properties(${RESOURCES} PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )

    get_target_property(APP_NAME ${CMAKE_PROJECT_NAME} MACOSX_BUNDLE_BUNDLE_NAME)
    get_target_property(APP_ID ${CMAKE_PROJECT_NAME} MACOSX_BUNDLE_GUI_IDENTIFIER)
    get_target_property(APP_VER ${CMAKE_PROJECT_NAME} MACOSX_BUNDLE_BUNDLE_VERSION)
    get_target_property(APP_ICON ${CMAKE_PROJECT_NAME} MACOSX_BUNDLE_ICON_FILE)

    if(CX_VERBOSE_OUTPUT)
        message(STATUS "${CX_PRETTY_PRESET} Application bundle information")
        message(STATUS "    Bundle Name: ${APP_NAME}")
        message(STATUS "    Bundle Identifier: ${APP_ID}")
        message(STATUS "    Bundle Version: ${APP_VER}")

        if("${CX_APP_ICON}" STREQUAL "")
            message(STATUS "    Bundle Icon App Name: ${CX_APP_ICON} > ${APP_ICON}")
        else()
            message(STATUS "    Bundle Icon App Name: ${APP_ICON}")
        endif()
    endif()

    foreach(RESOURCE_FILE ${RESOURCES})
        get_source_file_property(PKG_LOC "${RESOURCE_FILE}" MACOSX_PACKAGE_LOCATION)
        if(CX_VERBOSE_OUTPUT)
            message(STATUS "    Resource: ${RESOURCE_FILE} -> Package Location: ${PKG_LOC}")
        endif()
    endforeach()
    
endfunction(set_macos_apple_bundle)


#################################################
# Common: Multi Type Generator Config
#################################################
function(set_target_definitions)

    target_compile_definitions(${CMAKE_PROJECT_NAME} PRIVATE 
        $<$<CONFIG:Debug>:DEBUG_MODE=1>
        $<$<CONFIG:Release>:RELEASE_MODE=1>
    )

endfunction(set_target_definitions)


#################################################
# Common: Show CACHE Variables
#################################################
function(show_cache_vars)

    message(STATUS "${CX_PRETTY_PREFIX} CACHE VARIABLES:")
    get_directory_property(${CMAKE_PROJECT_NAME} CACHE_VARIABLES)

    foreach(cache_var IN LISTS ${CMAKE_PROJECT_NAME})
        get_property(cache_val CACHE ${cache_var} PROPERTY VALUE)
        message(STATUS "${cache_var} = ${cache_val}")
    endforeach()

    message(STATUS "")

endfunction()


#################################################
# Common: Show CACHE Variables and Properties
#################################################
function(show_dir_properties)

    message(STATUS "${CX_PRETTY_PREFIX} DIRECTORY PROPERTIES:")

    define_property(DIRECTORY PROPERTY INTERNAL BRIEF_DOCS "" FULL_DOCS "") 

    get_directory_property(prop_list PROPERTIES)
    list(SORT prop_list)

    foreach(prop IN LISTS prop_list)

        get_directory_property(prop_val ${prop})
        if(prop_val)
            message(STATUS "    ${prop} = ${prop_val}")
        endif()

    endforeach()

    message(STATUS "")

endfunction()


#################################################
# Common: Show the Complete Internal Properties
#################################################
function(print_target_properties _tgt)

    if(NOT TARGET ${CMAKE_PROJECT_NAME})
        message(WARNING "Target '${_tgt}' does not exist.")
    else()

        # CMake's complete internal list of target properties
        set(target_props
            SOURCES TYPE LINK_LIBRARIES INCLUDE_DIRECTORIES COMPILE_DEFINITIONS
            COMPILE_OPTIONS INTERFACE_INCLUDE_DIRECTORIES INTERFACE_COMPILE_DEFINITIONS
            BINARY_DIR SOURCE_DIR OUTPUT_NAME SUFFIX PREFIX CLEAN_DIRECT_OUTPUT
        )
        
        message(STATUS "${CX_PRETTY_PREFIX} TARGET PROPERTIES: ${_tgt}")
        foreach(prop IN LISTS target_props)
            get_target_property(prop_val ${_tgt} ${prop})

            if(prop_val)
                message(STATUS "    ${prop} = ${prop_val}")
            endif()
            
        endforeach()

    endif()

    message(STATUS "")

endfunction()


#################################################
# Common: Show all Global Properties
#################################################
function(show_global_properties)

    set(global_props
        ALLOW_DUPLICATE_CUSTOM_TARGETS ECLIPSE_EXTRA_NATURES 
        FIND_LIBRARY_USE_LIB32_PATHS FIND_LIBRARY_USE_LIB64_PATHS 
        GHS_CUSTOM_TARGETS IN_TRY_COMPILE PACKAGES_FOUND PACKAGES_NOT_FOUND
        TARGET_ARCHIVES_MAY_FAST_LINK TARGET_SUPPORTS_SHARED_LIBS USE_FOLDERS
    )

    foreach(prop IN LISTS global_props)
        get_property(prop_val GLOBAL PROPERTY ${prop})
        if(prop_val)
            message(STATUS "    ${prop} = ${prop_val}")
        endif()
    endforeach()

    message(STATUS "")

endfunction()


#################################################
# Common: Show Basic Start Information
#################################################
function(show_start_up_info)
    message(STATUS "")
    message(STATUS "${CX_PRETTY_PRESET} Cerberus-X information:")
    string(TOUPPER "${CX_TARGET_SYSTEM_NAME}" CX_TARGET_SYSTEM_NAME_UPPER)
    message(STATUS "${CX_PRETTY_PRESET} Target System Name: ${CX_TARGET_SYSTEM_NAME_UPPER}")
    message(STATUS "${CX_PRETTY_PRESET} Cerberus Root Directory:")
    message(STATUS "    ${CX_ROOT_DIR}")
    message(STATUS "${CX_PRETTY_PRESET} Cerberus Library Directory")
    message(STATUS "    ${CX_LIBS_DIR}")
    message(STATUS "")
    message(STATUS "${CX_PRETTY_PRESET} Project information:")
    message(STATUS "    Output Name: ${CMAKE_PROJECT_NAME}")
    message(STATUS "    Output Directory:")
    message(STATUS "        ${CX_INSTALL_PREFIX}")
    message(STATUS "")

    if(CMAKE_HOST_WIN32 AND CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        message(STATUS "${CX_PRETTY_PRESET} MSVC Setup:")
        message(STATUS "    Platform Tool Set: ${CMAKE_VS_PLATFORM_TOOLSET}")
        message(STATUS "    Windows SDK Version: ${CX_WINDOWS_SDK}")
        message(STATUS "")
    endif(CMAKE_HOST_WIN32 AND CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    
    show_env("PATH")

    message(STATUS "${CX_PRETTY_PRESET} CMake setup:")
    message(STATUS "    CMake Version: ${CMAKE_VERSION}")
    message(STATUS "    CMake Generator: ${CMAKE_GENERATOR}")
    message(STATUS "")
    message(STATUS "${CX_PRETTY_PRESET} Compiler Language:")
    message(STATUS "    C Compiler Standard: ${CMAKE_C_STANDARD}")
    message(STATUS "    C++ Compiler Standard: ${CMAKE_CXX_STANDARD}")
    message(STATUS "")
   
endfunction(show_start_up_info)
