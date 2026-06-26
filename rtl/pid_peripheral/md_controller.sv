// motor controller for DRV8833

// verilator lint_off IMPORTSTAR
import pp_pkg::*;
// verilator lint_on IMPORTSTAR

module md_controller #(
    int CLOCK_RATE = 50_000_000,
    int PWM_FREQ = 25_000
)(
    input clk,
    input rst_n,
    input md_mode_e mode,
    input [7:0] duty,

    output logic in1,
    output logic in2
);

    logic pwm_out;

    pwm #(
        .CLOCK_RATE(CLOCK_RATE),
        .PWM_FREQ(PWM_FREQ)
    ) u_pwm (
        .clk(clk),
        .rst_n(rst_n),
        .duty_i(duty),
        .pwm_o(pwm_out)
    );

    always_comb begin
        case(mode)
            FORWARD: begin
                in1 = pwm_out;
                in2 = '0;
            end
            REVERSE: begin
                in1 = '0;
                in2 = pwm_out;
            end
            COAST: begin
                in1 = '0;
                in2 = '0;
            end
            BRAKE: begin
                in1 = '1;
                in2 = '1;
            end
            default: begin
                in1 = '0;
                in2 = '0;
            end
        endcase
    end

endmodule
