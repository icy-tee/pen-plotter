`ifndef UART_MONITOR_SVH
`define UART_MONITOR_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "uart_item.svh"
`include "uart_cfg.svh"

class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    uart_cfg cfg;
    virtual interface uart_if iface;
    uvm_analysis_port #(uart_item) dut_rx_ap;
    uvm_analysis_port #(uart_item) dut_tx_ap;

    function new(string name, uvm_component parent);
    super.new(name, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(uart_cfg)::get(null, "*", "m_uart_cfg", cfg))
            `uvm_fatal(get_type_name(), "Failed to get UART config")
        if (!uvm_config_db #(virtual interface uart_if)::get(null, "*", "uart_if", iface)) begin
            `uvm_fatal(get_type_name(), "DUT interface not found")
        end
        dut_rx_ap = new("dut_rx_ap", this);
        dut_tx_ap = new("dut_tx_ap", this);
    endfunction

    virtual task run_phase (uvm_phase phase);
        fork
            forever begin
                uart_item packet = uart_item::type_id::create ("packet", this);
                @(negedge iface.mon.cb.rx);
                repeat (cfg.clks_per_bit()) @(posedge iface.clk);
                for (int unsigned i = 0; i < 8; i++) begin
                    repeat (cfg.clks_per_bit() / 2) @(posedge iface.clk);
                    packet.data[i] = iface.mon.cb.rx;
                    repeat (cfg.clks_per_bit() / 2) @(posedge iface.clk);
                end
                repeat (cfg.clks_per_bit() / 2) @(posedge iface.clk);
                if (iface.mon.cb.rx) dut_tx_ap.write(packet);
                repeat (cfg.clks_per_bit() / 2) @(posedge iface.clk);
            end
            forever begin
                uart_item packet = uart_item::type_id::create ("packet", this);
                @(negedge iface.mon.cb.tx);
                repeat (cfg.clks_per_bit()) @(posedge iface.clk);
                for (int unsigned i = 0; i < 8; i++) begin
                    repeat (cfg.clks_per_bit() / 2) @(posedge iface.clk);
                    packet.data[i] = iface.mon.cb.tx;
                    repeat (cfg.clks_per_bit() / 2) @(posedge iface.clk);
                end
                repeat (cfg.clks_per_bit() / 2) @(posedge iface.clk);
                if (iface.mon.cb.tx) dut_rx_ap.write(packet);
                repeat (cfg.clks_per_bit() / 2) @(posedge iface.clk);
            end
        join
    endtask

endclass

`endif // UART_MONITOR_SVH
