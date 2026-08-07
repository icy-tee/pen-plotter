`ifndef OBI_BUS_SCOREBOARD_SVH
`define OBI_BUS_SCOREBOARD_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;

`include "obi_bus_env_cfg.svh"

class obi_bus_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(obi_bus_scoreboard)

    typedef struct {
        int unsigned host;
        bit valid;
    } pend_t;

    virtual obi_if vif;

    obi_bus_env_cfg cfg;

    uvm_tlm_analysis_fifo #(obi_item) host_aphase_fifo[];
    uvm_tlm_analysis_fifo #(obi_item) device_aphase_fifo[];
    uvm_tlm_analysis_fifo #(obi_item) host_rphase_fifo[];
    uvm_tlm_analysis_fifo #(obi_item) device_rphase_fifo[];

    pend_t pending_rphase[]; // indexed by device; one outstanding response per device

    function new (string name = "obi_bus_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(obi_bus_env_cfg)::get(null, "*", "obi_bus_env_cfg", cfg))
            `uvm_fatal(get_type_name(), "Failed to get obi_bus_env config")
        if (!uvm_config_db #(virtual obi_if)::get(this, "", "obi_if", vif))
            `uvm_fatal(get_type_name(), "Failed to get obi_if")

        host_aphase_fifo = new [cfg.host_count];
        host_rphase_fifo = new [cfg.host_count];

        device_aphase_fifo = new [cfg.device_count];
        device_rphase_fifo = new [cfg.device_count];
        pending_rphase = new [cfg.device_count];

        foreach (host_aphase_fifo[i])
            host_aphase_fifo[i] = new($sformatf("host_aphase_fifo_%0d", i), this);
        foreach (device_aphase_fifo[i])
            device_aphase_fifo[i] = new($sformatf("device_aphase_fifo_%0d", i), this);

        foreach (host_rphase_fifo[i])
            host_rphase_fifo[i] = new($sformatf("host_rphase_fifo_%0d", i), this);
        foreach (device_rphase_fifo[i])
            device_rphase_fifo[i] = new($sformatf("device_rphase_fifo_%0d", i), this);
    endfunction

    task run_phase(uvm_phase phase);
        obi_item host_ot;
        obi_item device_ot;
        super.run_phase(phase);

        forever begin
            @(posedge vif.clk);

            foreach (host_aphase_fifo[i]) begin
                if (host_aphase_fifo[i].try_get(host_ot)) begin
                    bit matched;
                    matched = 1'b0;

                    for (int unsigned j = 0; j < cfg.device_count; j++) begin
                        if ((host_ot.addr & cfg.device_addr_mask[j])
                                == cfg.device_addr_base[j]) begin
                            int unsigned host_idx;
                            int unsigned device_idx;
                            matched = 1'b1;
                            host_idx = $unsigned(i);
                            device_idx = j;

                            fork
                                begin : check_a_phase
                                    device_aphase_fifo[device_idx].get(device_ot);

                                    if (pending_rphase[device_idx].valid) begin
                                        `uvm_error("SB", $sformatf("(H:%0d, D:%0d) New request while response is pending",
                                            host_idx, device_idx))
                                    end else if (host_ot.be != device_ot.be ||
                                            host_ot.we != device_ot.we ||
                                            host_ot.wdata != device_ot.wdata ||
                                            (host_ot.addr & ~cfg.device_addr_mask[device_idx]) != device_ot.addr) begin
                                        `uvm_error("SB", $sformatf("(H:%0d, D:%0d) OBI transaction corrupted",
                                            host_idx, device_idx))
                                    end else begin
                                        `uvm_info("SB", $sformatf("(H:%0d, D:%0d) OBI transaction successful",
                                            host_idx, device_idx), UVM_MEDIUM)
                                        pending_rphase[device_idx].host = host_idx;
                                        pending_rphase[device_idx].valid = 1'b1;
                                    end
                                end
                                begin : check_for_drop
                                    repeat (20) @(posedge vif.clk);
                                    `uvm_error("SB", $sformatf("(H:%0d, D:%0d) OBI transaction dropped",
                                        host_idx, device_idx))
                                end
                            join_any
                            disable fork;
                        end
                    end

                    if (!matched) begin
                        `uvm_error("SB", $sformatf("(H:%0d) OBI transaction to unmapped address %08h",
                            i, host_ot.addr))
                    end
                end
            end

            foreach (device_rphase_fifo[i]) begin
                if (device_rphase_fifo[i].try_get(device_ot)) begin
                    int unsigned device_idx;
                    int unsigned host_idx;
                    device_idx = $unsigned(i);

                    if (!pending_rphase[device_idx].valid) begin
                        `uvm_error("SB", $sformatf("(D:%0d) Unexpected OBI device response", device_idx))
                        continue;
                    end else begin
                        host_idx = pending_rphase[device_idx].host;

                        fork
                            begin : check_host
                                host_rphase_fifo[host_idx].get(host_ot);

                                if (device_ot.rdata != host_ot.rdata ||
                                    device_ot.err   != host_ot.err) begin
                                    `uvm_error("SB", $sformatf("(H:%0d, D:%0d) Corrupted OBI response",
                                        host_idx, device_idx))
                                end else begin
                                    `uvm_info("SB", $sformatf("(H:%0d, D:%0d) Full OBI transaction completed",
                                        host_idx, device_idx), UVM_MEDIUM)
                                end

                                pending_rphase[device_idx].valid = 1'b0;
                            end
                            begin : timeout
                                repeat(20) @(posedge vif.clk);
                                `uvm_error("SB", $sformatf("(H:%0d, D:%0d) OBI host passthrough timeout",
                                    host_idx, device_idx))
                                pending_rphase[device_idx].valid = 1'b0;
                            end
                        join_any
                        disable fork;
                    end
                end
            end
        end
    endtask
endclass

`endif
