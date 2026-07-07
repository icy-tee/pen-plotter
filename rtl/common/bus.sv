
module bus #(
    parameter int unsigned HostCount = 2,
    parameter int unsigned DeviceCount = 7,

    parameter int unsigned BufferMax = 4 // must be a power-of-two
) (
    input logic clk,
    input logic rst_ni,

    input  logic        host_req_i        [HostCount],
    output logic        host_gnt_o        [HostCount],
    input  logic [31:0] host_addr_i       [HostCount],
    input  logic        host_we_i         [HostCount],
    input  logic [ 3:0] host_be_i         [HostCount],
    input  logic [31:0] host_wdata_i      [HostCount],
    output logic        host_rvalid_o     [HostCount],
    output logic [31:0] host_rdata_o      [HostCount],
    output logic        host_err_o        [HostCount],

    output logic        device_req_o    [DeviceCount],
    input  logic        device_gnt_i    [DeviceCount],
    output logic [31:0] device_addr_o   [DeviceCount],
    output logic        device_we_o     [DeviceCount],
    output logic [ 3:0] device_be_o     [DeviceCount],
    output logic [31:0] device_wdata_o  [DeviceCount],
    input  logic        device_rvalid_i [DeviceCount],
    input  logic [31:0] device_rdata_i  [DeviceCount],
    input  logic        device_err_i    [DeviceCount],

    input logic [31:0]  device_addr_base [DeviceCount],
    input logic [31:0]  device_addr_mask [DeviceCount]
);
    localparam int HostCountBits = $clog2(HostCount);
    localparam int DeviceCountBits = $clog2(DeviceCount);
    localparam int BufferCountBits = $clog2(BufferMax);

    typedef struct packed {
        logic [HostCountBits-1:0] host;
        logic [DeviceCountBits-1:0] device;
        logic [31:0] rdata;
        logic done;
        logic err;
    } pair_t;

    logic host_req_valid, device_req_valid;

    logic [HostCountBits-1:0] host_req;
    logic [DeviceCountBits-1:0] device_req;

    logic [BufferCountBits-1:0] outstanding_front, outstanding_back;
    logic [BufferMax-1:0] capture_en;
    pair_t outstanding [BufferMax], response;
    logic outstanding_full;

    assign response = outstanding[outstanding_front];
    assign outstanding_full = (outstanding_back + 1'b1) == outstanding_front;

    always_comb begin
        host_req_valid = '0;
        host_req = '0;
        for (int i = HostCount-1; i >= 0; i--) begin
            if (host_req_i[i]) begin
                host_req_valid = '1;
                host_req = (HostCountBits)'(i);
            end
        end
    end

    always_comb begin
        device_req_valid = '0;
        device_req = '0;
        for (int unsigned i = 0; i < DeviceCount; i++) begin
            if (host_req_valid &&
                ((host_addr_i[host_req] & device_addr_mask[i]) == device_addr_base[i])
            ) begin
                device_req_valid = '1;
                device_req = (DeviceCountBits)'(i);
            end
        end
    end

    always_comb begin
        logic[DeviceCount-1:0] claimed;
        logic [BufferCountBits-1:0] occ;

        capture_en = '0;
        claimed = '0;
        occ = outstanding_back - outstanding_front;

        for (int unsigned i = 0; i < BufferMax; i++) begin
            automatic logic [BufferCountBits-1:0] idx = outstanding_front + BufferCountBits'(i);
            automatic logic [DeviceCountBits-1:0] dev = outstanding[idx].device;

            if (i < occ) begin
                if (device_rvalid_i[dev] &&
                    !outstanding[idx].done &&
                    !outstanding[idx].err &&
                    !claimed[dev]) begin
                        capture_en[idx] = 1'b1;
                        claimed[dev] = 1'b1;
                    end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_ni) begin
        if (!rst_ni) begin
            outstanding <= '{default: '0};
            outstanding_front <= '0;
            outstanding_back <= '0;
        end else begin
            if (host_req_valid && !outstanding_full) begin
                if (device_req_valid && device_gnt_i[device_req]) begin
                    outstanding[outstanding_back].host <= host_req;
                    outstanding[outstanding_back].device <= device_req;
                    outstanding[outstanding_back].err <= '0;
                    outstanding_back <= outstanding_back + 1;
                end
                if (!device_req_valid) begin
                    outstanding[outstanding_back].host <= host_req;
                    outstanding[outstanding_back].device <= '0;
                    outstanding[outstanding_back].err <= '1;
                    outstanding[outstanding_back].done <= '1;
                    outstanding_back <= outstanding_back + 1;
                end
            end

            for (int unsigned i = 0; i < BufferMax; i++) begin
                if (capture_en[i]) begin
                    outstanding[i].rdata <= device_rdata_i[outstanding[i].device];
                    outstanding[i].err <= device_err_i[outstanding[i].device];
                    outstanding[i].done <= '1;
                end
            end

            if (outstanding_front != outstanding_back && response.done) begin
                outstanding[outstanding_front].done <= '0;
                outstanding[outstanding_front].err <= '0;
                outstanding_front <= outstanding_front + 1;
            end
        end
    end

    // A Transcation
    always_comb begin
        host_gnt_o     = '{default: 'b0};
        device_req_o   = '{default: 'b0};
        device_addr_o  = '{default: 'b0};
        device_we_o    = '{default: 'b0};
        device_be_o    = '{default: 'b0};
        device_wdata_o = '{default: 'b0};
        if (host_req_valid && !outstanding_full) begin
            if (device_req_valid) begin
                host_gnt_o[host_req]       = device_gnt_i[device_req];
                device_req_o[device_req]   = host_req_i[host_req];
                device_addr_o[device_req]  = host_addr_i[host_req] & (~device_addr_mask[device_req]);
                device_we_o[device_req]    = host_we_i[host_req];
                device_be_o[device_req]    = host_be_i[host_req];
                device_wdata_o[device_req] = host_wdata_i[host_req];
            end else begin
                host_gnt_o[host_req]       = 'b1;
            end
        end
    end

    // R Transaction
    always_comb begin
        host_err_o = '{default: '0};
        host_rdata_o = '{default: '0};
        host_rvalid_o = '{default: '0};
        if (outstanding_front != outstanding_back && response.done) begin
            host_rvalid_o[response.host] = 1'b1;
            host_rdata_o[response.host]  = response.err ? 'b0 : response.rdata;
            host_err_o[response.host]    = response.err;
        end
    end

endmodule
