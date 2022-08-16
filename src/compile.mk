# Define make goals for compiling for all supported target types and the intermediate files they
# require. Each target source directory added via $(ADD_TARGET) may contain a file called files.mk.
# The contents expected of that file depend on the target type. This files.mk file is also where
# the APIs defined in release.mk may be used to create an archived release package.
#
# All variables defined in a files.mk file should be defined in terms of the special variable $(d):
#
#     d = The path to the directory containing the current files.mk file.
#
# This variable is defined and maintained by stack.mk. It is used to define variables of the same
# meaning on a per-source-directory basis.
#
# The files.mk for all target types may contain:
#
#     SRC_DIRS_$(d) = The source directories relative to $(d) to include in the build.
#     SRC_$(d) = The sources in this directory to build.
#
# The files.mk for target type JAR may additionally contain:
#
#     MAIN_CLASS_$(d) = (Required) The application entry point for the executable JAR.
#     CLASS_PATH_$(d) = The paths to any JARs or packages to reference for compilation.
#     RESOURCES_$(d) = The paths to any runtime resources to include in the executable JAR.
#
# Each directory added to $(SRC_DIRS_$(d)) may optionally contain a files.mk file to define
# variables specific to that directory.
#
# If a directory in $(SRC_DIRS_$(d)) does not contain a files.mk file, then $(SRC_$(d)) defaults to
# every source file in that directory.
#
# Any of the files.mk files may contain the per-directory compiler/linker flag extensions described
# in flags.mk.

# Define helper aliases for compiler/linker invocations.
COMP_CC = $(Q)$(CC) $(CFLAGS) $(1) -MF $$(@:%.o=%.d) -o $$@ -c $$<
LINK_CC = $(Q)$(CC) $(CFLAGS) $(2) -o $$@ $(1) $(LDFLAGS) $(3) $(LDLIBS) $(4)

COMP_CXX = $(Q)$(CXX) $(CXXFLAGS) $(1) -MF $$(@:%.o=%.d) -o $$@ -c $$<
LINK_CXX = $(Q)$(CXX) $(CXXFLAGS) $(2) -o $$@ $(1) $(LDFLAGS) $(3) $(LDLIBS) $(4)

COMP_JAVA = $(Q)$(JAVAC) $(JFLAGS) $(2) -d $(3) $(4) $(1)
LINK_JAVA = $(Q)$(JAR) $(JAR_CREATE_FLAGS) $(1) $$@ $(2)

STATIC = $(Q)$(AR) rcs $$@ $(1)

ifeq ($(SYSTEM), LINUX)
    SHARED_CC = $(Q)$(CC) $(CFLAGS) $(2) -shared -Wl,-soname,$$(@F) -o $$@ $(1) $(LDFLAGS) $(3)
    SHARED_CXX = $(Q)$(CXX) $(CXXFLAGS) $(2) -shared -Wl,-soname,$$(@F) -o $$@ $(1) $(LDFLAGS) $(3)
else ifeq ($(SYSTEM), MACOS)
    SHARED_CC = $(Q)$(CC) $(CFLAGS) $(2) -dynamiclib -o $$@ $(1) $(LDFLAGS) $(3)
    SHARED_CXX = $(Q)$(CXX) $(CXXFLAGS) $(2) -dynamiclib -o $$@ $(1) $(LDFLAGS) $(3)
else
    $(error Unrecognized system $(SYSTEM), check compile.mk)
endif

# Define the make goal to link a binary target from a set of object files.
#
# $(1) = The path to the target output binary.
define BIN_RULES

