
import pp_pkg::*;

typedef enum logic [1:0] {
     FETCH, EXECUTE
} pp_controller_state_e;

module pp_controller #(
    int CLOCK_RATE = 50_000_000,
    int BUFFER_SIZE = 10
) (
    input clk,
    input rst_n,
    input [7:0] data_i,
    input data_empty_i,

    input int signed tickX_i,
    input int signed tickY_i,

    output md_mode_e modeX,
    output logic [7:0] dutyX,

    output md_mode_e modeY,
    output logic [7:0] dutyY,

    output logic [7:0] tx_data_o,
    output logic tx_valid_o,
    output logic tx_flush_o,

    output logic next_data_o
);
    int stream_timer;

    pp_controller_state_e state;
    md_mode_e next_modeX, next_modeY;
    logic is_x_command, is_y_command, is_write;
    logic [7:0] data_latch;

    logic needs_duty;
    logic x_needs_duty, y_needs_duty;

    logic tx_writing;
    int buf_len, idx, next_buf_len;
    logic [7:0] buffer [BUFFER_SIZE], next_buffer[BUFFER_SIZE];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= FETCH;
            data_latch <= '0;
            dutyX <= '0;
            dutyY <= '0;
            x_needs_duty <= '0;
            y_needs_duty <= '0;
            next_data_o <= '0;
            stream_timer <= 0;
            modeX <= COAST;
            modeY <= COAST;
            idx <= '0;
            tx_writing <= '0;
            tx_valid_o <= '0;
            tx_flush_o <= '0;
        end else begin
            next_data_o <= '0;
            tx_valid_o <= '0;
            tx_flush_o <= '0;

            if (stream_timer == CLOCK_RATE / 4) begin
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
                stream_timer <= stream_timer + 1;

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

            case (state)
                FETCH: begin
                    if (!data_empty_i) begin
                        data_latch <= data_i;
                        next_data_o <= '1;
                        state <= EXECUTE;
                    end
                end
                EXECUTE: begin
                    if (x_needs_duty) begin
                        dutyX <= data_latch;
                        x_needs_duty <= '0;
                        state <= FETCH;
                    end else if (y_needs_duty) begin
                        dutyY <= data_latch;
                        y_needs_duty <= '0;
                        state <= FETCH;
                    end else begin
                        if (is_x_command) begin
                            modeX <= next_modeX;
                            state <= FETCH;
                        end
                        if (is_y_command) begin
                            modeY <= next_modeY;
                            state <= FETCH;
                        end
                        if (is_write && !tx_writing) begin
                            tx_writing <= '1;
                            buf_len <= next_buf_len;
                            buffer <= next_buffer;
                            state <= FETCH;
                        end

                        x_needs_duty <= needs_duty & is_x_command;
                        y_needs_duty <= needs_duty & is_y_command;
                    end
                end
                default: begin end
            endcase
        end
    end

    always_comb begin
        next_modeX = COAST; next_modeY = COAST;
        needs_duty = '0;
        is_x_command = '0; is_y_command = '0; is_write = '0;
        next_buffer = '{default: '0};
        next_buf_len = 0;
        case (instr_e'(data_latch))
            RST: begin
                    next_modeX = COAST; next_modeY = COAST;
                    is_x_command = '1; is_y_command = '1;
            end
            FWDX: begin  next_modeX = FORWARD; needs_duty = '1; is_x_command = '1; end
            REVX: begin  next_modeX = REVERSE; needs_duty = '1; is_x_command = '1; end
            CSTX: begin  next_modeX = COAST; is_x_command = '1; end
            BRKX: begin  next_modeX = BRAKE; is_x_command = '1; end
            FWDY: begin  next_modeY = FORWARD; needs_duty = '1; is_y_command = '1; end
            REVY: begin  next_modeY = REVERSE; needs_duty = '1; is_y_command = '1; end
            CSTY: begin  next_modeY = COAST; is_y_command = '1; end
            BRKY: begin  next_modeY = BRAKE; is_y_command = '1; end
            STS: begin
                is_write = '1;
                next_buf_len = 2; next_buffer[0] = 8'd0; next_buffer[1] = 8'd1;
            end
            default: begin end
        endcase
    end

endmodule
