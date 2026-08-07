`ifndef OBI_UART_ENV_SVH
`define OBI_UART_ENV_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;
import uart_pkg::*;
`include "obi_uart_scoreboard.svh"
`include "obi_uart_vsqr.svh"

class obi_uart_env extends uvm_env;
    `uvm_component_utils(obi_uart_env)

    uart_agent uart_agt;
    obi_agent obi_agt;
    obi_uart_scoreboard scb;
    obi_uart_vsqr vsqr;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uart_agt = uart_agent::type_id::create("uart_agt", this);
        obi_agt = obi_agent::type_id::create("obi_agt", this);
        scb = obi_uart_scoreboard::type_id::create("scb", this);
        vsqr = obi_uart_vsqr::type_id::create("vsqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        vsqr.obi_sqr = obi_agt.sqr;
        vsqr.uart_sqr = uart_agt.sqr;

        obi_agt.mon.ap.connect(scb.obi_imp);
        uart_agt.mon.dut_rx_ap.connect(scb.dut_rx_imp);
        uart_agt.mon.dut_tx_ap.connect(scb.dut_tx_imp);
    endfunction

endclass

`endif // OBI_UART_ENV_SVH
