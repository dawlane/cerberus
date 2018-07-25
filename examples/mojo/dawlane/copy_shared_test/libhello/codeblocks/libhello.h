/*
 libhello.h
 A Simple shared object interface.
 */

#ifndef EXAMPLE_DLL_H
#define EXAMPLE_DLL_H

#ifdef __cplusplus
extern "C" {
#endif

// Sort out the calling convention to use
#if defined _WIN32 || defined WIN32
  /* You should define ADD_EXPORTS *only* when building the DLL. */
  #ifdef ADD_EXPORTS
    #define ADDAPI __declspec(dllexport)
  #else
    #define ADDAPI __declspec(dllimport)
  #endif

  /* Define calling convention in one place, for convenience. */
  #ifndef VSC
  #define ADDCALL __cdecl
  #else
  #define ADDCALL ADDAPI
  #endif // VSC

#else /* _WIN32 or WIN32 not defined. */

  /* Define with no value on non-Windows OS's. */
  #define ADDAPI
  #define ADDCALL

#endif // _WIN32

#ifndef VSC
ADDAPI ADDCALL char* Msg(const char *name);
ADDAPI ADDCALL void MemFree();
#else
ADDCALL char* Msg(const char *name);
ADDCALL void MemFree();
#endif // VSC

#ifdef __cplusplus
}
#endif
#endif // EXAMPLE_DLL_H
