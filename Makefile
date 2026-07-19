.PHONY: sim build-firmware

MAKE := make
FUSESOC := fusesoc

UVM_TARGETS := uart reg bus

all: sim

sim: build-firmware
	$(FUSESOC) --cores-root=. run --target=sim icytee:soc:plotter

build-firmware: sw/main.c sw/startup.S
	cd sw; $(MAKE) -f vmem.mk

$(addprefix uvm-, $(UVM_TARGETS)): uvm-%: 
	$(FUSESOC) --cores-root=. run icytee:dv:obi_$*_tb
