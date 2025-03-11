# GLFW MINGW TARGET MAKE FILE

# White space substitution for new line
null :=
space := ${null} ${null}
${space} := ${space}# ${ }

# For this to work a couple of empty lines must be used in the define.
define \n


endef

CC=gcc
CFLAGS=-D_GLFW_WIN32

CXX=g++
CXXFLAGS=

# The flags required for GLFW includes and defines.
CPPFLAGS=
ifneq (${CCOPTS},)
CPPFLAGS=$(CCOPTS)
endif

CPPFLAGS+=-Wno-free-nonheap-object \
-I../curl/include \
-I../glfw3/include \
-I../glfw3/src \
-I../openal/include \
-I../stb \
-I../tinyfiledialogs \
-I../zlib-1.2.8 \
-I../lpng1610

# Set the linker, imported and basic flags.
LD=g++
LDFLAGS=
ifneq (${LDOPTS},)
LDFLAGS=$(LDOPTS)
endif

ifneq (${SHAREDPATH},)
LDFLAGS+=-L$(SHAREDPATH)
endif

LDFLAGS+=-Wl,--subsystem,windows

# NOTE: The common practice for MinGW is to distribute the required libgcc, libstdc++ and libwinpthread as dynamic link libraries.
LDLIBS=
ifeq ($(MINGW_STATIC),1)
	LDLIBS=-Wl,-Bstatic -static-libgcc -static-libstdc++ -Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive -Wl,-Bdynamic
endif

LDLIBS+=-lcomdlg32 -lgdi32 -lopengl32

ifneq (${LIBOPTS},)
LDLIBS+=$(LIBOPTS)
endif 
LDLIBS+=-lws2_32 -lole32

RES=windres
ifeq ($(ARCH),64)
    RES_ARCH=pe-x86-64
else
    RES_ARCH=pe-i386
endif

# Set any virtual paths
VPATH=
ifneq (${VPATHOPTS},)
VPATH=$(VPATHOPTS)
endif
VPATH+=%.c ../glfw3/src \
%.c ../stb \
%.c ../tinyfiledialogs \
%.cpp .. \
%.rc ..

OBJS0= $(SRCOPTS) \
context.o \
egl_context.o \
init.o \
input.o \
monitor.o \
osmesa_context.o \
vulkan.o \
wgl_context.o \
win32_init.o \
win32_joystick.o \
win32_monitor.o \
win32_time.o \
win32_thread.o \
win32_window.o \
window.o \
stb_vorbis.o \
stb_image.o \
resource.o \
tinyfiledialogs.o \
main.o

TMP=$(BUILD_DIR)/$(dir $(OUT))

OBJS=$(patsubst %.o,$(TMP)%.o,$(OBJS0))
all : $(OUT_PATH)/$(OUT)

$(OUT_PATH)/$(OUT) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

$(TMP)%.o : %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(TMP)%.o : %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<
	
$(TMP)%.o : %.rc
	$(RES) -O COFF --target $(RES_ARCH) -i $< -o $@

$(info )
$(info )
$(info ------------------------------ MAKEFILE INFORMATION ------------------------------)
$(info WINDOWS GLFW MINGW TARGET)
$(info )

$(info C COMPILER: $(CC))
$(info C++ COMPILER: $(CXX))

$(info )
$(info PRE PROCESSOR FLAGS (CPPFLAGS):)
ifneq (${CPPFLAGS},)
$(info $(subst ${ },${\n},${CPPFLAGS}))
$(info )
endif

$(info LINKER: $(LD))
ifneq (${LDFLAGS},)
$(info LINKER FLAGS (LDFLAGS):)
$(info $(subst ${ },${\n},${LDFLAGS}))
$(info )
endif

ifneq (${LDLIBS},)
$(info LINKER LIBRARY OPTS (LDLIBS):)
$(info $(subst ${ },${\n},${LDLIBS}))
$(info )
endif

ifneq (${VPATH},)
$(info SOURCE PATH SEARCH (VPATH):)
$(info $(subst ${ },${\n},${VPATH}))
$(info )
endif

ifneq (${SRCOPTS},)
$(info ADDITIONAL SOURCES (SRCOPTS):)
$(info $(subst ${ },${\n},${SRCOPTS}))
$(info )
endif

$(info TEMP DIRECTORY: $(TMP))
$(info )

$(info OBJECT SUBSTITUTION (OBJS):)
$(info $(subst ${ },${\n},${OBJS}))
$(info )

$(info OUTPUT PATH: $(OUT_PATH))
$(info OUTPUT: $(OUT))
$(info )

ifneq ($(MINGW_STATIC),)
$(info NOTE: MINGW_STATIC SET)
$(info 		 Setting MINGW_STATIC links in libgcc, libstdc++ and winpthead. Remeber to distribute any licences required.)
$(info )
endif