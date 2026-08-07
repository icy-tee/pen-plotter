`ifndef READ_RX_SEQ_SVH
`define READ_RX_SEQ_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;
import uart_pkg::*;

class read_rx_seq extends base_obi_seq;
    `uvm_object_utils(read_rx_seq)

    rand int unsigned num_reads;
    constraint num_reads_c { num_reads inside {[1:16]}; }

    bit [31:0] data;
    bit err;

    function new(string name = "read_rx_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat(num_reads) begin
            do read(uart_obi_pkg::STSLane, data, err);
            while(data[7] !== 1'b0);

            read(uart_obi_pkg::RXLane, data, err);
        end
    endtask

endclass

`endif // READ_RX_SEQ_SVH
