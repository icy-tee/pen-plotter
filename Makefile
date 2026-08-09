.PHONY: sim clean uvm-% run-* build-*

MAKE := make
GCC := gcc
FUSESOC := fusesoc

QUARTUS_BUILD := build/plotter_quartus
QUARTUS_PROJECT := icytee_soc_plotter_0

UVM_TARGETS := uart reg bus

all: sim

run-interactive: fifos build-firmware
	cd build/icytee_soc_plotter_0/sim/; ./Vtop_verilator --piped --cycles 500000000 # roughly 50 seconds

run-ppcsender: 
	cd build; ./ppcsender sim /tmp/uart_rx /tmp/uart_tx

run-sim: build-dir build-firmware
	$(FUSESOC) --cores-root=. run --target=sim icytee:soc:plotter

build-ppcsender: build-dir
	$(GCC) -o build/ppcsender dv/verilator/ppcsender.c

build-sim: build-dir build-firmware
	$(GCC) -o build/ppcsender dv/verilator/ppcsender.c
	$(FUSESOC) --cores-root=. run --target=sim --build icytee:soc:plotter

build-dir: build
	mkdir -p build

build-firmware: sw/main.c sw/startup.S sw/peripherals.h
	cd sw; $(MAKE) -f vmem.mk
	cd sw; python3 vmem_to_mif.py firmware.vmem

fifos: /tmp/uart_tx /tmp/uart_rx
	rm -f /tmp/uart_tx /tmp/uart_rx
	mkfifo /tmp/uart_tx /tmp/uart_rx

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
	rm -f /tmp/uart_tx /tmp/uart_rx
	rm -rf build/
