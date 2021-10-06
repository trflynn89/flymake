# Define steps for generating an archived release package for a target. The APIs defined below may
# be used to add a file to the release package, or execute a command while creating the package. If
# none of these APIs are used, no release package will be created.
#
# Any shared libraries added to the release package will also include a chain of symbolic links
# which resolve to the real, versioned library defined by the application's Makefile. For example,
# if the Makefile defines $(VERSION) as "1.0.0" and invokes $(ADD_TARGET) for a LIB target with the
# name "libfly", the following symbolic link chain will be created under $(INSTALL_LIB_DIR):
#
#     libfly.so -> libfly.so.1 -> libfly.so.1.0 -> libfly.so.1.0.0 (the real file)
#
# The release package will also include an uninstall script with a simple $(RM) command to remove
# all files included in the release package.

# Build the release package.
define BUILD_REL

    echo -e "[$(YELLOW)Package$(DEFAULT) $(subst $(output)/,,$@)]"; \
    \
    $(RM) -r $(ETC_TMP_DIR) && \
    mkdir -p $(REL_BIN_DIR) $(REL_LIB_DIR) $(REL_INC_DIR) $(REL_SRC_DIR) \
    \
    $(REL_CMDS) && \
    cd $(ETC_TMP_DIR) && \
    \
    for f in $$(find .$(INSTALL_LIB_DIR) -type f -name "*\.$(SHARED_LIB_EXT)\.$(VERSION)") ; do \
        src=$${f:1}; \
        dst=$${src%.*}; \
        ext=$${src##*.}; \
        \
        while [[ "$$ext" != "$(SHARED_LIB_EXT)" ]] ; do \
            ln -sf $$src .$$dst; \
            \
            src=$$dst; \
            dst=$${dst%.*}; \
            ext=$${src##*.}; \
        done; \
    done; \
    \
    if [[ $$? -ne 0 ]] ; then \
        exit 1; \
    fi; \
    \
    echo "#!/usr/bin/env bash" > $(REL_BIN_DIR)/uninstall_$(REL_NAME); \
    chmod 755 $(REL_BIN_DIR)/uninstall_$(REL_NAME); \
    \
    files="$(subst $(ETC_TMP_DIR),,$(REL_UNINSTALL))"; \
    files="$$files $(INSTALL_BIN_DIR)/uninstall_$(REL_NAME)"; \
    echo $(SUDO) $(RM) -r "$$files" >> $(REL_BIN_DIR)/uninstall_$(REL_NAME); \
    \
    if [[ $(SYSTEM) == "LINUX" ]] ; then \
        echo $(SUDO) ldconfig >> $(REL_BIN_DIR)/uninstall_$(REL_NAME); \
    fi; \
    \
    tar $(TAR_CREATE_FLAGS) $@ *; \
    if [[ $$? -ne 0 ]] ; then \
        exit 1; \
    fi; \
    \
    $(RM) -r $(ETC_TMP_DIR)

endef

# Set the path and target variables for the release package.
define SET_REL_VAR

ifeq ($(TARGET_TYPE_$(t)), PKG)
    ETC_TMP_DIR_$(t) := $(PKG_DIR)/$(t)
else
    ETC_TMP_DIR_$(t) := $(ETC_DIR)/$(t)
endif

REL_NAME_$(t) := $(t)
REL_BIN_DIR_$(t) := $$(ETC_TMP_DIR_$(t))$(INSTALL_BIN_DIR)
REL_LIB_DIR_$(t) := $$(ETC_TMP_DIR_$(t))$(INSTALL_LIB_DIR)
REL_INC_DIR_$(t) := $$(ETC_TMP_DIR_$(t))$(INSTALL_INC_DIR)
REL_SRC_DIR_$(t) := $$(ETC_TMP_DIR_$(t))$(INSTALL_SRC_DIR)

endef

# Add a command to be run while building the release package.
#
# $(1) = The command to run.
define ADD_REL_CMD

REL_CMDS_$(t) := $(REL_CMDS_$(t)) && $(1)

endef

# Add a binary file to the release package. The file will be made executable and have its symbols
# stripped.
define ADD_REL_BIN

$(eval $(call SET_REL_VAR, $(t)))
$(eval $(call ADD_REL_CMD, cp -f $(BIN_DIR)/$(t) $(REL_BIN_DIR_$(t))))
$(eval $(call ADD_REL_CMD, $(STRIP) $(STRIP_FLAGS) $(REL_BIN_DIR_$(t))/$(t)))
$(eval $(call ADD_REL_CMD, chmod 755 $(REL_BIN_DIR_$(t))/$(t)))

REL_UNINSTALL_$(t) += $(REL_BIN_DIR_$(t))/$(t)
REL_FILES_$(t) += $(BIN_DIR)/$(t)

endef

# Add a shared library file to release package. The file will have its symbols stripped.
define ADD_REL_LIB

$(eval $(call SET_REL_VAR, $(t)))
$(eval $(call ADD_REL_CMD, cp -f $(LIB_DIR)/$(t).a $(REL_LIB_DIR_$(t))))
$(eval $(call ADD_REL_CMD, cp -f $(LIB_DIR)/$(t).$(SHARED_LIB_EXT).$(VERSION) $(REL_LIB_DIR_$(t))))
$(eval $(call ADD_REL_CMD, $(STRIP) $(STRIP_FLAGS) $(REL_LIB_DIR_$(t))/$(t).*))

REL_UNINSTALL_$(t) += $(REL_LIB_DIR_$(t))/$(t).*
REL_FILES_$(t) += $(LIB_DIR)/$(t).a
REL_FILES_$(t) += $(LIB_DIR)/$(t).$(SHARED_LIB_EXT).$(VERSION)

endef

# Add all header files under a directory to the release package.
#
# $(1) = The path to the directory.
# $(2) = Header file extension.
# $(3) = Header file destination under $(INSTALL_INC_DIR).
define ADD_REL_INC

$(eval $(call SET_REL_VAR, $(t)))
$(foreach f, $(call RECURSIVE_WILDCARD, $(1), $(2)), \
    $(eval $(call ADD_REL_FILE_IMPL, $(1), $(REL_INC_DIR_$(t))/$(strip $(3)))))

REL_UNINSTALL_$(t) += $(REL_INC_DIR_$(t))/$(strip $(3))

endef

# Add all source files under a directory to the release package.
#
# $(1) = The path to the directory.
# $(2) = Source file extension.
# $(3) = Source file destination under $(INSTALL_SRC_DIR).
define ADD_REL_SRC

$(eval $(call SET_REL_VAR, $(t)))
$(foreach f, $(call RECURSIVE_WILDCARD, $(1), $(2)), \
    $(eval $(call ADD_REL_FILE_IMPL, $(1), $(REL_SRC_DIR_$(t))/$(strip $(3)))))

REL_UNINSTALL_$(t) += $(REL_SRC_DIR_$(t))/$(strip $(3))

endef

# Helper to add a single file to the release package. The caller should define $(f), the path to the
# file to copy.
#
# $(1) = The path to the directory that was searched to find this file.
# $(2) = Source file destination.
define ADD_REL_FILE_IMPL

REL_OUT_$(f) := $(dir $(strip $(2))$(subst $(strip $(1)),,$(f)))

$$(eval $$(call ADD_REL_CMD, mkdir -p $$(REL_OUT_$(f))))
$$(eval $$(call ADD_REL_CMD, cp -fp $(f) $$(REL_OUT_$(f))))

REL_FILES_$(t) += $(f)

endef

# Wrapper around $(wildcard) to recursively find files of a given extension.
#
# $(1) = The path to the directory to search.
# $(2) = File extension to search for.
RECURSIVE_WILDCARD = $(foreach d, $(wildcard $(1:=/*)), \
    $(call RECURSIVE_WILDCARD, $d, $2) $(filter $(subst *, %, $2), $d))
