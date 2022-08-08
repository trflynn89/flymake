# Define the path to the source directory.
SOURCE_ROOT := $(CURDIR)

# Define the project version.
VERSION := 1.12.0

# Import the build API.
include $(SOURCE_ROOT)/src/api.mk

# Main targets.
$(eval $(call ADD_TARGET, flymake, ., PKG))

# Import the build system.
include $(SOURCE_ROOT)/src/build.mk
