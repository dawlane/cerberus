#ifndef CX_SHARED_LIBRARY_UPPER_H
#define CX_SHARED_LIBRARY_UPPER_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) || defined(__CYGWIN__)

    #if defined(CX_LIBRARY_BUILD)
        #define CX_API __declspec(dllexport)
    #else
        #define CX_API __declspec(dllimport)
    #endif

#elif defined(__GNUC__) || defined(__clang__)

    #define CX_API __attribute__((visibility("default")))

#else

    #define CX_API

#endif

    CX_API char* cx_string_transform(const char* input);
    CX_API void  cx_static_free_string(const char* string);
    //CX_API void cx_shared_library_upper_free_string(const char* string);

#ifdef __cplusplus
}
#endif

#endif // CX_SHARED_LIBRARY_UPPER_H