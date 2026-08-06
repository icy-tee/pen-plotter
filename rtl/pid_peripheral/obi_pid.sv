
module obi_pid
    import pp_pkg::*; (
    input clk,
    input rst_ni,

    input i32_t hw_pv_x_i,
    input i32_t hw_pv_y_i,

    output [1:0] motor_x_o,
    output [1:0] motor_y_o,
    output logic irq_o,

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
import prim_subreg_pkg::SwAccessRW;
import prim_subreg_pkg::SwAccessW1C;

localparam int unsigned ClockRate = 50_000_000;
localparam int unsigned SampleRateWidth = $clog2(ClockRate);
localparam int unsigned PerPIDRegCount = 4; // Kp, Kd, Rs, SP
localparam int unsigned PIDCount = 2;
localparam int unsigned PIDRegCount = PerPIDRegCount * PIDCount;
localparam int unsigned PIDOffset = 1; // to account for STS register
localparam int unsigned StatusIdx = 0;
localparam int unsigned TotalRegCount = PIDRegCount + 1;

localparam int unsigned PidX = 0;
localparam int unsigned PidY = 1;

localparam int unsigned KpReg = 0;
localparam int unsigned KdReg = 1;
localparam int unsigned RsReg = 2;
localparam int unsigned SpReg = 3;

typedef struct packed {
    logic [29:0] padding;
    logic stable_y;
    logic stable_x;
} pid_status_reg_t;

typedef struct {
    q16_16_t     Kp;
    q16_16_t     Kd;
    logic [31:0] Rs;
    i32_t        SP;
} pid_reg_layout_t;

logic [TotalRegCount-1:0] hw_de;
logic [TotalRegCount-1:0][31:0] hw_q, hw_d;
pid_reg_layout_t pid_cfg [PIDCount];

md_mode_e   md_x_dir,  md_y_dir;
logic [7:0] md_x_duty, md_y_duty;

wire stable_x, stable_y;
logic [1:0] stable_x_l, stable_y_l;
logic status_de;
pid_status_reg_t status_d, status_q;

genvar gi;
generate
    for (gi = 0; gi < PIDCount; gi++) begin : gen_pid_cfg
        assign pid_cfg[gi].Kp = $signed(hw_q[PIDOffset + gi * PerPIDRegCount + KpReg]);
        assign pid_cfg[gi].Kd = $signed(hw_q[PIDOffset + gi * PerPIDRegCount + KdReg]);
        assign pid_cfg[gi].Rs = hw_q[PIDOffset + gi * PerPIDRegCount + RsReg];
        assign pid_cfg[gi].SP = $signed(hw_q[PIDOffset + gi * PerPIDRegCount + SpReg]);

        assign hw_d[PIDOffset + gi * PerPIDRegCount + KpReg] = 32'b0;
        assign hw_d[PIDOffset + gi * PerPIDRegCount + KdReg] = 32'b0;
        assign hw_d[PIDOffset + gi * PerPIDRegCount + RsReg] = 32'b0;
        assign hw_d[PIDOffset + gi * PerPIDRegCount + SpReg] = 32'b0;

        assign hw_de[PIDOffset + gi * PerPIDRegCount + KpReg] = 1'b0;
        assign hw_de[PIDOffset + gi * PerPIDRegCount + KdReg] = 1'b0;
        assign hw_de[PIDOffset + gi * PerPIDRegCount + RsReg] = 1'b0;
        assign hw_de[PIDOffset + gi * PerPIDRegCount + SpReg] = 1'b0;
    end
endgenerate

assign hw_de[StatusIdx] = status_de;
assign hw_d[StatusIdx] = status_d;
assign status_q = hw_q[StatusIdx];

obi_reg #(
    .RegisterCount(TotalRegCount),
    .UsedAddrWidth(8),
    .RegAccess    ({{PIDRegCount{SwAccessRW}}, SwAccessW1C})
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

pid_controller #(
    .CLOCK_RATE(ClockRate)
) u_pid_x (
    .clk                    (clk),
    .rst_n                  (rst_ni),
    .proportional_constant_i(pid_cfg[PidX].Kp),
    .derivative_constant_i  (pid_cfg[PidX].Kd),
    .sample_rate_i          (pid_cfg[PidX].Rs[SampleRateWidth-1:0]),
    .process_variable_i     (hw_pv_x_i),
    .setpoint_i             (pid_cfg[PidX].SP),
    .stable_o               (stable_x),
    .motor_dir_o            (md_x_dir),
    .motor_duty_o           (md_x_duty)
);

pid_controller #(
    .CLOCK_RATE(ClockRate)
) u_pid_y (
    .clk                    (clk),
    .rst_n                  (rst_ni),
    .proportional_constant_i(pid_cfg[PidY].Kp),
    .derivative_constant_i  (pid_cfg[PidY].Kd),
    .sample_rate_i          (pid_cfg[PidY].Rs[SampleRateWidth-1:0]),
    .process_variable_i     (hw_pv_y_i),
    .setpoint_i             (pid_cfg[PidY].SP),
    .stable_o               (stable_y),
    .motor_dir_o            (md_y_dir),
    .motor_duty_o           (md_y_duty)
);

md_controller #(
    .CLOCK_RATE(ClockRate)
) u_md_x (
    .clk  (clk),
    .rst_n(rst_ni),
    .mode (md_x_dir),
    .duty (md_x_duty),
    .in1  (motor_x_o[0]),
    .in2  (motor_x_o[1])
);

md_controller #(
    .CLOCK_RATE(ClockRate)
) u_md_y (
    .clk  (clk),
    .rst_n(rst_ni),
    .mode (md_y_dir),
    .duty (md_y_duty),
    .in1  (motor_y_o[0]),
    .in2  (motor_y_o[1])
);

always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
        stable_x_l <= '0;
        stable_y_l <= '0;
    end else begin
        stable_x_l <= {stable_x, stable_x_l[1]};
        stable_y_l <= {stable_y, stable_y_l[1]};
    end
end

always_comb begin
    automatic logic stable_x_event = stable_x_l[1] && !stable_x_l[0];
    automatic logic stable_y_event = stable_y_l[1] && !stable_y_l[0];

    status_d = status_q;

    status_de = stable_x_event | stable_y_event;
    if (stable_x_event) status_d.stable_x = 1'b1;
    if (stable_y_event) status_d.stable_y = 1'b1;

    irq_o = status_q.stable_x | status_q.stable_y;
end

endmodule