MAKEFILES_$(d) := $(BUILD_ROOT)/flags.mk $(wildcard $(d)/*.mk)

$(1): $$(OBJ_$$(t)) $$(MAKEFILES_$(d)) $$(GEN_STATIC_LIB_$$(t))
	@mkdir -p $$(@D)
	@echo -e "[$(RED)Link$(DEFAULT) $$(subst $(output)/,,$$@)]"
	$(call LINK_CXX, $(OBJ_$(t)), $(CXXFLAGS_$(d)), $(LDFLAGS_$(d)), \
		$(LDLIBS_$(d)) $(GEN_STATIC_LIB_$(t)))

endef

# Define the make goal to link static and shared targets from a set of object files.
#
# $(1) = The path to the target output files.
define LIB_RULES

MAKEFILES_$(d) := $(BUILD_ROOT)/flags.mk $(wildcard $(d)/*.mk)

STATIC_LIB_$$(t) := $(filter %$(STATIC_LIB_EXTENSION), $(1))
SHARED_LIB_$$(t) := $(filter %$(SHARED_LIB_EXTENSION), $(1))

$$(STATIC_LIB_$$(t)): $$(OBJ_$$(t)) $$(MAKEFILES_$(d))
	@mkdir -p $$(@D)
	@echo -e "[$(GREEN)Static$(DEFAULT) $$(subst $(output)/,,$$@)]"
	@$(RM) $$@
	$(call STATIC, $(OBJ_$(t)))

$$(SHARED_LIB_$$(t)): $$(OBJ_$$(t)) $$(MAKEFILES_$(d))
	@mkdir -p $$(@D)
	@echo -e "[$(GREEN)Shared$(DEFAULT) $$(subst $(output)/,,$$@)]"
	$(call SHARED_CXX, $(OBJ_$(t)), $(CXXFLAGS_$(d)), $(LDFLAGS_$(d)))

endef

# Define the make goal to compile Java files and link an executable JAR file from the compiled class
# files.
#
# $(1) = The path to the target output JAR file.
# $(2) = The application entry point.
define JAR_RULES

MAKEFILES_$(d) := $(BUILD_ROOT)/flags.mk $(wildcard $(d)/*.mk)

$(1): $$(SOURCES_$$(t)) $$(MAKEFILES_$(d))
	@# Remove the target's class directory as a safe measure in case Java files have been deleted.
	@$(RM) -r $(CLASS_DIR_$(t))
	@mkdir -p $$(@D) $(CLASS_DIR_$(t))

	@# Compile the Java source files into class files.
	@echo -e "[$(CYAN)Compile$(DEFAULT) $(strip $(2))]"
	$(call COMP_JAVA, $(SOURCES_$(t)), $(JFLAGS_$(d)), $(CLASS_DIR_$(t)), $(CLASS_PATH_$(t)))

	@# Iterate over every JAR file in the class path and extracts them for inclusion in the target.
	$(Q)for jar in $(CLASS_PATH_JAR_$(t)) ; do \
		unzip $(ZIP_EXTRACT_FLAGS) -o $$$$jar -d $(CLASS_DIR_$(t)) "*.class" ; \
	done

	@# Create the JAR archive from the compiled set of class files, the contents of the extracted
	@# dependent JARs, and the contents of any resource directories.
	@echo -e "[$(RED)JAR$(DEFAULT) $$(subst $(output)/,,$$@)]"
	$(call LINK_JAVA, $(2), $(CONTENTS_$(t)))

endef

# Define the make goal to generate an archived release package.
#
# $(1) = The path to the target release package.
define PKG_RULES

ifeq ($$(REL_CMDS_$$(t)),)

$(1):

else

MAKEFILES_$(d) := $(BUILD_ROOT)/release.mk $(wildcard $(d)/*.mk)

$(1): REL_CMDS := $$(REL_CMDS_$$(t))
$(1): REL_NAME := $$(REL_NAME_$$(t))
$(1): ETC_TMP_DIR := $$(ETC_TMP_DIR_$$(t))
$(1): REL_BIN_DIR := $$(REL_BIN_DIR_$$(t))
$(1): REL_LIB_DIR := $$(REL_LIB_DIR_$$(t))
$(1): REL_INC_DIR := $$(REL_INC_DIR_$$(t))
$(1): REL_SRC_DIR := $$(REL_SRC_DIR_$$(t))
$(1): REL_UNINSTALL := $$(REL_UNINSTALL_$$(t))

$(1): $$(MAKEFILES_$(d)) $$(REL_FILES_$$(t))
	$(Q)$$(BUILD_REL)

endif

endef

# Define the make goal to compile C-family files to object files.
#
# $(1) = Path to directory where object files should be created.
define OBJ_RULES

MAKEFILES_$(d) := $(BUILD_ROOT)/flags.mk $(wildcard $(d)/*.mk)

# C files.
$(1)/%.o: $(d)/%.c $$(MAKEFILES_$(d))
	@mkdir -p $$(@D)
	@echo -e "[$(CYAN)Compile$(DEFAULT) $$(subst $(SOURCE_ROOT)/,,$$<)]"
	$(call COMP_CC, $(CFLAGS_$(d)))

# CC files.
$(1)/%.o: $(d)/%.cc $$(MAKEFILES_$(d))
	@mkdir -p $$(@D)
	@echo -e "[$(CYAN)Compile$(DEFAULT) $$(subst $(SOURCE_ROOT)/,,$$<)]"
	$(call COMP_CXX, $(CXXFLAGS_$(d)))

# C++ files.
$(1)/%.o: $(d)/%.cpp $$(MAKEFILES_$(d))
	@mkdir -p $$(@D)
	@echo -e "[$(CYAN)Compile$(DEFAULT) $$(subst $(SOURCE_ROOT)/,,$$<)]"
	$(call COMP_CXX, $(CXXFLAGS_$(d)))

# Objective-C files.
$(1)/%.o: $(d)/%.m $$(MAKEFILES_$(d))
	@mkdir -p $$(@D)
	@echo -e "[$(CYAN)Compile$(DEFAULT) $$(subst $(SOURCE_ROOT)/,,$$<)]"
	$(call COMP_CC, $(CFLAGS_$(d)))

# Objective-C++ files.
$(1)/%.o: $(d)/%.mm $$(MAKEFILES_$(d))
	@mkdir -p $$(@D)
	@echo -e "[$(CYAN)Compile$(DEFAULT) $$(subst $(SOURCE_ROOT)/,,$$<)]"
	$(call COMP_CXX, $(CXXFLAGS_$(d)))

endef

# Define all make goals required to execute a script target.
#
# $(1) = The path to the script.
# $(2) = Space-separated arguments to pass to the script.
define SCRIPT_RULES

ifeq ($$(GEN_DIRS_$(d)),)
    GEN_TARGET_$$(t) := $(GEN_DIR)/$$(t).stamp
else
    GEN_TARGET_$$(t) := $$(foreach src, $$(GEN_SRC_$$(t)), $$(dir $$(src))%$$(suffix $$(src)))
    GEN_TARGET_$$(t) += $$(foreach inc, $$(GEN_INC_$$(t)), $$(dir $$(inc))%$$(suffix $$(inc)))
endif

$$(GEN_TARGET_$$(t)): $(1)
	@echo -e "[$(YELLOW)Script$(DEFAULT) $(t)]"
	@mkdir -p $(GEN_DIR) $(DATA_DIR)

	$(Q)sources=($$(foreach source, $(GEN_SRC_$(t)) $(GEN_INC_$(t)), "$$(source)")); \
	arguments=($$(foreach argument, $(2), "$$(argument)")); \
	\
	for source in "$$$${sources[@]}" ; do \
		mkdir -p $$$${source%/*}; \
		$(RM) $$$$source; \
	done; \
	\
	$(1) $(GEN_DIR) $(DATA_DIR) $$$${arguments[@]}; \
	status=$$$$?; \
	\
	if [[ $$$$status -ne 0 ]] ; then \
		echo -e "[$(RED)ERROR$(DEFAULT)] Target $(t) exited with fatal error code: $$$$status"; \
		exit 1; \
	fi; \
	\
	for source in "$$$${sources[@]}" ; do \
		if [[ ! -f $$$$source ]] ; then \
			echo -e "[$(RED)ERROR$(DEFAULT)] Target $(t) did not generate: $$$${source##*/}"; \
			exit 1; \
		fi \
	done

