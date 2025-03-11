Dynamic link libraries and MinGW archive files should be placed in their architecture folders.

Static libraries
There are two folders within each of the architecture folders called msvc-static and mingw-static.
The files within these were build against gcc version 14.2.0 urcrt and Visual Studio 2019.
It's is recommended to distribute a dynamic-link libraries or compile a static library with the compiler you are using.

NOTE:
Two types of licence file can be copied.
If you need to distribute a licence then use the libraries name appended with _LICENCE.
If you need to distribute a copying licence (i.e. LGPL) then append _COPYING.
In some cases where a library has a _LICENCE and a _COPYING postfix, then both files should be distributed.