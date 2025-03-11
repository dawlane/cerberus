# STANDARD C++ TOOL WINNT MINGW TARGET MAKE FILE

# White space substitution for new line
null :=
space := ${null} ${null}
${space} := ${space}# ${ }

# For this to work a couple of empty lines must be used in the define.
define \n


endef

# Set the compilers and basic flags
# The compilers are alwyas gcc and g++
CC=gcc
CFLAGS=

CXX=g++
CXXFLAGS=

# The flags required for standard c++ tool includes, defines and basic linking.
# Only add CCOPTS to CPPFLAGS if it's not empty
CPPFLAGS=
ifneq (${CCOPTS},)
CPPFLAGS=$(CCOPTS)
endif
CPPFLAGS+=-fpic

# Set the linker, imported and basic flags.
# The linker is always g++
LD=g++

# Linker options
# Only add LDOPTS to LDFLAGS if it's not empty
LDFLAGS=
ifneq (${LDOPTS},)
LDFLAGS=$(LDOPTS)
endif
LDFLAGS+=-fpic

# Linker library options
# Only add LIBOPTS to LDLIBS if it's not empty
LDLIBS=
ifneq (${LIBOPTS},)
LDLIBS=$(LIBOPTS)
endif
LDLIBS+=-lwinmm -lws2_32

# Virtual path options
# Only add VPATHOPTS to VPATH if it's not empty
VPATH=
ifneq (${VPATHOPTS},)
VPATH= $(VPATHOPTS)
endif
VPATH+= %.cpp ..

# The list of source/object files to build
OBJS0= $(SRCOPTS) \
main.o

# Set build variables
TMP=$(BUILD_DIR)/$(dir $(OUT))

OBJS=$(patsubst %.o,$(TMP)%.o,$(OBJS0))

# Main build
all : $(OUT_PATH)/$(OUT)

$(OUT_PATH)/$(OUT) : $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

$(TMP)%.o : %.cpp
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
	
# Show the current build information.
$(info )
$(info )
$(info ------------------------------ MAKEFILE INFORMATION ------------------------------)
$(info WINDOWS C++ Tool MINGW TARGET)
$(info )

$(info C COMPILER: $(CC))
$(info C++ COMPILER: $(CXX))

ifneq (${CPPFLAGS},)
$(info PRE PROCESSOR (CPPFLAGS) FLAGS:)
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

$(info SOURCE PATH SEARCH (VPATH):)
$(info $(subst ${ },${\n},${VPATH}))
$(info )

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
$(info OUTPUT FILE NAME: $(OUT))
$(info )

$(info )