#############################################################################
# Include "Makefile.x" to edit below & keep Makefile as a template:
#############################################################################

-include Makefile.000

#----------------------------------------------------------

CLIENT_PATH_NAME         = client
SERVER_PATH_NAME         = server

CLIENT_BPATH_NAME        = client
SERVER_BPATH_NAME        = ded
REND1_BPATH_NAME         = rend1
REND2_BPATH_NAME         = rend2
RENDV_BPATH_NAME         = rendv

CLIENT_NAME             = quake3e
SERVER_NAME             = $(CLIENT_NAME)_$(SERVER_BPATH_NAME)

APP_TYPE                = games

#----------------------------------------------------------

ifndef APP_PATH
APP_PATH=/usr/local/$(APP_TYPE)/$(CLIENT_NAME)
endif

ifndef CODE_PATH
CODE_PATH=code
endif

ifndef BUILD_PATH
BUILD_PATH=build
endif

#----------------------------------------------------------

BUILD_DEBUG=$(BUILD_PATH)/debug-$(PLATFORM)-$(CPU)
BUILD_RELEASE=$(BUILD_PATH)/release-$(PLATFORM)-$(CPU)

ASM_PATH=$(CODE_PATH)/asm
CLIENT_PATH=$(CODE_PATH)/client
SERVER_PATH=$(CODE_PATH)/server
SDL_PATH=$(CODE_PATH)/sdl

COMMON_PATH=$(CODE_PATH)/qcommon
UNIX_PATH=$(CODE_PATH)/unix
WIN32_PATH=$(CODE_PATH)/win32
BOTLIB_PATH=$(CODE_PATH)/botlib
UI_PATH=$(CODE_PATH)/ui
JPG_PATH=$(CODE_PATH)/libjpeg

RENDERER_COMMON_PATH=$(CODE_PATH)/renderercommon
RENDERER1_PATH=$(CODE_PATH)/renderer
RENDERER2_PATH=$(CODE_PATH)/renderer2
RENDERERV_PATH=$(CODE_PATH)/renderervk

#----------------------------------------------------------

CLIENT_BPATH=$(B)/$(CLIENT_BPATH_NAME)
SERVER_BPATH=$(B)/$(SERVER_BPATH_NAME)
BOTLIB_BPATH=$(B)/botlib

REND1_BPATH=$(B)/$(REND1_BPATH_NAME)
REND2_BPATH=$(B)/$(REND2_BPATH_NAME)
RENDV_BPATH=$(B)/$(RENDV_BPATH_NAME)

BIN_PATH=$(shell which $(1) 2> /dev/null)
VERSION=$(shell grep "\#define APP_VERSION" $(COMMON_PATH)/q_shared.h | \
  sed -e 's/.*".* \([^ ]*\)"/\1/')

#==========================================================
# ON or OFF (1 or 0):
#==========================================================

CLIENT_ON               = 1
SERVER_ON               = 0

OPENGL1_ON              = 1
OPENGL2_ON              = 1

VULKAN_ON_Make          = 1
VULKAN_API_ON_Make      = 1
 
RENDERER_DLLS_ON_Make   = 1

SDL_ON_Make             = 1
CURL_ON_Make            = 1

HEADERS_ON_Make         = 0
APP_JPG_ON_Make         = 0
 
#----------------------------------------------------------

# Default main Renderer(opengl, opengl2, or vulkan):
RENDERER_MAIN_Make = vulkan

RENDERER_PREFIX_Make  = $(CLIENT_NAME)

#----------------------------------------------------------

ifndef HEADERS_ON_Make
HEADERS_ON_Make=1
endif

ifndef CURL_ON_Make
CURL_ON_Make=1
endif

ifndef CURL_DLL_ON_Make
  ifdef MINGW
    CURL_DLL_ON_Make=0
  else
    CURL_DLL_ON_Make=1
  endif
endif

ifndef DEPENDENCIES_ON
DEPENDENCIES_ON=1
endif

ifndef CCACHE_ON
CCACHE_ON=0
endif
export CCACHE_ON

#----------------------------------------------------------

ifeq ($(RENDERER_DLLS_ON_Make),0)
  ifeq ($(RENDERER_MAIN_Make),opengl)
    OPENGL1_ON=1
    OPENGL2_ON=0
    VULKAN_ON_Make=0
    VULKAN_API_ON_Make=0
  endif
  ifeq ($(RENDERER_MAIN_Make),opengl2)
    OPENGL1_ON=0
    OPENGL2_ON=1
    VULKAN_ON_Make=0
    VULKAN_API_ON_Make=0
  endif
  ifeq ($(RENDERER_MAIN_Make),vulkan)
    OPENGL1_ON=0
    OPENGL2_ON=0
    VULKAN_ON_Make=1
  endif
endif

ifneq ($(VULKAN_ON_Make),0)
  VULKAN_API_ON_Make=1
endif

#==========================================================
# CPU & Platform:
#==========================================================

SET_CPU = $(shell uname -m | sed -e 's/i.86/x86/' | sed -e 's/^arm.*/arm/')

ifeq ($(shell uname -m),arm64)
  SET_CPU   = aarch64
endif

ifeq ($(SET_CPU),i86pc)
  SET_CPU=x86
endif

ifeq ($(SET_CPU),amd64)
  SET_CPU=x86_64
endif
ifeq ($(SET_CPU),x64)
  SET_CPU=x86_64
endif

#----------------------------------------------------------

SET_PLATFORM = $(shell uname | sed -e 's/_.*//' | tr '[:upper:]' '[:lower:]' | sed -e 's/\//_/g')

ifeq ($(SET_PLATFORM),mingw32)
  ifeq ($(SET_CPU),i386)
    SET_CPU = x86
  endif
endif

ifeq ($(SET_PLATFORM),darwin)
  SDL_ON_Make=1
endif

ifeq ($(SET_PLATFORM),cygwin)
  PLATFORM=mingw32
endif

#----------------------------------------------------------

ifndef PLATFORM
PLATFORM=$(SET_PLATFORM)
endif
export PLATFORM

ifeq ($(PLATFORM),mingw32)
  MINGW=1
endif
ifeq ($(PLATFORM),mingw64)
  MINGW=1
endif

#----------------------------------------------------------

ifndef CPU
CPU=$(SET_CPU)
endif
export CPU

#----------------------------------------------------------

ifneq ($(PLATFORM),$(SET_PLATFORM))
  CROSS_COMPILE=1
else
  CROSS_COMPILE=0

  ifneq ($(CPU),$(SET_CPU))
    CROSS_COMPILE=1
  endif
endif
export CROSS_COMPILE

#==========================================================

STRIP ?= strip
PKG_CONFIG ?= pkg-config
INSTALL=install
MKDIR=mkdir

#----------------------------------------------------------

ifneq ($(call BIN_PATH, $(PKG_CONFIG)),)
  SDL_CODE_HEADERS ?= $(shell $(PKG_CONFIG) --silence-errors --cflags-only-I sdl2)
  SDL_LIBS ?= $(shell $(PKG_CONFIG) --silence-errors --libs sdl2)
  X11_CODE_HEADERS ?= $(shell $(PKG_CONFIG) --silence-errors --cflags-only-I x11)
  X11_LIBS ?= $(shell $(PKG_CONFIG) --silence-errors --libs x11)
endif

# SDL/X11 Defaults:
ifeq ($(X11_CODE_HEADERS),)
  X11_CODE_HEADERS = -I/usr/X11R6/include
endif
ifeq ($(X11_LIBS),)
  X11_LIBS = -lX11
endif
ifeq ($(SDL_LIBS),)
  SDL_LIBS = -lSDL2
endif

#----------------------------------------------------------

# Common VM:
ifeq ($(CPU),x86_64)
  VM_ON = true
else
ifeq ($(CPU),x86)
  VM_ON = true
else
  VM_ON = false
endif
endif

ifeq ($(CPU),arm)
  VM_ON = true
endif
ifeq ($(CPU),aarch64)
  VM_ON = true
endif

#==========================================================

BASE_CFLAGS =

ifeq ($(APP_JPG_ON_Make),1)
  BASE_CFLAGS += -DAPP_JPG_ON_Make
endif

ifneq ($(VM_ON),true)
  BASE_CFLAGS += -DVM_OFF_CFlags
endif

ifneq ($(RENDERER_DLLS_ON_Make),0)
  BASE_CFLAGS += -DRENDERER_DLLS_ON_Make
  BASE_CFLAGS += -DRENDERER_PREFIX_Make=\\\"$(RENDERER_PREFIX_Make)\\\"
  BASE_CFLAGS += -DRENDERER_MAIN_Make="$(RENDERER_MAIN_Make)"
endif

ifdef MAIN_PATH
  BASE_CFLAGS += -DMAIN_PATH=\\\"$(MAIN_PATH)\\\"
endif

ifeq ($(HEADERS_ON_Make),1)
  BASE_CFLAGS += -DHEADERS_ON_Make=1
endif

ifeq ($(CURL_ON_Make),1)
  BASE_CFLAGS += -DCURL_ON_Make
  ifeq ($(CURL_DLL_ON_Make),1)
    BASE_CFLAGS += -DCURL_DLL_ON_Make
  else
    ifeq ($(MINGW),1)
      BASE_CFLAGS += -DCURL_EXE
    endif
  endif
endif

ifeq ($(VULKAN_API_ON_Make),1)
  BASE_CFLAGS += -DVULKAN_API_ON_Make
endif

ifeq ($(DEPENDENCIES_ON),1)
  BASE_CFLAGS += -MMD
endif

#==========================================================

ifeq ($(V),1)
echo_cmd=@:
Q=
else
echo_cmd=@echo
Q=@
endif

#----------------------------------------------------------

CPU_EXT=

CLIENT_EXTRA_FILES=

#############################################################################
# BUILD MINGW32 (Windows):
#############################################################################

ifdef MINGW

  ifeq ($(CROSS_COMPILE),1)
    # If CC is already set to something generic, we probably want to use
    # something more specific
    ifneq ($(findstring $(strip $(CC)),cc gcc),)
      CC=
    endif

    # We need to figure out the correct gcc & windres
    ifeq ($(CPU),x86_64)
      MINGW_PREFIXES=x86_64-w64-mingw32 amd64-mingw32msvc
      STRIP=x86_64-w64-mingw32-strip
    endif
    ifeq ($(CPU),x86)
      MINGW_PREFIXES=i686-w64-mingw32 i586-mingw32msvc i686-pc-mingw32
    endif

    ifndef CC
      CC=$(firstword $(strip $(foreach MINGW_PREFIX, $(MINGW_PREFIXES), \
         $(call BIN_PATH, $(MINGW_PREFIX)-gcc))))
    endif

    #STRIP=$(MINGW_PREFIX)-strip -g

    ifndef WINDRES
      WINDRES=$(firstword $(strip $(foreach MINGW_PREFIX, $(MINGW_PREFIXES), \
         $(call BIN_PATH, $(MINGW_PREFIX)-windres))))
    endif
  else
    #If MinGW doesn't use CC (not cc) use gcc:
    ifeq ($(call BIN_PATH, $(CC)),)
      CC=gcc
    endif

  endif

#----------------------------------------------------------

  # Use generic Windres if unfound:
  ifeq ($(WINDRES),)
    WINDRES=windres
  endif

  ifeq ($(CC),)
    $(error Cannot find a suitable cross compiler for $(PLATFORM))
  endif

  BASE_CFLAGS += -Wall -Wimplicit -Wstrict-prototypes -DICON_ON_Make -DMINGW=1
  BASE_CFLAGS += -Wno-unused-result -fvisibility=hidden

#----------------------------------------------------------

  ifeq ($(CPU),x86_64)
    CPU_EXT = .x64
    BASE_CFLAGS += -m64
    OPTIMIZE = -s -O2 -ffast-math -fstrength-reduce
  endif
  ifeq ($(CPU),x86)
    BASE_CFLAGS += -m32
    OPTIMIZE = -O2 -march=i586 -mtune=i686 -ffast-math -fstrength-reduce
  endif

#----------------------------------------------------------

  SHARED_LIB_EXT = dll
  SHARED_LIB_CFLAGS = -fPIC -fvisibility=hidden
  SHARED_LIB_LDFLAGS = -shared $(LDFLAGS)

  BIN_EXT = .exe

  LDFLAGS = -mwindows -Wl,--dynamicbase -Wl,--nxcompat
  LDFLAGS += -Wl,--gc-sections -fvisibility=hidden
  LDFLAGS += -lwsock32 -lgdi32 -lwinmm -lole32 -lws2_32 -lpsapi -lcomctl32

  CLIENT_LDFLAGS=$(LDFLAGS)

#----------------------------------------------------------

  ifeq ($(SDL_ON_Make),1)
    BASE_CFLAGS += -DHEADERS_ON_Make=1 -I$(CODE_PATH)/libsdl/windows/include/SDL2
    #CLIENT_CFLAGS += -DHEADERS_ON_Make=1
    ifeq ($(CPU),x86)
      CLIENT_LDFLAGS += -L$(CODE_PATH)/libsdl/windows/mingw/lib32
      CLIENT_LDFLAGS += -lSDL2
      CLIENT_EXTRA_FILES += $(CODE_PATH)/libsdl/windows/mingw/lib32/SDL2.dll
    else
      CLIENT_LDFLAGS += -L$(CODE_PATH)/libsdl/windows/mingw/lib64
      CLIENT_LDFLAGS += -lSDL264
      CLIENT_EXTRA_FILES += $(CODE_PATH)/libsdl/windows/mingw/lib64/SDL264.dll
    endif
  endif

  ifeq ($(CURL_ON_Make),1)
    BASE_CFLAGS += -I$(CODE_PATH)/libcurl/windows/include
    ifeq ($(CPU),x86)
      CLIENT_LDFLAGS += -L$(CODE_PATH)/libcurl/windows/mingw/lib32
    else
      CLIENT_LDFLAGS += -L$(CODE_PATH)/libcurl/windows/mingw/lib64
    endif
    CLIENT_LDFLAGS += -lcurl -lwldap32 -lcrypt32
  endif

#----------------------------------------------------------

  DEBUG_CFLAGS = $(BASE_CFLAGS) -DDEBUG -D_DEBUG -g -O0
  RELEASE_CFLAGS = $(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

#----------------------------------------------------------

else # !MINGW:

ifeq ($(SET_PLATFORM),darwin)

#############################################################################
# BUILD MAC:
#############################################################################

  BASE_CFLAGS += -Wall -Wimplicit -Wstrict-prototypes -pipe
  BASE_CFLAGS += -Wno-unused-result

  OPTIMIZE = -O2 -fvisibility=hidden

  SHARED_LIB_EXT = dylib
  SHARED_LIB_CFLAGS = -fPIC -fvisibility=hidden
  SHARED_LIB_LDFLAGS = -dynamiclib $(LDFLAGS)

  LDFLAGS =

#----------------------------------------------------------

  ifneq ($(SDL_CODE_HEADERS),)
    BASE_CFLAGS += $(SDL_CODE_HEADERS)
    CLIENT_LDFLAGS = $(SDL_LIBS)
  else
    BASE_CFLAGS += -I/Library/Frameworks/SDL2.framework/Headers
    CLIENT_LDFLAGS = -F/Library/Frameworks -framework SDL2
  endif

#----------------------------------------------------------

  DEBUG_CFLAGS = $(BASE_CFLAGS) -DDEBUG -D_DEBUG -g -O0
  RELEASE_CFLAGS = $(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

#----------------------------------------------------------

else

#############################################################################
# BUILD *NIX:
#############################################################################

  BASE_CFLAGS += -Wall -Wimplicit -Wstrict-prototypes -pipe
  BASE_CFLAGS += -Wno-unused-result
  BASE_CFLAGS += -DICON_ON_Make
  BASE_CFLAGS += -I/usr/include -I/usr/local/include

  OPTIMIZE = -O2 -fvisibility=hidden

#----------------------------------------------------------

  ifeq ($(CPU),x86_64)
    CPU_EXT = .x64
  else
  ifeq ($(CPU),x86)
    OPTIMIZE += -march=i586 -mtune=i686
  endif
  endif

  ifeq ($(CPU),arm)
    OPTIMIZE += -march=armv7-a
    CPU_EXT = .arm
  endif

  ifeq ($(CPU),aarch64)
    CPU_EXT = .aarch64
  endif

#----------------------------------------------------------

  SHARED_LIB_EXT = so
  SHARED_LIB_CFLAGS = -fPIC -fvisibility=hidden
  SHARED_LIB_LDFLAGS = -shared $(LDFLAGS)

  LDFLAGS = -lm
  LDFLAGS += -Wl,--gc-sections -fvisibility=hidden

#----------------------------------------------------------

  ifeq ($(SDL_ON_Make),1)
    BASE_CFLAGS += $(SDL_CODE_HEADERS)
    CLIENT_LDFLAGS = $(SDL_LIBS)
  else
    BASE_CFLAGS += $(X11_CODE_HEADERS)
    CLIENT_LDFLAGS = $(X11_LIBS)
  endif

  ifeq ($(APP_JPG_ON_Make),1)
    CLIENT_LDFLAGS += -ljpeg
  endif

  ifeq ($(CURL_ON_Make),1)
    ifeq ($(CURL_DLL_ON_Make),0)
      CLIENT_LDFLAGS += -lcurl
    endif
  endif

#----------------------------------------------------------

  ifeq ($(PLATFORM),linux)
    LDFLAGS += -ldl -Wl,--hash-style=both
    ifeq ($(CPU),x86)
      # linux32 make:
      BASE_CFLAGS += -m32
      LDFLAGS += -m32
    endif
  endif

#----------------------------------------------------------

  DEBUG_CFLAGS = $(BASE_CFLAGS) -DDEBUG -D_DEBUG -g -O0
  RELEASE_CFLAGS = $(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

  DEBUG_LDFLAGS = -rdynamic

#----------------------------------------------------------

endif # *NIX platforms

endif # !MINGW

#----------------------------------------------------------

TARGET_CLIENT = $(CLIENT_NAME)$(CPU_EXT)$(BIN_EXT)

TARGET_RENDERER1 = $(RENDERER_PREFIX_Make)_opengl_$(SHARED_LIB_NAME)
TARGET_RENDERER2 = $(RENDERER_PREFIX_Make)_opengl2_$(SHARED_LIB_NAME)
TARGET_RENDERER_VULKAN = $(RENDERER_PREFIX_Make)_vulkan_$(SHARED_LIB_NAME)

TARGET_SERVER = $(SERVER_NAME)$(CPU_EXT)$(BIN_EXT)

STRINGIFY = $(REND2_BPATH)/stringify$(BIN_EXT)

TARGETS =

#----------------------------------------------------------

ifneq ($(SERVER_ON),0)
  TARGETS += $(B)/$(TARGET_SERVER)
endif

ifneq ($(CLIENT_ON),0)
  TARGETS += $(B)/$(TARGET_CLIENT)
  ifneq ($(RENDERER_DLLS_ON_Make),0)
    ifeq ($(OPENGL1_ON),1)
      TARGETS += $(B)/$(TARGET_RENDERER1)
    endif
    ifeq ($(OPENGL2_ON),1)
      TARGETS += $(B)/$(TARGET_RENDERER2)
    endif
    ifeq ($(VULKAN_ON_Make),1)
      TARGETS += $(B)/$(TARGET_RENDERER_VULKAN)
    endif
  endif
endif

ifeq ($(CCACHE_ON),1)
  CC := ccache $(CC)
endif

ifneq ($(RENDERER_DLLS_ON_Make),0)
    RENDERER_CFLAGS=$(SHARED_LIB_CFLAGS)
else
    RENDERER_CFLAGS=$(UNSHARED_LIB_CFLAGS)
endif

#----------------------------------------------------------

define DO_CC
$(echo_cmd) "CC $<"
$(Q)$(CC) $(UNSHARED_LIB_CFLAGS) $(CFLAGS) -o $@ -c $<
endef

define DO_RENDERER_CC
$(echo_cmd) "RENDERER_CC $<"
$(Q)$(CC) $(RENDERER_CFLAGS) $(CFLAGS) -o $@ -c $<
endef

define DO_REF_STR
$(echo_cmd) "REF_STR $<"
$(Q)rm -f $@
$(Q)$(STRINGIFY) $< $@
endef

define DO_BOT_CC
$(echo_cmd) "BOT_CC $<"
$(Q)$(CC) $(UNSHARED_LIB_CFLAGS) $(CFLAGS) $(BOTCFLAGS) -DBOTLIB -o $@ -c $< 
endef

# -MF $(patsubst %.o,%.d,$@) -include INCLUDE

define DO_UNSHARED_LIB_CC
$(echo_cmd) "DO_UNSHARED_LIB_CC $<"
$(Q)$(CC) $(UNSHARED_LIB_CFLAGS) $(CFLAGS) -o $@ -c $<
endef

define DO_SHARED_LIB_CC
$(echo_cmd) "SHARED_LIB_CC $<"
$(Q)$(CC) $(CFLAGS) $(SHARED_LIB_CFLAGS) -o $@ -c $<
endef

define DO_AS
$(echo_cmd) "AS $<"
$(Q)$(CC) $(CFLAGS) -DELF -x assembler-with-cpp -o $@ -c $<
endef

define DO_DED_CC
$(echo_cmd) "DED_CC $<"
$(Q)$(CC) $(UNSHARED_LIB_CFLAGS) -DDEDICATED $(CFLAGS) -o $@ -c $<
endef

define DO_WINDRES
$(echo_cmd) "WINDRES $<"
$(Q)$(WINDRES) -i $< -o $@
endef

#----------------------------------------------------------

ifndef SHARED_LIB_NAME
  SHARED_LIB_NAME=$(CPU).$(SHARED_LIB_EXT)
endif

#############################################################################
# RULES:
#############################################################################

$(CLIENT_BPATH)/%.o: $(ASM_PATH)/%.s
	$(DO_AS)

$(CLIENT_BPATH)/%.o: $(CLIENT_PATH)/%.c
	$(DO_CC)

$(CLIENT_BPATH)/%.o: $(CURLH_PATH)/%.c $(CLIENT_PATH)/%.h) $(CURLH_PATH)/%.h
	$(DO_CC)

$(CLIENT_BPATH)/%.o: $(SERVER_PATH)/%.c
	$(DO_CC)

$(CLIENT_BPATH)/%.o: $(COMMON_PATH)/%.c
	$(DO_CC)

#DEPS := $(OBJ:.o=.d)
#-include $(DEPS)  

# broken:
$(BOTLIB_BPATH)/%.o: $(BOTLIB_PATH)/%.c $(BOTLIB_PATH)/%.h $(COMMON_PATH)/%.h
  %.o: %.c 
  #$(BOTLIB_BPATH)/%.o: $(BOTLIB_PATH)/%.c Makefile
  #%.o: %.c ${BOTLIB_HEADER}
	$(DO_BOT_CC)

$(B)/libjpeg/%.o: $(JPG_PATH)/%.c
	$(DO_CC)

$(CLIENT_BPATH)/%.o: $(SDL_PATH)/%.c
	$(DO_CC)

$(REND1_BPATH)/%.o: $(RENDERER1_PATH)/%.c
	$(DO_RENDERER_CC)

$(REND1_BPATH)/%.o: $(RENDERER_COMMON_PATH)/%.c
	$(DO_RENDERER_CC)

$(REND1_BPATH)/%.o: $(COMMON_PATH)/%.c
	$(DO_RENDERER_CC)

$(REND2_BPATH)/glsl/%.c: $(RENDERER2_PATH)/glsl/%.glsl $(STRINGIFY)
	$(DO_REF_STR)

$(REND2_BPATH)/glsl/%.o: $(RENDERER2_PATH)/glsl/%.c
	$(DO_RENDERER_CC)

$(REND2_BPATH)/%.o: $(RENDERER2_PATH)/%.c
	$(DO_RENDERER_CC)

$(REND2_BPATH)/%.o: $(RENDERER_COMMON_PATH)/%.c
	$(DO_RENDERER_CC)

$(REND2_BPATH)/%.o: $(COMMON_PATH)/%.c
	$(DO_RENDERER_CC)

$(RENDV_BPATH)/%.o: $(RENDERERV_PATH)/%.c
	$(DO_RENDERER_CC)

$(RENDV_BPATH)/%.o: $(RENDERER_COMMON_PATH)/%.c
	$(DO_RENDERER_CC)

$(RENDV_BPATH)/%.o: $(COMMON_PATH)/%.c
	$(DO_RENDERER_CC)

$(CLIENT_BPATH)/%.o: $(UNIX_PATH)/%.c
	$(DO_CC)

$(CLIENT_BPATH)/%.o: $(WIN32_PATH)/%.c
	$(DO_CC)

$(CLIENT_BPATH)/%.o: $(WIN32_PATH)/%.rc
	$(DO_WINDRES)

$(SERVER_BPATH)/%.o: $(ASM_PATH)/%.s
	$(DO_AS)

$(SERVER_BPATH)/%.o: $(SERVER_PATH)/%.c
	$(DO_DED_CC)

$(SERVER_BPATH)/%.o: $(COMMON_PATH)/%.c
	$(DO_DED_CC)

$(SERVER_BPATH)/%.o: $(BOTLIB_PATH)/%.c
	$(DO_BOT_CC)

$(SERVER_BPATH)/%.o: $(UNIX_PATH)/%.c
	$(DO_DED_CC)

$(SERVER_BPATH)/%.o: $(WIN32_PATH)/%.c
	$(DO_DED_CC)

$(SERVER_BPATH)/%.o: $(WIN32_PATH)/%.rc
	$(DO_WINDRES)

#############################################################################
# TARGETS:
#############################################################################

default: release
all: debug release

debug:
	@$(MAKE) targets B=$(BUILD_DEBUG) CFLAGS="$(CFLAGS) $(DEBUG_CFLAGS)" LDFLAGS="$(LDFLAGS) $(DEBUG_LDFLAGS)" V=$(V)

release:
	@$(MAKE) targets B=$(BUILD_RELEASE) CFLAGS="$(CFLAGS) $(RELEASE_CFLAGS)" V=$(V)

#----------------------------------------------------------

define ADD_COPY_TARGET
TARGETS += $2
$2: $1
	$(echo_cmd) "CP $$<"
	@cp $1 $2
endef

#Create rules for copying files into the base build path (useful for bundling):
define GENERATE_COPY_TARGETS
$(foreach FILE,$1, \
  $(eval $(call ADD_COPY_TARGET, \
    $(FILE), \
    $(addprefix $(B)/,$(notdir $(FILE))))))
endef

#----------------------------------------------------------

ifneq ($(CLIENT_ON),0)
  $(call GENERATE_COPY_TARGETS,$(CLIENT_EXTRA_FILES))
endif

#----------------------------------------------------------

#Create Build folders & tools, then build:
targets: doFolders tools
	@echo ""
	@echo "Building $(CLIENT_NAME) in $(B):"
	@echo ""
	@echo "  VERSION: $(VERSION)"
	@echo "  PLATFORM: $(PLATFORM)"
	@echo "  CPU: $(CPU)"
	@echo "  SET_PLATFORM: $(SET_PLATFORM)"
	@echo "  SET_CPU: $(SET_CPU)"
ifdef MINGW
	@echo "  WINDRES: $(WINDRES)"
endif
	@echo "  CC: $(CC)"
	@echo ""
	@echo "  CFLAGS:"
	@for i in $(CFLAGS); \
	do \
		echo "    $$i"; \
	done
	@echo ""
	@echo "  Output:"
	@for i in $(TARGETS); \
	do \
		echo "    $$i"; \
	done
	@echo ""
ifneq ($(TARGETS),)
	@$(MAKE) $(TARGETS) V=$(V)
endif

#----------------------------------------------------------

#Create folders from paths:
doFolders:
	@if [ ! -d $(BUILD_PATH) ];then $(MKDIR) $(BUILD_PATH);fi
	@if [ ! -d $(B) ];then $(MKDIR) $(B);fi
	@if [ ! -d $(CLIENT_BPATH) ];then $(MKDIR) $(CLIENT_BPATH);fi
	@if [ ! -d $(SERVER_BPATH) ];then $(MKDIR) $(SERVER_BPATH);fi
	@if [ ! -d $(REND1_BPATH) ];then $(MKDIR) $(REND1_BPATH);fi
	@if [ ! -d $(REND2_BPATH) ];then $(MKDIR) $(REND2_BPATH);fi
	@if [ ! -d $(REND2_BPATH)/glsl ];then $(MKDIR) $(REND2_BPATH)/glsl;fi
	@if [ ! -d $(RENDV_BPATH) ];then $(MKDIR) $(RENDV_BPATH);fi
	@if [ ! -d $(BOTLIB_BPATH) ];then $(MKDIR) $(BOTLIB_BPATH);fi
	@if [ ! -d $(B)/libjpeg ];then $(MKDIR) $(B)/libjpeg;fi

#############################################################################
# CLIENT/SERVER:
#############################################################################
CODE_HEADERS = 

RENDERER1_OBJS = $(wildcard $(RENDERER1_PATH)/*.c)

ifneq ($(RENDERER_DLLS_ON_Make), 0)
  RENDERER1_OBJS += \
    $(REND1_BPATH)/q_shared.o \
    $(REND1_BPATH)/puff.o \
    $(REND1_BPATH)/q_math.o
endif

#----------------------------------------------------------

RENDERER2_OBJS = $(wildcard $(RENDERER2_PATH)/*.c)

ifneq ($(RENDERER_DLLS_ON_Make), 0)
  RENDERER2_OBJS += \
    $(REND2_BPATH)/q_shared.o \
    $(REND2_BPATH)/puff.o \
    $(REND2_BPATH)/q_math.o
endif

RENDERER2_FX_OBJS = $(REND2_BPATH)/glsl/*.o
#RENDERER2_FX_CODE = $(wildcard $(RENDERER2_PATH)/glsl/*.glsl)
#RENDERER2_FX_OBJS = $(RENDERER2_FX_CODE:%.glsl=%.o)

#-----------------------------------------------------------

RENDERER_VULKAN_OBJS = $(wildcard $(RENDERERV_PATH)/*.c)

ifneq ($(RENDERER_DLLS_ON_Make), 0)
  RENDERER_VULKAN_OBJS += \
    $(RENDV_BPATH)/q_shared.o \
    $(RENDV_BPATH)/puff.o \
    $(RENDV_BPATH)/q_math.o
endif

#----------------------------------------------------------

JPG_OBJS = $(wildcard $(JPG_PATH)/*.c)

#----------------------------------------------------------

OBJ=
CLIENT_CODE = $(wildcard $(CLIENT_PATH)/*.c)
CLIENT_OBJS = $(CLIENT_CODE:%.c=%.o)

OBJ += $(CLIENT_OBJS)


#COMMON_OBJS += $(wildcard $(COMMON_PATH)/*.c)
#OBJ += $(COMMON_OBJS)

OBJ += \
  $(CLIENT_BPATH)/cmd.o \
  $(CLIENT_BPATH)/cm_load.o \
  $(CLIENT_BPATH)/cm_patch.o \
  $(CLIENT_BPATH)/cm_polylib.o \
  $(CLIENT_BPATH)/cm_test.o \
  $(CLIENT_BPATH)/cm_trace.o \
  $(CLIENT_BPATH)/common.o \
  $(CLIENT_BPATH)/cvar.o \
  $(CLIENT_BPATH)/files.o \
  $(CLIENT_BPATH)/history.o \
  $(CLIENT_BPATH)/keys.o \
  $(CLIENT_BPATH)/md4.o \
  $(CLIENT_BPATH)/md5.o \
  $(CLIENT_BPATH)/msg.o \
  $(CLIENT_BPATH)/net_chan.o \
  $(CLIENT_BPATH)/net_ip.o \
  $(CLIENT_BPATH)/huffman.o \
  $(CLIENT_BPATH)/huffman_static.o \
  $(CLIENT_BPATH)/q_math.o \
  $(CLIENT_BPATH)/q_shared.o \
  $(CLIENT_BPATH)/unzip.o \
  $(CLIENT_BPATH)/puff.o \
  $(CLIENT_BPATH)/vm.o \
  $(CLIENT_BPATH)/vm_interpreted.o 

#server:
SERVER_OBJS = $(wildcard $(SERVER_PATH)/*.c)
OBJ += $(SERVER_OBJS)

#botlib:
#BOTLIB_HEADER = $(wildcard $(BOTLIB_PATH)/*.h) $(wildcard $(COMMON_PATH)/*.h) 
BOTLIB_CODE = $(wildcard $(BOTLIB_PATH)/*.c)
BOTLIB_OBJS = $(BOTLIB_CODE:%.c=%.o)
#BOTLIB_OBJS = $(patsubst %.c, %.o, $(BOTLIB_CODE))
#CODE_HEADERS += $(CLIENT_PATH)/*.c $(BOTLIB_PATH)/*c $(COMMON_PATH)/*c

OBJ += $(BOTLIB_OBJS)

#----------------------------------------------------------

ifneq ($(APP_JPG_ON_Make),1)
  OBJ += $(JPG_OBJS)
endif

ifneq ($(RENDERER_DLLS_ON_Make),1)
  ifeq ($(VULKAN_ON_Make),1)
    OBJ += $(RENDERER_VULKAN_OBJS)
  else
    ifeq ($(OPENGL2_ON),1)
      OBJ += $(RENDERER2_OBJS)
      OBJ += $(RENDERER2_FX_OBJS)
    else
      OBJ += $(RENDERER1_OBJS)
    endif
  endif
endif

#----------------------------------------------------------

ifeq ($(CPU),x86)
ifndef MINGW
  OBJ += \
    $(CLIENT_BPATH)/snd_mix_mmx.o \
    $(CLIENT_BPATH)/snd_mix_sse.o
endif
endif

#----------------------------------------------------------

ifeq ($(VM_ON),true)
  VM_CODE =

  ifeq ($(CPU),x86)
  $(wildcard $(VM_CODE)/*.c)
    VM_CODE = $(wildcard $(CLIENT_PATH)/vm/x86/*.c)
    OBJ += $(CLIENT_BPATH)/vm_x86.o
  endif
  ifeq ($(CPU),x86_64)
    VM_CODE = $(wildcard $(CLIENT_PATH)/vm/x86_64/*.c)
    OBJ += $(CLIENT_BPATH)/vm_x86.o
  endif
  ifeq ($(CPU),arm)
    VM_CODE = $(wildcard $(CLIENT_PATH)/vm/arm/*.c)
    #OBJ += $(CLIENT_BPATH)/vm_armv7l.o
  endif
  ifeq ($(CPU),aarch64)
    VM_CODE = $(wildcard $(CLIENT_PATH)/vm/aarch64/*.c)
    #OBJ += $(CLIENT_BPATH)/vm_aarch64.o
  endif

  #VM_OBJS = $(VM_CODE:%.c=%.o)
  #OBJ += $(VM_OBJS)
endif

#----------------------------------------------------------


#OBJ += $(CLIENT_BPATH)/curlh/cl_curl.o

ifeq ($(CURL_ON_Make),1)
  CURLH_PATH = $(CLIENT_PATH)/curlh
  #CURLH_HEADER = $(wildcard $(CLIENT_PATH)/client.h) $(wildcard $(CURLH_PATH)/*.h) 
  CURLH_CODE = $(wildcard $(CURLH_PATH)/*.c)
  CURLH_OBJS = $(CURLH_CODE:%.c=%.o)
  OBJ += $(CURLH_OBJS)
endif

ifdef MINGW

#----------------------------------------------------------

  OBJ += \
    $(CLIENT_BPATH)/win_main.o \
    $(CLIENT_BPATH)/win_shared.o \
    $(CLIENT_BPATH)/win_syscon.o \
    $(CLIENT_BPATH)/win_resource.o

ifeq ($(SDL_ON_Make),1)
    OBJ += \
        $(CLIENT_BPATH)/sdl_glimp.o \
        $(CLIENT_BPATH)/sdl_gamma.o \
        $(CLIENT_BPATH)/sdl_input.o \
        $(CLIENT_BPATH)/sdl_snd.o
else # !SDL_ON_Make
    OBJ += \
        $(CLIENT_BPATH)/win_gamma.o \
        $(CLIENT_BPATH)/win_glimp.o \
        $(CLIENT_BPATH)/win_input.o \
        $(CLIENT_BPATH)/win_minimize.o \
        $(CLIENT_BPATH)/win_qgl.o \
        $(CLIENT_BPATH)/win_snd.o \
        $(CLIENT_BPATH)/win_wndproc.o
ifeq ($(VULKAN_API_ON_Make),1)
    OBJ += \
        $(CLIENT_BPATH)/win_qvk.o
endif
endif # !SDL_ON_Make

#----------------------------------------------------------

else # !MINGW:

  OBJ += \
    $(CLIENT_BPATH)/unix_main.o \
    $(CLIENT_BPATH)/unix_shared.o \
    $(CLIENT_BPATH)/linux_signals.o

ifeq ($(SDL_ON_Make),1)
    OBJ += \
        $(CLIENT_BPATH)/sdl_glimp.o \
        $(CLIENT_BPATH)/sdl_gamma.o \
        $(CLIENT_BPATH)/sdl_input.o \
        $(CLIENT_BPATH)/sdl_snd.o
else # !SDL_ON_Make:
    OBJ += \
        $(CLIENT_BPATH)/linux_glimp.o \
        $(CLIENT_BPATH)/linux_qgl.o \
        $(CLIENT_BPATH)/linux_snd.o \
        $(CLIENT_BPATH)/x11_dga.o \
        $(CLIENT_BPATH)/x11_randr.o \
        $(CLIENT_BPATH)/x11_vidmode.o
ifeq ($(VULKAN_API_ON_Make),1)
    OBJ += \
        $(CLIENT_BPATH)/linux_qvk.o
endif

endif # !SDL_ON_Make

endif # !MINGW

#----------------------------------------------------------

# Client binary:

$(B)/$(TARGET_CLIENT): $(OBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) -o $@ $(OBJ) $(CLIENT_LDFLAGS) \
		$(LDFLAGS)

#===========================================================
# Modular renderers:
#===========================================================

$(B)/$(TARGET_RENDERER1): $(RENDERER1_OBJS)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) -o $@ $(RENDERER1_OBJS) $(SHARED_LIB_CFLAGS) $(SHARED_LIB_LDFLAGS)

$(STRINGIFY): $(CODE_PATH)/renderer2/stringify.c
	$(echo_cmd) "LD $@"
	$(Q)$(CC) -o $@ $(CODE_PATH)/renderer2/stringify.c $(LDFLAGS)

$(B)/$(TARGET_RENDERER2): $(RENDERER2_OBJS) $(RENDERER2_FX_OBJS)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) -o $@ $(RENDERER2_OBJS) $(RENDERER2_FX_OBJS) $(SHARED_LIB_CFLAGS) $(SHARED_LIB_LDFLAGS)

$(B)/$(TARGET_RENDERER_VULKAN): $(RENDERER_VULKAN_OBJS)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) -o $@ $(RENDERER_VULKAN_OBJS) $(SHARED_LIB_CFLAGS) $(SHARED_LIB_LDFLAGS)

#############################################################################
# DEDICATED SERVER:
#############################################################################

DOBJ = \
  $(SERVER_BPATH)/sv_bot.o \
  $(SERVER_BPATH)/sv_client.o \
  $(SERVER_BPATH)/sv_ccmds.o \
  $(SERVER_BPATH)/sv_filter.o \
  $(SERVER_BPATH)/sv_game.o \
  $(SERVER_BPATH)/sv_init.o \
  $(SERVER_BPATH)/sv_main.o \
  $(SERVER_BPATH)/sv_net_chan.o \
  $(SERVER_BPATH)/sv_snapshot.o \
  $(SERVER_BPATH)/sv_world.o \
  \
  $(SERVER_BPATH)/cm_load.o \
  $(SERVER_BPATH)/cm_patch.o \
  $(SERVER_BPATH)/cm_polylib.o \
  $(SERVER_BPATH)/cm_test.o \
  $(SERVER_BPATH)/cm_trace.o \
  $(SERVER_BPATH)/cmd.o \
  $(SERVER_BPATH)/common.o \
  $(SERVER_BPATH)/cvar.o \
  $(SERVER_BPATH)/files.o \
  $(SERVER_BPATH)/history.o \
  $(SERVER_BPATH)/keys.o \
  $(SERVER_BPATH)/md4.o \
  $(SERVER_BPATH)/md5.o \
  $(SERVER_BPATH)/msg.o \
  $(SERVER_BPATH)/net_chan.o \
  $(SERVER_BPATH)/net_ip.o \
  $(SERVER_BPATH)/huffman.o \
  $(SERVER_BPATH)/huffman_static.o \
  \
  $(SERVER_BPATH)/q_math.o \
  $(SERVER_BPATH)/q_shared.o \
  \
  $(SERVER_BPATH)/unzip.o \
  $(SERVER_BPATH)/vm.o \
  $(SERVER_BPATH)/vm_interpreted.o \
  \
  $(SERVER_BPATH)/be_aas_bspq3.o \
  $(SERVER_BPATH)/be_aas_cluster.o \
  $(SERVER_BPATH)/be_aas_debug.o \
  $(SERVER_BPATH)/be_aas_entity.o \
  $(SERVER_BPATH)/be_aas_file.o \
  $(SERVER_BPATH)/be_aas_main.o \
  $(SERVER_BPATH)/be_aas_move.o \
  $(SERVER_BPATH)/be_aas_optimize.o \
  $(SERVER_BPATH)/be_aas_reach.o \
  $(SERVER_BPATH)/be_aas_route.o \
  $(SERVER_BPATH)/be_aas_routealt.o \
  $(SERVER_BPATH)/be_aas_sample.o \
  $(SERVER_BPATH)/be_ai_char.o \
  $(SERVER_BPATH)/be_ai_chat.o \
  $(SERVER_BPATH)/be_ai_gen.o \
  $(SERVER_BPATH)/be_ai_goal.o \
  $(SERVER_BPATH)/be_ai_move.o \
  $(SERVER_BPATH)/be_ai_weap.o \
  $(SERVER_BPATH)/be_ai_weight.o \
  $(SERVER_BPATH)/be_ea.o \
  $(SERVER_BPATH)/be_interface.o \
  $(SERVER_BPATH)/l_crc.o \
  $(SERVER_BPATH)/l_libvar.o \
  $(SERVER_BPATH)/l_log.o \
  $(SERVER_BPATH)/l_memory.o \
  $(SERVER_BPATH)/l_precomp.o \
  $(SERVER_BPATH)/l_script.o \
  $(SERVER_BPATH)/l_struct.o

ifdef MINGW
  DOBJ += \
  $(SERVER_BPATH)/win_main.o \
  $(CLIENT_BPATH)/win_resource.o \
  $(SERVER_BPATH)/win_shared.o \
  $(SERVER_BPATH)/win_syscon.o
else
  DOBJ += \
  $(SERVER_BPATH)/linux_signals.o \
  $(SERVER_BPATH)/unix_main.o \
  $(SERVER_BPATH)/unix_shared.o
endif

ifeq ($(VM_ON),true)
  ifeq ($(CPU),x86)
    DOBJ += $(SERVER_BPATH)/vm_x86.o
  endif
  ifeq ($(CPU),x86_64)
    DOBJ += $(SERVER_BPATH)/vm_x86.o
  endif
  ifeq ($(CPU),arm)
    DOBJ += $(SERVER_BPATH)/vm_armv7l.o
  endif
  ifeq ($(CPU),aarch64)
    DOBJ += $(SERVER_BPATH)/vm_aarch64.o
  endif
endif

$(B)/$(TARGET_SERVER): $(DOBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) -o $@ $(DOBJ) $(LDFLAGS)

INCLUDE = $(CODE_HEADERS:.c=.d)
#############################################################################
# TOOLS:
#############################################################################

install: release 
	@for i in $(TARGETS); do 
		if [ -f $(BUILD_RELEASE)$$i ]; then 
			$(INSTALL) -D -m 0755 "$(BUILD_RELEASE)/$$i" "$(APP_PATH)$$i";
			$(STRIP) "$(APP_PATH)$$i"; 
		fi 
	done

wipe: wipe-debug wipe-release

clean:
	@echo "'clean' $(B):" 
	@rm $(BUILD_RELEASE)/$(CLIENT_BPATH_NAME) 
	@rm -f $(B)/$(OBJ) $(B)/$(DOBJ)
	@rm -f $(B)/$(TARGETS)
	@rm -rf $(BUILD_RELEASE)/$(CLIENT_BPATH_NAME)
	@rm $(B)/$(CLIENT_BPATH_NAME)/'*.o, *.d'
	@rm $(SERVER_BPATH)/'*.o, *.d'
	@rm $(B)/$(REND1_BPATH_NAME)/'*.o, *.d'
	@rm $(B)/$(REND2_BPATH_NAME)/'*.o, *.d'
	@rm $(B)/$(RENDV_BPATH_NAME)/'*.o, *.d' 

clean2: 
	@echo "'clean2' $(B):" 
	@rm $(BUILD_RELEASE)/$(CLIENT_BPATH_NAME) 
	@rm -f $(B)/$(OBJ) $(B)/$(DOBJ)
	@rm -f $(B)/$(TARGETS)
	@rm -rf $(BUILD_RELEASE)/$(CLIENT_BPATH_NAME)
	@rm $(B)/$(CLIENT_BPATH_NAME)/'*.o, *.d'
	@rm $(SERVER_BPATH)/'*.o, *.d'
	@rm $(B)/$(REND1_BPATH_NAME)/'*.o, *.d'
	@rm $(B)/$(REND2_BPATH_NAME)/'*.o, *.d'
	@rm $(B)/$(RENDV_BPATH_NAME)/'*.o, *.d' 

clean-d:
	@echo "clean-d $(B):"
	@if [ -d $(B) ];then (find $(B) -name '*.d' -exec rm {} \;)fi
	@rm -f $(OBJ) $(DOBJ)
	@rm -f $(TARGETS)

wipe-debug:
	@rm -rf $(BUILD_DEBUG)

wipe-release:
	@rm -rf $(BUILD_RELEASE)

wipe-build: clean
	@rm -rf $(BUILD_PATH)

#############################################################################
# KEEP FILES (DEPENDENCIES):
#############################################################################

KEEP=$(shell find . -name '*.d')
include $(KEEP)

ifneq ($(strip $(KEEP)),)
 include $(KEEP)
endif

.PHONY: all clean clean2 clean-debug clean-release copyfiles \
	debug default dist distclean doFolders release \
	targets tools toolsclean
