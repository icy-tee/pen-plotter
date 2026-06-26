`ifndef OBI_REG_ENV_SVH
`define OBI_REG_ENV_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;
import reg_pkg::*;
`include "obi_reg_env_cfg.svh"
`include "obi_reg_scoreboard.svh"

class obi_reg_env extends uvm_env;
    `uvm_component_utils(obi_reg_env)

    obi_reg_env_cfg cfg;

    obi_agent obi_agt;
    reg_agent hw_agt[];
    obi_reg_scoreboard scb;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(obi_reg_env_cfg)::get(null, "*", "obi_reg_env_cfg", cfg))
            `uvm_fatal(get_type_name(), "Failed to get obi_reg_env config")

        obi_agt = obi_agent::type_id::create("obi_agt", this);
        hw_agt = new[cfg.register_count];
        foreach (hw_agt[i])
            hw_agt[i] = reg_agent::type_id::create($sformatf("hw_agt_%0d", i), this);
        scb = obi_reg_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        obi_agt.mon.ap.connect(scb.obi_fifo.analysis_export);
        foreach(hw_agt[i])
            hw_agt[i].mon.ap.connect(scb.hw_fifo[i].analysis_export);
    endfunction

endclass

`endif // OBI_REG_ENV_SVH
