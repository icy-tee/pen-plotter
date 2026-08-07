`ifndef REG_ITEM_SVH
`define REG_ITEM_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;

class reg_item extends uvm_sequence_item;
    `uvm_object_utils(reg_item)

    rand bit hw_de;
    rand bit [31:0] hw_d;
    bit [31:0] hw_q;

    function new(string name = "reg_item");
        super.new(name);
    endfunction
endclass

`endif // REG_ITEM_SVH
