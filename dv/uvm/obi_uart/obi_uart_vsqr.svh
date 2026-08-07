`ifndef OBI_UART_VSQR_SVH
`define OBI_UART_VSQR_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;

import obi_pkg::obi_sequencer;
import uart_pkg::uart_sequencer;

class obi_uart_vsqr extends uvm_sequencer;
    `uvm_component_utils(obi_uart_vsqr)

    obi_sequencer obi_sqr;
    uart_sequencer uart_sqr;

    function new(string name = "obi_uart_vsqr", uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
