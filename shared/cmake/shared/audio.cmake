if(WIN32)
    debug_log("audio.cmake: importing winnt supported audio driver functions")
    include(audio_winnt)
elseif(UNIX AND NOT APPLE)
    debug_log("audio.cmake: importing linux supported audio driver functions")
    include(audio_linux)
elseif(APPLE)
    debug_log("audio.cmake: importing macos supported audio driver functions")
    include(audio_macos)
else()
    message(FATAL_ERROR "audio.cmake: Unknown host OS")
endif()


# Main function for selecting the audio driver.
# dependency_default_audio_driver only excepts one or two arguments depending on the host
# in the future it could be expanded to except multiple arguments
function(dependency_audio)

    # TODO: For later implementation when the audio is untied from the desktop target.
    # if(NOT DEFINED CX_TRIGGER_AUDIO_DRIVER)
    #     debug_log("function dependency_audio_winnt: audio driver disabled")
    #     return()
    # endif()

    # Get the audio driver name
    if(ARGC GREATER_EQUAL 1)
        set(_audio_driver "${ARGV0}")
    endif()

    # Get the directory
    if(ARGC GREATER_EQUAL 2)
        set(_lib_dir "${ARGV1}")
    endif()

    if("${_audio_driver}" STREQUAL "")
        message(STATUS "${CX_PRETTY_PRESET} Audio driver not set, falling back to the default dependency audio driver[OpenAL].")
    else()
        message(STATUS "${CX_PRETTY_PRESET} Selected audio driver[${_audio_driver}] to use")
    endif()

    debug_log("function dependency_audio_winnt: parameters")
    message(DEBUG "    Audio Driver: ${_audio_driver}")
    message(DEBUG "    Library Dir: ${_lib_dir}")
    message(DEBUG "    CX Lib Dir: ${CX_LIBS_DIR}")
    message(DEBUG "    Install Dir: ${CX_INSTALL_PREFIX}")

    string(TOLOWER "${_audio_driver}" driver_option)

    if("${driver_option}" STREQUAL "openal")

        debug_log("function dependency_audio: Using OpenAL")
        dependency_default_audio_driver(${_lib_dir})
    
    # TODO: Add other audio drivers. NOTE: other drivers need to be placed before the dependency_audio_winnt function,
    # or through the use of CMake's include functions at the top of this file. 
    #elseif("${driver_option} STREQUAL "other_drivers")
    #    debug_log("function dependency_audio: other_drivers")
       
    elseif("${driver_option}" STREQUAL "")

        message(STATUS "${CX_PRETTY_PRESET} Audio driver not set, falling back to the default dependency audio driver[OpenAL].")
        dependency_default_audio_driver(${_lib_dir})

    else()

        message(FATAL_ERROR "${CX_PRETTY_PRESET} Unknown audio driver[${_audio_driver}]")
        
    endif()

endfunction()