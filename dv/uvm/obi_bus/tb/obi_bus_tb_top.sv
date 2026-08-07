`include "uvm_macros.svh"

module obi_bus_tb_top;
    timeunit 1ns / 1ps;

    import uvm_pkg::*;
    import obi_bus_env_pkg::*;
    import obi_bus_tests_pkg::*;

    localparam time         ClkPeriod   = 10ns;
    localparam int unsigned HostCount   = 2;
    localparam int unsigned DeviceCount = 2;
    localparam int unsigned BufferMax   = 4;

    bit clk, rst_n;
    always #(ClkPeriod / 2) clk <= ~clk;

    obi_if #(.DEVICE(1'b0)) host_if   [HostCount]   (.clk(clk), .rst_n(rst_n));
    obi_if #(.DEVICE(1'b1)) device_if [DeviceCount] (.clk(clk), .rst_n(rst_n));

    logic        host_req      [HostCount];
    logic        host_gnt      [HostCount];
    logic [31:0] host_addr     [HostCount];
    logic        host_we       [HostCount];
    logic [ 3:0] host_be       [HostCount];
    logic [31:0] host_wdata    [HostCount];
    logic        host_rvalid   [HostCount];
    logic [31:0] host_rdata    [HostCount];
    logic        host_err      [HostCount];

    logic        device_req    [DeviceCount];
    logic        device_gnt    [DeviceCount];
    logic [31:0] device_addr   [DeviceCount];
    logic        device_we     [DeviceCount];
    logic [ 3:0] device_be     [DeviceCount];
    logic [31:0] device_wdata  [DeviceCount];
    logic        device_rvalid [DeviceCount];
    logic [31:0] device_rdata  [DeviceCount];
    logic        device_err    [DeviceCount];

    logic [31:0] device_addr_base [DeviceCount];
    logic [31:0] device_addr_mask [DeviceCount];

    bus #(
        .HostCount   (HostCount),
        .DeviceCount (DeviceCount),
        .BufferMax   (BufferMax)
    ) dut (
        .clk              (clk),
        .rst_ni           (rst_n),

        .host_req_i       (host_req),
        .host_gnt_o       (host_gnt),
        .host_addr_i      (host_addr),
        .host_we_i        (host_we),
        .host_be_i        (host_be),
        .host_wdata_i     (host_wdata),
        .host_rvalid_o    (host_rvalid),
        .host_rdata_o     (host_rdata),
        .host_err_o       (host_err),

        .device_req_o     (device_req),
        .device_gnt_i     (device_gnt),
        .device_addr_o    (device_addr),
        .device_we_o      (device_we),
        .device_be_o      (device_be),
        .device_wdata_o   (device_wdata),
        .device_rvalid_i  (device_rvalid),
        .device_rdata_i   (device_rdata),
        .device_err_i     (device_err),

        .device_addr_base (device_addr_base),
        .device_addr_mask (device_addr_mask)
    );

    genvar gi;
    generate
        for (gi = 0; gi < HostCount; gi++) begin : g_host_if
            assign host_req[gi]       = host_if[gi].req;
            assign host_addr[gi]      = host_if[gi].addr;
            assign host_we[gi]        = host_if[gi].we;
            assign host_be[gi]        = host_if[gi].be;
            assign host_wdata[gi]     = host_if[gi].wdata;
            assign host_if[gi].gnt    = host_gnt[gi];
            assign host_if[gi].rvalid = host_rvalid[gi];
            assign host_if[gi].rdata  = host_rdata[gi];
            assign host_if[gi].err    = host_err[gi];

            initial begin
                uvm_config_db #(virtual obi_if #('0))::set(null,
                    $sformatf("uvm_test_top.env.host_agt_%0d*", gi), "obi_if", host_if[gi]);
                uvm_config_db #(virtual obi_if)::set(null,
                    $sformatf("uvm_test_top.env.host_agt_%0d*", gi), "obi_if", host_if[gi]);
            end
        end

        for (gi = 0; gi < DeviceCount; gi++) begin : g_device_if
            assign device_if[gi].req   = device_req[gi];
            assign device_if[gi].addr  = device_addr[gi];
            assign device_if[gi].we    = device_we[gi];
            assign device_if[gi].be    = device_be[gi];
            assign device_if[gi].wdata = device_wdata[gi];
            assign device_gnt[gi]      = device_if[gi].gnt;
            assign device_rvalid[gi]   = device_if[gi].rvalid;
            assign device_rdata[gi]    = device_if[gi].rdata;
            assign device_err[gi]      = device_if[gi].err;

            initial begin
                uvm_config_db #(virtual obi_if #('1))::set(null,
                    $sformatf("uvm_test_top.env.device_agt_%0d*", gi), "obi_if", device_if[gi]);
            end
        end
    endgenerate

    initial begin
        static obi_bus_env_cfg cfg = obi_bus_env_cfg::type_id::create("cfg");

        device_addr_base[0] = 32'h0000_0000;
        device_addr_mask[0] = 32'hFFFF_F000;
        device_addr_base[1] = 32'h0000_1000;
        device_addr_mask[1] = 32'hFFFF_F000;

        cfg.host_count = HostCount;
        cfg.device_count = DeviceCount;
        cfg.device_addr_base = new[DeviceCount];
        cfg.device_addr_mask = new[DeviceCount];
        foreach (cfg.device_addr_base[i]) begin
            cfg.device_addr_base[i] = device_addr_base[i];
            cfg.device_addr_mask[i] = device_addr_mask[i];
        end

        uvm_config_db #(obi_bus_env_cfg)::set(null, "*", "obi_bus_env_cfg", cfg);
        uvm_config_db #(virtual obi_if)::set(null, "uvm_test_top.env.scb", "obi_if", host_if[0]);

        #0;
        run_test("obi_bus_test");
    end

    initial begin
        rst_n = 1'b0;
        repeat (4) @(posedge clk);
        rst_n = 1'b1;
    end

    initial begin
        $dumpvars;
        $dumpfile("dump.vcd");
    end
endmodule
