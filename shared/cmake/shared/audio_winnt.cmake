#####################################################################
# Dependencies for Windows MinGw Audio libraries

# The default driver to use is currently OpenAL, so a dedicated function is used to save duplication.
function(dependency_default_audio_driver _lib_dir)

    set(OPENAL_DLL_DIR "${CX_LIBS_DIR}/${_lib_dir}")
    set(OPENAL_DLL_PATH "${OPENAL_DLL_DIR}/OpenAL32.dll")

    debug_log("function dependency_default_audio_driver: local variable OPENAL_DLL_DIR\n    ${OPENAL_DLL_DIR} ")
    debug_log("function dependency_default_audio_driver: local variable OPENAL_DLL_PATH\n    ${OPENAL_DLL_PATH} ")
    
    if(NOT TARGET OpenAL::Imported) 

        if(MSVC)

            debug_log("function dependency_default_audio_driver: setting import library paths")
            set(OPENAL_IMPLIB_PATH "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/lib/${_lib_dir}/OpenAL32.lib")
            debug_log("function dependency_default_audio_driver:  local variable OPENAL_IMPLIB_PATH\n    ${OPENAL_IMPLIB_PATH} ")

            add_library(OpenAL::Imported SHARED IMPORTED)

            set_target_properties(OpenAL::Imported PROPERTIES
                IMPORTED_LOCATION "${OPENAL_DLL_PATH}"
                IMPORTED_IMPLIB "${OPENAL_IMPLIB_PATH}"
                INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/include/openal"
            )

        else()

            add_library(OpenAL::Imported UNKNOWN IMPORTED)

            set_target_properties(OpenAL::Imported PROPERTIES
                IMPORTED_LOCATION "${OPENAL_DLL_PATH}"
                INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/include/openal"
            )

        endif()

    endif()

    # Automatically defers the linking of dependencies to the end of the directory 
    # evaluation, ensuring the target exists before target_link_libraries is executed.
    cmake_language(DEFER CALL target_link_libraries 
        ${CMAKE_PROJECT_NAME} PRIVATE OpenAL::Imported
    )

    # Store OpenAL asset paths inside custom target properties, then defer the 
    # installation commands to the end of the file so they resolve during the install phase.
    set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES
        CX_INTERNAL_AUDIO_DLL "${OPENAL_DLL_PATH}"
        CX_INTERNAL_AUDIO_LICENCES "${CX_LIBS_DIR}/licences/openal"
        CX_INTERNAL_AUDIO_PREFIX "${CX_INSTALL_PREFIX}"
    )

    cmake_language(DEFER CALL install
        FILES "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_AUDIO_DLL>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_AUDIO_PREFIX>"
    )

    cmake_language(DEFER CALL install
        DIRECTORY "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_AUDIO_LICENCES>"
        DESTINATION "$<TARGET_PROPERTY:${CMAKE_PROJECT_NAME},CX_INTERNAL_AUDIO_PREFIX>/licences"
    )

endfunction(dependency_default_audio_driver _lib_dir)