
module tb_bus;
    timeunit 1ns / 1ps;
    bit clk, rst_n;

    localparam time CLK_PERIOD = 10ns;
    initial clk = 0;

    localparam int unsigned HOST_COUNT = 2;
    localparam int unsigned DEVICE_COUNT = 2;

    logic host_req          [HOST_COUNT];
    logic host_gnt          [HOST_COUNT];
    logic [31:0] host_addr  [HOST_COUNT];
    logic host_we           [HOST_COUNT];
    logic [ 3:0] host_be    [HOST_COUNT];
    logic [31:0] host_wdata [HOST_COUNT];
    logic host_rvalid       [HOST_COUNT];
    logic [31:0] host_rdata [HOST_COUNT];
    logic host_err          [HOST_COUNT];

    logic device_req          [DEVICE_COUNT];
    logic device_gnt          [DEVICE_COUNT];
    logic [31:0] device_addr  [DEVICE_COUNT];
    logic device_we           [DEVICE_COUNT];
    logic [ 3:0] device_be    [DEVICE_COUNT];
    logic [31:0] device_wdata [DEVICE_COUNT];
    logic device_rvalid       [DEVICE_COUNT];
    logic [31:0] device_rdata [DEVICE_COUNT];
    logic device_err          [DEVICE_COUNT];

    localparam logic [31:0] Device1Size = 32 * 1024;
    localparam logic [31:0] Device1Base = 'h00000000;
    localparam logic [31:0] Device1Mask = ~(Device1Size-1);

    localparam logic [31:0] Device2Size = 32 * 1024;
    localparam logic [31:0] Device2Base = 'h00008000;
    localparam logic [31:0] Device2Mask = ~(Device2Size-1);


    bus #(
        .HostCount  (2),
        .DeviceCount(2)
    ) u_bus (
        .clk             (clk),
        .rst_ni          (rst_n),
        .host_req_i      (host_req),
        .host_gnt_o      (host_gnt),
        .host_addr_i     (host_addr),
        .host_we_i       (host_we),
        .host_be_i       (host_be),
        .host_wdata_i    (host_wdata),
        .host_rvalid_o   (host_rvalid),
        .host_rdata_o    (host_rdata),
        .host_err_o      (host_err),
        .device_req_o    (device_req),
        .device_gnt_i    (device_gnt),
        .device_addr_o   (device_addr),
        .device_we_o     (device_we),
        .device_be_o     (device_be),
        .device_wdata_o  (device_wdata),
        .device_rvalid_i (device_rvalid),
        .device_rdata_i  (device_rdata),
        .device_err_i    (device_err),
        .device_addr_base('{Device1Base, Device2Base}),
        .device_addr_mask('{Device1Mask, Device2Mask})
    );

    function automatic int unsigned dev_from_addr(logic[31:0] addr);
        if ((Device1Mask & addr) == Device1Base) return 0;
        if ((Device2Mask & addr) == Device2Base) return 1;
    endfunction

    task automatic host_write(int index, logic [31:0] word, logic [31:0] addr);
        host_req[index] = '1;
        host_addr[index] = addr;
        host_wdata[index] = word;
        host_we[index] = '1;
        host_be[index] = 4'hF;
    endtask

    task automatic addr_transfer_check(int hindex, logic[31:0] word, logic[31:0] addr);
        $display("[%0t] Injecting Transfer with %h at %h", $time, word, addr);
        host_write(hindex, word, addr);
        repeat (2) @(posedge clk);
        for (int unsigned i = 0; i < DEVICE_COUNT; i++) begin
            if (i == dev_from_addr(addr)) begin
                assert(device_req[i]) else begin
                    $error("[%0t] device_req[%d] deasserted for %h when should be asserted.", $time, i, addr);
                end
                if (device_we[i])
                    assert(device_wdata[i] == word)
                        else $error("[%0t] device_wdata[%d] not expected value of %h", $time, i, word);
            end else begin
                assert(!device_req[i]) else begin
                    $error("[%0t] device_req[%d] asserted for %h when should be deasserted.", $time, i, addr);
                end
            end
        end
        @(posedge clk);
        device_gnt[dev_from_addr(addr)] = '1;
        @(posedge clk);
        device_gnt[dev_from_addr(addr)] = '0;
        host_req[hindex] = '0;
        $display("[%0t] Passed Transfer!", $time);
    endtask

    task automatic resp_transfer_check(int dindex);
        if (device_req[dindex]) begin
            int hindex;
            device_gnt[dindex] = 1'b1;
            @(posedge clk);
            device_gnt[dindex] = 1'b0;
            @(posedge clk);
            host_req[u_bus.host_req] = 1'b0;
            @(posedge clk);
            hindex = u_bus.response.host;
            device_rvalid[dindex] = 1'b1;
            @(posedge clk);
            assert(!host_rvalid[hindex]) else $error("[%0t] Response unsuccesful", $time);
        end
    endtask

    task automatic host_read(int index, logic [31:0] addr);
        host_req[index] = '1;
        host_addr[index] = addr;
        host_wdata[index] = '0;
        host_we[index] = '0;
        host_be[index] = 4'hF;
    endtask


    always #(CLK_PERIOD/2) clk = ~clk;

    initial
    begin
        rst_n = '0;
        repeat (2) @(posedge clk);
        rst_n = '1;
        @(posedge clk);

        addr_transfer_check(0, 32'h0000FFFF, 32'h00000000); // 0
        @(posedge clk);
        addr_transfer_check(0, 32'h000FFFFF, 32'h00008000); // 1

        @(posedge clk);

        device_rdata[1] = 32'h0F0F0F0F;
        device_rvalid[1] = '1;

        @(posedge clk);

        device_rvalid[0] = '1;
        device_rdata[0] = 32'h00000001;

        $monitor("[%0t]: host_rdata=%h, host_rvalid=%d", $time, host_rdata[0], host_rvalid[0]);

        @(posedge clk);

        assert(host_rvalid[0]) else $error("should be valid");
        assert(host_rdata[0] == 32'h00000001) else $error("got: %h, expected: %h", host_rdata[0], 32'h00000001);

        @(posedge clk);

        assert(host_rvalid[0]) else $error("should be valid");
        assert(host_rdata[0] == 32'h0F0F0F0F) else $error("got: %h, expected: %h", host_rdata[0], 32'h0F0F0F0F);

        // resp_transfer_check(0);
        // resp_transfer_check(1);

        // host_write(0, 32'h00000FFFF, 32'h0000000);

        // @(posedge clk);
        // $display("[%0t] host0: req=%b addr=%h wdata=%h we=%b be=%h",
        //         $time, host_req[0], host_addr[0], host_wdata[0], host_we[0], host_be[0]);
        // @(posedge clk);
        // $display("[%0t] dev0: req=%b addr=%h wdata=%h we=%b be=%h",
        //         $time, device_req[0], device_addr[0], device_wdata[0], device_we[0], device_be[0]);
        // $display("[%0t] internal: host=%d valid=%b dev=%d valid=%b",
        //         $time, u_bus.host_req, u_bus.host_req_valid, u_bus.device_req, u_bus.device_req_valid);
        // $display("[%0t] compare: tb_host_req[0]=%b  bus_req_i[0]=%b",
        //         $time, host_req[0], u_bus.host_req_i[0]);
        // assert(device_req[0] && !device_req[1])
        //     else $error("addr 0x0 should select dev 0");
        // assert(device_wdata[0] == 32'h0000FFFF)
        //     else $error("wdata doesn't match");

        $finish;
    end

    initial
    begin
        #1000 $error("Took too long..."); $finish;
    end
endmodule
