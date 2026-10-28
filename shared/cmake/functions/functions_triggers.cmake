########################################################
# External functions file for adding additional options
# This file contains functions to either include certain target options.
if(APPLE)
    include(triggers_macos)
elseif(WIN32)
    include(triggers_windows)
else()
    include(triggers_linux)
endif()

########################################################
# Trigger: Show CACHE Variables and Properties
########################################################
function(show_properties_and_cache)

    if(NOT CX_TRIGGER_CMAKE_DEBUG_SHOW_CACHE_VARS)
        return()
    endif()

    show_cache_vars()
    show_dir_properties()
    print_target_properties(${CMAKE_PROJECT_NAME})
    show_global_properties()

endfunction(show_properties_and_cache)


########################################################
# Trigger: Source Files
########################################################
function(source_file_trigger _sources)

    if(NOT DEFINED CX_TRIGGER_OPTS_SOURCE)
        debug_log("function source_file_trigger: No additional sources passed")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Processing additional source files")
    include("${CMAKE_CURRENT_LIST_DIR}/cmake/source-files.cmake")

    foreach(_item IN LISTS CX_OPTS_SOURCE)
        path_to_posix(_item _item)
        list(APPEND ${_sources} "${_item}")
    endforeach()

    if(CX_VERBOSE_OUTPUT)
        foreach(_list_item IN LISTS ${_sources})
            message(STATUS "    ${_list_item}")
        endforeach()
        message(STATUS "")
    endif()

    set(${_sources} "${${_sources}}" PARENT_SCOPE)

endfunction(source_file_trigger)


########################################################
# Trigger: Compiler Options
########################################################
function(compiler_options_trigger)

    if(NOT DEFINED CX_TRIGGER_OPTS_COMPILER)
        debug_log("function compiler_c_options_trigger: No compiler options passed")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Processing compile options")
    foreach(_item IN LISTS CX_OPTS_COMPILER)
        target_compile_options(
            ${CMAKE_PROJECT_NAME}
            PRIVATE
            ${_item}
        )
    endforeach()

    if(CX_VERBOSE_OUTPUT)
        debug_show_target_properties(COMPILE_OPTIONS)
    endif()

endfunction()


########################################################
# Trigger: Compiler Define Options
########################################################
function(compiler_defines_trigger)

    if(NOT DEFINED CX_TRIGGER_OPTS_DEFINES)
        debug_log("function compiler_defines_trigger: No compiler defines passed")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Processing compiler definitions")
    target_compile_definitions(
        ${CMAKE_PROJECT_NAME}
        PRIVATE
        ${CX_OPTS_DEFINES}
    )

    if(CX_VERBOSE_OUTPUT)
        debug_show_target_properties(COMPILE_DEFINITIONS)
    endif()

endfunction()


########################################################
# Trigger Compiler Header File Paths
########################################################
function(compiler_header_paths_trigger)

    if(NOT DEFINED CX_TRIGGER_PATHS_INCLUDE)
        debug_log("function compiler_header_paths_trigger: No header files passed")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Processing header search paths")
    target_include_directories(
        ${CMAKE_PROJECT_NAME}
        PRIVATE
        ${CX_PATHS_INCLUDE}
    )

    if(CX_VERBOSE_OUTPUT)
        debug_show_target_properties(INCLUDE_DIRECTORIES)
    endif()

endfunction()


########################################################
# Trigger: Linker Options
########################################################
function(linker_options_trigger)

    if(NOT DEFINED CX_TRIGGER_OPTS_LINKER)
        debug_log("function linker_options_trigger: No linker options passed")
        return()
    endif()

    message(STATUS "${CX_PRETTY_PRESET} Processing linker options")
    target_link_options(
        ${CMAKE_PROJECT_NAME}
        PRIVATE
        ${CX_OPTS_LINKER}
    )

    if(CX_VERBOSE_OUTPUT)
        debug_show_target_properties(LINK_OPTIONS)
    endif()
    
endfunction()