SRC_DIRS_$(d) := \
    $(d)/inner_lib

CXXFLAGS_$(d) += \
    -DOUTER_VALUE=123

$(eval $(call WILDCARD_SOURCES, CPP))
