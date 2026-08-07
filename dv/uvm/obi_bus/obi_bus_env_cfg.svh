`ifndef OBI_BUS_ENV_CFG_SVH
`define OBI_BUS_ENV_CFG_SVH

`include "uvm_macros.svh"
import uvm_pkg::*;

class obi_bus_env_cfg extends uvm_object;
    `uvm_object_utils(obi_bus_env_cfg)

    int unsigned device_count;
    int unsigned host_count;

    logic [31:0]  device_addr_base [];
    logic [31:0]  device_addr_mask [];

    function new(string name = "obi_bus_env_cfg");
        super.new(name);
    endfunction

endclass

`endif
