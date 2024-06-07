.PHONY: all clean run

# Define required environment variables
#------------------------------------------------------------------------------------------------
# Define target platform: PLATFORM_DESKTOP, PLATFORM_RPI, PLATFORM_DRM, PLATFORM_ANDROID, PLATFORM_WEB
PLATFORM              ?= PLATFORM_DESKTOP

# Define project variables
PROJECT_NAME          ?= main
PROJECT_VERSION       ?= 1.0
PROJECT_BUILD_PATH    ?= .

RAYLIB_PATH           ?= ../../raylib

# Locations of raylib.h and libraylib.a/libraylib.so
RAYLIB_INCLUDE_PATH   ?= /usr/local/include
RAYLIB_LIB_PATH       ?= /usr/local/lib

# Library type compilation: STATIC (.a) or SHARED (.so/.dll)
RAYLIB_LIBTYPE        ?= STATIC

# Build mode for project: DEBUG or RELEASE
BUILD_MODE            ?= RELEASE

# Use Wayland display server protocol on Linux desktop
USE_WAYLAND_DISPLAY   ?= FALSE

# PLATFORM_WEB: Default properties
BUILD_WEB_ASYNCIFY    ?= FALSE
BUILD_WEB_SHELL       ?= minshell.html
BUILD_WEB_HEAP_SIZE   ?= 134217728
BUILD_WEB_RESOURCES   ?= TRUE
BUILD_WEB_RESOURCES_PATH  ?= resources

# Use cross-compiler for PLATFORM_RPI
ifeq ($(PLATFORM),PLATFORM_RPI)
    USE_RPI_CROSS_COMPILER ?= FALSE
    ifeq ($(USE_RPI_CROSS_COMPILER),TRUE)
        RPI_TOOLCHAIN ?= C:/SysGCC/Raspberry
        RPI_TOOLCHAIN_SYSROOT ?= $(RPI_TOOLCHAIN)/arm-linux-gnueabihf/sysroot
    endif
endif

# Determine PLATFORM_OS in case PLATFORM_DESKTOP selected
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(OS),Windows_NT)
        PLATFORM_OS = WINDOWS
        ifndef PLATFORM_SHELL
            PLATFORM_SHELL = cmd
        endif
    else
        UNAMEOS = $(shell uname)
        ifeq ($(UNAMEOS),Linux)
            PLATFORM_OS = LINUX
        endif
        ifeq ($(UNAMEOS),FreeBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),OpenBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),NetBSD)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),DragonFly)
            PLATFORM_OS = BSD
        endif
        ifeq ($(UNAMEOS),Darwin)
            PLATFORM_OS = OSX
        endif
        ifndef PLATFORM_SHELL
            PLATFORM_SHELL = sh
        endif
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    UNAMEOS = $(shell uname)
    ifeq ($(UNAMEOS),Linux)
        PLATFORM_OS = LINUX
    endif
    ifndef PLATFORM_SHELL
        PLATFORM_SHELL = sh
    endif
endif
ifeq ($(PLATFORM),PLATFORM_DRM)
    UNAMEOS = $(shell uname)
    ifeq ($(UNAMEOS),Linux)
        PLATFORM_OS = LINUX
    endif
    ifndef PLATFORM_SHELL
        PLATFORM_SHELL = sh
    endif
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    ifeq ($(OS),Windows_NT)
        PLATFORM_OS = WINDOWS
        ifndef PLATFORM_SHELL
            PLATFORM_SHELL = cmd
        endif
    else
        UNAMEOS = $(shell uname)
        ifeq ($(UNAMEOS),Linux)
            PLATFORM_OS = LINUX
        endif
        ifeq ($(UNAMEOS),Darwin)
            PLATFORM_OS = OSX
        endif
        ifndef PLATFORM_SHELL
            PLATFORM_SHELL = sh
        endif
    endif
endif

# Default path for raylib on Raspberry Pi
ifeq ($(PLATFORM),PLATFORM_RPI)
    RAYLIB_PATH        ?= /home/pi/raylib
endif
ifeq ($(PLATFORM),PLATFORM_DRM)
    RAYLIB_PATH        ?= /home/pi/raylib
