
`include "uvm_macros.svh"

module obi_uart_tb_top;
    timeunit 1ns / 1ps;
    import uvm_pkg::*;
    import obi_uart_tests_pkg::*;
    import uart_pkg::uart_cfg;


    localparam time ClkPeriod = 10ns;

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
        uart_cfg m_uart_cfg = uart_cfg::type_id::create("m_uart_cfg");
        m_uart_cfg.baud = uart_obi_pkg::BAUD_115200;
        uvm_config_db #(virtual uart_if)::set (null, "*", "uart_if", uart_if);
        uvm_config_db #(virtual obi_if)::set (null, "uvm_test_top.env.obi_agt*", "obi_if", obi_if);
        uvm_config_db #(uart_cfg)::set (null, "*", "m_uart_cfg", m_uart_cfg);

        run_test("obi_uart_write_test");
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
