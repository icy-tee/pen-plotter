`ifndef UART_CFG_SVH
`define UART_CFG_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_obi_pkg::*;


class uart_cfg extends uvm_object;
    `uvm_object_utils(uart_cfg)

    const int unsigned const_from_baud[] = {
        0, 4800, 9600, 19200, 38400, 57600, 115200, 230400
    };

    int unsigned clock_rate = 50_000_000;
    baud_e baud = BAUD_DISABLED;

    function new(string name = "uart_cfg");
        super.new(name);
    endfunction

    function int unsigned clks_per_bit();
        return baud == BAUD_DISABLED ? 0 : clock_rate / const_from_baud[baud];
    endfunction

endclass

`endif
