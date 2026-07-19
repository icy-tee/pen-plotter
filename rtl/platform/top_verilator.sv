
module top_verilator #(
    parameter string SRAMInitFile = ""
) (
    input clk,
    input rst_n,
    input [1:0] quad_x,
    input [1:0] quad_y,
    input uart_rx,
    output uart_tx,
    output [1:0] motor_x,
    output [1:0] motor_y,
    output servo
);

pp_system #(
    .SRAMInitFile(SRAMInitFile)
) pp_system (
    .clk,
    .rst_n,
    .quad_x,
    .quad_y,
    .uart_rx,
    .uart_tx,
    .motor_x,
    .motor_y,
    .pwm(servo)
);

endmodule
