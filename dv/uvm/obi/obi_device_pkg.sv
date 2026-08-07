package obi_device_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import base_obi_pkg::*;
    export base_obi_pkg::*;

    `include "obi_device_driver.svh"
    `include "obi_device_agent.svh"
endpackage
