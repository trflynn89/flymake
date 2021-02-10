# Set of API functions for using the build system. Applications using this build system should
# include this file first in their Makefile. Before including this file, the Makefile should define:
#
#     SOURCE_ROOT = The path from the Makfile to the application's source directory.
#     VERSION = The current application version, of the form X.Y.Z.
#
# The application then may use the APIs defined below to create their application targets and
# manipulate the build system's behavior.

# Verify expected variables.
ifeq ($(SOURCE_ROOT),)
    $(error SOURCE_ROOT must be defined)
else ifeq ($(wildcard $(SOURCE_ROOT)/.*),)
    $(error SOURCE_ROOT $(SOURCE_ROOT) does not exist)
endif

ifeq ($(VERSION),)
    $(error VERSION must be defined)
else ifneq ($(words $(subst ., ,$(VERSION))), 3)
    $(error VERSION $(VERSION) must be of the form X.Y.Z)
endif

# Add a target to the build system. The target name must be unique. This name will be used to
# generate file names for the target library/binary/etc. The target type may be one of:
#
#    BIN = The target is an executable binary compiled from C-family sources.
#
#    LIB = The target is a library compiled from C-family sources. Both static and shared libraries
#          will be created.
#
#    JAR = The target is an executable JAR file compiled from Java sources.
#
#    PKG = The target is a package of files.
#
#    TEST = An alias for BIN for unit testing targets.
#
# $(1) = The target's name.
# $(2) = The target's source directory relative to $(SOURCE_ROOT).
# $(3) = The target's type.
# $(4) = The target's dependencies.
define ADD_TARGET

ifeq ($$(strip $(1)), $$(filter $(TARGETS), $$(strip $(1))))
    $$(error Target $$(strip $(1)) has already been defined, check your Makefile)
endif

TARGETS += $(1)
TARGET_PATH_$$(strip $(1)) := $(2)
TARGET_DEPENDENCIES_$$(strip $(1)) := $(4)

ifeq ($(strip $(3)), TEST)
    TEST_TARGETS += $(1)
    TARGET_TYPE_$$(strip $(1)) := BIN
else
    TARGET_TYPE_$$(strip $(1)) := $(3)
endif

ifneq ($$(TARGET_DEPENDENCIES_$$(strip $(1))),)
    ifneq ($$(TARGET_TYPE_$$(strip $(1))), BIN)
        $$(error Target dependencies are only supported for binary targets, check your Makefile)
    endif

    $$(foreach dep, $$(TARGET_DEPENDENCIES_$$(strip $(1))), \
        $$(if $$(filter $(TARGETS), $$(dep)),, \
        $$(error Target dependency $$(dep) has not been defined, check your Makefile)))

    $$(foreach dep, $$(TARGET_DEPENDENCIES_$$(strip $(1))), \
        $$(if $$(filter $$(TARGET_TYPE_$$(dep)), LIB),, \
        $$(error Target dependency $$(dep) must be a library, check your Makefile)))
endif

endef

# Add a path to the style enforcement exclusion list. The path may be a directory or file.
#
# $(1) = The path relative to $(SOURCE_ROOT) to exclude.
define EXCLUDE_FROM_STYLE_ENFORCEMENT

ifeq ($$(wildcard $(SOURCE_ROOT)/$$(strip $(1))),)
    $$(error Could not find path $$(strip $(1)), check your Makefile)
endif

STYLE_ENFORCEMENT_EXCLUSIONS += $(1)

endef

# Add a path to the code coverage exclusion list. The path may be a directory or file.
#
# $(1) = The path relative to $(SOURCE_ROOT) to exclude.
define EXCLUDE_FROM_COVERAGE

ifeq ($$(wildcard $(SOURCE_ROOT)/$$(strip $(1))),)
    $$(error Could not find path $$(strip $(1)), check your Makefile)
endif

COVERAGE_EXCLUSIONS += $(1)

endef

# Add a path to the compilation database exclusion list. The path may be a directory or file.
#
# $(1) = The path relative to $(SOURCE_ROOT) to exclude.
define EXCLUDE_FROM_COMPILATION_DATABASE

ifeq ($$(wildcard $(SOURCE_ROOT)/$$(strip $(1))),)
    $$(error Could not find path $$(strip $(1)), check your Makefile)
endif

COMPILATION_DATABASE_EXCLUSIONS += $(1)

endef
