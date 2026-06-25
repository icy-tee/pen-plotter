`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_pkg::*;

class base_uart_seq extends uvm_sequence #(uart_item);
    `uvm_object_utils(base_uart_seq)
    `uvm_declare_p_sequencer(uart_sequencer)

    function new(string name = "base_uart_seq");
        super.new(name);
    endfunction

    virtual task write(input bit [7:0] data);
        uart_item rsp = uart_item::type_id::create("rsp");
        `uvm_info(get_type_name(), $sformatf("uart write %02h", data),
                UVM_MEDIUM)
        start_item(rsp);
        rsp.data = data;
        finish_item(rsp);
    endtask

    virtual task write_randomized();
        uart_item rsp = uart_item::type_id::create("rsp");
        start_item(req);
        assert(rsp.randomize());
        `uvm_info(get_type_name(), $sformatf("uart write %02h", rsp.data),
                UVM_MEDIUM)
        finish_item(req);
    endtask

endclass
