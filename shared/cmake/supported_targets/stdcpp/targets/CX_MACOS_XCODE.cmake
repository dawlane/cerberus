########################################################
# Setting up macOS build options
# NOTE: Architecture must be set via the "CMAKE_OSX_ARCHITECTURES" cache variable in the preset.

# Include cmake file related to MSVC builds
include(install_macos)

function(load_options_macos)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")
    
    # Add additional options if required
    
endfunction(load_options_macos)


function(load_options)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")

    if("${CX_PLATFORM}" STREQUAL "CX_MACOS_INTEL")
        debug_log("load_options: selected CX_MACOS_INTEL")
        load_options_macos()

    elseif("${CX_PLATFORM}" STREQUAL "CX_MACOS_ARM64")
        debug_log("load_options: selected CX_MACOS_ARM64")
        load_options_linux_x64()

    elseif("${CX_PLATFORM}" STREQUAL "CX_MACOS_UNIVERSAL")
        debug_log("load_options: selected CX_MACOS_UNIVERSAL")
        load_options_macos()

    elseif("${CX_PLATFORM}" STREQUAL "CX_NINJA_MACOS_INTEL")
        debug_log("load_options: selected CX_NINJA_MACOS_INTEL")
        load_options_linux_x64()

    elseif("${CX_PLATFORM}" STREQUAL "CX_NINJA_MACOS_ARM64")
        debug_log("load_options: selected CX_NINJA_MACOS_ARM64")
        load_options_macos()

    elseif("${CX_PLATFORM}" STREQUAL "CX_NINJA_MACOS_UNIVERSAL")
        debug_log("load_options: selected CX_NINJA_MACOS_UNIVERSAL")
        load_options_macos()

    else()
        message(FATAL_ERROR "Unknown CX_PLATFORM: ${CX_PLATFORM}")
    endif()
    
endfunction(load_options)


# Common entry function to call target specific external link options
function(link_externals)

    # file functions/macos/triggers_macos.cmake:
    linker_static_library_macos_trigger()
    linker_shared_library_macos_trigger()
    linker_frameworks_macos_trigger()

    # file install_macos.cmake:
    install_shared_libraries_macos()
    install_frameworks_macos()

endfunction(link_externals)