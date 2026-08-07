
module obi_sys_timer (
    input logic clk,
    input logic rst_ni,

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

localparam int unsigned RegisterCount = 5;

localparam int unsigned ControlLane = 0;
localparam int unsigned MTimeLoLane = 1;
localparam int unsigned MTimeHiLane = 2;
localparam int unsigned MTimeCMPLoLane = 3;
localparam int unsigned MTimeCMPHiLane = 4;

localparam logic [RegisterCount-1:0][31:0] RegResValue = '{
    ControlLane: 32'b0,
    MTimeLoLane: 32'b0,
    MTimeHiLane: 32'b0,
    MTimeCMPLoLane: 32'hFFFF_FFFF,
    MTimeCMPHiLane: 32'hFFFF_FFFF
};

typedef struct {
    logic enable;
    logic irq_enable;
} control_t;

logic [RegisterCount-1:0][31:0] hw_d, hw_q;
logic [RegisterCount-1:0] hw_de;
logic [RegisterCount-1:0] sw_we;

logic [63:0] mtime, mtime_cmp;
control_t ctrl;

assign ctrl.enable = hw_q[ControlLane][0];
assign ctrl.irq_enable = hw_q[ControlLane][1];

assign mtime = {hw_q[MTimeHiLane], hw_q[MTimeLoLane]};
assign mtime_cmp = {hw_q[MTimeCMPHiLane], hw_q[MTimeCMPLoLane]};

assign irq_o = ctrl.irq_enable && ctrl.enable && (mtime >= mtime_cmp);

always_comb begin
    hw_d = '0;
    hw_de = '0;
    if (ctrl.enable && !sw_we[MTimeLoLane] && !sw_we[MTimeHiLane]) begin
        {hw_d[MTimeHiLane], hw_d[MTimeLoLane]} = mtime + 64'd1;
        {hw_de[MTimeHiLane], hw_de[MTimeLoLane]} = 2'b11;
    end
end

obi_reg #(
    .RegisterCount(RegisterCount),
    .ResValue( RegResValue )
    ) obi_reg (
    .clk     (clk),
    .rst_ni  (rst_ni),

    .hw_de_i (hw_de),
    .hw_d_i  (hw_d),
    .hw_q_o  (hw_q),

    .sw_we_o (sw_we),
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
