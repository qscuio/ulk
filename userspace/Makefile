CUR_DIR=$(shell pwd)

CC=gcc

CURDIR=`pwd`
DEPDIR=$(CURDIR)/.deps

DEP_CFLAGS:= -MD

CFLAGS:= -rdynamic
#CLFAGS+= $(DEP_CFLAGS)
CFLAGS+= -MD
CFLAGS+= -Wall -Werror -g -Wno-deprecated-declarations -Wno-unknown-pragmas -Wno-unused-variable
#CFLAGS+= -fsanitize=address -fno-omit-frame-pointer -fsanitize-recover=address -fsanitize-address-use-after-scope -static-libasan
CFLAGS+= -I$(CUR_DIR)/lib 

EXTRA_CFLAGS:= -Wa,-alh,-L -fverbose-asm

#LDFLAGS:= -fsanitize=address -fno-omit-frame-pointer -fsanitize-recover=address -fsanitize-address-use-after-scope -static-libasan
LDFLAGS+= -L$(CUR_DIR)/lib -Wl,-rpath=$(CUR_DIR)/lib -lpthread -lunbound -lrt -lssl -lcrypto -lcunit -lunwind -luv -lcurl -lbsd  -lm
APP_LDFLAGS+= $(LDFLAGS) -lw 

# Print log does not exist
#ASAN="ASAN_OPTIONS=quarantine_size_mb=1024,log_path=./asan.log,log_to_syslog=true,fast_unwind_on_malloc=0,disable_coredump=false,halt_on_error=false"

# Print log and panic
ASAN="ASAN_OPTIONS=quarantine_size_mb=1024,log_path=./asan.log,log_to_syslog=true,fast_unwind_on_malloc=0,disable_coredump=false,abort_on_error=true"

# sudo apt-get install libcunit1 libcunit1-doc libcunit1-dev
# sudo apt-get install libaio-dev
# sudo apt-get install libunbound-dev
# sudo apt-get install libssl-dev
# sudo apt-get install libunwind-dev
export

# ulimit -c unlimited
# sysctl kernel.core_pattern

APP=app
SUBDIRS:=lib app

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

run: $(SUBDIRS)
	$(MAKE) -C $(APP) $@

clean:
	rm -rf core .gdb_history temp*
	@for dir in $(SUBDIRS); do\
		$(MAKE) -C $$dir $@;\
	done

.PHONY: all clean $(SUBDIRS)
