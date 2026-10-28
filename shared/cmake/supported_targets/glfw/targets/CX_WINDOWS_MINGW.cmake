########################################################
# Setting up MinGw build options

# Include dependencies
include(functions_mingw)
include(glfw)
include(stb)
include(tiny_file_dialogs)
include(audio)
include(network_client)

# Include cmake file related to MinGW builds
include(install_mingw)

# Architecture target specific options
function(load_options_mingw_x86)

    # The functions will check if the flag for static linking is set.
    set_static_linking()
    install_mingw_runtimes()

    # Required for tcp,udp, and network stuff.
    linker_winsocket2_trigger()

    dependency_library_glfw()
    dependency_library_stb()
    dependency_library_tiny_file_dialogs()

    dependency_audio("${CX_AUDIO_DRIVER}" "Win32")
    dependency_network_client("${CX_NETWORK_CLIENT}" "Win32")
    
endfunction(load_options_mingw_x86)


function(load_options_mingw_x64)

    # The functions will check if the flag for static linking is set.
    set_static_linking()
    install_mingw_runtimes()

    # Required for tcp,udp, and network stuff.
    linker_winsocket2_trigger()

    dependency_library_glfw()
    dependency_library_stb()
    dependency_library_tiny_file_dialogs()

    dependency_audio("${CX_AUDIO_DRIVER}" "Win64")
    dependency_network_client("${CX_NETWORK_CLIENT}" "Win64")

endfunction(load_options_mingw_x64)


# Common entry function. Check the CX_PLATFORM against those in the presets
function(load_options)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")

    if("${CX_PLATFORM}" STREQUAL "CX_MINGW_X86")
        debug_log("load_options: selected CX_MINGW_X86")
        load_options_mingw_x86()

    elseif("${CX_PLATFORM}" STREQUAL "CX_MINGW_X64")
        debug_log("load_options: selected CX_MINGW_X64")
        load_options_mingw_x64()

    elseif("${CX_PLATFORM}" STREQUAL "CX_NINJA_MINGW_X86")
        debug_log("load_options: selected CX_NINJA_MINGW_X86")
        load_options_mingw_x86()

    elseif("${CX_PLATFORM}" STREQUAL "CX_NINJA_MINGW_X64")
        debug_log("load_options: selected CX_NINJA_MINGW_X64")
        load_options_mingw_x64()

    else()
        message(FATAL_ERROR "Unknown CX_PLATFORM: ${CX_PLATFORM}")
    endif()
    
endfunction(load_options)


# Common entry function to call target specific external link options
function(link_externals)

    message(STATUS "${CX_PRETTY_PRESET} Linking external dependencies")

    # triggers_windows.cmake:
    linker_static_library_windows_trigger()
    linker_shared_library_windows_trigger()

    # file install_mingw.cmake:
    install_shared_libraries_mingw()

endfunction(link_externals)