# Define functions to modify the directory stack. The stack works by maintaining these variables:
#
#     sp = The stack pointer.
#     pd = The previous directory.
#     d  = The current directory.
#
# Each time a directory is entered, the stack pointer is "incremented" by appending ".x" to the
# current value of the pointer. So, a value of ".x.x.x" would indicate we are 3 levels deep in the
# stack.
#
# The previous directory is stored on a per stack-level basis. This is to be able to include
# subdirectories without the current directory forgetting the previous directory.

# Push a directory to the stack. Default compiler and linker flags to the parent directory's flag
# values.
#
# $(1) = The path to the target root directory.
define PUSH_DIR

sp := $$(sp).x
pd_$$(sp) := $$(d)

p := $$(d)
d := $(abspath $(1))

ifneq ($$(p),)
    CFLAGS_$$(d) := $$(CFLAGS_$$(p))
    CXXFLAGS_$$(d) := $$(CXXFLAGS_$$(p))
    LDFLAGS_$$(d) := $$(LDFLAGS_$$(p))
    LDLIBS_$$(d) := $$(LDLIBS_$$(p))
    JFLAGS_$$(d) := $$(JFLAGS_$$(p))
endif

endef

# Pop a directory from the stack.
define POP_DIR

d := $$(pd_$$(sp))

sp := $$(basename $$(sp))

endef
