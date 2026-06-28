`ifndef REG_MONITOR_SVH
`define REG_MONITOR_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "reg_item.svh"

class reg_monitor extends uvm_monitor;
    `uvm_component_utils(reg_monitor)

    virtual interface reg_if iface;
    uvm_analysis_port #(reg_item) ap;

    function new(string name, uvm_component parent);
    super.new(name, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual interface reg_if)::get(this, "", "reg_if", iface)) begin
            `uvm_fatal(get_type_name(), "DUT interface not found")
        end
        ap = new("ap", this);
    endfunction

    virtual task run_phase (uvm_phase phase);
        reg_item item;
        do @(iface.mon.mon_cb); while (iface.mon.rst_n !== 1'b1);
        forever begin
            @(iface.mon.mon_cb);
            if (iface.mon.mon_cb.hw_de === 1'b1) begin
                item = reg_item::type_id::create("item");
                item.hw_de = iface.mon.mon_cb.hw_de;
                item.hw_d  = iface.mon.mon_cb.hw_d;
                item.hw_q  = iface.mon.mon_cb.hw_q;
                ap.write(item);
            end
        end
    endtask

endclass

`endif // REG_MONITOR_SVH
