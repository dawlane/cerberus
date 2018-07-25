/*
 libhello.h
 A Simple shared object interface.
 */

#import <Foundation/Foundation.h>

// Export the functions. This equates to extern "C"
FOUNDATION_EXPORT char *Msg(const char *name);
FOUNDATION_EXPORT void MemFree();