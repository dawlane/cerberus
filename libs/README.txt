Directory description.
shared:
	This is where you should place any shared libraries that are prebuilt.
	The directories in here must be in the format OS_NAME:CPU_ARCHITECTURE; with the exception of those that support multiple platforms such as OS X and iOS.
	For example OS X would be MacOS, and Win32 (using OS_NAME:CPU_ARCHITECTURE) for Windows 32 bit builds.
	Apple devices can also have a sub-directory called Frameworks where you can place any user frameworks to be used.
	You will of course need to use the Cerberus pre-processor config commands to let the Cerberus compiler know what and where to look for additional build files, etc.
	You can use the pre-processor config directive #GFLW_COPY_SHAREDLIBS to copy a dynamic library over to the final build directory.
	As MinGW versions greater than 4.9 have issues with .lib files. MinGW now has it's own .a files for OpenAL within the templates directory.
	You can find a the installer at https://www.openal.org

static:
	This is where you should place any static link libraries or shared library export files.
	This is almost exactly like the shared directory, but sub directories are based on the compiler used due to the difference between object file ABI's.
	The format of each compilers sub directories are exactly the same as for the shared library directory.

licenses:
	This is where all licence files must go for any libraries you use.
	Use the compiler directive #COPY_LICENCES to copy over the licences.
	You should place your licence files in a single directory with a unque name, e.g. curl. They will be copied over to your final build.
