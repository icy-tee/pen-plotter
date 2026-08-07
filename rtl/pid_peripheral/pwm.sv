
module pwm #(
    int CLOCK_RATE = 50_000_000,
    int PWM_FREQ = 25_000
) (
    input logic clk,
    input logic rst_n,
    input logic [7:0] duty_i,
    output logic pwm_o
);
    localparam int Period = CLOCK_RATE / PWM_FREQ;

    logic [$clog2(Period)-1:0] threshold;
    logic [$clog2(Period)-1:0] counter;

    assign threshold = $clog2(Period)'((32'(duty_i) * Period) >> 8); // / 256
    assign pwm_o = (counter < threshold);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end else if (counter == $unsigned($clog2(Period)'(Period - 1))) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule
