`ifndef OBI_BUS_SEQ_SVH
`define OBI_BUS_SEQ_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;

class obi_bus_host_seq extends base_obi_seq;
    `uvm_object_utils(obi_bus_host_seq)

    bit [31:0] target_addr[];
    rand int unsigned num_loops;

    constraint num_loops_c { num_loops inside {[1:4]}; }

    function new (string name = "obi_bus_host_seq");
        super.new(name);
    endfunction

    virtual task body();
        if (target_addr.size() == 0) begin
            `uvm_fatal(get_type_name(), "obi_bus_host_seq requires at least one target address")
        end

        repeat (num_loops) begin
            foreach (target_addr[i]) begin
                logic err;
                logic [31:0] data;

                write_randomized(target_addr[i]);
                read(target_addr[i], data, err);
                if (err) begin
                    `uvm_error(get_type_name(), $sformatf("Unexpected OBI error for mapped address %08h",
                        target_addr[i]))
                end
            end
        end
    endtask
endclass

class obi_bus_device_rsp_seq extends base_obi_seq;
    `uvm_object_utils(obi_bus_device_rsp_seq)

    function new (string name = "obi_bus_device_rsp_seq");
        super.new(name);
    endfunction

    virtual task body();
        forever begin
            obi_item rsp = obi_item::type_id::create("rsp");
            start_item(rsp);
            assert(rsp.randomize() with {
                err == 1'b0;
                latency inside {[1:4]};
            });
            finish_item(rsp);
        end
    endtask
endclass

`endif
