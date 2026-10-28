########################################################
# Setting up Visual Studio build options
# NOTE: Architecture must be set via the "architecture" property in the preset.

# Include cmake file related to MSVC builds
include(install_msvc)


function(load_options_msvc)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")

    # Required for tcp,udp, and network stuff.
    linker_winsocket2_trigger()
    
    # Add additional options if required
    
endfunction(load_options_msvc)


# Common entry function. Check the CX_PLATFORM against those in the presets
function(load_options)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")

    if("${CX_PLATFORM}" STREQUAL "CX_VS2019_X86")
        debug_log("load_options: selected CX_VS2019_X86")
        load_options_msvc()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2019_X64")
        debug_log("load_options: selected CX_VS2019_X64")
        load_options_msvc()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2022_X86")
        debug_log("load_options: selected CX_VS2022_X86")
        load_options_msvc()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2022_X64")
        debug_log("load_options: selected CX_VS2022_X64")
        load_options_msvc()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2026_X86")
        debug_log("load_options: selected CX_VS2026_X86")
        load_options_msvc()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2026_X64")
        debug_log("load_options: selected CX_VS2026_X64")
        load_options_msvc()

    else()
        message(FATAL_ERROR "Unknown CX_PLATFORM: ${CX_PLATFORM}")
    endif()
    
endfunction(load_options)


# Common entry function to call target specific external link options
function(link_externals)

    # triggers_windows.cmake:
    linker_static_library_windows_trigger()
    linker_shared_library_windows_trigger()

    # file install_msvc.cmake:
    install_shared_libraries_msvc()

endfunction(link_externals)