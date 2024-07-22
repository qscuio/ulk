all: userspace modules

ARCH := $(shell [ -f .arch ] && cat .arch)
KERNEL_VERSION := $(shell [ -f .kernel_version ] && cat .kernel_version)

# Actually, we need to compile the app inside the guest machine.
userspace:
	@echo "Compiling userspace..."
	make -C userspace

modules:
ifeq ($(ARCH),)
	@echo "ARCH is not set, skipping modules"
else
	@echo "Compiling modules for ARCH=$(ARCH)..."
	make -C modules ARCH=$(ARCH)
endif

clean_userspace:
	@echo "Cleaning userspace..."
	make -C userspace clean

clean_modules:
ifeq ($(ARCH),)
	@echo "ARCH is not set, skipping modules"
else
	@echo "Cleaning modules..."
	make -C modules clean
endif

debug-module:
ifeq ($(ARCH),)
	@echo "ARCH is not set, skipping modules"
else
	@echo "Buiding debug modules..."
	make -C modules $@
endif

clean:
	@echo "Cleaning all components..."
	make -C userspace clean
ifeq ($(ARCH),)
	@echo "ARCH is not set, skipping module clean"
else
	make -C modules clean
endif

reset: clean
	@echo "Resetting environment..."
	rm -rf *.log *.pid *.pub *.img *.id_rsa tar build kernel tools cores .arch .ssh .kernel_version .debootstrap .user_packages .prepare .profile .bash_history
	sudo rm -rf crash chroot libbpf-bootstrap retsnoop

patch:
ifeq ($(ARCH),)
	@echo "ARCH is not set, skipping patch creation"
else
	@echo "Creating patch for kernel version $(KERNEL_VERSION)..."
	find kernel -name *.rej | xargs rm -rf
	mkdir -p patch/linux-$(KERNEL_VERSION)
	-diff -urNa tar/linux-$(KERNEL_VERSION)/ kernel/linux-$(KERNEL_VERSION)/ > patch/linux-$(KERNEL_VERSION)/kernel.patch
	sed -i 's|tar/linux|kernel/linux|g' patch/linux-$(KERNEL_VERSION)/kernel.patch
endif

.PHONY: rootfs all apps modules kernel clean patch userspace cores

