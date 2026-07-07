`ifndef OBI_BUS_ENV_SVH
`define OBI_BUS_ENV_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;
import obi_device_pkg::*;

`include "obi_bus_env_cfg.svh"
`include "obi_bus_scoreboard.svh"

class obi_bus_env extends uvm_env;
    `uvm_component_utils(obi_bus_env)

    obi_bus_env_cfg cfg;

    obi_agent host_agt[];
    obi_device_agent device_agt[];
    obi_bus_scoreboard scb;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(obi_bus_env_cfg)::get(null, "*", "obi_bus_env_cfg", cfg))
            `uvm_fatal(get_type_name(), "Failed to get obi_bus_env config")

        host_agt = new[cfg.host_count];
        device_agt = new[cfg.device_count];
        foreach (host_agt[i])
            host_agt[i] = obi_agent::type_id::create($sformatf("host_agt_%0d", i), this);
        foreach (device_agt[i])
            device_agt[i] = obi_device_agent::type_id::create($sformatf("device_agt_%0d", i), this);

        scb = obi_bus_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        foreach (host_agt[i]) begin
            host_agt[i].mon.phase_a_ap.connect(scb.host_aphase_fifo[i].analysis_export);
            host_agt[i].mon.phase_r_ap.connect(scb.host_rphase_fifo[i].analysis_export);
        end

        foreach (device_agt[i]) begin
            device_agt[i].mon.phase_a_ap.connect(scb.device_aphase_fifo[i].analysis_export);
            device_agt[i].mon.phase_r_ap.connect(scb.device_rphase_fifo[i].analysis_export);
        end
    endfunction

endclass

`endif // OBI_BUS_ENV_SVH
