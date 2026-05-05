# Pen Plotter

This is the synthesized hardware and later firmware for a closed-loop pen plotter. It uses SystemVerilog for the HDL, Verilator for simulation and Quartus Prime for Synthesis.

## Organization

```
  rtl/ - the source files for the controller and surrounding hardware
  rtl/platform - the top-level files for different platforms (Quartus for now)
  sim/ - simulation for pp_top.sv
  syn/ - quartus files
  syn/ip - ip required for quartus top-level module
```

## State

Currently, it is a simple controller for my pen plotter rig that can drive all the inputs of a DRV8833 to get movement and read the output of quadrature encoders from the JGA25-371.
It has 9 commands (1 non-specific and 4 per-axis):
```
  STS - Status: sends OK packet with controller version
  FWD(X|Y) $DUTY - Forward: sets whatever motor to FORWARD state with $DUTY value which ranges from 0-255 (0%-100%)
  REV(X|Y) $DUTY - Reverse: sets motor to REVERSE with $DUTY value.
  CST(X|Y) - Coast: sets motor to coast
  BRK(X|Y) - Brake: sets motor to brake
```

## Simulation

Simulating the current state of the project is straightforward. Ensure Verilator is installed and run the Makefile. The simulation itself should be crossplatform but 'ppcsender' is unix-based and for Windows would
require a port for the named pipes.

'./ppcsender.c' is the program that parses user commands into their byte representations (in LE) and sends them over USB for actual use, or over named pipes for the simulation.
It runs with either 'act [dev]' where the default is /dev/TTYUSB0 or 'sim [read] [write]' that defaults to 'uart_rx' and 'uart_tx' respectively.

## Synthesis

Synthesis has been done on Quartus Prime Pro targetting the Agilex 3 series (Specifically, the Agilex 3 A3CZ135BB18AE7S, as I am using the DE23-Lite). Though, the pin assignments would need to be reconfigured. 
