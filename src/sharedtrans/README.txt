This is a work in progress.
Targets that work so far:
    Windows Desktop

The sharetrans program takes two input strings in the format "PATH;PATH;PATH" and "sharedlib;sharedlib;sharedlib"
and output string to a destination directory to copy shred dynamic libraris.
A number of additional option can be passed to control the what files are copied over based on a tool chain.
Note that the program will slow down with more search path and libraries added.

-srcdirs=
    Path to search for shared dynamic libraries e.g. "C:\MyPathToLibraies;D:\MyPathToOtherLibraies"

-libs=
    Share dynamic libraries to copy over e.g. "libcrypto-1_1;libcurl;libssl-1_1;libhello;libcrypto-1_1-x64;libssl-1_1-x64"

-toolchain=
    A method to select special operation based of a compiler tool chain.
    "mingw" : Looks in the MinGW application root directory for runtime shared dynamic libraries. These are need for MinGW-w64 normally.
    "mingw-static" : Ignores the MinGW application root directory for runtime shared dynamic libraries.
    "visualstudio" : This current is just a dummy and doesn't search any other compiler path.
    "linux" : This current is just a dummy and doesn't search any other compiler path.
    "macos" : This current is just a dummy and doesn't search any other compiler path.

-toolpath=
    The root directory for a compiler tool chain. This is optional depending on the tool chain in question.

-dst=
    The directory to transfer all shared dynamic libraries found.

-arch=
    Use this to isolate the exact architecture of the shared dynamic library for the application you are building.

    Implement a primative txt file storage for files copied over to avoid search over-head on a re-run.
