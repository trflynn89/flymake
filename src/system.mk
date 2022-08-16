# Determine information about the host system environment and define system-dependent variables.

SYSTEM_AND_ARCH := $(shell uname -s -m)
SYSTEM := $(word 1, $(SYSTEM_AND_ARCH))
ARCH := $(word 2, $(SYSTEM_AND_ARCH))

SUDO := $(shell which sudo)
CCACHE := $(shell which ccache)

# Define installation directories.
INSTALL_ROOT ?= /usr/local
INSTALL_BIN_DIR := $(INSTALL_ROOT)/bin
INSTALL_INC_DIR := $(INSTALL_ROOT)/include
INSTALL_SRC_DIR := $(INSTALL_ROOT)/src
INSTALL_LIB_DIR := $(INSTALL_ROOT)/lib

# Determine host operating system.
ifeq ($(SYSTEM), Linux)
    SYSTEM := LINUX
else ifeq ($(SYSTEM), Darwin)
    SYSTEM := MACOS
else
    $(error Unrecognized system $(SYSTEM), check system.mk)
endif

# Determine default architecture.
ifeq ($(SYSTEM), LINUX)
    SUPPORTED_ARCH := x64 x86
else ifeq ($(SYSTEM), MACOS)
    SUPPORTED_ARCH := x64
else
    $(error Unrecognized system $(SYSTEM), check system.mk)
endif

ifneq ($(findstring x86_64, $(ARCH)),)
    arch ?= x64
else ifeq ($(arch), x64)
    $(error Cannot build 64-bit architecture on 32-bit machine)
else
    arch ?= x86
endif

ifneq ($(arch), $(filter $(SUPPORTED_ARCH), $(arch)))
    $(error Architecture $(arch) not supported, check system.mk)
endif

# System-dependent shared library extension.
ifeq ($(SYSTEM), LINUX)
    SYSTEM_SHARED_LIB_EXTENSION := so
else ifeq ($(SYSTEM), MACOS)
    SYSTEM_SHARED_LIB_EXTENSION := dylib
else
    $(error Unknown system $(SYSTEM), check system.mk)
endif

# On macOS, detect system Xcode installation path.
ifeq ($(SYSTEM), MACOS)
    XCODE := $(shell xcode-select -p)
endif
