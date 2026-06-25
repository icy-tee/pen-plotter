
`ifndef OBI_UART_WRITE_TEST_SVH
`define OBI_UART_WRITE_TEST_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_uart_env_pkg::*;

`include "tests/obi_uart_base_test.svh"

class obi_uart_write_test extends obi_uart_base_test;
    `uvm_component_utils(obi_uart_write_test)


    function new(string name = "obi_uart_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction


    virtual task run_phase(uvm_phase phase);
        baud_seq bseq = baud_seq::type_id::create("bseq");
        write_tx_seq wseq = write_tx_seq::type_id::create("wseq");
        assert(wseq.randomize());
        wseq.randomized_data = 1'b1;

        super.run_phase(phase);
        phase.raise_objection(this);

        bseq.start(env.vsqr.obi_sqr);
        #1us;
        wseq.start(env.vsqr.obi_sqr);
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
