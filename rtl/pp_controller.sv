
import pp_pkg::*;

`define VERSION 2

typedef enum logic [1:0] {
     FETCH, EXECUTE
} pp_controller_state_e;

typedef struct packed {
    q32_t setpoint_x; // 0x0
    q32_t setpoint_y; // 0x4
    q16_16_t Kp; // 0x08
    q16_16_t Kd; // 0x0C
    logic[31:0] sample_rate; // 0x10
    logic[31:0] servo_angle;
} pp_register_t;

typedef struct packed {
    logic [7:0] offset;
    logic [31:0] data;
} pp_set_pkt_t;

module pp_controller #(
    int CLOCK_RATE = 50_000_000,
    int BUFFER_SIZE = 10
) (
    input clk,
    input rst_n,
    input [7:0] data_i,
    input data_empty_i,

    input logic stableX_i,
    input logic stableY_i,
    input q32_t tickX_i,
    input q32_t tickY_i,

    output logic quad_rst_n_o,

    output q32_t setpointX_o,
    output q32_t setpointY_o,
    output q16_16_t Kp_o,
    output q16_16_t Kd_o,
    output logic [31:0] sample_rate_o,
    output logic [15:0] servo_angle_o, // 0 -> 0, 65535 -> 180

    output logic [7:0] tx_data_o,
    output logic tx_valid_o,
    output logic tx_flush_o,

    output logic next_data_o
);
    logic streaming_n;
    int stream_timer;

    pp_controller_state_e state;
    pp_register_t registers;
    logic [7:0] data_latch;

    logic [2:0] load_counter;
    pp_set_pkt_t load_info;
    logic load, get, tx_writing;

    logic [1:0] stable;

    int buf_len, idx;
    logic [7:0] buffer [BUFFER_SIZE];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= FETCH;
            registers <= '0;
            stable <= '0;
            data_latch <= '0;
            streaming_n <= '0;
            load <= '0;
            get <= '0;
            load_counter <= '0;
            next_data_o <= '0;
            stream_timer <= 0;
            idx <= '0;
            tx_writing <= '0;
            tx_valid_o <= '0;
            tx_flush_o <= '0;
            quad_rst_n_o <= '1;
        end else begin
            next_data_o <= '0;
            quad_rst_n_o <= '1;
            tx_valid_o <= '0;
            tx_flush_o <= '0;

            stable[0] <= stableX_i & stableY_i;
            stable[1] <= stable[0];

            if (stable[0] && !stable[1]) begin
                buffer[0] <= 8'd3;
                buf_len <= 1;
                tx_writing <= '1;
            end

            if (stream_timer == CLOCK_RATE / 4 && !streaming_n) begin
                if (!tx_writing) begin
                    buffer[0] <= 8'd1;
                    buffer[1] <= tickX_i[7:0];
                    buffer[2] <= tickX_i[15:8];
                    buffer[3] <= tickX_i[23:16];
                    buffer[4] <= tickX_i[31:24];
                    buffer[5] <= 8'd2;
                    buffer[6] <= tickY_i[7:0];
                    buffer[7] <= tickY_i[15:8];
                    buffer[8] <= tickY_i[23:16];
                    buffer[9] <= tickY_i[31:24];
                    buf_len <= 10;
                    tx_writing <= '1;
                    idx <= 0;
                end
                stream_timer <= 0;
            end else
                stream_timer <= streaming_n ? 0 : stream_timer + 1;

            if (tx_writing) begin
                tx_data_o <= buffer[idx];
                tx_valid_o <= '1;
                idx <= idx + 1;
                if (idx + 1 >= buf_len) begin
                    tx_writing <= '0;
                    tx_flush_o <= '1;
                    idx <= 0;
                end
            end

            unique case (state)
                FETCH: begin
                    if (!next_data_o & !data_empty_i) begin
                        if (load) begin
                            load_counter <= load_counter + 1;
                            next_data_o <= '1;
                            case (load_counter)
                                'd0: load_info.offset <= data_i;
                                'd1: load_info.data[7:0] <= data_i;
                                'd2: load_info.data[15:8] <= data_i;
                                'd3: load_info.data[23:16] <= data_i;
                                'd4: begin
                                    load <= '0;
                                    load_counter <= 'd0;
                                    case (load_info.offset)
                                        'd0: registers.setpoint_x <= $signed({data_i, load_info.data[23:0]});
                                        'd1: registers.setpoint_y <= $signed({data_i, load_info.data[23:0]});
                                        'd2: registers.Kp <= $signed({data_i, load_info.data[23:0]});
                                        'd3: registers.Kd <= $signed({data_i, load_info.data[23:0]});
                                        'd4: registers.sample_rate <= {data_i, load_info.data[23:0]};
                                        'd5: registers.servo_angle <= {data_i, load_info.data[23:0]};
                                        default:
                                            ;
                                    endcase
                                end
                                default:
                                    ;
                            endcase
                            state <= FETCH;
                        end else if (get) begin
                            get <= '0;
                        end else begin
                            data_latch <= data_i;
                            next_data_o <= '1;
                            state <= EXECUTE;
                        end
                    end
                end
                EXECUTE: begin
                    case (instr_e'(data_latch))
                        RST: begin // should pulse reset for quadratue decoders
                            registers.setpoint_x <= 0;
                            registers.setpoint_y <= 0;
                            quad_rst_n_o <= '0;
                        end
                        STS: begin
                            tx_writing <= '1;
                            buf_len <= 2;
                            buffer[0] <= 'd0;
                            buffer[1] <= 'd2;
                        end
                        SET: begin
                            load <= '1;
                            load_counter <= 'd0;
                        end
                        GET: begin
                            get <= '1;
                        end
                        STR: streaming_n <= !streaming_n;
                        default:
                            ;
                    endcase
                    state <= FETCH;
                end
            endcase
        end
    end

    assign setpointX_o = registers.setpoint_x;
    assign setpointY_o = registers.setpoint_y;
    assign Kp_o = registers.Kp;
    assign Kd_o = registers.Kd;
    assign sample_rate_o = registers.sample_rate;
    assign servo_angle_o = registers.servo_angle[15:0];

endmodule
