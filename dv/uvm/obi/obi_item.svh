`ifndef OBI_ITEM_SVH
`define OBI_ITEM_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;

class obi_item extends uvm_sequence_item;
    `uvm_object_utils(obi_item)

    // request channel
    rand bit [31:0] addr;
    rand bit        we;
    rand bit [ 3:0] be;
    rand bit [31:0] wdata;

    // response channel
    rand bit [4:0]  latency;
    rand bit        err;
    bit [31:0]      rdata;

    function new(string name = "obi_item");
        super.new(name);
    endfunction
endclass

`endif // OBI_ITEM_SVH
