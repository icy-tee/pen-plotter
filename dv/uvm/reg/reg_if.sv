interface reg_if (input logic clk, input logic rst_n);
    logic        hw_de;
    logic [31:0] hw_d;
    logic [31:0] hw_q;

    clocking drv_cb @(posedge clk);
        output hw_de, hw_d;
    endclocking

    clocking mon_cb @(posedge clk);
        input hw_q, hw_de, hw_d;
    endclocking

    modport drv (clocking drv_cb, input clk, rst_n);
    modport mon (clocking mon_cb, input clk, rst_n);

endinterface
