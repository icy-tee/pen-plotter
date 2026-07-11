
module obi_stub (
    input logic clk,
    input logic rst_ni,

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

logic unused;
assign unused = ^{addr_i, we_i, be_i, wdata_i};

assign gnt_o = req_i;

always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
        rvalid_o <= 1'b0;
        rdata_o  <= '0;
        err_o    <= 1'b0;
    end else begin
        rvalid_o <= req_i;
        rdata_o  <= '0;
        err_o    <= req_i;
    end
end

endmodule
