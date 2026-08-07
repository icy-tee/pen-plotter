`ifndef REG_AGENT_SVH
`define REG_AGENT_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "reg_driver.svh"
`include "reg_monitor.svh"

class reg_agent extends uvm_agent;
    `uvm_component_utils(reg_agent)

    reg_driver                drv;
    reg_monitor               mon;
    uvm_sequencer #(reg_item) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = reg_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv = reg_driver::type_id::create("drv", this);
            sqr = uvm_sequencer #(reg_item)::type_id::create("sqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass

`endif // REG_AGENT_SVH
