`ifndef OBI_AGENT_SVH
`define OBI_AGENT_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "obi_driver.svh"
`include "obi_monitor.svh"

typedef uvm_sequencer #(obi_item) obi_sequencer;

class obi_agent extends uvm_agent;
    `uvm_component_utils(obi_agent)

    obi_driver  drv;
    obi_sequencer  sqr;
    obi_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = obi_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv = obi_driver::type_id::create("drv", this);
            sqr = obi_sequencer::type_id::create("sqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass

`endif // OBI_AGENT_SVH
