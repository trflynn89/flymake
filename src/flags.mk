# Define flags to pass to the various compilation tools for the current build configuration and
# host system environment.
#
# The following flags are defined:
#
#     CFLAGS = Compiler flags for C and Objective-C files.
#     CXXFLAGS = Compiler flags for C++ and Objective-C++ files.
#     LDFLAGS = Linker flags for C-family targets.
#     LDLIBS = Linker libraries required by the STL for C-family targets.
#
#     JFLAGS = Compiler flags for Java files.
#
#     STRIP_FLAGS = Flags to be used when stripping symbols from a target.
#     JAR_CREATE_FLAGS = Flags to be used when creating a JAR archive
#     TAR_EXTRACT_FLAGS = Flags to be used when extracting a tar archive.
#     TAR_CREATE_FLAGS = Flags to be used when creating a tar archive
#     ZIP_EXTRACT_FLAGS = Flags to be used when extracting a zip archive.
#
# The application may define the following variables in any files.mk to define compiler/linker flags
# on a per-directory level. These variables are defaulted to the values of the parent directory, so
# generally these variables should be treated as append-only (+=). But this behavior may be avoided
# by assigning values instead (:=).
#
#     CFLAGS_$(d)
#     CXXFLAGS_$(d)
#     LDFLAGS_$(d)
#     LDLIBS_$(d)
#     JFLAGS_$(d)
#
# The resulting flags used when compiling a directory are the global flags defined in this file
# followed by any _$(d) variants defined in the directory's files.mk.

# Remove built-in rules.
MAKEFLAGS += --no-builtin-rules --no-print-directory
.SUFFIXES:

# Use bash instead of sh.
SHELL := /bin/bash

# Linker flags.
LDFLAGS ?=
LDLIBS ?=

# Standard linker flags.
LDFLAGS += -L$(INSTALL_LIB_DIR) -fuse-ld=$(linker)
LDLIBS += -lpthread

ifeq ($(SYSTEM), LINUX)
    LDLIBS += -latomic
endif

# Compiler flags for all C-family files.
CF_ALL := -MD -MP -fPIC
CF_ALL += -I$(SOURCE_ROOT) -I$(GEN_DIR) -I$(INSTALL_INC_DIR)

ifeq ($(SYSTEM), MACOS)
    CF_ALL += -isysroot $(XCODE)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
endif

ifeq ($(arch), x86)
    CF_ALL += -m32
endif

ifeq ($(toolchain), gcc)
    CF_ALL += -Wno-psabi
endif

# C and C++ specific flags.
CFLAGS ?=
CXXFLAGS ?=

# Compiler flags for Java files.
JFLAGS ?=

# Language standard flags.
CFLAGS += -std=$(cstandard)
CXXFLAGS += -std=$(cxxstandard)

# Error and warning flags.
ifneq ($(strict), 0)
    CF_ALL += \
        -Wall \
        -Wextra \
        -Werror

    ifneq ($(strict), 1)
        CF_ALL += \
            -pedantic \
            -Wcast-align \
            -Wcast-qual \
            -Wdisabled-optimization \
            -Wfloat-equal \
            -Winvalid-pch \
            -Wmissing-declarations \
            -Wpointer-arith \
            -Wredundant-decls \
            -Wshadow \
            -Wstrict-overflow=2 \
            -Wundef \
            -Wunreachable-code \
            -Wunused \

        CXXFLAGS += \
            -Wctor-dtor-privacy \
            -Wnon-virtual-dtor \
            -Wold-style-cast \
            -Woverloaded-virtual \

        # Disabled due to LLVM bug: https://bugs.llvm.org/show_bug.cgi?id=44325
        #    -Wzero-as-null-pointer-constant \

        ifeq ($(mode), debug)
            CF_ALL += -Winline
        endif

        ifeq ($(toolchain), clang)
            CF_ALL += \
                -Wnewline-eof \
                -Wsign-conversion

            # C++20 introduces __VA_OPT__ to handle variadic macros invoked with zero variadic
            # arguments. However, Apple's clang has not updated -pedantic to allow such invocations.
            # See: https://stackoverflow.com/a/67996331
            ifeq ($(SYSTEM), MACOS)
                ifeq ($(cxxstandard), $(filter c++20 c++2a, $(cxxstandard)))
                    CF_ALL += \
                        -Wno-gnu-zero-variadic-macro-arguments
                endif
            endif
        else ifeq ($(toolchain), gcc)
            CF_ALL += \
                -Wlogical-op \
                -Wnull-dereference \
                -Wredundant-decls

            CXXFLAGS += -Wsuggest-override

            ifeq ($(mode), debug)
                CXXFLAGS += \
                    -Wsuggest-final-methods \
                    -Wsuggest-final-types
            endif
        endif
    endif
endif

JFLAGS += \
    -Werror \
    -Xlint

# Add debug symbols, optimize release builds, or add profiling symbols.
ifeq ($(mode), debug)
    CF_ALL += -O0 -g$(symbols)
    JFLAGS += -g:lines,vars,source
else ifeq ($(mode), release)
    CF_ALL += -O2 -DNDEBUG
    JFLAGS += -g:none
else ifeq ($(mode), profile)
    ifeq ($(toolchain), gcc)
        CF_ALL += -O2 -DNDEBUG -g$(symbols) -pg -DFLY_PROFILE
        LDFLAGS += -pg
    else
        $(error Profiling not supported with toolchain $(toolchain), check flags.mk)
    endif
endif

# Enable sanitizers.
ifneq ($(sanitize),)
    CF_ALL += -fsanitize=$(sanitize) -fno-omit-frame-pointer -fno-sanitize-recover=all
endif

# Enable code coverage instrumentation.
ifeq ($(coverage), 1)
    ifeq ($(toolchain), clang)
        CF_ALL += -fprofile-instr-generate -fcoverage-mapping
    else ifeq ($(toolchain), gcc)
        CF_ALL += --coverage
    endif
endif

CFLAGS += $(CF_ALL)
CXXFLAGS += $(CF_ALL)

# Enable verbose Java output.
ifeq ($(verbose), 1)
    JFLAGS += -verbose
endif

# On macOS: Link commonly used frameworks.
ifeq ($(SYSTEM), MACOS)
    LDFLAGS += \
        -framework CoreFoundation \
        -framework CoreServices \
        -framework Foundation
endif

# strip flags.
ifeq ($(SYSTEM), LINUX)
    STRIP_FLAGS := -s
else ifeq ($(SYSTEM), MACOS)
    STRIP_FLAGS := -rSx
else
    $(error Unrecognized system $(SYSTEM), check flags.mk)
endif

# jar flags.
ifeq ($(verbose), 1)
    JAR_CREATE_FLAGS := cvef
else
    JAR_CREATE_FLAGS := cef
endif

# tar flags.
ifeq ($(verbose), 1)
    TAR_EXTRACT_FLAGS := -xjvf
    TAR_CREATE_FLAGS := -cjvf
else
    TAR_EXTRACT_FLAGS := -xjf
    TAR_CREATE_FLAGS := -cjf
endif

ifeq ($(SYSTEM), MACOS)
    TAR_EXTRACT_FLAGS := -mo $(TAR_EXTRACT_FLAGS)
endif

# zip flags.
ifeq ($(verbose), 0)
    ZIP_EXTRACT_FLAGS := -q
endif
