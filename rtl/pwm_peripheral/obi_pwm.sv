
module obi_pwm #(
    parameter int unsigned PWMCount = 1
) (
    input logic clk,
    input logic rst_ni,

    output logic [PWMCount-1:0] pwm_o,

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

localparam int unsigned RegisterCount = 2 * PWMCount;

localparam int unsigned PeriodIdx = 0;
localparam int unsigned WidthIdx = 1;

logic [RegisterCount-1:0][31:0] hw_d, hw_q;
logic [RegisterCount-1:0] hw_de;

assign hw_d = '0;
assign hw_de = '0;

generate
    for (genvar i = 0; i < PWMCount; i++) begin : gen_pwm
        prgm_pwm u_pwm (
          .clk     (clk),
          .rst_n   (rst_ni),
          .period_i(hw_q[$unsigned(i*2)+PeriodIdx]),
          .width_i (hw_q[$unsigned(i*2)+WidthIdx]),
          .pwm_o   (pwm_o[i])
        );
    end
endgenerate

obi_reg #(
    .RegisterCount(RegisterCount)
    ) obi_reg (
    .clk     (clk),
    .rst_ni  (rst_ni),

    .hw_de_i (hw_de),
    .hw_d_i  (hw_d),
    .hw_q_o  (hw_q),

    .sw_we_o (),
    .sw_wd_o (),

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

endmodule
