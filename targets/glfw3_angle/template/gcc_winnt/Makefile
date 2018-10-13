# GLFW ANGLE MAKEFILE WINDOWS TAREGET
$(info EXECUTING GLFW DESKTOP TEMPLATE MAKEFILE)

CC=gcc
CFLAGS=

CXX=g++
CXXFLAGS=

CPPFLAGS=$(CCOPTS) \
-Wno-free-nonheap-object \
-I../zlib-1.2.8 \
-I../lpng1610

LD=g++

# Detect the system architecture
ifeq ($(ARCH),)
# If no ARCH value passed, then make a guess
$(info AUTO DETECT ARCHITECTURE)
		# If, PROCESSOR_ARCHITEW6432 is set. Then the process bitiness is the same as the OS. e.g. 32 bit app on 32 bit OS. 
		ifeq (,$(PROCESSOR_ARCHITEW6432))
			ifeq (AMD64,$(PROCESSOR_ARCHITECTURE))
				override ARCH = 64
        		OPTS += -m64
				OPENAL_DLL=$(SystemRoot)/System32/openal32.dll
    		endif
			ifeq (x86,$(PROCESSOR_ARCHITECTURE))
        		override ARCH = 32
        	    OPTS += -m32
				OPENAL_DLL=$(SystemRoot)/System32/openal32.dll	
        	endif
		else
		# If, PROCESSOR_ARCHITEW6432 is set. Then it's a 32 bit process on a 64 bit OS. e.g. 32 bit app on a 64 bit OS.
			ifeq (x86,$(PROCESSOR_ARCHITEW6432))
        		override ARCH = 32
        	    OPTS += -m32
				OPENAL_DLL=$(SystemRoot)/SysWOW64/openal32.dll
			else
				override ARCH = 64
        	    OPTS += -m64
				OPENAL_DLL=$(SystemRoot)/System32/openal32.dll
        	endif
		endif
else
# ARCH has a value
	ifeq ($(ARCH),64)
$(info 64 BIT SYSTEM ARCHITECTURE)
		OPTS += -m64
		OPENAL_DLL=$(SystemRoot)/System32/openal32.dll
	else
		ifeq ($(ARCH),32)
$(info 32 BIT SYSTEM ARCHITECTURE)
			OPTS += -m32
			ifeq (x86,$(PROCESSOR_ARCHITECTURE))
				OPENAL_DLL=$(SystemRoot)/System32/openal32.dll
			else
			# If the PROCESSOR_ARCHITECTURE comes back as AMD64, then set the path to SysWOW64
				OPENAL_DLL=$(SystemRoot)/SysWOW64/openal32.dll
			endif
		else
$(error UNABLE TO DETERMINE SYSTEM ARCHITECTURE)
		endif
	endif
endif

ifeq (,$(ARCH))
$(error UNRECOGNISED ARCHITECTURE $(ARCH))
endif

# Check OpenAL path
ifeq (,$(wildcard $(OPENAL_DLL)))
$(error OpenAL32 not found at $(OPENAL_DLL))
endif

# Set the default library paths
SHARE_PATH=$(CERBERUSDIR)/libs/shared/win$(ARCH)
STATIC_PATH=$(CERBERUSDIR)/libs/static/MinGW/$(ARCH)
LICENCE_PATH=$(CERBERUSDIR)/libs/licences

# Depending on the STATIC and POSIX, set the additional liner options for MinGW-w64
ifeq ($(STATIC),1)
$(info STATIC BUILDING $(POSIX_MSG))
	LDFLAGS=$(LDOPTS) -L$(SHARE_PATH) -L$(STATIC_PATH) -Wl,--subsystem,windows
# STATIC BUILDING WITH DIRECT LINKING TO OPENAL DLL
	LDLIBS=-Wl,-Bstatic -static-libgcc -static-libstdc++ -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive -Wl,-Bdynamic -lglfwgame -lEGLdll -lGLESv2dll -lcomdlg32 -lgdi32 -lopengl32 $(OPENAL_DLL) $(LIBOPTS) -lws2_32
else
$(info NON STATIC)
	LDFLAGS=$(LDOPTS) -L$(SHARE_PATH) -L$(STATIC_PATH) -Wl,--subsystem,windows
# NON STATIC BUILDING WITH DIRECT LINKING TO OPENAL DLL
	LDLIBS=	-Wl,-Bdynamic -lglfwgame -lEGLdll -lGLESv2dll -lcomdlg32 -lgdi32 -lopengl32 $(OPENAL_DLL) $(LIBOPTS) -lws2_32
endif

# Set the correct architecture output for resource building.
RES=windres
ifeq ($(ARCH),64)
	RES_ARCH=pe-x86-64
else
	RES_ARCH=pe-i386
endif

# Set the primary path to where the main.cpp file is located
vpath %.cpp ..
vpath %.rc ..

# Objects to create
OBJS0=resource.o \
main.o

# The build directory for binary object creation
TMP=build/$(dir $(OUT))

# File extension substitution
OBJS=$(patsubst %.o,$(TMP)%.o,$(OBJS0))

# Compile
all : glfwobjects mainobjects $(OUT)
	copy $(subst /,\,${SHARE_PATH}/libEGL.dll) $(subst /,\,$(dir $(OUT)))
	copy $(subst /,\,${SHARE_PATH}/libGLESv2.dll) $(subst /,\,$(dir $(OUT)))
	copy $(subst /,\,${SHARE_PATH}/d3dcompiler_47.dll) $(subst /,\,$(dir $(OUT)))
ifeq (,$(wildcard $(subst /,\,$(dir $(OUT))licenses/angle)))
	mkdir $(subst /,\,$(dir $(OUT))licenses\angle)
	copy $(subst /,\,${LICENCE_PATH}/angle) $(subst /,\,$(dir $(OUT))licenses/angle)
endif

# Call the external Makefile that creates the libglfwgame.a static library.
# Note You should always pass the OS, the Ceberus root directory and any other compiler flags that are required.
# In this case only the OS, Cerberus root directory and CCOPTS options need to be passed.
.PHONY: glfwobjects
glfwobjects:
	$(info )
	$(info EXECUTING BUILDING OF GLFW GAME STATIC LIBRARY MAKEFILE)
	$(MAKE) -f $(CERBERUSDIR)/src/thirdparty/desktop/makefiles/glfwgame.gcc OS=Windows_NT CERBERUSDIR=$(CERBERUSDIR) CCOPTS="$(CCOPTS)"

.PHONY: mainobjects
mainobjects:
	$(info )
	$(info CONTINUING WITH GLFW DESKTOP TEMPLATE MAKEFILE)

$(OUT) : $(OBJS)
	$(info )
	$(info LINKING OBJECT FILES)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

$(TMP)%.o : %.c
	$(info )
	$(info COMPILING C FILES)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(TMP)%.o : %.cpp
	$(info )
	$(info COMPILING C++ FILES)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

$(TMP)%.o : %.rc
	$(info )
	$(info COMPILING RESOURCES)
	$(RES) --target $(RES_ARCH) -i $< -o $@
	
