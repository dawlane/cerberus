As it is possible for the ABI of a library to change between different versions of Visual Studio.
Each version should be placed in the directory named under the version it was built with.
When a version becomes old, any libraries that still work with a later vserion of VS
should by moved into that versions static directory.