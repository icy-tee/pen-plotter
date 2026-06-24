
`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;

class simple_seq extends base_obi_seq;
    `uvm_object_utils(simple_seq)

    function new(string name = "simple_seq");
        super.new(name);
    endfunction

    virtual task body();
        write('h0000_0001, 'h0000_0002); // write BAUD to 9600
        write('h0000_0002, 'h4300_2105);
    endtask

endclass
