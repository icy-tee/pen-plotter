`ifndef REG_DRIVER_SVH
`define REG_DRIVER_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "reg_item.svh"

class reg_driver extends uvm_driver #(reg_item);
    `uvm_component_utils(reg_driver)

    virtual interface reg_if iface;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual interface reg_if)::get(this, "", "reg_if", iface))
            `uvm_fatal(get_type_name(), "Failed to get REG interface")
    endfunction

    virtual task run_phase(uvm_phase phase);
        reg_item reg_packet;
        super.run_phase(phase);

        iface.drv.drv_cb.hw_de <= 1'b0;
        iface.drv.drv_cb.hw_d <= 1'b0;
        do @(iface.drv.drv_cb); while (iface.drv.rst_n !== 1'b1);

        forever begin
            `uvm_info(get_type_name(), $sformatf("Waiting for data from sequencer"), UVM_MEDIUM)
            seq_item_port.get_next_item(reg_packet);

            iface.drv.drv_cb.hw_de <= reg_packet.hw_de;
            iface.drv.drv_cb.hw_d <= reg_packet.hw_d;
            @(posedge iface.clk);
            iface.drv.drv_cb.hw_de <= 1'b0;
            iface.drv.drv_cb.hw_d <= '0;

            seq_item_port.item_done();
        end
    endtask

endclass

`endif // REG_DRIVER_SVH
