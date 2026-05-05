
typedef enum logic [1:0] {
    FILL, FLUSH
} uart_fifo_state_e;

typedef enum logic [1:0] {
    TX_START, TX_DATA, TX_STOP
} uart_tx_state_e;

module uart_tx_fifo #(
    int CLOCK_RATE = 50_000_000,
    int BAUD_RATE = 9600,
    int BUFFER_SIZE = 64
) (
    input clk,
    input rst_n,
    input [7:0] data_i,
    input data_valid_i,
    input flush_p,

    output logic uart_tx_o,
    output busy_o
);

    localparam int ClksPerBit = CLOCK_RATE / BAUD_RATE;

    int baud_counter;
    logic baud_tick;
    int bit_counter;

    uart_fifo_state_e state;
    uart_tx_state_e tx_state;

    logic flush_p_latch;
    logic [7:0] buffer [BUFFER_SIZE];
    int bf_start, bf_end;

    assign baud_tick = (baud_counter == ClksPerBit - 1);
    assign busy_o = (state == FLUSH);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= FILL;
            tx_state <= TX_START;
            buffer <= '{default: '0};
            bf_start <= '0;
            bf_end <= '0;
            baud_counter <= '0;
            bit_counter <= '0;
            flush_p_latch <= '0;
            uart_tx_o <= '1;
        end else begin
            flush_p_latch <= flush_p;

            if (state == FLUSH) begin
                if (baud_tick)
                    baud_counter <= 0;
                else
                    baud_counter <= baud_counter + 1;
                end
            else
                baud_counter <= 0;

            case (state)
                FILL: begin
                    tx_state <= TX_START;
                    if (data_valid_i) begin
                        buffer[bf_end] <= data_i;
                        bf_end <= bf_end + 1;
                        if (bf_end == BUFFER_SIZE - 1) // automatically flush if full
                            state <= FLUSH;
                    end
                    if (flush_p && !flush_p_latch)
                        state <= FLUSH;
                end
                FLUSH: begin
                    case (tx_state)
                        TX_START: begin
                            uart_tx_o <= '0;
                            if (baud_tick) begin
                                tx_state <= TX_DATA;
                                bit_counter <= 0;
                            end
                        end
                        TX_DATA: begin
                            uart_tx_o <= buffer[bf_start][bit_counter];
                            if (baud_tick) begin
                                if (bit_counter == 7)
                                    tx_state <= TX_STOP;
                                else
                                    bit_counter <= bit_counter + 1;
                            end
                        end
                        TX_STOP: begin
                            uart_tx_o <= '1;
                            if (baud_tick) begin
                                if (bf_start + 1 >= bf_end) begin
                                    bf_start <= '0;
                                    bf_end <= '0;
                                    state <= FILL;
                                end else begin
                                    bf_start <= bf_start + 1;
                                end
                                    tx_state <= TX_START;
                            end
                        end
                        default: begin end
                    endcase
                end
                default: begin end
            endcase
        end
    end

endmodule
