
PROJ_ROOT := ./..
RTL := $(PROJ_ROOT)/rtl
VERILATOR := verilator
VFLAGS := --cc --exe -j 0

CPP_HARNESS := ./sim_main.cpp

RTL_FILES = pp_pkg.sv uart_rx_fifo.sv uart_tx_fifo.sv quad_decoder.sv md_controller.sv pp_controller.sv pp_top.sv
SRCS := \
	$(addprefix $(RTL)/, $(RTL_FILES))

sim:
	$(VERILATOR) $(VFLAGS) --build $(CPP_HARNESS) $(SRCS) --top-module pp_top
	
