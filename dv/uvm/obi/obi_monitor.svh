`ifndef OBI_MONITOR_SVH
`define OBI_MONITOR_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "obi_item.svh"

class obi_monitor #(parameter bit DEVICE = 1'b0) extends uvm_monitor;
    `uvm_component_param_utils(obi_monitor #(DEVICE))

    virtual interface obi_if #(DEVICE) iface;
    uvm_analysis_port #(obi_item) ap; // full transaction port
    uvm_analysis_port #(obi_item) phase_a_ap;
    uvm_analysis_port #(obi_item) phase_r_ap;

    function new(string name, uvm_component parent);
    super.new(name, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual obi_if #(DEVICE))::get(this, "", "obi_if", iface)) begin
            `uvm_fatal(get_type_name(), "DUT interface not found")
        end
        ap = new("ap", this);
    endfunction

    virtual task run_phase (uvm_phase phase);
        obi_item waiting [$];

        do @(iface.mon_cb); while (iface.rst_n !== 1'b1);
        fork
            forever begin
                obi_item packet;
                @(iface.mon_cb);
                if (iface.mon_cb.req !== 1'b1 || iface.mon_cb.gnt !== 1'b1) continue;
                packet = obi_item::type_id::create("packet", this);
                packet.addr  = iface.mon_cb.addr;
                packet.we    = iface.mon_cb.we;
                packet.be    = iface.mon_cb.be;
                packet.wdata = iface.mon_cb.wdata;
                phase_a_ap.write(packet);
                waiting.push_back(packet);
            end
            forever begin
                obi_item rsp_tr;
                @(iface.mon_cb);
                if (iface.mon_cb.rvalid !== 1'b1) continue;
                if (waiting.size() == 0) begin
                    `uvm_error(get_type_name(),
                        "rvalid asserted with no outstanding request in queue")
                    continue;
                end
                rsp_tr = waiting.pop_front();
                rsp_tr.rdata = iface.mon_cb.rdata;
                rsp_tr.err   = iface.mon_cb.err;
                phase_r_ap.write(rsp_tr);
                ap.write(rsp_tr);
            end
        join
    endtask

endclass

`endif // OBI_MONITOR_SVH
