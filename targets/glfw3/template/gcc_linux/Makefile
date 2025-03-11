# GLFW LINUX TARGET MAKE FILE

# White space substitution for new line
null :=
space := ${null} ${null}
${space} := ${space}# ${ }

# For this to work a couple of empty lines must be used in the define.
define \n


endef

# Set the compilers and basic flags
CC=$(C_COMPILER)
CFLAGS=-D_GLFW_X11

CXX=$(CXX_COMPILER)
CXXFLAGS=

# The flags required for GLFW includes, defines and basic linking.
CPPFLAGS=
ifneq (${CCOPTS},)
CPPFLAGS=$(CCOPTS)
endif

CPPFLAGS+=-Wno-int-to-pointer-cast \
-Wno-free-nonheap-object \
-Wno-unused-result \
-I../curl/include \
-I../glfw3/include \
-I../openal/include \
-I../stb \
-I../tinyfiledialogs \
-I../glfw3/deps \
-I../glfw3/deps/vulkan \
-D_GLFW_HAS_GLXGETPROCADDRESS \
-pthread

# Set the linker, imported and basic flags.
# The linker is always g++
LD=g++
LDFLAGS=
ifneq (${LDOPTS},)
LDFLAGS=$(LDOPTS)
endif

LDFLAGS+=-no-pie
LDLIBS=-lGL -lX11 -lXxf86vm -lXi -lXrandr -lXinerama -lXcursor
ifneq (${LIBOPTS},)
LDLIBS+= $(LIBOPTS)
endif
LDLIBS+=-lpthread -ldl

# Set any virtual paths
VPATH=
ifneq (${VPATHOPTS},)
VPATH=$(VPATHOPTS)
endif
VPATH+=%.c ../glfw3/src \
%.c ../stb \
%.c ../tinyfiledialogs \
%.cpp ..

# The list of source/object files to build
OBJS0= $(SRCOPTS) \
context.o \
init.o \
input.o \
monitor.o \
window.o \
glx_context.o \
x11_init.o \
x11_monitor.o \
x11_window.o \
posix_time.o \
posix_thread.o \
linux_joystick.o \
vulkan.o \
egl_context.o \
osmesa_context.o \
xkb_unicode.o \
stb_vorbis.o \
stb_image.o \
tinyfiledialogs.o \
main.o

# Set build variables	
TMP=$(BUILD_DIR)/$(dir $(OUT))

OBJS_SPLIT=$()

OBJS=$(patsubst %.o,$(TMP)%.o,$(OBJS0))

# Main build
all : $(OUT_PATH)/$(OUT)

$(OUT_PATH)/$(OUT) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

$(TMP)%.o : %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(TMP)%.o : %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

# Show the current build information.
$(info )
$(info )
$(info ------------------------------ MAKEFILE INFORMATION ------------------------------)
$(info LINUX GLFW GCC TARGET)
$(info  )

$(info C COMPILER: $(CC))
$(info C++ COMPILER: $(CXX))

$(info )
$(info PRE PROCESSOR FLAGS:)
ifneq (${CPPFLAGS},)
$(info $(subst ${ },${\n},${CPPFLAGS}))
$(info )
endif

$(info LINKER: $(LD))
ifneq (${LDFLAGS},)
$(info LINKER FLAGS:)
$(info $(subst ${ },${\n},${LDFLAGS}))
$(info )
endif

ifneq (${LDLIBS},)
$(info LINKER LIBRARY OPTS:)
$(info $(subst ${ },${\n},${LDLIBS}))
$(info )
endif

ifneq (${VPATH},)
$(info SOURCE PATH SEARCH (VPATH):)
$(info $(subst ${ },${\n},${VPATH}))
$(info )
endif

ifneq (${SRCOPTS},)
$(info ADDITIONAL SOURCES:)
$(info $(subst ${ },${\n},${SRCOPTS}))
$(info )
endif

$(info TEMP DIRECTORY: $(TMP))
$(info )

$(info OBJECT SUBSTITUTION:)
$(info $(subst ${ },${\n},${OBJS}))
$(info )

$(info OUTPUT PATH: $(OUT_PATH))
$(info OUTPUT: $(OUT))
$(info )

$(info )
