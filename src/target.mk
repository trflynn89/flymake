# Verify targets added via api.mk and define make goals for each of the targets. Before defining the
# targets, the following special variable is defined:
#
#     t = The current target for which rules should be generated.
#
# Any file in this build system may use this variable to define per-target variable instances. With
# this, the following per-target variables are defined:
#
#     TARGET_TYPE_$(t) = The target's type.
#     TARGET_PATH_$(t) = The target's source directory.
#     TARGET_FILE_$(t) = The target output files, dependent on the target type.
#     TARGET_PACKAGE_$(t) = The target's output archived release package.
#     TARGET_DEPENDENCIES_$(t) = Output files from other targets that this target depends on.
#
# $(TARGET_TYPE_$(t)) and $(TARGET_PATH_$(t)) are the values provided by the application Makefile
# via $(ADD_TARGET). $(TARGET_FILE_$(t)) will be the path to the generated binary, libraries, or JAR
# file. $(TARGET_PACKAGE_$(t)) will be the path to the archived release package defined via
# release.mk.  If this target is a binary target, $(TARGET_DEPENDENCIES_$(t)) will be the path to
# the generated libraries of other targets that this target depends on.
#
# Lastly, a make goal is defined for target $(t). This is a PHONY target for convenience to build
# $(TARGET_FILE_$(t)) and $(TARGET_PACKAGE_$(t)). Make goals for those are defined by compile.mk
# functions, invoked near the bottom of this file.

# List of all target release packages.
TARGET_PACKAGES :=

# List of all test target output binaries.
TEST_BINARIES :=

# Verify a single target and, if valid, define a make goal to build that target.
#
# $(1) = The target's name.
define DEFINE_TARGET

# Define the global variable $(t) to refer to the current target.
t := $(strip $(1))
.PHONY: $$(t)

# Define the path to the target output binary/library.
ifeq ($$(TARGET_TYPE_$$(t)), BIN)
    TARGET_FILE_$$(t) := $(BIN_DIR)/$$(t)

    ifneq ($$(filter $(TEST_TARGETS), $$(t)),)
        TEST_BINARIES += $$(TARGET_FILE_$$(t))
    endif
else ifeq ($$(TARGET_TYPE_$$(t)), LIB)
    TARGET_FILE_$$(t) := $(LIB_DIR)/$$(t)$(STATIC_LIB_EXTENSION)
    TARGET_FILE_$$(t) += $(LIB_DIR)/$$(t)$(SHARED_LIB_EXTENSION)
else ifeq ($$(TARGET_TYPE_$$(t)), JAR)
    TARGET_FILE_$$(t) := $(JAR_DIR)/$$(t)-$(VERSION).jar
else ifeq ($$(TARGET_TYPE_$$(t)), PKG)
    TARGET_FILE_$$(t) :=
else ifeq ($$(TARGET_TYPE_$$(t)), SCRIPT)
    ifeq ($$(TARGET_OUTPUT_$$(t)),)
        TARGET_FILE_$$(t) := $(GEN_DIR)/$$(t).stamp
    else
        TARGET_FILE_$$(t) := $$(addprefix $(GEN_DIR)/, $$(TARGET_OUTPUT_$$(t)))
    endif
else
    $$(error Target type $$(TARGET_TYPE_$$(t)) not supported)
endif

# Define the path to the target release package.
ifeq ($$(TARGET_TYPE_$$(t)), SCRIPT)
    TARGET_PACKAGE_$$(t) :=
else ifeq ($$(TARGET_TYPE_$$(t)), PKG)
    TARGET_PACKAGE_$$(t) := $(PKG_DIR)/$$(t)-$(VERSION).tar.bz2
else ifeq ($(SYSTEM), LINUX)
    TARGET_PACKAGE_$$(t) := $(ETC_DIR)/$$(t)-linux-$(VERSION).$(arch).tar.bz2
else ifeq ($(SYSTEM), MACOS)
    TARGET_PACKAGE_$$(t) := $(ETC_DIR)/$$(t)-macos-$(VERSION).$(arch).tar.bz2
else
    $$(error Unrecognized system $(SYSTEM), check target.mk)
endif

TARGET_PACKAGES += $$(TARGET_PACKAGE_$$(t))

# Define the make goal to build the targets.
$$(t): $$(TARGET_FILE_$$(t)) $$(TARGET_PACKAGE_$$(t))

TARGET_DEPENDENCY_FILES_$$(t) := \
    $$(foreach dep, $$(TARGET_DEPENDENCIES_$$(t)), $$(TARGET_FILE_$$(dep)))

# Define the compilation goals for the target.
ifeq ($$(TARGET_TYPE_$$(t)), BIN)
    $(call DEFINE_BIN_RULES, \
        $$(TARGET_PATH_$$(t)), \
        $$(TARGET_FILE_$$(t)), \
        $$(TARGET_PACKAGE_$$(t)), \
        $$(TARGET_DEPENDENCY_FILES_$$(t)))
else ifeq ($$(TARGET_TYPE_$$(t)), LIB)
    $(call DEFINE_LIB_RULES, \
        $$(TARGET_PATH_$$(t)), \
        $$(TARGET_FILE_$$(t)), \
        $$(TARGET_PACKAGE_$$(t)), \
        $$(TARGET_DEPENDENCY_FILES_$$(t)))
else ifeq ($$(TARGET_TYPE_$$(t)), JAR)
    $(call DEFINE_JAR_RULES, $$(TARGET_PATH_$$(t)), $$(TARGET_FILE_$$(t)), $$(TARGET_PACKAGE_$$(t)))
else ifeq ($$(TARGET_TYPE_$$(t)), PKG)
    $(call DEFINE_PKG_RULES, $$(TARGET_PATH_$$(t)), $$(TARGET_PACKAGE_$$(t)))
else ifeq ($$(TARGET_TYPE_$$(t)), SCRIPT)
    $(call DEFINE_SCRIPT_RULES, \
        $$(TARGET_PATH_$$(t)), \
        $$(TARGET_ARGS_$$(t)), \
        $$(TARGET_FILE_$$(t)), \
        $$(TARGET_DEPENDENCY_FILES_$$(t)))
endif

endef

$(foreach target, $(TARGETS), $(eval $(call DEFINE_TARGET, $(target))))
