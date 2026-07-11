
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
  .clk    (clk),
  .rst_n  (rst_n),
  .quad_x (quad_x),
  .quad_y (quad_y),
  .uart_rx(uart_rx),
  .uart_tx(uart_tx),
  .motor_x(motor_x),
  .motor_y(motor_y),
  .servo  (servo)
);

endmodule
