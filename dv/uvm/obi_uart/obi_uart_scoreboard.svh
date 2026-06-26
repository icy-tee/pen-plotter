`ifndef OBI_UART_SCOREBOARD_SVH
`define OBI_UART_SCOREBOARD_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;
import uart_pkg::*;

`uvm_analysis_imp_decl(_obi)
`uvm_analysis_imp_decl(_dut_rx)
`uvm_analysis_imp_decl(_dut_tx)

class obi_uart_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(obi_uart_scoreboard)

    uvm_analysis_imp_obi #(obi_item, obi_uart_scoreboard) obi_imp;
    uvm_analysis_imp_dut_rx #(uart_item, obi_uart_scoreboard) dut_rx_imp;
    uvm_analysis_imp_dut_tx #(uart_item, obi_uart_scoreboard) dut_tx_imp;

    byte unsigned tx_expected [$];
    byte unsigned rx_expected [$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        obi_imp = new("obi_imp", this);
        dut_rx_imp = new("dut_rx_imp", this);
        dut_tx_imp = new("dut_tx_imp", this);
    endfunction

    function void write_obi(obi_item itm);
        if (itm.addr == uart_obi_pkg::TXLane && itm.we) begin
            `uvm_info("SB", $sformatf("OBI TX write data=%08h be=%04b", itm.wdata, itm.be), UVM_LOW)
            for (int i = 0; i < 4; i++) begin
                if (itm.be[i]) tx_expected.push_back(itm.wdata[i*8 +: 8]);
            end
        end else if (itm.addr == uart_obi_pkg::RXLane && !itm.we) begin
            byte unsigned expected;
            `uvm_info("SB", $sformatf("OBI RX read rdata=%08h", itm.rdata), UVM_LOW)
            if (rx_expected.size() == 0) begin
                `uvm_error("SB",
                    $sformatf("RX read (rdata=%02h) with no expected byte queued", itm.rdata[7:0]))
                return;
            end
            expected = rx_expected.pop_front();
            if (expected != itm.rdata[7:0]) `uvm_error("SB",
                    $sformatf("RX mismatch expected %02h got %02h", expected, itm.rdata[7:0]))
        end else begin
            `uvm_info("SB",
                $sformatf("OBI %s addr=%08h (no scoreboard action)",
                    itm.we ? "write" : "read", itm.addr), UVM_HIGH)
        end
    endfunction

    function void write_dut_tx(uart_item itm);
        byte unsigned expected;
        `uvm_info("SB", $sformatf("DUT transmitted byte %02h", itm.data), UVM_LOW)
        if (tx_expected.size() == 0) begin
            `uvm_error("SB",
                $sformatf("DUT transmitted %02h with no expected byte queued", itm.data))
            return;
        end
        expected = tx_expected.pop_front();
        if (expected != itm.data) `uvm_error("SB",
                $sformatf("TX mismatch expected %02h got %02h", expected, itm.data))
    endfunction

    function void write_dut_rx(uart_item itm);
        `uvm_info("SB", $sformatf("stimulus drove byte %02h into DUT RX", itm.data), UVM_LOW)
        rx_expected.push_back(itm.data);
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (tx_expected.size() != 0)
            `uvm_error("SB",
                $sformatf("%0d expected TX byte(s) never transmitted by DUT", tx_expected.size()))
        if (rx_expected.size() != 0)
            `uvm_error("SB",
                $sformatf("%0d byte(s) driven into DUT RX never read back over OBI",
                    rx_expected.size()))
    endfunction

endclass

`endif
