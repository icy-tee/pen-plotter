# Pen Plotter

This is the synthesized hardware and later firmware for a closed-loop pen plotter. It uses SystemVerilog for the HDL, Verilator for simulation and Quartus Prime Pro for Synthesis.

## Organization

```
  rtl/ - the source files for the controller and surrounding hardware
  rtl/platform/ - the top-level files for different platforms
  sim/verilator/ - setup for verilator simulation including programs to interact with simulation
  sim/tb/ - testbenches for rtl
  constraints/ - for tcl, sdc for timing and pin planning
  ip/ - ip files
  vendor/ - contains ibex, lowrisc_ip (ibex's primitives) and the debug core from pulp
```

## State

Currently, it is a simple controller for my pen plotter rig that can drive all the inputs of a DRV8833 to get movement and read the output of quadrature encoders from the JGA25-371.
It has 4 working commands:
```
  STS - Status: sends OK packet with controller version
  RST - Reset: resets the quadrature counters and the setpoint values, keeps constants
  STR - Stream: toggles the streaming mode that sends position packets
  SET $REG: 1 byte $WORD: 4 bytes - Set: sets the corresponding register to the bytes sent with it.
```

It currently has 5 4-byte long registers: `setpoint_x`, `setpoint_y`, `Kp`, `Kd`, and `sample_rate`. There will be
per-axis proportional constants and the sample rate will likely become hardcoded but for now its for quicker testing.


## Running

`fusesoc` is used to generate the build files necessary for both Quartus Prime Pro and Verilator.

### Simulation

Run `fusesoc --cores-root=. run --target=sim --build icytee:plotter:soc`

This generates the `Vtop_verilator` binary into `build/icytee_plotter_soc_0/sim-verilator`, where it can be run from.

`./ppcsender` (from `./ppcsender.c`) is the program that parses user commands into their byte representations (in LE) and sends them over USB for actual use, or over named pipes for the simulation.
It runs with either `act [dev]` where the default is /dev/ttyUSB0 or `sim [read] [write]` that defaults to 'uart_rx' and 'uart_tx' respectively.

### Synthesis

Currently, the only EDA supported is Quartus Prime Pro targeting the Agilex 3 A3CZ135BB18AE7S with the pin assignments being set by `constraints/de23lite_assignments.tcl`.

To create the Quartus Project files run `fusesoc --cores-root=. run --target=synth --setup icytee:plotter:soc` followed by `make project` in the `build/icytee_plotter_soc_0/synth-quartus/` folder generated.
