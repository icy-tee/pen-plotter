`ifndef OBI_REG_TEST_SVH
`define OBI_REG_TEST_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_reg_env_pkg::*;
import obi_pkg::*;

class obi_reg_test extends uvm_test;
    `uvm_component_utils(obi_reg_test)

    obi_reg_env env;

    function new(string name = "obi_reg_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = obi_reg_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);

        super.run_phase(phase);
        phase.raise_objection(this);

        for (int unsigned i = 0; i < 4; i++) begin
            reg_wr_seq oseq = reg_wr_seq::type_id::create("oseq");
            assert(oseq.randomize());
            oseq.target = i * 4;
            oseq.start(env.obi_agt.sqr);
        end
        #1us;
        phase.drop_objection(this);
    endtask
endclass

`endif