endif

# Define raylib release directory for compiled library
RAYLIB_RELEASE_PATH 	?= $(RAYLIB_PATH)/src

ifeq ($(OS),Windows_NT)
    ifeq ($(PLATFORM),PLATFORM_WEB)
        # Emscripten required variables
        EMSDK_PATH         ?= C:/emsdk
        EMSCRIPTEN_PATH    ?= $(EMSDK_PATH)/upstream/emscripten
        CLANG_PATH          = $(EMSDK_PATH)/upstream/bin
        PYTHON_PATH         = $(EMSDK_PATH)/python/3.9.2-nuget_64bit
        NODE_PATH           = $(EMSDK_PATH)/node/14.15.5_64bit/bin
        export PATH         = $(EMSDK_PATH);$(EMSCRIPTEN_PATH);$(CLANG_PATH);$(NODE_PATH);$(PYTHON_PATH):$$(PATH)
    endif
endif

# Define default C compiler: CC
#------------------------------------------------------------------------------------------------
CC = gcc

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),OSX)
        # OSX default compiler
        CC = clang
    endif
    ifeq ($(PLATFORM_OS),BSD)
        # FreeBSD, OpenBSD, NetBSD, DragonFly default compiler
        CC = clang
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    ifeq ($(USE_RPI_CROSS_COMPILER),TRUE)
        # Define RPI cross-compiler
        #CC = armv6j-hardfloat-linux-gnueabi-gcc
        CC = $(RPI_TOOLCHAIN)/bin/arm-linux-gnueabihf-gcc
    endif
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    # HTML5 emscripten compiler
    # WARNING: To compile to HTML5, code must be redesigned
    # to use emscripten.h and emscripten_set_main_loop()
    CC = emcc
endif

# Define default make program: MAKE
#------------------------------------------------------------------------------------------------
MAKE ?= make

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),WINDOWS)
        MAKE = mingw32-make
    endif
endif
ifeq ($(PLATFORM),PLATFORM_ANDROID)
    MAKE = mingw32-make
endif

# Define compiler flags: CFLAGS
#------------------------------------------------------------------------------------------------
CFLAGS = -std=c99 -Wall -Wno-missing-braces -Wunused-result -D_DEFAULT_SOURCE -MMD -MP

ifeq ($(BUILD_MODE),DEBUG)
    CFLAGS += -g -D_DEBUG
else
    ifeq ($(PLATFORM),PLATFORM_WEB)
        ifeq ($(BUILD_WEB_ASYNCIFY),TRUE)
            CFLAGS += -O3
        else
            CFLAGS += -Os
        endif
    else
        CFLAGS += -s -O2
    endif
endif

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),LINUX)
        ifeq ($(RAYLIB_LIBTYPE),STATIC)
            CFLAGS += -D_DEFAULT_SOURCE
        endif
        ifeq ($(RAYLIB_LIBTYPE),SHARED)
            CFLAGS += -Wl,-rpath,$(RAYLIB_RELEASE_PATH)
        endif
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    CFLAGS += -std=gnu99
endif
ifeq ($(PLATFORM),PLATFORM_DRM)
    CFLAGS += -std=gnu99 -DEGL_NO_X11
endif

# Define include paths for required headers: INCLUDE_PATHS
#------------------------------------------------------------------------------------------------
INCLUDE_PATHS = -I. -I$(RAYLIB_PATH)/src -I$(RAYLIB_PATH)/src/external -I$(RAYLIB_PATH)/src/extras

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),BSD)
        INCLUDE_PATHS += -I$(RAYLIB_INCLUDE_PATH)
    endif
    ifeq ($(PLATFORM_OS),LINUX)
        INCLUDE_PATHS += -I$(RAYLIB_INCLUDE_PATH)
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    INCLUDE_PATHS += -I$(RPI_TOOLCHAIN_SYSROOT)/opt/vc/include
    INCLUDE_PATHS += -I$(RPI_TOOLCHAIN_SYSROOT)/opt/vc/include/interface/vmcs_host/linux
    INCLUDE_PATHS += -I$(RPI_TOOLCHAIN_SYSROOT)/opt/vc/include/interface/vcos/pthreads
