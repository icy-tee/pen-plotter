`ifndef OBI_DRIVER_SVH
`define OBI_DRIVER_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;

class obi_driver extends uvm_driver #(obi_item);
    `uvm_component_utils(obi_driver)

    virtual interface obi_if iface;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual interface obi_if)::get(this, "", "obi_if", iface))
            `uvm_fatal(get_type_name(), "Failed to get OBI interface")
    endfunction

    virtual task run_phase(uvm_phase phase);
        obi_item obi_packet;
        super.run_phase(phase);

        iface.g_drv.drv_cb.req <= 1'b0;
        do @(iface.g_drv.drv_cb); while (iface.rst_n !== 1'b1);

        forever begin
            `uvm_info(get_type_name(), $sformatf("Waiting for data from sequencer"), UVM_MEDIUM)
            seq_item_port.get_next_item(obi_packet);

            // address phase
            iface.g_drv.drv_cb.req   <= 1'b1;
            iface.g_drv.drv_cb.addr  <= obi_packet.addr;
            iface.g_drv.drv_cb.wdata <= obi_packet.wdata;
            iface.g_drv.drv_cb.we    <= obi_packet.we;
            iface.g_drv.drv_cb.be    <= obi_packet.be;

            do @(iface.g_drv.drv_cb); while (iface.g_drv.drv_cb.gnt !== 1'b1);

            iface.g_drv.drv_cb.req   <= 1'b0;
            iface.g_drv.drv_cb.addr  <= '0;
            iface.g_drv.drv_cb.wdata <= '0;
            iface.g_drv.drv_cb.we    <= 1'b0;
            iface.g_drv.drv_cb.be    <= '0;

            do @(iface.g_drv.drv_cb); while (iface.g_drv.drv_cb.rvalid !== 1'b1);
            if (!obi_packet.we) begin
                obi_packet.rdata = iface.g_drv.drv_cb.rdata;
                obi_packet.err   = iface.g_drv.drv_cb.err;
            end

            seq_item_port.item_done();
        end
    endtask

endclass

`endif // OBI_DRIVER_SVH
