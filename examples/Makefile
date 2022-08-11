# Example usage of the build system.

# Define the path to the source directory.
SOURCE_ROOT := $(CURDIR)

# Define the project version.
VERSION = 1.0.0

# Import the build API.
include /usr/local/src/fly/api.mk

# Generated targets.
$(eval $(call ADD_SCRIPT, \
    generate_foo_sources, \
    generated_cpp/generate_sources.sh, \
    foo, \
    foo/generated.hpp foo/generated.cpp))

$(eval $(call ADD_SCRIPT, \
    generate_bar_sources, \
    generated_cpp/generate_sources.sh, \
    bar, \
    bar/generated.hpp bar/generated.cpp))

$(eval $(call ADD_SCRIPT, true, generated_cpp/true.sh))

# Main targets.
$(eval $(call ADD_TARGET, simple_c_example, simple_c, LIB))
$(eval $(call ADD_TARGET, simple_cpp_example, simple_cpp, LIB))
$(eval $(call ADD_TARGET, nested_cpp_example, nested_cpp, LIB))
$(eval $(call ADD_TARGET, generated_cpp_example, generated_cpp, LIB, generate_foo_sources))
$(eval $(call ADD_TARGET, jar_example, jar/src/main/java, JAR))

# Test targets.
$(eval $(call ADD_TARGET, simple_c_example_tests, simple_c/test, TEST, simple_c_example))
$(eval $(call ADD_TARGET, simple_cpp_example_tests, simple_cpp/test, TEST, simple_cpp_example))
$(eval $(call ADD_TARGET, nested_cpp_example_tests, nested_cpp/test, TEST, nested_cpp_example))
$(eval $(call ADD_TARGET, \
    generated_cpp_example_tests, \
    generated_cpp/test, \
    TEST, \
    generate_bar_sources generated_cpp_example true))

# Import the build system.
include /usr/local/src/fly/build.mk
