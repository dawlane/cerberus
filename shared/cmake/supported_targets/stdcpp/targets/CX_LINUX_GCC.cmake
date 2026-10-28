########################################################
# Setting up Linux build options
include(install_linux)

function(load_options_linux_x86)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")

    # Force 64 bit compilation.
    target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE "-m32")
    target_link_options(${CMAKE_PROJECT_NAME} PRIVATE "-m32")

    # Add additional options if required
    
endfunction(load_options_linux_x86)


function(load_options_linux_x64)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")

    # Force 64 bit compilation.
    target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE "-m64")
    target_link_options(${CMAKE_PROJECT_NAME} PRIVATE "-m64")

    # Add additional options if required
    
endfunction(load_options_linux_x64)


# Common entry function. Check the CX_PLATFORM against those in the presets
function(load_options)

    message(STATUS "${CX_PRETTY_PRESET} Setting up build options")

    if("${CX_PLATFORM}" STREQUAL "CX_LINUX_X86")
        debug_log("load_options: selected CX_LINUX_X86")
        load_options_linux_x86()

    elseif("${CX_PLATFORM}" STREQUAL "CX_LINUX_X64")
        debug_log("load_options: selected CX_LINUX_X64")
        load_options_linux_x64()

    elseif("${CX_PLATFORM}" STREQUAL "CX_NINJA_LINUX_X86")
        debug_log("load_options: selected CX_NINJA_LINUX_X86")
        load_options_linux_x86()

    elseif("${CX_PLATFORM}" STREQUAL "CX_NINJA_LINUX_X64")
        debug_log("load_options: selected CX_NINJA_LINUX_X64")
        load_options_linux_x64()

    else()
        message(FATAL_ERROR "Unknown CX_PLATFORM: ${CX_PLATFORM}")
    endif()
    
endfunction(load_options)


# Common entry function to call target specific external link options
function(link_externals)

    message(STATUS "${CX_PRETTY_PRESET} Linking external dependencies")

    # file functions/linux/triggers_linux.cmake:
    linker_static_library_linux_trigger()
    linker_shared_library_linux_trigger()

    # file install_linux.cmake:
    install_shared_libraries_linux_gcc()

endfunction(link_externals)