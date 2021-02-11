# Examples

These examples serve to demonstrate usage of the flymake build system.

The example folder contains a main `Makefile` which imports the flymake build system from its
default installation location. It contains the following example targets:

1. simple_c_example - A library created from a simple C project.
2. simple_c_example_tests - An example unit test of the simple C project.
3. simple_cpp_example - A library created from a simple C++ project.
4. simple_cpp_example_tests - An example unit test of the simple C++ project.
5. jar_example - An executable JAR file created from a Java project.

To build all of the above:

    make -C examples
