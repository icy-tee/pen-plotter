

import pp_pkg::*;

module pp_top (
  input clk,
  input rst_n,
  input [1:0] quad_x,
  input [1:0] quad_y,
  input uart_rx,
  output uart_tx,
  output [1:0] motor_x,
  output [1:0] motor_y
);

int signed tick_pos_x, tick_pos_y;

logic fifo_read, fifo_empty;
logic [7:0] fifo_data;

logic tx_flush, tx_valid, tx_busy;
logic [7:0] tx_data;

md_mode_e x_dir /* verilator public */, y_dir /* verilator public */;
logic [7:0] x_duty /* verilator public */, y_duty /* verilator public */;

uart_rx_fifo u_rx_fifo(
    .clk(clk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .bf_data(fifo_data),
    .bf_read(fifo_read),
    .bf_empty(fifo_empty)
);

uart_tx_fifo u_tx_fifo(
    .clk(clk),
    .rst_n(rst_n),
    .uart_tx_o(uart_tx),
    .data_i(tx_data),
    .data_valid_i(tx_valid),
    .flush_p(tx_flush),
    .busy_o(tx_busy)
);

pp_controller u_pp_controller(
    .clk(clk),
    .rst_n(rst_n),
    .data_i(fifo_data),
    .data_empty_i(fifo_empty),
    .modeX(x_dir),
    .modeY(y_dir),
    .dutyX(x_duty),
    .dutyY(y_duty),
    .next_data_o(fifo_read),
    .tickX_i(tick_pos_x),
    .tickY_i(tick_pos_y),
    .tx_data_o(tx_data),
    .tx_valid_o(tx_valid),
    .tx_flush_o(tx_flush)
);

md_controller u_x_motor_controller(
    .clk(clk),
    .rst_n(rst_n),
    .mode(x_dir),
    .duty(x_duty),
    .in1(motor_x[0]),
    .in2(motor_x[1])
);

md_controller u_y_motor_controller(
    .clk(clk),
    .rst_n(rst_n),
    .mode(y_dir),
    .duty(y_duty),
    .in1(motor_y[0]),
    .in2(motor_y[1])
);

quad_decoder u_x_quad(
    .clk(clk),
    .rst_n(rst_n),
    .A_i(quad_x[0]),
    .B_i(quad_x[1]),
    .tick_position(tick_pos_x)
);

quad_decoder u_y_quad(
    .clk(clk),
    .rst_n(rst_n),
    .A_i(quad_y[0]),
    .B_i(quad_y[1]),
    .tick_position(tick_pos_y)
);

endmodule
