
RISCV_PREFIX ?= riscv32-unknown-elf

CC := $(RISCV_PREFIX)-clang
OBJCOPY := $(RISCV_PREFIX)-objcopy
OBJDUMP := $(RISCV_PREFIX)-objdump
READELF := $(RISCV_PREFIX)-readelf

MARCH := rv32imc_zicsr
MABI := ilp32

CFLAGS := \
	-march=$(MARCH) \
	-mabi=$(MABI) \
	-ffreestanding \
	-fno-builtin \
	-O2 \
	-g \
	-Wall \
	-Wextra

LDFLAGS := \
	-nostdlib \
	-nostartfiles \
	-Wl,-T,link.ld \
	-Wl,-Map,firmware.map

SRCS := startup.S main.c

all: firmware.elf firmware.vmem firmware.bin

firmware.elf: $(SRCS) link.ld
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRCS) -o $@

firmware.vmem: firmware.bin
	srec_cat $< -binary -offset 0x0000 -byte-swap 4 -o $@ -vmem

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

dump: firmware.elf
	$(OBJDUMP) -d $<

headers: firmware.elf
	$(READELF) -h $<
	$(OBJDUMP) -h $<

clean:
	rm -f firmware.elf firmware.vmem firmware.bin firmware.map
