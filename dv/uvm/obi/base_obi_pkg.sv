package base_obi_pkg;
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "obi_item.svh"

    typedef uvm_sequencer #(obi_item) obi_sequencer;

    `include "obi_monitor.svh"
    `include "base_obi_seq.svh"
endpackage
