/*
    libhello.h
    A Simple shared object interface.
*/
#ifndef EXAMPLE_DYLIB_H
#define EXAMPLE_DYLIB_H

#import <Foundation/Foundation.h>

//! Project version number for helloframework.
FOUNDATION_EXPORT double helloframeworkVersionNumber;

//! Project version string for helloframework.
FOUNDATION_EXPORT const unsigned char helloframeworkVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <helloframework/PublicHeader.h>

// Export the functions. This equates to extern "C"
FOUNDATION_EXPORT char* Msg(const char *name);
FOUNDATION_EXPORT void MemFree();

#endif


