`ifndef SIMPLE_SEQ_SVH
`define SIMPLE_SEQ_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;

`include "seq/baud_seq.svh"

class simple_seq extends base_obi_seq;
    `uvm_object_utils(simple_seq)

    function new(string name = "simple_seq");
        super.new(name);
    endfunction

    task body();
        baud_seq bs = baud_seq::type_id::create("bs");
        bs.start(null, this);

        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'h1);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'h2);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'h4);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'h8);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'h3);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'h6);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'h9);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'hC);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'h7);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'hE);
        repeat (2) write_randomized(uart_obi_pkg::TXLane, 4'hF);

    endtask

endclass

`endif // SIMPLE_SEQ_SVH
