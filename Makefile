.PHONY: sim clean uvm-% build-firmware quartus-setup quartus

MAKE := make
FUSESOC := ./.venv/bin/fusesoc

QUARTUS_BUILD := build/plotter_quartus
QUARTUS_PROJECT := icytee_soc_plotter_0

UVM_TARGETS := uart reg bus

all: sim

sim: build-firmware
	$(FUSESOC) --cores-root=. run --target=sim icytee:soc:plotter

build-firmware: sw/main.c sw/startup.S sw/peripherals.h
	cd sw; $(MAKE) -f vmem.mk
	cd sw; python3 vmem_to_mif.py firmware.vmem

$(addprefix uvm-, $(UVM_TARGETS)): uvm-%: 
	$(FUSESOC) --cores-root=. run icytee:dv:obi_$*_tb

quartus-setup:
	$(FUSESOC) --cores-root=. run \
		--target=synth \
		--setup \
		--work-root=$(QUARTUS_BUILD)\
		icytee:soc:plotter

# NOTE: quartus flow is done this way bc IP generation is hard to have in full fusesoc/edalize flow
# likely will change when Edalize adds a Quartus flow
quartus: quartus-setup
	cd $(QUARTUS_BUILD) && quartus_sh -t $(QUARTUS_PROJECT).tcl
	cd $(QUARTUS_BUILD) && quartus_sh --flow compile $(QUARTUS_PROJECT)

clean:
	rm -rf build/
