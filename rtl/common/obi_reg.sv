
module obi_reg
    import prim_subreg_pkg::*; #(
    parameter int unsigned RegisterCount = 4,
    parameter int unsigned UsedAddrWidth = 8,
    parameter logic [RegisterCount-1:0][2:0] RegAccess = {RegisterCount{SwAccessRW}}
) (
    input clk,
    input rst_ni,

    input  logic [RegisterCount-1:0] hw_de_i,
    input  logic [RegisterCount-1:0] [31:0] hw_d_i,
    output logic [RegisterCount-1:0] [31:0] hw_q_o,

    output logic [RegisterCount-1:0] sw_we_o,
    output logic [RegisterCount-1:0] [31:0] sw_wd_o,

    input  logic        req_i,
    output logic        gnt_o,
    input  logic [31:0] addr_i,
    input  logic        we_i,
    input  logic [ 3:0] be_i,
    input  logic [31:0] wdata_i,
    output logic        rvalid_o,
    output logic [31:0] rdata_o,
    output logic        err_o
);

    localparam int unsigned RegisterCountBits = RegisterCount > 1 ? $clog2(RegisterCount) : 1;

    logic [UsedAddrWidth-1:0] trimmed_addr;
    logic [RegisterCountBits-1:0] reg_idx;
    logic [UsedAddrWidth-1:0] reg_word_idx;
    logic err;

    logic [RegisterCount-1:0] we;
    logic [RegisterCount-1:0] [31:0] wd;
    logic [RegisterCount-1:0] [31:0] q;

    initial begin
    end

    genvar i;

    generate
        for (i = 0; i < RegisterCount; i++) begin : gen_subregs
            localparam sw_access_e RegAccessI = sw_access_e'(RegAccess[i]);
            prim_subreg #( .DW(32), .SwAccess(RegAccessI) ) u_reg (
                .clk_i(clk),
                .rst_ni(rst_ni),
                .we(we[i]),
                .wd(wd[i]),
                .qe(),
                .q(q[i]),

                .de(hw_de_i[i]),
                .d(hw_d_i[i]),
                .ds(),
                .qs()
            );
        end
    endgenerate

    assign hw_q_o = q;
    assign sw_we_o = we;
    assign sw_wd_o = wd;

    assign trimmed_addr = addr_i[UsedAddrWidth-1:0];
    assign reg_word_idx = trimmed_addr >> 2;
    assign reg_idx = RegisterCountBits'(reg_word_idx);
    assign gnt_o = req_i;
    // byte masking is unavailable for writes
    assign err = reg_word_idx >= UsedAddrWidth'(RegisterCount) || (we_i && be_i != 4'hF);

    always_comb begin
        we = '0;
        wd = '{default: '0};
        if (req_i && we_i && !err) begin
            we[reg_idx] = we_i;
            wd[reg_idx] = wdata_i;
        end
    end

    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            rvalid_o <= 1'b0;
            rdata_o <= '0;
            err_o <= 1'b0;
        end else begin
            rvalid_o <= 1'b0;
            rdata_o <= '0;
            err_o <= 1'b0;
            if (req_i) begin
                if (!we_i && !err) begin
                    for (int unsigned k = 0; k < $unsigned($bits(be_i)); k++) begin
                        if (be_i[k]) rdata_o[k*8+:8] <= q[reg_idx][k*8+:8];
                    end
                end
                rvalid_o <= 1'b1;
                err_o <= err;
            end
        end
    end

endmodule
