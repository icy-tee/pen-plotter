`ifndef OBI_BUS_TEST_SVH
`define OBI_BUS_TEST_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_bus_env_pkg::*;
import obi_pkg::*;
import obi_device_pkg::*;

class obi_bus_test extends uvm_test;
    `uvm_component_utils(obi_bus_test)

    obi_bus_env env;

    function new(string name = "obi_bus_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = obi_bus_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this);

        foreach (env.device_agt[i]) begin
            automatic int unsigned device = i;
            automatic obi_bus_device_rsp_seq rsp_seq;
            fork
                begin
                    rsp_seq = obi_bus_device_rsp_seq::type_id::create($sformatf("rsp_seq_%0d", device));
                    rsp_seq.start(env.device_agt[device].sqr);
                end
            join_none
        end

        foreach (env.host_agt[i]) begin
            obi_bus_host_seq host_seq = obi_bus_host_seq::type_id::create($sformatf("host_seq_%0d", i));
            host_seq.target_addr = new[env.cfg.device_count];
            foreach (host_seq.target_addr[j]) begin
                host_seq.target_addr[j] = env.cfg.device_addr_base[j] | 32'h0000_0004;
            end
            assert(host_seq.randomize());
            host_seq.start(env.host_agt[i].sqr);
        end

        #1us;
        phase.drop_objection(this);
    endtask
endclass

`endif
