SRC_DIR := $(M)

IGNORE_OBJS := 

SRC_FILES := $(wildcard $(SRC_DIR)/*.c)
OBJ_FILES := $(patsubst $(SRC_DIR)/%.c, %.o, $(SRC_FILES))

MODULES := $(filter-out $(IGNORE_OBJS), $(OBJ_FILES))
MODULES := $(filter-out %.mod.o, $(MODULES))

$(info Starting building kernel modules)

obj-m := $(MODULES)
