

`include "uvm_macros.svh"

module obi_reg_tb_top;
    timeunit 1ns / 1ps;
    import uvm_pkg::*;
    import prim_subreg_pkg::*;
    import obi_reg_env_pkg::*;
    import obi_reg_tests_pkg::*;


    localparam time         ClkPeriod     = 10ns;
    localparam int unsigned RegisterCount = 4;
    localparam int unsigned UsedAddrWidth = 8;

    localparam sw_access_e RegAccess [RegisterCount] = '{
        SwAccessRW,
        SwAccessRO,
        SwAccessW1C,
        SwAccessW0C
    };

    bit clk, rst_n;
    always #ClkPeriod clk <= ~clk;

    obi_if obi_if (.clk(clk), .rst_n(rst_n));
    reg_if reg_if [RegisterCount] (.clk(clk), .rst_n(rst_n));

    logic [RegisterCount-1:0]       hw_de;
    logic [RegisterCount-1:0][31:0] hw_d;
    logic [RegisterCount-1:0][31:0] hw_q;

    obi_reg #(
      .RegisterCount(RegisterCount),
      .UsedAddrWidth(UsedAddrWidth),
      .RegAccess    (RegAccess)
     ) obi_reg (
      .clk        (clk),
      .rst_ni     (rst_n),

      .hw_de      (hw_de),
      .hw_d       (hw_d),
      .hw_q       (hw_q),

      .req_i      (obi_if.req),
      .gnt_o      (obi_if.gnt),
      .addr_i     (obi_if.addr),
      .we_i       (obi_if.we),
      .be_i       (obi_if.be),
      .wdata_i    (obi_if.wdata),
      .rvalid_o   (obi_if.rvalid),
      .rdata_o    (obi_if.rdata),
      .err_o      (obi_if.err)
    );

    genvar gi;
    generate
        for (gi = 0; gi < RegisterCount; gi++) begin : g_hw
            assign hw_de[gi]        = reg_if[gi].hw_de;
            assign hw_d[gi]         = reg_if[gi].hw_d;
            assign reg_if[gi].hw_q  = hw_q[gi];

            initial
                uvm_config_db #(virtual reg_if)::set(null,
                    $sformatf("uvm_test_top.env.hw_agt_%0d*", gi), "reg_if", reg_if[gi]);
        end
    endgenerate

    initial begin
        obi_reg_env_cfg cfg = obi_reg_env_cfg::type_id::create("cfg");
        cfg.register_count = RegisterCount;
        cfg.modes = new[RegisterCount];
        foreach (cfg.modes[i]) cfg.modes[i] = RegAccess[i];

        uvm_config_db #(obi_reg_env_cfg)::set(null, "*", "obi_reg_env_cfg", cfg);
        uvm_config_db #(virtual obi_if)::set (null, "uvm_test_top.env*", "obi_if", obi_if);

        run_test("obi_reg_test");
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
