`ifndef BAUD_SEQ_SVH
`define BAUD_SEQ_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;
import uart_pkg::*;

class baud_seq extends base_obi_seq;
    `uvm_object_utils(baud_seq)

    uart_cfg cfg;

    function new(string name = "baud_seq");
        super.new(name);
    endfunction

    virtual task body();
        if (!uvm_config_db #(uart_cfg)::get(m_sequencer, "", "m_uart_cfg", cfg)) begin
            `uvm_fatal(get_type_name(), "Failed to get uart_cfg")
        end
        `uvm_info(get_type_name(),
            $sformatf("setting DUT baud to %s", cfg.baud.name()), UVM_MEDIUM)
        write(uart_obi_pkg::BaudLane, 32'(cfg.baud));  // enum value is the register encoding
    endtask

endclass

`endif // BAUD_SEQ_SVH
