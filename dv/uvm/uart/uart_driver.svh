`ifndef UART_DRIVER_SVH
`define UART_DRIVER_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_item.svh"

class uart_driver extends uvm_driver #(uart_item);
    `uvm_component_utils(uart_driver)

    int unsigned clks_per_bit; // = 50_000_000 / 9600;
    virtual interface uart_if iface;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(int unsigned)::get(null, "*", "clks_per_bit", clks_per_bit))
            `uvm_fatal(get_type_name(), "Failed to get baud rate")
        if (!uvm_config_db #(virtual interface uart_if)::get(null, "*", "uart_if", iface))
            `uvm_fatal(get_type_name(), "Failed to get UART interface")
        iface.drv.tx = 1'b1;
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_item uart_packet;
        super.run_phase(phase);

        forever begin
            `uvm_info(get_type_name(), $sformatf("Waiting for data from sequencer"), UVM_MEDIUM)
            seq_item_port.get_next_item(uart_packet);

            iface.drv.tx = 1'b0;
            repeat(clks_per_bit) @(posedge iface.clk);
            for (int unsigned i = 0; i < 8; i++) begin
                iface.drv.tx = uart_packet.data[i];
                repeat (clks_per_bit) @(posedge iface.clk);
            end
            iface.drv.tx = 1'b1;
            repeat(clks_per_bit) @(posedge iface.clk);

            seq_item_port.item_done();
        end
    endtask

endclass

`endif // UART_DRIVER_SVH
