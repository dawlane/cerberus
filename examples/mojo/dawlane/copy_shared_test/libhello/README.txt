When the shared libraries are built. You should move them over to the relevant Cerberus\libs\shared directory for use with Cerberus.
But there should be nothing to stop you from using a different directory as long as you pass the path to search for them.

CODEBLOCKS

The Codeblocks project file is for use with GCC/MinGW compilers. There is a compiled libhello.dll already compiled for 32 and 64 bit Windows in the libs\shared directories.
To successfully build the DLL's using MinGW, you should use MinGW-w64 with dwarf exceptions of 32 bit and MinGW-w64 with seh exceptions.
Visual Studio created 64 bit applications can have difficulty loading the libraries created with the sjlj exceptions.
In general, you should use Visual Studio to create dynamic link libraries for Windows.

Codeblocks allows you add additional compiler tool chains and set each individual project build option to use a particular compiler.

For ease we shall use the dynamic link libraries created in the Codeblocks project as it keeps the dlls created separate.
Make sure that you have the Visual Studio Command line tools environment installed. For the 32 bit dll use the x86 native tool environment and for the 64 bit use the x64 native tool environments.

To create a MSVC compatible .lib file then take these steps.
First compile the library.

After compiling change directory into bin\Release32 (x86 native), or bin\Release64 (x64 native).
In each directory you will find three files, the library (libhello.dll), the definition file (libhello.def) and a MinGW library archive (libhello.a).

In most cases you can use the created definition file and use the lib command to create a MSVC version (.lib) of the MinGW library archive (.a), but below are the basics for any shared Windows shared library.

We need the names exported by the dll, so eneter the command:
dumpbin /exports libhello.dll

You should see something like below:

Dump of file libhello.dll

File Type: DLL

  Section contains the following exports for libhello.dll

    00000000 characteristics
    5A2004A1 time date stamp Thu Nov 30 13:16:17 2017
        0.00 version
           1 ordinal base
           2 number of functions
           2 number of names

    ordinal hint RVA      name

          1    0 00001550 MemFree@0
          2    1 000014C0 Msg@4

  Summary

        1000 .CRT
        1000 .bss
        1000 .data
        1000 .edata
        1000 .idata
        3000 .rdata
        2000 .reloc
       18000 .text
        1000 .tls

The bit of interest is:
   ordinal hint RVA      name

          1    0 00001550 MemFree@0
          2    1 000014C0 Msg@4

NOTE: That the above is a 32 bit dll exporting function using __cdecl and that the names can be a little different for the 64 bit version.
See https://msdn.microsoft.com/en-us/library/deaxefa7.aspx for name decorations.

What we need is MemFree@0 and Msg@4 that we can use to create a .def file.
Create a new file named libhellow.def and add the the three lines below, then save.

EXPORTS
MemFree@0
Msg@4

Now we can create the .lib file with:
lib /def:libhello.def /OUT:libhello.lib

There are similar command line tools for MinGW called gendef and dlltool, but they sometimes do not come as part of the installed tool chain.
Check out https://stackoverflow.com/a/36611421 for details.

XCODE
There are two Xcode projects files set up to create either a Mach-O 32/64 bin Universal Framework or a Mach-O 32/64 bit Universal dynamic shared library (dylib).
NOTE: The creation of a dynamic shared library on Intel Macs hard-codes the install directory to /usr/local/. You can change this in the XCode settings (search for
install), or use the install_tool to change the path. For Cerberus application to work, they it needs to be changed to @executable_path/../Frameworks/.
Any framework or dylib will be copied over to the application bundle in the Contents/Frameworks directory. 