
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
) u_pp_system (
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

import "DPI-C" function void host_gnt_received (
        input bit [31:0] addr,
        input bit [31:0] wdata,
        input bit we,
        input bit [3:0] be
);

import "DPI-C" function void host_rvalid_received (
        input bit [31:0] rdata,
        input bit err
);

always_ff @(posedge clk or negedge rst_n) begin
    if (rst_n) begin
        if (u_pp_system.host_req[0] &&
            u_pp_system.host_gnt[0]) begin
            host_gnt_received(
                u_pp_system.host_addr [0],
                u_pp_system.host_wdata[0],
                u_pp_system.host_we   [0],
                u_pp_system.host_be   [0]
            );
        end

        if (u_pp_system.host_rvalid[0]) begin
            host_rvalid_received(
                u_pp_system.host_rdata[0],
                u_pp_system.host_err  [0]
            );
        end
    end
end

endmodule
