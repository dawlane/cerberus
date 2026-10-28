#####################################################################
# Dependencies for macOS Audio libraries

# TODO: OpenAL is deprecate on macOS this will need updating in the future
function(dependency_default_audio_driver)

    debug_log("function dependency_default_audio: Using OpenAL for macOS bundle")

    find_package(OpenAL REQUIRED)

    # Directly link OpenAL (CMake's imported target handles includes and framework flags automatically)
    cmake_language(DEFER CALL target_link_libraries 
        ${CMAKE_PROJECT_NAME} PRIVATE OpenAL::OpenAL
    )

    # Set rpath to look inside the app bundle's Frameworks directory
    cmake_language(DEFER CALL set_target_properties 
        ${CMAKE_PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "@executable_path/../Frameworks"
    )

    # If OpenAL is built as a dynamic framework/library to be bundled with the app
    if(EXISTS "${OPENAL_LIBRARY}" AND NOT "${OPENAL_LIBRARY}" MATCHES "/System/Library/Frameworks")
        cmake_language(DEFER CALL add_custom_command 
            TARGET ${CMAKE_PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "$<TARGET_FILE_DIR:${CMAKE_PROJECT_NAME}>/../Frameworks"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${OPENAL_LIBRARY}"
                "$<TARGET_FILE_DIR:${CMAKE_PROJECT_NAME}>/../Frameworks/"
            COMMENT "Embedding OpenAL inside macOS application bundle"
        )
    endif()
    
endfunction(dependency_default_audio_driver)