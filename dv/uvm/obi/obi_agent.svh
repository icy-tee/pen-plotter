`ifndef OBI_AGENT_SVH
`define OBI_AGENT_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "obi_driver.svh"

class obi_agent extends uvm_agent;
    `uvm_component_param_utils(obi_agent)

    obi_driver  drv;
    obi_sequencer  sqr;
    obi_monitor #() mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = obi_monitor #('0)::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv = obi_driver::type_id::create("drv", this);
            sqr = obi_sequencer::type_id::create("sqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass

`endif // OBI_AGENT_SVH
