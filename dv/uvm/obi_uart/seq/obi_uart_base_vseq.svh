`ifndef OBI_UART_BASE_VSEQ_SVH
`define OBI_UART_BASE_VSEQ_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_pkg::uart_item;

`include "obi_uart_vsqr.svh"

class obi_uart_base_vseq extends uvm_sequence;
    `uvm_object_utils(obi_uart_base_vseq)
    `uvm_declare_p_sequencer(obi_uart_vsqr)

    function new(string name = "obi_uart_base_vseq");
        super.new(name);
    endfunction

    task uart_send(output uart_item it, input logic [7:0] data);
        it = uart_item::type_id::create("it");
        start_item(it, -1, p_sequencer.uart_sqr);
        it.data = data;
        finish_item(it);
    endtask

    task uart_send_rand(output uart_item it);
        it = uart_item::type_id::create("it");
        start_item(it, -1, p_sequencer.uart_sqr);
        assert(it.randomize());
        finish_item(it);
    endtask

endclass

`endif
