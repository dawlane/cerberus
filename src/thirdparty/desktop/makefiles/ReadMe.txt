MAKEFILES AND VISUAL STUDIO SOLUTIONS

In this directory you will find a cross platform GCC makefiles and directories for a number of Visual Studio versions.
Note: Visual Studio requires two versions of a static library: One Release and one Debug.
You must also use /bigobj in the additional options to avoid link errors.

glfwgame.gcc and glfwgame_msvcXXXX using GLFW 3.2:
These are use to create a static library for the standard GLFW Desktop target that comes with Cerberus.