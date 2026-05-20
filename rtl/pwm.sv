
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



module pwm_tb;

    localparam int ClockRate = 50_000_000;
    localparam int PwmFreq = 50;

    bit clk;
    bit rstn;
    bit [7:0] duty;
    bit pwm;

    pwm #(
        .CLOCK_RATE(ClockRate),
        .PWM_FREQ(PwmFreq)
    ) u0 (
        .clk(clk),
        .rst_n(rstn),
        .duty_i(duty),
        .pwm_o(pwm)
    );

    always #1 clk <= ~clk;

    task automatic check_duty(input bit [7:0] d);
        int high_count = 0;
        int expected = (int'(d) * (ClockRate / PwmFreq)) >>> 8;
        duty = d;
        for (int i = 0; i < (ClockRate / PwmFreq); i++) begin
            @(posedge clk);
            if (pwm) high_count++;
        end
        assert(high_count == expected)
            else $error("duty=%0d: measured high=%0d, expected %0d", expected, high_count, expected);
        $display("duty=%0d -> high=%0d  PASS", expected, high_count);
    endtask

    initial begin
        rstn = 0; duty = 0;
        repeat(4) @(posedge clk);
        rstn = 1;

        check_duty(128); // ~50%
        check_duty(0);   // 0%
        check_duty(255); // 100%

        $display("All checks passed!");

        $finish;
    end

    initial begin
        #50_000_000;
        $fatal(1, "Timeout: testbench did not finish");
    end


endmodule
