SRC_DIRS_$(d) := \
    $(d)/inner_lib

CXXFLAGS_$(d) += \
    -DOUTER_VALUE=123

SRC_$(d) := \
    $(d)/outer_lib.cpp
