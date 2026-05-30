
module tb_pwm;

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