endif
ifeq ($(PLATFORM),PLATFORM_DRM)
    INCLUDE_PATHS += -I/usr/include/libdrm
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    INCLUDE_PATHS += -I$(EMSCRIPTEN_PATH)/cache/sysroot/include
endif

# Define library paths containing required libs: LDFLAGS
#------------------------------------------------------------------------------------------------
LDFLAGS = -L. -L$(RAYLIB_RELEASE_PATH) -L$(RAYLIB_PATH)/src

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),WINDOWS)
        LDFLAGS += $(RAYLIB_PATH)/src/raylib.rc.data
        ifeq ($(BUILD_MODE), RELEASE)
            LDFLAGS += -Wl,--subsystem,windows
        endif
    endif
    ifeq ($(PLATFORM_OS),LINUX)
        LDFLAGS += -L$(RAYLIB_LIB_PATH)
    endif
    ifeq ($(PLATFORM_OS),BSD)
        LDFLAGS += -Lsrc -L$(RAYLIB_LIB_PATH)
    endif
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    LDFLAGS += -s USE_GLFW=3 -s TOTAL_MEMORY=$(BUILD_WEB_HEAP_SIZE) -s FORCE_FILESYSTEM=1
    
    ifeq ($(BUILD_WEB_ASYNCIFY),TRUE)
        LDFLAGS += -s ASYNCIFY
    endif
    
    ifeq ($(BUILD_WEB_RESOURCES),TRUE)
        LDFLAGS += --preload-file $(BUILD_WEB_RESOURCES_PATH)
    endif
    
    ifeq ($(BUILD_MODE),DEBUG)
        LDFLAGS += -s ASSERTIONS=1 --profiling
    endif

    LDFLAGS += --shell-file $(BUILD_WEB_SHELL)
    EXT = .html
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    LDFLAGS += -L$(RPI_TOOLCHAIN_SYSROOT)/opt/vc/lib
endif

# Define libraries required on linking: LDLIBS
#------------------------------------------------------------------------------------------------
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),WINDOWS)
        LDLIBS = -lraylib -lopengl32 -lgdi32 -lwinmm
        LDLIBS += -static -lpthread
    endif
    ifeq ($(PLATFORM_OS),LINUX)
        LDLIBS = -lraylib -lGL -lm -lpthread -ldl -lrt
        LDLIBS += -lX11
        ifeq ($(USE_WAYLAND_DISPLAY),TRUE)
            LDLIBS += -lwayland-client -lwayland-cursor -lwayland-egl -lxkbcommon
        endif
        ifeq ($(RAYLIB_LIBTYPE),SHARED)
            LDLIBS += -lc
        endif
    endif
    ifeq ($(PLATFORM_OS),OSX)
        LDLIBS = -lraylib -framework OpenGL -framework Cocoa -framework IOKit -framework CoreAudio -framework CoreVideo
    endif
    ifeq ($(PLATFORM_OS),BSD)
        LDLIBS = -lraylib -lGL -lpthread -lm
        LDLIBS += -lX11 -lXrandr -lXinerama -lXi -lXxf86vm -lXcursor
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
    LDLIBS = -lraylib -lbrcmGLESv2 -lbrcmEGL -lpthread -lrt -lm -lbcm_host -ldl
    ifeq ($(USE_RPI_CROSS_COMPILER),TRUE)
        LDLIBS += -lvchiq_arm -lvcos
    endif
endif
ifeq ($(PLATFORM),PLATFORM_DRM)
    LDLIBS = -lraylib -lGLESv2 -lEGL -lpthread -lrt -lm -lgbm -ldrm -ldl
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    LDLIBS = $(RAYLIB_RELEASE_PATH)/libraylib.a
endif

# Define source and include directories
SRC_DIR ?= src
OBJDIR = obj
BINDIR = bin
DEPDIR = deps

