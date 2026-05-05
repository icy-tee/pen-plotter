
typedef enum logic [1:0] {
    IDLE, START, DATA, STOP
} rxstate_e;

module uart_rx_fifo #(
    int CLOCK_RATE = 50_000_000,
    int BAUD_RATE = 9600,
    int BUFFER_SIZE = 32
) (
    input clk,
    input rst_n,
    input uart_rx,
    input bf_read,

    output logic [7:0] bf_data,
    output bf_empty
);

    // buffer
    logic [7:0] buffer [BUFFER_SIZE];
    int bf_start, bf_end;
    logic read_latch;

    // rx
    rxstate_e rx_state;
    logic [1:0] rx_latch;
    logic [7:0] rx_collected;
    int rx_collected_count;

    // baud
    localparam int ClksPerBit = CLOCK_RATE / BAUD_RATE;
    localparam int ClksPerBitHalf = ClksPerBit / 2;

    int baud_counter = 0;
    logic baud, sample;

    assign baud = (baud_counter == ClksPerBit - 1);
    assign sample = (baud_counter == ClksPerBitHalf - 1);

    assign bf_empty = (bf_start == bf_end);
    assign bf_data = buffer[bf_start];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_latch <= 0;
            read_latch <= 0;
        end else begin
            rx_latch[1] <= uart_rx;
            rx_latch[0] <= rx_latch[1];

            read_latch <= bf_read;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= IDLE;
            rx_collected_count <= 0;
            rx_collected <= '0;
            buffer <= '{default: '0 };
            bf_start <= '0;
            bf_end <= '0;
            baud_counter <= '0;
        end else begin

            if (bf_read && !read_latch) begin
                if (bf_start == BUFFER_SIZE - 1)
                    bf_start <= 0;
                else
                    bf_start <= bf_start + 1;
            end

            if (rx_state != IDLE) begin
                if (baud)
                    baud_counter <= 0;
                else
                    baud_counter <= baud_counter + 1;
            end else begin
                baud_counter <= 0;
            end

            case (rx_state)
                IDLE: begin
                    if (!rx_latch[0])
                        rx_state <= START;
                    else
                        rx_state <= IDLE;
                end
                START: begin
                    if (sample) begin
                        if (!rx_latch[0]) begin
                            baud_counter <= 0;
                            rx_collected_count <= 0;
                            rx_state <= DATA;
                        end else begin
                            rx_state <= IDLE;
                        end
                    end
                end
                DATA: begin
                    if (baud) begin
                        rx_collected[rx_collected_count] <= rx_latch[0];
                        rx_collected_count <= rx_collected_count + 1;

                        if (rx_collected_count == 7)
                            rx_state <= STOP;
                    end
                end
                STOP: begin
                    if (baud && rx_latch[0]) begin
                        buffer[bf_end] <= rx_collected;
                        rx_collected <= '0;

                        if (bf_end == BUFFER_SIZE - 1)
                            bf_end <= 0;
                        else
                            bf_end <= bf_end + 1;

                        rx_state <= IDLE;
                    end
                end
                default: begin end
            endcase
        end
    end
endmodule
