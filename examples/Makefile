# Example usage of the build system.

# Define the path to the source directory.
SOURCE_ROOT := $(CURDIR)

# Define the project version.
VERSION = 1.0.0

# Import the build API.
include /usr/local/src/fly/api.mk

# Main targets.
$(eval $(call ADD_TARGET, c_example, c, LIB))
$(eval $(call ADD_TARGET, cpp_example, cpp, LIB))
$(eval $(call ADD_TARGET, jar_example, jar/src/main/java, JAR))

# Test targets.
$(eval $(call ADD_TARGET, c_example_tests, c/test, TEST, c_example))
$(eval $(call ADD_TARGET, cpp_example_tests, cpp/test, TEST, cpp_example))

# Import the build system.
include /usr/local/src/fly/build.mk
