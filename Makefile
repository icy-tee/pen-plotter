.PHONY: verilator build-firmware

MAKE := make
FUSESOC := fusesoc


all: verilator

build-firmware: sw/main.c sw/startup.S
	cd sw; $(MAKE) -f vmem.mk

verilator: build-firmware
	$(FUSESOC) --cores-root=. run --target=sim icytee:soc:plotter
