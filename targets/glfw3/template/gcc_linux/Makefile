# GLFW MAKEFILE LINUX TAREGET
$(info EXECUTING GLFW DESKTOP TEMPLATE MAKEFILE)

CC=gcc
CFLAGS=

CXX=g++
CXXFLAGS=

# Set Compiler flag options
CPPFLAGS=$(CCOPTS) \
-Wno-int-to-pointer-cast \
-Wno-free-nonheap-object \
-Wno-unused-result \
-D_GLFW_HAS_GLXGETPROCADDRESS \
-pthread

LD=g++

# Set the default library paths
SHAREPATH=$(CERBERUSDIR)/libs/shared/Linux$(ARCH)
STATICPATH=$(CERBERUSDIR)/libs/static/Linux/$(ARCH)

# Pass the liner options
LDFLAGS=$(LDOPTS) -L$(STATICPATH) -L$(SHAREPATH) '-Wl,-rpath,$$ORIGIN/libs'
LDLIBS=-lglfwgame -lGL -lX11 -lXxf86vm -lXi -lXrandr -lXinerama -lXcursor $(LIBOPTS) -lpthread -ldl

# Set the primary path to where the main.cpp file is located
vpath %.cpp ..
OBJS0=main.o

# The build directory for binary object creation
TMP=build/$(dir $(OUT))

# File extension substitution
OBJS=$(patsubst %.o,$(TMP)%.o,$(OBJS0))

# Compile
all : glfwobjects mainobjects $(OUT)

# Call the external Makefile that creates the libglfwgame.a static library.
# Note You should always pass the OS, the Ceberus root directory and any other compiler flags that are required.
# In this case only the OS, Cerberus root directory and CCOPTS options need to be passed.
.PHONY: glfwobjects
glfwobjects:
	$(info )
	$(info EXECUTING BUILDING OF GLFW GAME STATIC LIBRARY MAKEFILE)
	$(MAKE) -f $(CERBERUSDIR)/src/thirdparty/desktop/makefiles/glfwgame.gcc OS=Linux CERBERUSDIR=$(CERBERUSDIR) CCOPTS="$(CCOPTS)"

.PHONY: mainobjects
mainobjects:
	$(info )
	$(info CONTINUING WITH GLFW DESKTOP TEMPLATE MAKEFILE)

# Compile the source code files
$(OUT): $(OBJS)
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
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<


