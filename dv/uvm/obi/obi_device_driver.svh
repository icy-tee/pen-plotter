`ifndef OBI_DEVICE_DRIVER_SVH
`define OBI_DEVICE_DRIVER_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;

class obi_device_driver extends uvm_driver #(obi_item);
    `uvm_component_utils(obi_device_driver)

    virtual interface obi_if #('1) iface;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual interface obi_if #('1))::get(this, "", "obi_if", iface))
            `uvm_fatal(get_type_name(), "Failed to get OBI interface")
    endfunction

    virtual task run_phase(uvm_phase phase);
        obi_item obi_packet;
        super.run_phase(phase);

        iface.g_drv.drv_cb.gnt <= 1'b0;
        iface.g_drv.drv_cb.rvalid <= 1'b0;
        do @(iface.g_drv.drv_cb); while (iface.rst_n !== 1'b1);

        forever begin
            @(posedge iface.g_drv.drv_cb.req);

            iface.g_drv.drv_cb.gnt <= 1'b1;

            seq_item_port.get_next_item(obi_packet);

            repeat (obi_packet.latency) @(posedge iface.g_drv.drv_cb);

            iface.g_drv.drv_cb.rvalid <= 1'b1;
            iface.g_drv.drv_cb.rdata <= obi_packet.rdata;
            iface.g_drv.drv_cb.err <= obi_packet.err;

            @(posedge iface.g_drv.drv_cb);

            iface.g_drv.drv_cb.rvalid <= 1'b0;
            iface.g_drv.drv_cb.rdata <= '0;
            iface.g_drv.drv_cb.err <= 1'b0;

            seq_item_port.item_done();
        end

    endtask
endclass

`endif // OBI_DEVICE_DRIVER_SVH
