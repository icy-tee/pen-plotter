`ifndef UART_AGENT_SVH
`define UART_AGENT_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_driver.svh"
`include "uart_monitor.svh"

typedef uvm_sequencer #(uart_item) uart_sequencer;

class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    uart_driver drv;
    uart_sequencer sqr;
    uart_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = uart_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv = uart_driver::type_id::create("drv", this);
            sqr = uart_sequencer::type_id::create("sqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass

`endif
