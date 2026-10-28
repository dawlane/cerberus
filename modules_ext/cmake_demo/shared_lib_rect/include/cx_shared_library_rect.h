#ifndef CX_SHARED_LIBRARY_RECT_H
#define CX_SHARED_LIBRARY_RECT_H

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

    CX_API char* draw_console_rect(int width, int height);
    CX_API void console_rect_free(char* buffer);

#ifdef __cplusplus
}
#endif

#endif // CX_SHARED_LIBRARY_RECT_H