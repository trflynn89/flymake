# flymake

[![Build Status](https://dev.azure.com/trflynn89/libfly/_apis/build/status/trflynn89.flymake?branchName=main)](https://dev.azure.com/trflynn89/libfly/_build/latest?definitionId=6&branchName=main)

flymake is a parallel, non-recusrive GNU Makefile system for C/C++/Java projects. The goal is to
provide a system that is simple to use, requires minimal boilerplate, and produces fast builds.

## Installation

Installing flymake may be done from source or from a stable release package.

To install from source:

```bash
make install
```

To install from a release package, download the [latest release](https://github.com/trflynn89/flymake/releases)
and extract the downloaded archive in the root system directory:

```bash
tar -C / -xjf flymake-[version].tar.bz2
```

By default, both of the above methods will install flymake into `/usr/local/src/fly/`. It will also
install an uninstallation script into `/usr/local/bin/uninstall_flymake`. This location may be
overriden when installing from source:

```bash
make INSTALL_ROOT=$HOME install
```

This will install flymake into your home directory (`~/src/fly/` and `~/bin/uninstall_flymake`).

## Usage

In general, using flymake is as simple as defining the targets you want to build and the paths to
the source files for those targets.

The only required file is a Makefile, which may exist anywhere in your project. This Makefile must
define the following two variables:

* `SOURCE_ROOT` - The path to the the root directory of the project. All targets should fall under
  this path. This path will be added to the include path for all targets.
* `VERSION` - The current version of the project, using semantic versioning.

The Makefile should then import the flymake API for defining targets, `api.mk`. Use the `ADD_TARGET`
function to define the targets for your project. Usage of `ADD_TARGET` is as follows:

```make
$(eval $(call ADD_TARGET, [target name], [target path], [target type], [target dependencies]))
```

* Target name - A unique identifier for the target. This is used to generate the names for the
  output files created during the build, depending on the target type.
* Target path - The path, relative to `SOURCE_ROOT`, to the root directory containing the source
  files for this target.
* Target type - One of `BIN`, `LIB`, `JAR`, or `TEST`:
    * `BIN` - The target is an executable binary compiled from C-family sources. The executable's
      name will be the target name.
    * `LIB` - The target is a library compiled from C-family sources. Both static and shared
      libraries will be created.
    * `JAR` - The target is an executable JAR file compiled from Java sources.
    * `TEST` - An alias for `BIN` for unit testing targets.
* Target dependencies (optional) - If this target depends on other, previously defined targets in
  the Makefile, list those target names here (space-separated if multiple). Dependencies are
  currently only supported for `BIN` targets whose dependencies are all `LIB` targets. Those `LIB`
  targets will be built first, and will be automatically linked into the `BIN` target.

With all targets defined, the last step is to import the flymake build system, `build.mk`. This will
generate all of the Make goals required to build the defined targets, as well as goals to e.g. run
unit tests, generate code coverage reports, etc. (see [Make goals](#make-goals)).

### Simple C-family example

For example, if the layout of your project is as follows:

```
├── build/
│   └── Makefile
├── lib/
│   ├── foo.hpp
│   ├── foo.cpp
│   ├── bar.hpp
│   └── bar.cpp
├── bin/
│   └── main.cpp
└── test/
    ├── main.cpp
    ├── foo.cpp
    └── bar.cpp
```

The Makefile may be:

```make
SOURCE_ROOT := $(CURDIR)/..
VERSION := 1.0.0

include /usr/local/src/fly/api.mk

$(eval $(call ADD_TARGET, main_library, lib, LIB))
$(eval $(call ADD_TARGET, main_executable, bin, BIN, main_library))
$(eval $(call ADD_TARGET, unit_tests, test, TEST, main_library))

include /usr/local/src/fly/build.mk
```

That's it! You can run `make -C build` to build the entire project, or selectively build individual
targets with e.g. `make -C build main_library`.

### More realistic C-family example

The above example contains a rather flat directory structure - all targets are self-contained and
do not have nested subdirectories.

By default, flymake will find and build all source files in each target path. However, if your
project is large, or has platform-specific files that shouldn't always be compiled, a bit more setup
is required. Specifying subdirectories and specific source files to build involves adding a file
called `files.mk`.

Generally, a `files.mk` file would be added to the root target path to define the subdirectories to
build. Additionally, a `files.mk` file may be added to any of those subdirectories to explicitly
declare the source files to build. The following variables may be used to define these:

* `SRC_DIRS_$(d)` - The list of subdirectories (relative to `SOURCE_ROOT`) to build.
* `SRC_$(d)` - The list of source files (in this directory) to build.

> Note the variable `d` used here. This is a special variable that is defined just before each
`files.mk` file is included. It is the path, prefixed with `SOURCE_ROOT`, to the directory of the
current `files.mk`. This variable exists because flymake is a non-recursive build system (meaning
the entire build for all targets occurs in one Make process). Thus, this variable is used whenever
a variable might be defined in more than one `files.mk` file to avoid naming conflicts.

For example, if the layout of your project is as follows:

```
├── build/
│   └── Makefile
├── lib/
│   ├── files.mk
│   ├── lib.hpp
│   ├── lib.cpp
│   ├── foo/
│   │   ├── foo.hpp
│   │   └── foo.cpp
│   └── bar/
│       ├── files.mk
│       ├── bar.hpp
│       ├── bar_linux.cpp
│       └── bar_windows.cpp
├── bin/
│   └── main.cpp
└── test/
    ├── main.cpp
    ├── foo.cpp
    └── bar.cpp
```

The main Makefile from the simple example does not change. However, this example adds subdirectories
to `lib` with their own source files, some of which maybe should not be included in the build of
`main_library`.

The `files.mk` files should be written as follows to handle these nuances:

`lib/files.mk`: (here, `d` = `/path/to/lib`)
```make
SRC_DIRS_$(d) := lib/foo lib/bar
SRC_$(d) := $(d)/lib.cpp
```

`lib/bar/files.mk`: (here, `d` = `/path/to/lib/bar`)
```make
SRC_$(d) := $(d)/bar_linux.cpp
```

> Important: The presence of a `files.mk` file disables the automatic detection of source files for
that directory only. If you add a files.mk to a directory, you must explicitly define its source
files.

### Java example

Warning: Java support with flymake is currently experimental and rudimentary. It is subject to
change at any time. Currently, only executable JAR files may be created.

Just like with C-family targets, Java targets use `files.mk` files to define variables required to
build an executable JAR. `SRC_DIRS_$(d)` and `SRC_$(d)` have the same meaning for Java targets.
Additionally, a Java target's `files.mk` file may contain:

* `MAIN_CLASS_$(d)` - (Required) The application entry point for the executable JAR.
* `CLASS_PATH_$(d)` - The paths to any third-party JARs or packages to reference for compilation.
* `RESOURCES_$(d)` - The paths to any runtime resources to include in the executable JAR.

For example, if the layout of your project is as follows:

```
├── build/
│   └── Makefile
├── lib/com/third_party/library/
│   └── library.jar
└── src/main/
    ├── java/
    │   ├── files.mk
    │   └── com/project/example/
    │       └── App.java
    └── resources/images/
        └── logo.png
```

Where `library.jar` is a third-party library used by the Java target, and `src/resources/images/` is
a directory of resources to bundle in the executable JAR. The Makefile may be:

```make
SOURCE_ROOT := $(CURDIR)/..
VERSION := 1.0.0

include /usr/local/src/fly/api.mk

$(eval $(call ADD_TARGET, jar_example, src/main/java, JAR))

include /usr/local/src/fly/build.mk
```

There is a single `files.mk` file under `src/main/java` to define the variables required for the
`jar_example` target. It may contain:

```make
SRC_DIRS_$(d) := src/main/java/com/project/example
MAIN_CLASS_$(d) := com.project.example.App
CLASS_PATH_$(d) := $(d)/../../../lib/com/third_party/library/library.jar
RESOURCES_$(d) := $(d)/../resources/images
```

## Make goals

As noted above, running `make` without specifying any Make goals will build all defined targets.
Each target name is also defined as a Make goal for convenience.

The following primary goals are defined by flymake:

* `all` - (Default) Build all targets defined in the Makfile.
* `clean` - Remove the artifact directory for the current build configuration (see
  [Build configuration](#build-configuration)).
* `tests` - Run all unit tests defined in the Makefile with the `TEST` target type.
* `install` - Extract any target release package created during the build in the file system root
  directory (see [Release packages](#release-packages)).

The following secondary goals are defined by flymake to aid in development:

* `commands` - Create a `clangd` compliation database for the current build configuration.
* `coverage` - Generate a code coverage report of the last unit test execution.
* `profile` - Run all unit tests and generate a profile report of the unit test execution (see
  `gcc`'s `-pg` flag).
* `style` - Run `clang-format` on all source files under `SOURCE_ROOT`.
* `setup` - Install (via the system's package manager) tools used by the flymake build system, such
  as `gcc`, `clang`, `clang-format`, etc.

## Build configuration

The following options may be specified to configure the build:

| Option        | Accepted Values               | Default Value                 | Description |
| :--           | :--                           | :--                           | :--         |
| `output`      | Any directory                 | `CURDIR`                      | Build artifact directory (see [Build artifacts](#build-artifacts)). |
| `toolchain`   | `clang`, `gcc`, `none`        | `clang`                       | Compilation toolchain for C-family targets (see (1) below). |
| `mode`        | `debug`, `release`, `profile` | `debug`                       | Compilation mode (see (2) below). |
| `arch`        | `x86`, `x64`                  | Defaults to host architecture | Compilation architecture, 32-bit or 64-bit. |
| `strict`      | `0`, `1`, `2`                 | `2`                           | Compiler warning level (see (3) below). |
| `cstandard`   | See description               | `c2x`                         | The language standard to use for C files, passed directly to `-std`. |
| `cxxstandard` | See description               | `c++2a`                       | The language standard to use for C++ files, passed directly to `-std`. |
| `cacher`      | See description               | None                          | Enable use of a compilation cache (see (4) below). |
| `stylized`    | `0`, `1`                      | `1`                           | Enable pretty build output. |
| `verbose`     | `0`, `1`                      | `0`                           | Enable verbose build output. |

These options make be specified either via the command line (e.g. `make mode=release`), or by
setting them in the main Makefile before importing `build.mk`. The latter allows for changing the
defaults for the project.

1. flymake supports GCC and Clang toolchains out of the box, and will use Clang by default. Other
   toolchains have not been tested, but may be used by setting `toolchain=none`. If this is set,
   you must also define the following:

    * `CC` - Compiler for C files.
    * `CXX` - Compiler for C++ files.
    * `AR` - Archive tool for creating static libraries.
    * `STRIP` - Strip tool for discarding symbols from build artifacts.

2. Compilation mode changes the build flags used to build source files:

    * `debug` - Debugging symbols and code coverage instrumentation are added to compiled sources.
      For C-family targets, AddressSanitizer and UndefinedBehaviorSanitizer are enabled.
    * `release` - Builds are optimized and all debugging information is removed.
    * `profile` - Builds are optimized and profiling symbols are added for generation of profile
      reports. Currently only supported if the `toolchain` is `gcc`.

3. By default, flymake enables a strict set of compiler warnings. This may not be desired for all
   projects, so the warning level may be globablly reduced or disabled. For locally amending warning
   flags, see [Advanced build configuration](#advanced-build-configuration). The warning levels are:

   * `0` - Disable all warnings.
   * `1` - Enable `-Wall -Wextra -Werror`.
   * `2` - Enable `-pedantic` and more. See [flags.mk](src/flags.mk) for all warnings that are set.

4. By default, a compilation cache is not used. If you would like to use a compilation cache, set
   `cacher` to the cache binary to use (e.g. `cacher=ccache`).

## Build artifacts

All build artifacts are created under a hierarchy of subdirectories under the directory specified by
the `output` option (which defaults to the directory of the main Makefile). That hierarchy is
controlled by other build configuration options.

* C-family targets - The artifacts will appear in the path `$(output)/$(mode)/$(toolchain)/$(arch)`;
  with the default options listed above, the default path will be `$(CURDIR)/debug/clang/x64` on
  64-bit hosts. The following subdirectories will be created as needed by the build:

    * `bin` - Contains executable files created for `BIN` and `TEST` targets.
    * `lib` - Contains static and shared library files created for `LIB` targets.
    * `obj` - Contains intermediate object (`.o`) and dependency (`.d`) files compiled from source
      files.
    * `etc` - Contains any extra files created during the build or by one of the secondary Make
      goals, such as code coverage and profile reports. Also contains any release package created
      during the build (see [Release packages](#release-packages)).

* Java targets - The artifacts will appear in the path `$(output)/$(mode)/javac`; with the default
  options listed above, the default path will be `$(CURDIR)/debug/javac`. The following
  subdirectories will be created as needed by the build:

    * `bin` - Contains executable JAR files created for `JAR` targets.
    * `classes` - Contains intermediate class (`.class`) files compiled from source files. Class
      files from any third-party JARs or packages specified via `CLASS_PATH_$(d)` are also
      extracted/copied here.

## Release packages

flymake supports creating a release package bundled as a `.tar.bz2` containing any desired build
artifacts or source files. By default, the package will install files under `/usr/local/`, but this
is configurable by setting `INSTALL_ROOT` on the `make` command line.

A set of APIs is available to each target's `files.mk` file for creating a release package:

```make
$(eval $(call ADD_REL_BIN))
$(eval $(call ADD_REL_LIB))
$(eval $(call ADD_REL_INC, [directory], [header file extension], [header file destination]))
$(eval $(call ADD_REL_SRC, [directory], [source file extension], [source file destination]))
```

* `ADD_REL_BIN` - Add the executable file created for `BIN` targets to the release package.
  Executable files will be installed to `$(INSTALL_ROOT)/bin/`.
* `ADD_REL_LIB` - Add the static and shared library files created for `LIB` targets to the release
  package. Library files will be installed to `$(INSTALL_ROOT)/lib/`.
* `ADD_REL_INC` - Add header files from the project to the release package. Requires specifying the
  path to the directory containing the header files, the extension of the header files to bundle,
  and the subdirectory under the installation directory to place the header files. Header files will
  be installed to `$(INSTALL_ROOT)/include/$(specified subdirectory)`.
* `ADD_REL_SRC` - Add source files from the project to the release package. Requires specifying the
  path to the directory containing the source files, the extension of the source files to bundle,
  and the subdirectory under the installation directory to place the source files. Source files will
  be installed to `$(INSTALL_ROOT)/src/$(specified subdirectory)`.

If any of the above APIs are used by a target, the release package is created after the target is
built. It may be installed manually or by the `install` goal. There will also be an uninstallation
script created into `$(INSTALL_ROOT)/bin/uninstall_$(target name)` to remove the installed files.

## Advanced build configuration

Each `files.mk` file may specify compiler and linker flags to be applied to files in that directory.
The following variables may be defined:

* `CFLAGS_$(d)` - Compiler flags for C and Objective-C files.
* `CXXFLAGS_$(d)` - Compiler flags for C++ and Objective-C++ files.
* `LDFLAGS_$(d)` - Linker flags for C-family targets.
* `LDLIBS_$(d)` - Libraries to link for C-family targets.

These variables are defaulted to the values of the directory which included this directory via
`SRC_DIRS_$(d)`. Thus, these variables should generally be treated as append-only (i.e. modified
with `+=`). But this inheritance may be avoided by assigning instead (`:=`).

The reason for this inheritance is the target-level `files.mk` file may, for example, add a
third-party library to the include path via the `-I` flag. Inheritance of these flags means that
each subdirectory does not also need to update the include path.

The resulting flags used when compiling and linking files in a directory are the global flags
defined in `flags.mk` followed by any of the per-directory variants listed above.
