`ifndef WRITE_TX_SEQ_SVH
`define WRITE_TX_SEQ_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;
import uart_pkg::*;

class write_tx_seq extends base_obi_seq;
    `uvm_object_utils(write_tx_seq)

    rand int unsigned num_writes;
    constraint num_writes_c { num_writes inside {[1:16]}; }

    rand bit [31:0] data;
    rand bit [3:0] be;
    constraint be_c { be inside {'h1, 'h2, 'h4, 'h8, 'h3, 'h6, 'hC, 'h7, 'hE, 'hF}; }
    bit randomized_data;

    function new(string name = "write_tx_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat(num_writes) begin
            if (randomized_data)
                assert(randomize(data, be));
            write(uart_obi_pkg::TXLane, data, be);
        end
    endtask

endclass

`endif // WRITE_TX_SEQ_SVH
