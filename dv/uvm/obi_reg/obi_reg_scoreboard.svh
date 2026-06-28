`ifndef OBI_REG_SCOREBOARD_SVH
`define OBI_REG_SCOREBOARD_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import obi_pkg::*;
import reg_pkg::*;
import prim_subreg_pkg::*;

`include "obi_reg_env_cfg.svh"

`uvm_analysis_imp_decl(_reg)

class obi_reg_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(obi_reg_scoreboard)

    typedef struct {
        logic valid;
        logic [31:0] data;
    } pend_t;

    virtual obi_if vif; // used for system clk
    obi_reg_env_cfg cfg;

    uvm_tlm_analysis_fifo #(obi_item) obi_fifo;
    uvm_tlm_analysis_fifo #(reg_item) hw_fifo[];

    pend_t sw_pend[];
    pend_t hw_pend[];

    logic [31:0] predicted[];

    function new (string name = "obi_reg_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(obi_reg_env_cfg)::get(null, "*", "obi_reg_env_cfg", cfg))
            `uvm_fatal(get_type_name(), "Failed to get obi_reg_env config")
        if (!uvm_config_db #(virtual obi_if)::get(this, "", "obi_if", vif))
            `uvm_fatal(get_type_name(), "Failed to get obi_if")

        obi_fifo = new("obi_fifo", this);
        hw_fifo = new[cfg.register_count];
        hw_pend = new[cfg.register_count];
        sw_pend = new[cfg.register_count];
        predicted = new[cfg.register_count];
        foreach (hw_fifo[i])
            hw_fifo[i] = new($sformatf("hw_fifo_%d", i), this);
    endfunction

    task run_phase(uvm_phase phase);
        obi_item ot;
        reg_item rt;
        super.run_phase(phase);
        
        forever begin
            @(posedge vif.clk);
            while (obi_fifo.try_get(ot)) begin
                int unsigned idx = ot.addr >> 2;   // byte address -> register index
                if (ot.we) begin
                    sw_pend[idx].valid = 1'b1;
                    sw_pend[idx].data = ot.wdata;
                end else begin
                    `uvm_info("SB", $sformatf("OBI read register %08h, %08h", idx, ot.rdata), UVM_MEDIUM)
                    for (int unsigned i = 0; i < $unsigned($bits(ot.be)); i++)
                        if (ot.be[i] && ot.rdata[i*8+:8] != predicted[idx][i*8+:8])
                            `uvm_error("SB", $sformatf("Reg @ %08h, expected: %08h got: %08h",
                                    ot.addr, predicted[idx], ot.rdata))
                end
            end
            foreach (hw_fifo[i]) begin
                if (hw_fifo[i].try_get(rt)) begin
                    hw_pend[i].valid = rt.hw_de;   // only a real hw_de pulse is a write
                    hw_pend[i].data  = rt.hw_d;
                end

                if (hw_pend[i].valid || sw_pend[i].valid) begin
                    predicted[i] = next_reg(cfg.modes[i],
                        hw_pend[i].valid, sw_pend[i].valid,
                        hw_pend[i].data,  sw_pend[i].data,
                        predicted[i]);
                end

                sw_pend[i] = '{default: '0};
                hw_pend[i] = '{default: '0};
            end
        end
    endtask

    // Mirrors prim_subreg's arbitration:
   function logic [31:0] next_reg(
        sw_access_e mode,
        logic de, logic we,
        logic [31:0] d, logic [31:0] wd,
        logic [31:0] q
    );
        logic        wr_en;
        logic [31:0] wr_data;

        case (mode)
            SwAccessRW, SwAccessWO: begin
                wr_en   = we | de;
                wr_data = we ? wd : d;
            end
            SwAccessRO: begin
                wr_en   = de;
                wr_data = d;
            end
            SwAccessW1S: begin
                wr_en   = we | de;
                wr_data = (de ? d : q) | (we ? wd : '0);
            end
            SwAccessW1C: begin
                wr_en   = we | de;
                wr_data = (de ? d : q) & (we ? ~wd : '1);
            end
            SwAccessW0C: begin
                wr_en   = we | de;
                wr_data = (de ? d : q) & (we ? wd : '1);
            end
            // SwAccessRC: begin                           // RC is not used nor allowed
            //     wr_en   = we | de;
            //     wr_data = (de ? d : q) & (we ? 32'b0 : '1);
            // end
            default: begin
                wr_en   = de;
                wr_data = d;
            end
        endcase

        return wr_en ? wr_data : q;
    endfunction
endclass


`endif
