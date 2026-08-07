
module obi_quad (
    input clk,
    input rst_ni,

    input [1:0] quad_x_i,
    input [1:0] quad_y_i,

    output logic [31:0] hw_quad_x,
    output logic [31:0] hw_quad_y,

    input  logic        req_i,
    output logic        gnt_o,
    input  logic [31:0] addr_i,
    input  logic        we_i,
    input  logic [ 3:0] be_i,
    input  logic [31:0] wdata_i,
    output logic        rvalid_o,
    output logic [31:0] rdata_o,
    output logic        err_o
);

import prim_subreg_pkg::SwAccessW1C;

localparam int unsigned QuadCount = 2;
localparam int unsigned QuadX = 0;
localparam int unsigned QuadY = 1;

logic [QuadCount-1:0]        hw_de, sw_we;
logic [QuadCount-1:0] [31:0] sw_wd, hw_d;
logic [QuadCount-1:0]        clr_quad;

assign hw_d[QuadX] = hw_quad_x;
assign hw_d[QuadY] = hw_quad_y;

assign clr_quad[QuadX] = sw_we[QuadX] && (sw_wd[QuadX] == 32'h1);
assign clr_quad[QuadY] = sw_we[QuadY] && (sw_wd[QuadY] == 32'h1);
assign hw_de = ~clr_quad;

obi_reg #(
    .RegisterCount(QuadCount),
    .UsedAddrWidth(8),
    .RegAccess    ({QuadCount{SwAccessW1C}})
 ) obi_reg (
    .clk     (clk),
    .rst_ni  (rst_ni),

    .hw_de_i   (hw_de),
    .hw_d_i    (hw_d),
    .hw_q_o    (),

    .sw_we_o   (sw_we),
    .sw_wd_o   (sw_wd),

    .req_i,
    .gnt_o,
    .addr_i,
    .we_i,
    .be_i,
    .wdata_i,
    .rvalid_o,
    .rdata_o,
    .err_o
);

quad_decoder u_quad_x (
    .clk          (clk),
    .rst_n        (rst_ni),
    .clr_i        (clr_quad[QuadX]),
    .A_i          (quad_x_i[0]),
    .B_i          (quad_x_i[1]),
    .tick_position(hw_quad_x)
);

quad_decoder u_quad_y (
    .clk          (clk),
    .rst_n        (rst_ni),
    .clr_i        (clr_quad[QuadY]),
    .A_i          (quad_y_i[0]),
    .B_i          (quad_y_i[1]),
    .tick_position(hw_quad_y)
);


endmodule
