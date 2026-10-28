########################################################
# Setting up Visual Studio build options
# NOTE: Architecture must be set via the "architecture" property in the preset.

# Include dependencies
include(glfw)
include(stb)
include(tiny_file_dialogs)
include(audio)
include(network_client)

# Include cmake file related to MSVC builds
include(install_msvc)


function(load_options_msvc_x86)

    # Required for tcp,udp, and network stuff.
    linker_winsocket2_trigger()

    dependency_library_glfw()
    dependency_library_stb()
    dependency_library_tiny_file_dialogs()

    dependency_audio("${CX_AUDIO_DRIVER}" "Win32")
    dependency_network_client("${CX_NETWORK_CLIENT}" "Win32")
    
    # Add additional options if required
    
endfunction(load_options_msvc_x86)

function(load_options_msvc_x64)

    # Required for tcp,udp, and network stuff.
    linker_winsocket2_trigger()

    dependency_library_glfw()
    dependency_library_stb()
    dependency_library_tiny_file_dialogs()

    dependency_audio("${CX_AUDIO_DRIVER}" "Win64")
    dependency_network_client("${CX_NETWORK_CLIENT}" "Win64")
    
    # Add additional options if required
    
endfunction(load_options_msvc_x64)


# Common entry function. Check the CX_PLATFORM against those in the presets
function(load_options)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")

    if("${CX_PLATFORM}" STREQUAL "CX_VS2019_X86")
        debug_log("load_options: selected CX_VS2019_X86")
        load_options_msvc_x86()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2019_X64")
        debug_log("load_options: selected CX_VS2019_X64")
        load_options_msvc_x64()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2022_X86")
        debug_log("load_options: selected CX_VS2022_X86")
        load_options_msvc_x86()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2022_X64")
        debug_log("load_options: selected CX_VS2022_X64")
        load_options_msvc_x64()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2026_X86")
        debug_log("load_options: selected CX_VS2026_X86")
        load_options_msvc_x86()

    elseif("${CX_PLATFORM}" STREQUAL "CX_VS2026_X64")
        debug_log("load_options: selected CX_VS2026_X64")
        load_options_msvc_x64()

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