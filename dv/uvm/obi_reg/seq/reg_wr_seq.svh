`ifndef REG_WR_SEQ_SVH
`define REG_WR_SEQ_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;

class reg_wr_seq extends base_obi_seq;
    `uvm_object_utils(reg_wr_seq)

    int unsigned target = 0;
    rand int unsigned num_loops;
    constraint num_loops_c { num_loops inside {[1:16]}; }

    function new (string name = "reg_wr_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat(num_loops) begin
            logic err; logic [31:0] data;
            write_randomized(target);
            read(target, data, err);
        end
    endtask

endclass

`endif
