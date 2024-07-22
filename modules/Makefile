BUILD_DIR := $(PWD)/build
KERNEL_DIR := $(PWD)/kernel
MODULES_DIR := $(PWD)/modules
MODULES_DEBUG_DIR := $(PWD)/modules/debug
INSTALL_MOD_PATH := $(PWD)/chroot
EXTRA_CFLAGS := -I$(MODULES_DEBUG_DIR)
SUBDIRS := $(sort $(wildcard $(MODULES_DIR)/*/))

IGNORE_NAMES := 
IGNORE_DIRS := $(addprefix $(MODULES_DIR)/, $(IGNORE_NAMES))

SUBDIRS := $(filter-out $(IGNORE_DIRS), $(SUBDIRS))

all: modules_build

debug-module:
	$(MAKE) -C $(BUILD_DIR)/ M=$(abspath $(MODULES_DEBUG_DIR)) EXTRA_CFLAGS+="$(EXTRA_CFLAGS)" 

modules_build:
	@$(foreach dir,$(SUBDIRS), $(MAKE) -C $(BUILD_DIR)/ M=$(abspath $(dir)) EXTRA_CFLAGS+="$(EXTRA_CFLAGS)";)

clean:
	@$(foreach dir,$(SUBDIRS), $(MAKE) -C $(BUILD_DIR)/ M=$(abspath $(dir)) clean;)

.PHONY: all modules_build clean

