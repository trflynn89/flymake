# Example usage of the build system.

# Define the path to the source directory.
SOURCE_ROOT := $(CURDIR)

# Define the project version.
VERSION = 1.0.0

# Import the build API.
include /usr/local/src/fly/api.mk

# Main targets.
$(eval $(call ADD_TARGET, simple_c_example, simple_c, LIB))
$(eval $(call ADD_TARGET, simple_cpp_example, simple_cpp, LIB))
$(eval $(call ADD_TARGET, nested_cpp_example, nested_cpp, LIB))
$(eval $(call ADD_TARGET, jar_example, jar/src/main/java, JAR))

# Test targets.
$(eval $(call ADD_TARGET, simple_c_example_tests, simple_c/test, TEST, simple_c_example))
$(eval $(call ADD_TARGET, simple_cpp_example_tests, simple_cpp/test, TEST, simple_cpp_example))
$(eval $(call ADD_TARGET, nested_cpp_example_tests, nested_cpp/test, TEST, nested_cpp_example))

# Import the build system.
include /usr/local/src/fly/build.mk
