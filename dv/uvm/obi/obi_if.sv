// DEVICE=0 (default): host/master view
// DEVICE=1          : device/slave view
interface obi_if #(parameter bit DEVICE = 1'b0) (input logic clk, input logic rst_n);
    logic        req;
    logic        gnt;
    logic [31:0] addr;
    logic        we;
    logic [ 3:0] be;
    logic [31:0] wdata;
    logic        rvalid;
    logic [31:0] rdata;
    logic        err;

    clocking mon_cb @(posedge clk);
        input req, addr, we, be, wdata, gnt, rvalid, rdata, err;
    endclocking

    if (!DEVICE) begin : g_drv
        clocking drv_cb @(posedge clk);
            output req, addr, we, be, wdata;
            input  gnt, rvalid, rdata, err;
        endclocking
    end else begin : g_drv
        clocking drv_cb @(posedge clk);
            input  req, addr, we, be, wdata;
            output gnt, rvalid, rdata, err;
        endclocking
    end

endinterface
