`ifndef UART_DRIVER_SVH
`define UART_DRIVER_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_item.svh"
`include "uart_cfg.svh"

class uart_driver extends uvm_driver #(uart_item);
    `uvm_component_utils(uart_driver)

    uart_cfg cfg; // = 50_000_000 / 9600;
    virtual interface uart_if iface;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uart_cfg)::get(null, "*", "m_uart_cfg", cfg))
            `uvm_fatal(get_type_name(), "Failed to get UART config")
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
            repeat(cfg.clks_per_bit()) @(posedge iface.clk);
            for (int unsigned i = 0; i < 8; i++) begin
                iface.drv.tx = uart_packet.data[i];
                repeat (cfg.clks_per_bit()) @(posedge iface.clk);
            end
            iface.drv.tx = 1'b1;
            repeat(cfg.clks_per_bit()) @(posedge iface.clk);

            seq_item_port.item_done();
        end
    endtask

endclass

`endif // UART_DRIVER_SVH
