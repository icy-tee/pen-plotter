
module uart_obi #(
    parameter int unsigned ClockRate = 50_000_000,
    parameter int unsigned BufferLength = 32
) (
    input clk,
    input rst_ni,
    input  rx_i,
    input [31:0] device_mask_i,
    output logic tx_o,

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
import uart_obi_pkg::*;

typedef enum logic [1:0] {
    IDLE, START, DATA, STOP
} uart_state_e;

typedef enum logic [1:0] {
    WAIT,
    READ,
    WRITE
} device_state_e;

typedef struct packed {
    logic rx_empty;
    logic rx_full;
    logic tx_empty;
    logic tx_full;
    logic [3:0] padding;
} uart_status_t;

device_state_e device_state;
logic [31:0] wdata_latch, addr_latch;
logic [1:0] wdata_byte_idx;
logic we_latch;
logic [3:0] be_latch;
uart_status_t status;
logic [7:0] baud_selector;

register_e rdata_selector;
register_e wdata_selector;

localparam int unsigned BufferLengthBits = $clog2(BufferLength);
localparam int unsigned DataBits = 8;
localparam int unsigned DataBitsLength = $clog2(DataBits);

logic [31:0] rx_baud_counter, tx_baud_counter, clks_per_bit, clks_per_bit_half;

logic rx_baud, rx_restart_baud, rx_sample, tx_baud;

logic [7:0] rx_buf [BufferLength], rx_collecting;
logic [1:0] rx_sync;
logic [BufferLengthBits-1:0] rx_buf_start, rx_buf_end;
logic [DataBitsLength-1:0] rx_collecting_count;
uart_state_e rx_state;


logic [7:0] tx_buf [BufferLength], tx_data_latch;
logic [BufferLengthBits-1:0] tx_buf_start, tx_buf_end;
logic [DataBitsLength-1:0] tx_data_count;
uart_state_e tx_state;

initial begin
    assert(BufferLength > 0 && (BufferLength & BufferLength - 1) == 0)
        else $error("BufferLength must be power of two.");
end

assign clks_per_bit_half = clks_per_bit >> 1;
assign rx_baud = (rx_baud_counter == clks_per_bit - 1'b1);
assign tx_baud = (tx_baud_counter == clks_per_bit - 1'b1);
assign rx_sample = (rx_baud_counter == clks_per_bit_half - 1'b1);

assign status.rx_empty = rx_buf_start == rx_buf_end;
assign status.tx_empty = tx_buf_start == tx_buf_end;
assign status.rx_full = rx_buf_end + 1'b1 == rx_buf_start;
assign status.tx_full = tx_buf_end + 1'b1 == tx_buf_start;

always_comb begin
    case (baud_selector)
        'h00: clks_per_bit = 0; // 0 => DISABLED; stalls tx and rx
        'h01: clks_per_bit = ClockRate / 4800;
        'h02: clks_per_bit = ClockRate / 9600;
        'h03: clks_per_bit = ClockRate / 19200;
        'h04: clks_per_bit = ClockRate / 38400;
        'h05: clks_per_bit = ClockRate / 57600;
        'h06: clks_per_bit = ClockRate / 115200;
        'h07: clks_per_bit = ClockRate / 230400;
        default: clks_per_bit = 0;
    endcase
end

always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
        rx_baud_counter <= '0;
        tx_baud_counter <= '0;
    end else begin
        if (rx_baud || rx_restart_baud)
            rx_baud_counter <= 0;
        else
            rx_baud_counter <= rx_baud_counter + 1'b1;

        if (tx_baud)
            tx_baud_counter <= 0;
        else
            tx_baud_counter <= tx_baud_counter + 1'b1;
    end
end

always_comb begin
    gnt_o = (device_state == WAIT) && req_i;
    err_o = '0;

    if (we_latch) begin
        rdata_selector = DISABLED;
        case (addr_latch & device_mask_i)
            STSLane:  wdata_selector = DISABLED; // status is readonly
            BaudLane: wdata_selector = BAUD;
            TXLane:   wdata_selector = TX;
            RXLane:   wdata_selector = DISABLED;
            default: begin
                wdata_selector = DISABLED;
                err_o = '1;
            end
        endcase
    end else begin
        wdata_selector = DISABLED;
        case (addr_latch & device_mask_i)
            STSLane:  rdata_selector = STATUS;
            BaudLane: rdata_selector = BAUD;
            TXLane:   rdata_selector = DISABLED; // disabled on TX no reads allowed
            RXLane:   rdata_selector = RX;
            default: begin
                rdata_selector = DISABLED;
                err_o = '1;
            end
        endcase
    end
end

always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
        device_state <= WAIT;
        rvalid_o <= '0;
        baud_selector <= '0;
        rx_buf_start <= '0;
        tx_buf_end <= '0;
        wdata_byte_idx <= '0;
        we_latch <= '0;
        be_latch <= '0;
        wdata_latch <= '0;
        addr_latch <= '0;
    end else begin
        case (device_state)
            WAIT: begin
                rvalid_o <= '0;
                if (req_i) begin
                    device_state <= we_i ? WRITE : READ;
                    wdata_latch <= wdata_i;
                    addr_latch <= addr_i;
                    we_latch <= we_i;
                    be_latch <= be_i;
                end
            end
            READ: begin
                case (rdata_selector)
                    RX: begin
                        if (!status.rx_empty) begin
                            rdata_o <= 32'(rx_buf[rx_buf_start]);
                            rx_buf_start <= rx_buf_start + 1;
                        end else begin
                            rdata_o <= '0;
                        end
                    end
                    BAUD: rdata_o <= 32'(baud_selector);
                    STATUS: rdata_o <= 32'(status);
                    default: rdata_o <= '0;
                endcase
                rvalid_o <= '1;
                device_state <= WAIT;
            end
            WRITE: begin
                case (wdata_selector)
                    TX: begin
                        if (!be_latch[wdata_byte_idx] || !status.tx_full) begin
                            if (be_latch[wdata_byte_idx]) begin
                                tx_buf[tx_buf_end] <= wdata_latch[wdata_byte_idx*8 +: 8];
                                tx_buf_end <= tx_buf_end + 1'b1;
                            end
                            wdata_byte_idx <= wdata_byte_idx + 1'b1;
                            if (wdata_byte_idx == 2'd3) begin
                                rvalid_o <= '1;
                                device_state <= WAIT;
                            end
                        end
                    end
                    BAUD: begin
                        baud_selector <= 8'(wdata_latch);
                        rvalid_o <= '1;
                        device_state <= WAIT;
                    end
                    default: begin
                        rvalid_o <= '1;
                        device_state <= WAIT;
                    end
                endcase
            end
        endcase
    end
end

always_comb begin
    case (tx_state)
        IDLE: tx_o = '1;
        START: tx_o = '0;
        DATA: tx_o = tx_data_latch[tx_data_count];
        STOP: tx_o = '1;
        default: tx_o = '0;
    endcase
end

always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
        tx_state <= IDLE;
        tx_data_count <= '0;
        tx_data_latch <= '0;
        tx_buf_start <= '0;
    end else begin
        case (tx_state)
            IDLE: begin
                if (!status.tx_empty && tx_baud) begin
                    tx_data_latch <= tx_buf[tx_buf_start];
                    tx_state <= START;
                end
            end
            START: begin
                if (tx_baud) begin
                    tx_data_count <= '0;
                    tx_state <= DATA;
                end
            end
            DATA: begin
                if (tx_baud) begin
                    if (tx_data_count == DataBits - 1'b1)
                        tx_state <= STOP;
                    else
                        tx_data_count <= tx_data_count + 1;
                end
            end
            STOP: begin
                if (tx_baud) begin
                    if (status.tx_empty) begin
                    end else begin
                        tx_buf_start <= tx_buf_start + 1'b1;
                    end
                    tx_state <= IDLE;
                end
            end
            default: begin
            end
        endcase
    end
end


always_ff @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
        rx_state <= IDLE;
        rx_collecting_count <= '0;
        rx_collecting <= '0;
        rx_buf_end <= '0;
        rx_restart_baud <= '0;
        rx_sync <= '0;
    end else begin
        rx_sync <= { rx_i, rx_sync[1] };
        rx_restart_baud <= '0;
        case (rx_state)
            IDLE: begin
                if (!rx_sync[0]) begin
                    rx_restart_baud <= '1;
                    rx_state <= START;
                end else
                    rx_state <= IDLE;
            end
            START: begin
                if (rx_sample) begin
                    if (!rx_sync[0]) begin
                        rx_restart_baud <= '1;
                        rx_collecting_count <= '0;
                        rx_state <= DATA;
                    end else begin
                        rx_state <= IDLE;
                    end
                end
            end
            DATA: begin
                if (rx_baud) begin
                    rx_collecting[rx_collecting_count] <= rx_sync[0];
                    rx_collecting_count <= rx_collecting_count + 1'b1;

                    if (rx_collecting_count == (DataBits - 1'b1))
                        rx_state <= STOP;
                end
            end
            STOP: begin
                if (rx_baud && rx_sync[0]) begin
                    rx_buf[rx_buf_end] <= rx_collecting;
                    rx_collecting <= '0;

                    if (!status.rx_full)
                        rx_buf_end <= rx_buf_end + 1'b1;

                    rx_state <= IDLE;
                end
            end
            default: begin
            end
        endcase
    end
end

endmodule
