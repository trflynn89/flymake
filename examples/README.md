# Examples

These examples serve to demonstrate usage of the flymake build system.

The example folder contains a main `Makefile` which imports the flymake build system from its
default installation location. It contains the following example targets:

* simple_c_example - A library created from a simple C project.
* simple_c_example_tests - An example unit test of the simple C project.
* simple_cpp_example - A library created from a simple C++ project.
* simple_cpp_example_tests - An example unit test of the simple C++ project.
* nested_cpp_example - A library to demonstrate inheritance of compiler flags.
* nested_cpp_example_tests - An example unit test of the nested C++ project.
* generated_cpp_example - A library to demonstrate generation of source files.
* generated_cpp_example_tests - An example unit test of the generator C++ project.
* jar_example - An executable JAR file created from a Java project.

To build all of the above:

    make -C examples
