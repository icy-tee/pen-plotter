# Pen Plotter

This is a WIP RISC-V SoC to be used to control a closed-loop pen plotter.

## Organization

```
  rtl/ - the source files for the controller and surrounding hardware
  rtl/common/ - RTL modules commonly used in peripherals
  rtl/core/ - core SoC files such as `bus`, `pp_system`, and `ram_2p`
  sw/ - linker config, MMIO definitions and a demo program
  constraints/ - TCL, SDC, and pin-planning constraints
  dv/uvm/ - UVM environments containing OBI, UART, and register agents plus peripheral TBs
  dv/verilator/ - simulation harness
  ip/ - IP files
  vendor/ - contains Ibex, lowRISC IP, and the PULP RISC-V debug core
```

## State

Integration and verification are in progress. The UVM environment currently has basic tests for the
`obi_reg`, `uart_obi`, and `bus` modules. These tests are still coverage-light, but they run in
QuestaSim without errors.

Recently, all peripherals except GPIO have been implemented, and a Verilator simulation
has been added.

## Running

### Prerequisites

- `fusesoc` and its dependencies are required for build orchestration and can be installed with:
  ```sh
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -r python_requirements.txt
  ```
- a RISC-V 32-bit compiler and `srec_cat` are required to build and prepare the firmware for simulation

### Verification

Currently, QuestaSim is the only supported verification simulator.
The current UVM testbenches can be run directly with `fusesoc`:
  - `fusesoc --cores-root=. run icytee:dv:obi_uart_tb`
  - `fusesoc --cores-root=. run icytee:dv:obi_reg_tb`
  - `fusesoc --cores-root=. run icytee:dv:obi_bus_tb`

They can also be run via `make` using the `uvm-uart`, `uvm-reg`, or `uvm-bus` rules.

### Simulation

A Verilator simulation can be run through `make sim`, which also compiles and updates the program files when
their tracked inputs change.

The simulation accepts a `--cycles N` flag to set its run length. When omitted, the default is 6,000,000
cycles, which allows the first timer interrupt to occur.

Currently, the simulation runs a program that uses the `timer`, `uart`, and `quad` peripherals to report
the `QUAD_X` tick count every 5,000,000 clock cycles, or 100 ms at 50 MHz.

### Synthesis

Synthesis is now in progress, currently the only blocker is that the `ram_2p` does not yet target a synthesizable
RAM component in Quartus.

## Writing Programs

For now, the organization of the peripherals in memory is subject to change. For example, the QUAD peripheral
will likely be moved into the PID peripheral as they are closely related. Ordering may change as well.

|Peripheral|Memory Location|
|----------|---------------|
|   UART   |  0x8000_0000  |
|GPIO(stub)|  0x8000_1000  |
|   PWM    |  0x8000_2000  |
|   TIMER  |  0x8000_3000  |
|   PID    |  0x8000_4000  |
|   QUAD   |  0x8000_4400  |

`sw/peripherals.h` defines the peripheral register layouts used by firmware. The timer is currently
configurable, and its configuration functions are used by the `sw/main.c` demo.
