`ifndef RX_LOOPBACK_VSEQ_SVH
`define RX_LOOPBACK_VSEQ_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "obi_uart_vsqr.svh"
`include "seq/obi_uart_base_vseq.svh"
`include "seq/baud_seq.svh"
`include "seq/read_rx_seq.svh"

class rx_loopback_vseq extends obi_uart_base_vseq;
    `uvm_object_utils(rx_loopback_vseq)

    rand int unsigned num_loops;
    constraint num_loops_c { num_loops inside {[1:16]}; }

    baud_seq bs; // ensure baud is set

    function new(string name = "rx_loopback_vseq");
        super.new(name);
    endfunction

    virtual task pre_body();
        bs = baud_seq::type_id::create("bs");
    endtask

    virtual task body();
        bs.start(p_sequencer.obi_sqr);
        repeat(num_loops) begin
            read_rx_seq rs = read_rx_seq::type_id::create("rs");
            uart_item itm;

            rs.num_reads = 1;
            uart_send_rand(itm);
            rs.start(p_sequencer.obi_sqr);
        end
    endtask

endclass

`endif
