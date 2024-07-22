FILES=$(wildcard *.c)
OBJS=$(FILES:.c=.o)
BINS=binaries
BIN_OBJS=$(addprefix $(BINS)/,$(OBJS))
BIN_EXES=$(basename $(BIN_OBJS))

all: _prepare $(BIN_OBJS) $(BIN_EXES)

_prepare:
	mkdir -p $(BINS)

$(BINS)/%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@ 

$(BINS)/%: $(BINS)/%.o
	$(CC) -o $@ $< $(APP_LDFLAGS)

run: $(BIN_EXES)
	@for exe in $(BIN_EXES); do \
		echo ==== Running $$exe start=====; \
		$(ASAN) ./$$exe; \
	done

clean:
	rm -rf $(BINS) *.o *.so *.log *.log.* core *.txt *.d

.PHONY: all clean
