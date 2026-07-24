
module prim_altera_ram_2p
    import prim_ram_2p_pkg::*;
#(
    parameter int Depth       = 128,
    parameter     MemInitFile = "",

    localparam int Aw = $clog2(Depth)
) (
    input  logic          clk_i,

    input  logic          a_req_i,
    input  logic          a_write_i,
    input  logic [Aw-1:0] a_addr_i,
    input  logic [31:0]   a_wdata_i,
    input  logic [31:0]   a_wmask_i,
    output logic [31:0]   a_rdata_o,

    input  logic          b_req_i,
    input  logic          b_write_i,
    input  logic [Aw-1:0] b_addr_i,
    input  logic [31:0]   b_wdata_i,
    input  logic [31:0]   b_wmask_i,
    output logic [31:0]   b_rdata_o,

    input  ram_2p_cfg_t      cfg_i
);

logic unused_cfg;
assign unused_cfg = ^cfg_i;

// Reduce the Width-wide bit mask to a 4-bit per-byte enable, matching
// altsyncram's byteena semantics.
logic [3:0] a_byteena, b_byteena;
assign a_byteena[0] = &a_wmask_i[ 7: 0];
assign a_byteena[1] = &a_wmask_i[15: 8];
assign a_byteena[2] = &a_wmask_i[23:16];
assign a_byteena[3] = &a_wmask_i[31:24];
assign b_byteena[0] = &b_wmask_i[ 7: 0];
assign b_byteena[1] = &b_wmask_i[15: 8];
assign b_byteena[2] = &b_wmask_i[23:16];
assign b_byteena[3] = &b_wmask_i[31:24];

// Agilex 3's M20K TDP mode requires a single clock and forbids OLD_DATA
// mixed-port RDW.
// The demo system's bus arbiter prevents simultaneous same-address access
// from the two Ibex sides, so DONT_CARE RDW is safe.

altsyncram #(
    .operation_mode                    ("BIDIR_DUAL_PORT"),
    .width_a                           (32),
    .widthad_a                         (Aw),
    .numwords_a                        (Depth),
    .width_b                           (32),
    .widthad_b                         (Aw),
    .numwords_b                        (Depth),
    .width_byteena_a                   (4),
    .width_byteena_b                   (4),
    .byte_size                         (8),
    // M20K output register is *disabled* so total read latency is 1 cycle
    // (input register only). This matches the 1-cycle `rvalid` timing in
    // ram_2p.sv. Leaving the output register on yields 2-cycle latency, which
    // arrives after `rvalid` has already been asserted: Ibex then samples
    // stale/X rdata, traps on the bogus instruction, and never makes progress.
    .outdata_reg_a                     ("UNREGISTERED"),
    .outdata_reg_b                     ("UNREGISTERED"),
    .indata_reg_b                      ("CLOCK0"),
    .address_reg_b                     ("CLOCK0"),
    .byteena_reg_b                     ("CLOCK0"),
    .wrcontrol_wraddress_reg_b         ("CLOCK0"),
    .read_during_write_mode_port_a     ("DONT_CARE"),
    .read_during_write_mode_port_b     ("DONT_CARE"),
    .read_during_write_mode_mixed_ports("DONT_CARE"),
    .init_file                         ((MemInitFile == "") ? "UNUSED" : MemInitFile),
    .lpm_type                          ("altsyncram")
) u_impl (
    .clock0         (clk_i),
    .address_a      (a_addr_i),
    .address_b      (b_addr_i),
    .data_a         (a_wdata_i),
    .data_b         (b_wdata_i),
    .wren_a         (a_req_i &  a_write_i),
    .wren_b         (b_req_i &  b_write_i),
    .rden_a         (a_req_i & ~a_write_i),
    .rden_b         (b_req_i & ~b_write_i),
    .byteena_a      (a_byteena),
    .byteena_b      (b_byteena),
    .q_a            (a_rdata_o),
    .q_b            (b_rdata_o),
    .clocken0       (1'b1),
    .aclr0          (1'b0),
    .addressstall_a (1'b0),
    .addressstall_b (1'b0),
    .eccstatus      ()
);

endmodule
