`ifndef OBI_REG_ENV_CFG_SVH
`define OBI_REG_ENV_CFG_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;
import prim_subreg_pkg::sw_access_e;

class obi_reg_env_cfg extends uvm_object;
    `uvm_object_utils(obi_reg_env_cfg)

    int unsigned register_count;
    sw_access_e modes[];

    function new(string name = "obi_reg_env_cfg");
        super.new(name);
    endfunction

endclass

`endif
