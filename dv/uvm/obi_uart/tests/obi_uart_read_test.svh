`ifndef OBI_UART_READ_TEST_SVH
`define OBI_UART_READ_TEST_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_uart_env_pkg::*;

`include "tests/obi_uart_base_test.svh"

class obi_uart_read_test extends obi_uart_base_test;
    `uvm_component_utils(obi_uart_read_test)


    function new(string name = "obi_uart_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction


    virtual task run_phase(uvm_phase phase);
        rx_loopback_vseq seq = rx_loopback_vseq::type_id::create("seq");
        assert(seq.randomize());

        super.run_phase(phase);
        phase.raise_objection(this);

        seq.start(env.vsqr);
        #1us;

        fork
            begin : drain
                while (env.scb.tx_expected.size() != 0 || env.scb.rx_expected.size() != 0)
                    #1us;
            end
            begin : watchdog
                #10ms;
                `uvm_error("TEST", "timeout waiting for scoreboard to drain")
            end
        join_any
        disable fork;

        phase.drop_objection(this);
    endtask

endclass

`endif