# Automatically detect and list all .c files in SRC_DIR
PROJECT_SOURCE_FILES := $(wildcard $(SRC_DIR)/*.c)

# Define all object files from source files
OBJS = $(patsubst $(SRC_DIR)/%.c, $(OBJDIR)/%.o, $(PROJECT_SOURCE_FILES))

# Dependency files
DEPS = $(patsubst $(SRC_DIR)/%.c, $(DEPDIR)/%.d, $(PROJECT_SOURCE_FILES))

TARGET = $(BINDIR)/$(PROJECT_NAME)

# Default target entry
all: $(TARGET)

# Project target defined by PROJECT_NAME
$(TARGET): $(OBJS)
ifeq ($(OS),Windows_NT)
	@if not exist $(BINDIR) mkdir $(BINDIR)
else
	@mkdir -p $(BINDIR)
endif
	$(CC) -o $(TARGET)$(EXT) $(OBJS) $(CFLAGS) $(INCLUDE_PATHS) $(LDFLAGS) $(LDLIBS) -D$(PLATFORM)

# Compile source files
$(OBJDIR)/%.o: $(SRC_DIR)/%.c | $(OBJDIR) $(DEPDIR)
ifeq ($(OS),Windows_NT)
	@if not exist $(OBJDIR) mkdir $(OBJDIR)
else
	@mkdir -p $(OBJDIR)
endif
	@echo "Compiling $< to $@..."
	$(CC) -c $< -o $@ $(CFLAGS) $(INCLUDE_PATHS) -D$(PLATFORM) -MF $(DEPDIR)/$*.d

# Create the dependency files directory
$(DEPDIR):
ifeq ($(OS),Windows_NT)
	@if not exist $(DEPDIR) mkdir $(DEPDIR)
else
	@mkdir -p $(DEPDIR)
endif

-include $(DEPS)

# Debugging information
$(info SRC_DIR: $(SRC_DIR))
$(info OBJDIR: $(OBJDIR))
$(info BINDIR: $(BINDIR))
$(info DEPDIR: $(DEPDIR))
$(info PROJECT_SOURCE_FILES: $(PROJECT_SOURCE_FILES))
$(info OBJS: $(OBJS))
$(info DEPS: $(DEPS))

run:
	$(MAKE) $(MAKEFILE_PARAMS)

ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),WINDOWS)
		$(PROJECT_NAME)
    endif
    ifeq ($(PLATFORM_OS),LINUX)
		./$(PROJECT_NAME)
    endif
    ifeq ($(PLATFORM_OS),OSX)
		./$(PROJECT_NAME)
    endif
endif

.PHONY: clean_shell_cmd clean_shell_sh

# Clean everything
clean:	clean_shell_$(PLATFORM_SHELL)
	@echo Cleaning done

clean_shell_sh:
ifeq ($(PLATFORM),PLATFORM_DESKTOP)
    ifeq ($(PLATFORM_OS),LINUX)
		find . -type f -executable -delete
		rm -fv *.o *.d
    endif
    ifeq ($(PLATFORM_OS),OSX)
		find . -type f -perm +ugo+x -delete
		rm -f *.o *.d
    endif
endif
ifeq ($(PLATFORM),PLATFORM_RPI)
	find . -type f -executable -delete
	rm -fv *.o *.d
endif
ifeq ($(PLATFORM),PLATFORM_DRM)
	find . -type f -executable -delete
	rm -fv *.o *.d
endif
ifeq ($(PLATFORM),PLATFORM_WEB)
    ifeq ($(PLATFORM_OS),LINUX)
		rm -fv *.o *.d $(PROJECT_NAME).data $(PROJECT_NAME).html $(PROJECT_NAME).js $(PROJECT_NAME).wasm
    endif
    ifeq ($(PLATFORM_OS),OSX)
		rm -f *.o *.d $(PROJECT_NAME).data $(PROJECT_NAME).html $(PROJECT_NAME).js $(PROJECT_NAME).wasm
    endif
endif

clean_shell_cmd: SHELL=cmd
clean_shell_cmd:
	del /f /q *.o *.d *.exe $(PROJECT_NAME).data $(PROJECT_NAME).html $(PROJECT_NAME).js $(PROJECT_NAME).wasm
