
module servo_pwm #(
    int CLOCK_RATE = 50_000_000,
    int PERIOD_US = 20_000,
    int MIN_US = 1_000,
    int MAX_US = 2_000
) (
    input clk,
    input rst_n,
    input logic [15:0] angle_i,
    output logic pwm_o
);
    localparam int unsigned Period = (CLOCK_RATE / 1_000_000) * PERIOD_US;
    localparam int unsigned MinClks = (CLOCK_RATE / 1_000_000) * MIN_US;
    localparam int unsigned SpanClks = (CLOCK_RATE / 1_000_000) * (MAX_US - MIN_US);

    logic [$clog2(Period)-1:0] threshold, counter;

    assign threshold = 20'(MinClks + 32'(($clog2(Period-1)+16)'(angle_i) * SpanClks >> 16));
    assign pwm_o = counter < threshold;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end else if (counter == $clog2(Period)'(Period - 1)) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule
