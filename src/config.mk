# Define the default make configuration. Not all defaults are defined here, but all command line
# options are listed here for convenience.

# Build artifact directory.
output ?= $(CURDIR)

# Compilation toolchain (clang, gcc, none) for C-family targets.
toolchain ?= clang

# Compilation mode (debug, release, profile).
mode ?= debug

# Build 32-bit or 64-bit target.
arch ?= $(arch)

# Compiler warning level (0, 1, 2).
strict ?= 2

# Debug symbol level (0, 1, 2, 3).
symbols ?= 1

# C language standard.
cstandard ?= c2x

# C++ language standard.
cxxstandard ?= c++2a

# Linker (lld, gold, etc.) to use.
ifeq ($(SYSTEM), LINUX)
    linker ?= lld
else ifeq ($(SYSTEM), MACOS)
    linker ?= ld
else
    $(error Unknown system $(SYSTEM), check config.mk)
endif

# Sanitizers (AddressSanitizer, UndefinedBehaviorSanitizer) to enable.
sanitize ?=

# Enable code coverage instrumentation.
coverage ?= 0

# Compile caching system.
ifneq ($(CCACHE), )
    cacher ?= $(CCACHE)
endif

# Enable stylized build output.
stylized ?= 1

# Enable verbose builds.
verbose ?= 0

# Define the toolchain binaries.
ifeq ($(toolchain), clang)
    ifeq ($(SYSTEM), LINUX)
        CC := clang
        CXX := clang++
        AR := llvm-ar
        STRIP := llvm-strip
    else ifeq ($(SYSTEM), MACOS)
        TOOLCHAIN := $(XCODE)/Toolchains/XcodeDefault.xctoolchain/usr/bin

        CC := $(TOOLCHAIN)/clang
        CXX := $(TOOLCHAIN)/clang++
        AR := $(TOOLCHAIN)/ar
        STRIP := $(TOOLCHAIN)/strip
    else
        $(error Unrecognized system $(SYSTEM), check config.mk)
    endif
else ifeq ($(toolchain), gcc)
    CC := gcc
    CXX := g++
    AR := ar
    STRIP := strip
else ifneq ($(toolchain), none)
    $(error Unrecognized toolchain $(toolchain), check config.mk)
endif

JAVAC := javac
JAR := jar

# Validate the provided compilation mode.
SUPPORTED_MODES := debug release profile

ifneq ($(mode), $(filter $(SUPPORTED_MODES), $(mode)))
    $(error Compilation mode $(mode) not supported, check config.mk)
endif

# Validate the provided compiler warning level.
SUPPORTED_STRICTNESS := 0 1 2

ifneq ($(strict), $(filter $(SUPPORTED_STRICTNESS), $(strict)))
    $(error Compilation strictness level $(strict) not supported, check config.mk)
endif

# Use a compiler cache if requested.
ifneq ($(cacher), )
    override CC := $(cacher) $(CC)
    override CXX := $(cacher) $(CXX)
endif

# Define the output directories.
OUT_DIR := $(output)/$(mode)

CXX_DIR := $(OUT_DIR)/$(toolchain)/$(arch)
BIN_DIR := $(CXX_DIR)/bin
LIB_DIR := $(CXX_DIR)/lib
GEN_DIR := $(CXX_DIR)/gen
OBJ_DIR := $(CXX_DIR)/obj
ETC_DIR := $(CXX_DIR)/etc

JAVA_DIR := $(OUT_DIR)/$(JAVAC)
JAR_DIR := $(JAVA_DIR)/bin
CLASS_DIR := $(JAVA_DIR)/classes

PKG_DIR := $(output)/out
DATA_DIR := $(output)/data

# ANSI escape sequences to use in stylized builds.
ifeq ($(stylized), 1)
    DEFAULT := \x1b[0m
    BLACK := \x1b[1;30m
    RED := \x1b[1;31m
    GREEN := \x1b[1;32m
    YELLOW := \x1b[1;33m
    BLUE := \x1b[1;34m
    MAGENTA := \x1b[1;35m
    CYAN := \x1b[1;36m
    WHITE := \x1b[1;37m
endif

# Use @ suppression in non-verbose builds.
ifeq ($(verbose), 0)
    Q := @
else
    $(info Bin dir = $(BIN_DIR))
    $(info Lib dir = $(LIB_DIR))
    $(info Gen dir = $(GEN_DIR))
    $(info Obj dir = $(OBJ_DIR))
    $(info Etc dir = $(ETC_DIR))
    $(info JAR dir = $(JAR_DIR))
    $(info Class dir = $(CLASS_DIR))
    $(info Data dir = $(DATA_DIR))
    $(info Toolchain = $(toolchain))
    $(info Mode = $(mode))
    $(info Arch = $(arch))
    $(info Cacher = $(cacher))
endif
