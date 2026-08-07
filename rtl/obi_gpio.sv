
module obi_gpio #(
    
) (
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

// TODO: implement

endmodule