ifeq ($$(GEN_DIRS_$(d)),)
	@touch $$@
endif

endef

# Define the list of source files to all files in the current directory.
#
# $(1) - Family (CPP or JAVA) of files to wildcard.
define WILDCARD_SOURCES

ifeq ($(strip $(1)), CPP)
    SRC_$(d) := $$(foreach ext, $(C_SRC_EXTENSIONS), $$(wildcard $(d)/*$$(ext)))
else ifeq ($(strip $(1)), JAVA)
    SRC_$(d) := $$(foreach ext, $(JAVA_EXTENSIONS), $$(wildcard $(d)/*$$(ext)))
endif

endef

# Define all make goals required to build a target of type BIN (or TEST).
#
# $(1) = The path to the target root directory.
# $(2) = The path to the target output binary.
# $(3) = The path to the target release package.
# $(4) = The path(s) to the target dependency files.
define DEFINE_BIN_RULES

# Push the current directory to the stack.
$$(eval $$(call PUSH_DIR, $(strip $(1))))

# Define source, object, dependency, and binary files.
ifeq ($$(wildcard $$(d)/files.mk),)
    $$(eval $$(call WILDCARD_SOURCES, CPP))
else
    include $$(d)/files.mk
endif

$$(eval $$(call OBJ_OUT_FILES, $(SOURCE_ROOT), $$(SRC_$$(d))))
$$(eval $$(call GEN_OUT_FILES, $(4)))

# Include the source directories.
$$(foreach dir, $$(SRC_DIRS_$$(d)), $$(eval $$(call DEFINE_OBJ_RULES, $(SOURCE_ROOT), $$(dir))))
$$(foreach dir, $$(GEN_DIRS_$$(d)), $$(eval $$(call DEFINE_OBJ_RULES, $(GEN_DIR), $$(dir))))

# Define the compile rules.
$$(eval $$(call BIN_RULES, $(2)))
$$(eval $$(call PKG_RULES, $(3)))
$$(eval $$(call OBJ_RULES, $$(OBJ_DIR_$$(d))))

# Include dependency files.
-include $$(DEP_$$(d))

# Pop the current directory from the stack.
$$(eval $$(call POP_DIR))

endef

# Define all make goals required to build a target of type LIB.
#
# $(1) = The path to the target root directory.
# $(2) = The path to the target output libraries.
# $(3) = The path to the target release package.
# $(4) = The path(s) to the target dependency files.
define DEFINE_LIB_RULES

# Push the current directory to the stack.
$$(eval $$(call PUSH_DIR, $(strip $(1))))

# Define source, object, dependency, and binary files.
ifeq ($$(wildcard $$(d)/files.mk),)
    $$(eval $$(call WILDCARD_SOURCES, CPP))
else
    include $$(d)/files.mk
endif

$$(eval $$(call OBJ_OUT_FILES, $(SOURCE_ROOT), $$(SRC_$$(d))))
$$(eval $$(call GEN_OUT_FILES, $(4)))

# Include the source directories.
$$(foreach dir, $$(SRC_DIRS_$$(d)), $$(eval $$(call DEFINE_OBJ_RULES, $(SOURCE_ROOT), $$(dir))))
$$(foreach dir, $$(GEN_DIRS_$$(d)), $$(eval $$(call DEFINE_OBJ_RULES, $(GEN_DIR), $$(dir))))

# Define the compile rules.
$$(eval $$(call LIB_RULES, $(2)))
$$(eval $$(call PKG_RULES, $(3)))
$$(eval $$(call OBJ_RULES, $$(OBJ_DIR_$$(d))))

# Include dependency files.
-include $$(DEP_$$(d))

# Pop the current directory from the stack.
$$(eval $$(call POP_DIR))

endef

# Define all make goals required to build a target of type JAR.
#
# $(1) = The path to the target root directory.
# $(2) = The path to the target output JAR file.
# $(3) = The path to the target release package.
define DEFINE_JAR_RULES

# Push the current directory to the stack.
$$(eval $$(call PUSH_DIR, $(strip $(1))))

# Define source, class, and generated files.
include $$(d)/files.mk
$$(eval $$(call JAVA_SRC_FILES, $$(SRC_$$(d))))
$$(eval $$(call JAVA_JAR_FILES, $$(CLASS_PATH_$$(d)), $$(RESOURCES_$$(d))))

# Include the source directories.
$$(foreach dir, $$(SRC_DIRS_$$(d)), $$(eval $$(call DEFINE_JAVA_RULES, $$(dir))))

# Define the compile rules.
$$(eval $$(call JAR_RULES, $(2), $$(MAIN_CLASS_$$(d))))
$$(eval $$(call PKG_RULES, $(3)))

# Pop the current directory from the stack.
$$(eval $$(call POP_DIR))

endef

# Define all make goals and intermediate files required to compile C-family files.
#
# $(1) = The root directory (either $(SOURCE_ROOT) or the generated source directory).
# $(2) = The path to the source directory.
define DEFINE_OBJ_RULES

# Push the current directory to the stack.
$$(eval $$(call PUSH_DIR, $(2)))

# Define source, object and dependency files.
ifeq ($(strip $(1)), $(GEN_DIR))
    SRC_$$(d) := $$(foreach ext, $(C_SRC_EXTENSIONS), $$(filter $$(d)/%$$(ext), $$(GEN_SRC_$$(t))))
else ifeq ($$(wildcard $$(d)/files.mk),)
    $$(eval $$(call WILDCARD_SOURCES, CPP))
else
    include $$(d)/files.mk
endif

$$(eval $$(call OBJ_OUT_FILES, $(1), $$(SRC_$$(d))))

# Include the source directories.
$$(foreach dir, $$(SRC_DIRS_$$(d)), $$(eval $$(call DEFINE_OBJ_RULES, $(1), $$(dir))))

# Define the compile rules.
$$(eval $$(call OBJ_RULES, $$(OBJ_DIR_$$(d))))

# Include dependency files.
-include $$(DEP_$$(d))

# Pop the current directory from the stack.
$$(eval $$(call POP_DIR))

endef

# Define all make goals and intermediate files required to compile Java files.
#
# $(1) = The path to the source directory.
define DEFINE_JAVA_RULES

# Push the current directory to the stack.
$$(eval $$(call PUSH_DIR, $(1)))

# Define source, object and dependency files.
ifeq ($$(wildcard $$(d)/files.mk),)
    $$(eval $$(call WILDCARD_SOURCES, JAVA))
else
    include $$(d)/files.mk
endif

$$(eval $$(call JAVA_SRC_FILES, $$(SRC_$$(d))))

# Pop the current directory from the stack.
$$(eval $$(call POP_DIR))

endef

# Define all make goals required to build a target of type PKG.
#
# $(1) = The path to the target root directory.
# $(2) = The path to the target release package.
define DEFINE_PKG_RULES

# Push the current directory to the stack.
$$(eval $$(call PUSH_DIR, $(1)))

# Define source, class, and generated files.
include $$(d)/files.mk

# Define the packaging rules.
$$(eval $$(call PKG_RULES, $(2)))

# Pop the current directory from the stack.
$$(eval $$(call POP_DIR))

endef

# Define all make goals required to execute a script target.
#
# $(1) = The path to the script.
# $(2) = Space-separated arguments to pass to the script.
# $(3) = The path(s) to the generated target files.
define DEFINE_SCRIPT_RULES

# Push the current directory to the stack.
$$(eval $$(call PUSH_DIR, $(dir $(1))))

$$(eval $$(call GEN_OUT_FILES, $(3)))

# Define the script rules.
$$(eval $$(call SCRIPT_RULES, $(1), $(2)))

# Pop the current directory from the stack.
$$(eval $$(call POP_DIR))

endef
