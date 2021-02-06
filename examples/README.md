# flymake Build System Examples

These examples serve to demonstrate usage of the flymake build system.

## Installing flymake

Installing flymake may be done from source or from a stable release package.

To install from source:

    make install

To install from a release package, download the [latest release](https://github.com/trflynn89/flymake/releases)
and extract the downloaded `.tar.bz2` in the root system directory:

    tar -C / -xjf flymake-[version].tar.bz2

Note: On macOS you may need to add `-mo` to the `tar` command.

## Example

The usage example contains a main `Makefile` which imports the flymake build system from its
installed location. It contains the following example targets:

1. flymake_c_example - A binary created from a C project.
2. flymake_c_example_tests - An example unit test of the C project.
3. flymake_cpp_example - A binary created from a C++ project.
4. flymake_cpp_example_tests - An example unit test of the C++ project.
5. flymake_jar_example - An executable JAR file created from a Java project.

To build all of the above:

    make -C examples
