# Pen Plotter

This is a WIP RISC-V SoC to be used to control a closed-loop pen plotter.

## Organization

```
  rtl/ - the source files for the controller and surrounding hardware
  rtl/common/ - RTL modules commonly used in peripherals
  rtl/core/ - core SoC files such as `bus`, `pp_system`, and `ram_2p`
  constraints/ - TCL, SDC, and pin-planning constraints
  dv/uvm/ - UVM environments containing OBI, UART, and register agents plus peripheral TBs
  ip/ - IP files
  vendor/ - contains Ibex, lowRISC IP, and the PULP RISC-V debug core
```

## State

Integration and verification are in progress. The UVM environment currently has basic tests for the
`obi_reg`, `uart_obi`, and `bus` modules. These tests are still coverage-light, but they run in
QuestaSim without errors. Recently, an `obi_quad` peripheral was created using the `obi_reg` and `quad_decoder`
modules.

## Running

### Verification

Currently, the only supported verification simulator is QuestaSim:
  - `fusesoc --cores-root=. run icytee:dv:obi_uart_tb`
  - `fusesoc --cores-root=. run icytee:dv:obi_reg_tb`
  - `fusesoc --cores-root=. run icytee:dv:obi_bus_tb`

### Simulation

A Verilator simulation is planned.

### Synthesis

Synthesis is not yet available.
