
`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;

class base_obi_seq extends uvm_sequence #(obi_item);
    `uvm_object_utils(base_obi_seq)
    `uvm_declare_p_sequencer(obi_sequencer)

    function new(string name = "base_obi_seq");
        super.new(name);
    endfunction

    virtual task write(input bit [31:0] addr, input bit [31:0] data, input bit [3:0] be = 4'hF);
        obi_item req = obi_item::type_id::create("req");
        `uvm_info(get_type_name(), $sformatf("OBI write transaction at %08h with %08h", addr, data),
                UVM_MEDIUM)
        start_item(req);
        req.addr = addr;
        req.we = 1'b1;
        req.wdata = data;
        req.be = be;
        finish_item(req);
    endtask

    virtual task write_randomized(input bit [31:0] addr, input bit [3:0] be = 4'hF);
        obi_item req = obi_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with
                { this.addr == local::addr; this.be == local::be; req.we == 1'b1; });
        `uvm_info(get_type_name(), $sformatf("OBI write transaction [%08h: %08h]", addr, req.wdata),
                UVM_MEDIUM)
        finish_item(req);
    endtask

    virtual task read(input bit [31:0] addr, output bit [31:0] data, output bit err);
        obi_item req = obi_item::type_id::create("req");
        start_item(req);
        req.addr = addr;
        req.we = 1'b0;
        req.be = 4'hF;
        finish_item(req);
        data = req.rdata;
        err = req.err;
    endtask

endclass
