
`include "uvm_macros.svh"

module obi_uart_tb_top;
    timeunit 1ns / 1ps;
    import uvm_pkg::*;
    import obi_uart_tests_pkg::*;


    localparam time ClkPeriod = 10ns;
    localparam int unsigned DeviceMask = 32'h0000_000F;

    bit clk, rst_n;
    always #ClkPeriod clk <= ~clk;

    uart_if uart_if (.clk(clk), .rst_n(rst_n));
    obi_if  obi_if  (.clk(clk), .rst_n(rst_n));

    uart_obi #(
        .ClockRate   (50_000_000)
     ) dut (
        .clk          (clk),
        .rst_ni       (rst_n),
        .rx_i         (uart_if.tx),
        .device_mask_i(DeviceMask),
        .tx_o         (uart_if.rx),
        .req_i        (obi_if.req),
        .gnt_o        (obi_if.gnt),
        .addr_i       (obi_if.addr),
        .we_i         (obi_if.we),
        .be_i         (obi_if.be),
        .wdata_i      (obi_if.wdata),
        .rvalid_o     (obi_if.rvalid),
        .rdata_o      (obi_if.rdata),
        .err_o        (obi_if.err)
    );

    initial begin
        uvm_config_db #(virtual uart_if)::set (null, "*", "uart_if", uart_if);
        uvm_config_db #(virtual obi_if)::set (null, "*", "obi_if", obi_if);
        uvm_config_db #(int unsigned)::set (null, "*", "device_mask", DeviceMask);
        uvm_config_db #(int unsigned)::set (null, "*", "clks_per_bit", 50000000 / 9600);

        run_test("obi_uart_base_test");
    end

    initial begin
        rst_n = '0;
        repeat (4) @(posedge clk);
        rst_n = '1;
    end

    initial begin
        $dumpvars;
        $dumpfile("dump.vcd");
    end


endmodule
