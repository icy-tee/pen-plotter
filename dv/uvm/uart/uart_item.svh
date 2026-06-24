`ifndef UART_ITEM_SVH
`define UART_ITEM_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;

class uart_item extends uvm_sequence_item;
    `uvm_object_utils(uart_item)

    rand bit [7:0] data;

    function new(string name = "uart_item");
        super.new(name);
    endfunction
endclass

`endif // UART_ITEM_SVH
