
module top_de23lite #(
    parameter SRAMInitFile = ""
) (
    input              CLOCK0_50,
    input              CLOCK1_50,

    input    [ 3: 0]   KEY, //BUTTON is Low-Active
    input    [ 9: 0]   SW,
    output   [ 9: 0]   LEDR, //LED is Low-Active

    output   [ 6: 0]   HEX0,
    output   [ 6: 0]   HEX1,
    output   [ 6: 0]   HEX2,
    output   [ 6: 0]   HEX3,
    output   [ 6: 0]   HEX4,
    output   [ 6: 0]   HEX5,

    output             DRAM_CLK,
    output             DRAM_CKE,
    output   [12: 0]   DRAM_ADDR,
    output   [ 1: 0]   DRAM_BA,
    inout    [31: 0]   DRAM_DQ,
    output             DRAM_CS_n,
    output             DRAM_WE_n,
    output             DRAM_CAS_n,
    output             DRAM_RAS_n,
    output   [ 3: 0]   DRAM_DQM,

    inout              HDMI_LRCLK,
    inout              HDMI_MCLK,
    inout              HDMI_SCLK,
    output             HDMI_TX_CLK,
    output             HDMI_TX_HS,
    output             HDMI_TX_VS,
    output   [23: 0]   HDMI_TX_D,
    output             HDMI_TX_DE,
    input              HDMI_TX_INT,
    inout              HDMI_I2S0,

    inout              FPGA_I2C_SCL,
    inout              FPGA_I2C_SDA,

    output             FPGA_UART_TX,
    input              FPGA_UART_RX,

    inout    [35: 0]   GPIO_D
);

wire [1:0] motor_x_w, motor_y_w;
wire [1:0] quad_x, quad_y;
wire servo;
wire config_done;

// LEDs off
assign LEDR = '1;

// 7-segment displays off (active low segments)
assign HEX0 = 7'h7F;
assign HEX1 = 7'h7F;
assign HEX2 = 7'h7F;
assign HEX3 = 7'h7F;
assign HEX4 = 7'h7F;
assign HEX5 = 7'h7F;

// SDRAM disabled
assign DRAM_CLK   = 1'b0;
assign DRAM_CKE   = 1'b0;
assign DRAM_CS_n  = 1'b1;
assign DRAM_WE_n  = 1'b1;
assign DRAM_CAS_n = 1'b1;
assign DRAM_RAS_n = 1'b1;
assign DRAM_ADDR  = 13'b0;
assign DRAM_BA    = 2'b0;
assign DRAM_DQM   = 4'hF;
assign DRAM_DQ    = 32'dz;

// HDMI disabled
assign HDMI_TX_CLK = 1'b0;
assign HDMI_TX_HS  = 1'b0;
assign HDMI_TX_VS  = 1'b0;
assign HDMI_TX_D   = 24'b0;
assign HDMI_TX_DE  = 1'b0;
assign HDMI_LRCLK  = 1'bz;
assign HDMI_MCLK   = 1'bz;
assign HDMI_SCLK   = 1'bz;
assign HDMI_I2S0   = 1'bz;

// I2C disabled
assign FPGA_I2C_SCL = 1'bz;
assign FPGA_I2C_SDA = 1'bz;

// GPIO: quadrature input
assign quad_y[0] = GPIO_D[1];
assign quad_y[1] = GPIO_D[3];
assign quad_x[0] = GPIO_D[5];
assign quad_x[1] = GPIO_D[7];
// GPIO: motor pins driven
assign GPIO_D[11] = motor_x_w[1];
assign GPIO_D[13] = motor_x_w[0];
assign GPIO_D[15] = motor_y_w[1];
assign GPIO_D[17] = motor_y_w[0];
// GPIO: servo output, rest high-Z
assign GPIO_D[19] = servo;

assign GPIO_D[0] = 1'bz;
assign GPIO_D[2] = 1'bz;
assign GPIO_D[4] = 1'bz;
assign GPIO_D[6] = 1'bz;
assign GPIO_D[8] = 1'bz;
assign GPIO_D[10: 9] = 2'dz;
assign GPIO_D[12] = 1'bz;
assign GPIO_D[14] = 1'bz;
assign GPIO_D[16] = 1'bz;
assign GPIO_D[18] = 1'bz;
assign GPIO_D[35: 20] = 16'dz;

reset_release u_reset_release(
    .ninit_done(config_done)
);

pp_system #(
    .SRAMInitFile(SRAMInitFile)
 ) pp_system (
    .clk    (CLOCK0_50),
    .rst_n  (KEY[0 & ~config_done]),
    .quad_x (quad_x),
    .quad_y (quad_y),
    .uart_rx(FPGA_UART_RX),
    .uart_tx(FPGA_UART_TX),
    .motor_x(motor_x_w),
    .motor_y(motor_y_w),
    .pwm    (servo)
);

endmodule
