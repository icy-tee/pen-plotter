// motor controller for DRV8833

import pp_pkg::*;

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
    localparam int Period = CLOCK_RATE / PWM_FREQ;

    int counter;
    int threshold;

    logic pwm_out;

    assign threshold = duty * Period / 256;
    assign pwm_out = (counter < threshold);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end else if (counter == Period - 1) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

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
