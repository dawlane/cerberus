# MinGW GLFW 3 ANGLE

CC=gcc
CFLAGS=

CXX=g++
CXXFLAGS=

CPPFLAGS=$(CCOPTS) \
-Wno-free-nonheap-object \
-I../curl/include \
-I../angle/include \
-I../glfw3/include \
-I../glfw3/src \
-I../openal/include \
-I../stb \
-I../zlib-1.2.8 \
-I../lpng1610

LD=g++

# Detect the system architecture
ERROR=1

ifeq ($(ARCH),)
$(info AUTO DETECT ARCHITECTURE)
	ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
$(info 64 BIT)
		override ARCH=64
		OPENAL_DLL=$(SystemRoot)/System32/openal32.dll
		ERROR=0
	else
		ifeq ($(PROCESSOR_ARCHITECTURE),x86)
$(info 32 BIT)
			override ARCH=32
			OPENAL_DLL=$(SystemRoot)/System32/openal32.dll
			ERROR=0
		endif
	endif
else
	ifeq ($(ARCH),64)
$(info 64 BIT)
		override ARCH=64
		OPENAL_DLL=$(SystemRoot)/System32/openal32.dll
		ERROR=0
	else
		ifeq ($(ARCH),32)
$(info 32 BIT)
			override ARCH=32
			OPENAL_DLL=$(SystemRoot)/SysWOW64/openal32.dll
			ERROR=0
		else
$(error UNABLE TO DETERMINE SYSTEM ARCHITECTURE)
		endif
	endif
endif

ifeq ($(ERROR),1)
$(error UNRECOGNISED ARCHITECTURE $(ARCH))
endif

SHARE_PATH=$(APPLIBPATH)/shared/win$(ARCH)
STATIC_PATH=$(APPLIBPATH)/static/MinGW/$(ARCH)
LICENCE_PATH=$(APPLIBPATH)/licences

ifeq ($(STATIC),1)
	ifeq ($(POSIX),0)
		POSIX_MSG="POSIX_DISABLED"
		POSIX_ON=
	else
		POSIX_MSG="POSIX ENABLED"
		# This is a hack to get rount the winpthread problem.
		POSIX_ON=-Wl,-Bstatic,--whole-archive -lwinpthread -Wl,--no-whole-archive
	endif
$(info STATIC $(POSIX_MSG))
#	LDFLAGS=$(LDOPTS) -L$(SHARE_PATH) -L$(STATIC_PATH) -L../openal/libs/mingw/win$(ARCH) -Wl,--subsystem,windows
	LDFLAGS=$(LDOPTS) -L$(SHARE_PATH) -L$(STATIC_PATH) -Wl,--subsystem,windows
#	LDLIBS=-Wl,-Bstatic -static-libgcc -static-libstdc++ $(POSIX_ON) -Wl,-Bdynamic -lEGLdll -lGLESv2dll -lcomdlg32 -lgdi32 -lopengl32 -lopenal32 $(LIBOPTS) -lws2_32
	LDLIBS=-Wl,-Bstatic -static-libgcc -static-libstdc++ $(POSIX_ON) -Wl,-Bdynamic -lEGLdll -lGLESv2dll -lcomdlg32 -lgdi32 -lopengl32 $(OPENAL_DLL) $(LIBOPTS) -lws2_32
else
$(info NON STATIC)
#	LDFLAGS=$(LDOPTS) -L$(SHARE_PATH) -L$(STATIC_PATH) -L../openal/libs/mingw/win$(ARCH) -Wl,--subsystem,windows
	LDFLAGS=$(LDOPTS) -L$(SHARE_PATH) -L$(STATIC_PATH) -Wl,--subsystem,windows
#	LDLIBS=	-Wl,-Bdynamic -lEGLdll -lGLESv2dll -lcomdlg32 -lgdi32 -lopengl32 -lopenal32 $(LIBOPTS) -lws2_32
	LDLIBS=	-Wl,-Bdynamic -lEGLdll -lGLESv2dll -lcomdlg32 -lgdi32 -lopengl32 $(OPENAL_DLL) $(LIBOPTS) -lws2_32
endif

RES=windres
ifeq ($(ARCH),64)
	RES_ARCH=pe-x86-64
else
	RES_ARCH=pe-i386
endif

vpath %.c ../glfw3/src
vpath %.c ../stb
vpath %.cpp ..
vpath %.rc ..

OBJS0=\
context.o \
init.o \
input.o \
monitor.o \
egl_context.o \
win32_init.o \
win32_monitor.o \
win32_time.o \
win32_tls.o \
win32_window.o \
window.o \
winmm_joystick.o \
stb_vorbis.o \
stb_image.o \
resource.o \
main.o

TMP=build/$(dir $(OUT))

OBJS=$(patsubst %.o,$(TMP)%.o,$(OBJS0))

all : $(OUT)
	copy $(subst /,\,${SHARE_PATH}/libEGL.dll) $(subst /,\,$(dir $(OUT)))
	copy $(subst /,\,${SHARE_PATH}/libGLESv2.dll) $(subst /,\,$(dir $(OUT)))
	copy $(subst /,\,${SHARE_PATH}/d3dcompiler_47.dll) $(subst /,\,$(dir $(OUT)))
ifeq (,$(wildcard $(subst /,\,$(dir $(OUT))licenses/angle)))
	mkdir $(subst /,\,$(dir $(OUT))licenses\angle)
	copy $(subst /,\,${LICENCE_PATH}/angle) $(subst /,\,$(dir $(OUT))licenses/angle)
endif

$(OUT) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

$(TMP)%.o : %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

$(TMP)%.o : %.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c -o $@ $<

$(TMP)%.o : %.rc
	$(RES) --target $(RES_ARCH) -i $< -o $@
	
