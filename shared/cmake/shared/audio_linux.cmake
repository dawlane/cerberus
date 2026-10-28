#####################################################################
# Dependencies for Linux Audio libraries

function(dependency_default_audio)

    debug_log("function dependency_audio: Using OpenAL")

    find_package(OpenAL REQUIRED)

    cmake_language(DEFER CALL target_include_directories 
        ${CMAKE_PROJECT_NAME} PRIVATE ${OPENAL_INCLUDE_DIR}
    )

    cmake_language(DEFER CALL target_link_libraries 
        ${CMAKE_PROJECT_NAME} PRIVATE ${OPENAL_LIBRARY}
    )
    
endfunction(dependency_default_audio)

function(dependency_audio _audio_driver)

    if(${_audio_driver} STREQUAL "")
        message(STATUS "${CX_PRETTY_PRESET} Audio driver not set, falling back to the default dependency audio driver OpenAL")
    else()
        message(STATUS "${CX_PRETTY_PRESET} Selected audio driver[${_audio_driver}] to use")
    endif()

    string(TOLOWER "${_audio_driver}" _audio_driver_option)

    # Check against known audio drivers that are being used.
    if(${_audio_driver_option} STREQUAL "openal")

        dependency_default_audio()

    # TODO: Add other audio drivers. NOTE: other drivers need to be placed before the dependency_audio_winnt function,
    # or through the use of CMake's include functions at the top of this file. 
    #elseif(${driver_option} STREQUAL "other_drivers")

        # Add other audio drivers.
    #    debug_log("function dependency_audio: other_drivers")
       
    elseif(${_audio_driver_option} STREQUAL "")

        dependency_default_audio()

    else()

        message(FATAL_ERROR "${CX_PRETTY_PRESET} Unknown audio driver[${_audio_driver}]")
        
    endif()

endfunction()