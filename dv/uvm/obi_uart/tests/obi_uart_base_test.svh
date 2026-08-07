`ifndef OBI_UART_BASE_TEST_SVH
`define OBI_UART_BASE_TEST_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_uart_env_pkg::*;

class obi_uart_base_test extends uvm_test;
    `uvm_component_utils(obi_uart_base_test)

    obi_uart_env env;

    function new(string name = "base_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = obi_uart_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
endclass

`endif
