package obi_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import base_obi_pkg::*;
    export base_obi_pkg::*;
    export base_obi_pkg::base_obi_seq;

    `include "obi_driver.svh"
    `include "obi_agent.svh"
endpackage
