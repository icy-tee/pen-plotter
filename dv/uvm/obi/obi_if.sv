interface obi_if(input logic clk, input logic rst_n);
    logic        req;
    logic        gnt;
    logic [31:0] addr;
    logic        we;
    logic [ 3:0] be;
    logic [31:0] wdata;
    logic        rvalid;
    logic [31:0] rdata;
    logic        err;

    clocking drv_cb @(posedge clk);
        output req, addr, we, be, wdata;
        input gnt, rvalid, rdata, err;
    endclocking

    clocking mon_cb @(posedge clk);
        input req, addr, we, be, wdata, gnt, rvalid, rdata, err;
    endclocking

    modport drv (clocking drv_cb, input clk, rst_n);
    modport mon (clocking mon_cb, input clk, rst_n);

endinterface
