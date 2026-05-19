
import pp_pkg::*;

module pid_controller #(
    int CLOCK_RATE = 50_000_000,
    // int MARGIN_OF_ERROR = 40,
    int BASE_PWM = 179 // =  255 * 0.70
) (
    input clk,
    input rst_n,

    input q16_16_t proportional_constant_i,
    input q16_16_t derivative_constant_i,
    input logic[$clog2(CLOCK_RATE)-1:0] sample_rate_i, // todo: rename

    input q32_t process_variable_i, // in ticks
    input q32_t setpoint_i,         // in ticks

    output md_mode_e motor_dir_o,
    output logic [7:0] motor_duty_o
);

    q32_t pv_prev;
    logic[$clog2(CLOCK_RATE)-1:0] counter;
    logic[7:0] base_pwm;

    q32_t error;
    q32_t delta;
    q32_t p_term;
    q32_t d_term;
    q32_t response;

    assign error = setpoint_i - process_variable_i;
    assign p_term = 32'((64'(proportional_constant_i) * 64'(error)) >>> 16); // q32_t

    assign delta = (process_variable_i - pv_prev) >>> sample_rate_i;
    assign d_term = 32'((64'(delta) * 64'(derivative_constant_i)) >>> 16);

    assign response = p_term - d_term;

    assign base_pwm = 8'(BASE_PWM);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            pv_prev <= 0;
        end else begin
            if (counter == (26'd1 << sample_rate_i) - 1) begin
                counter <= 0;
                pv_prev <= process_variable_i;
            end else begin
                counter <= counter + 1;
            end
        end
    end

    always_comb begin
        automatic logic [31:0] magnitude = response < 0 ? $unsigned(-response) : $unsigned(response);
        automatic logic [7:0] contrib = (magnitude < 32'd1024) ? 8'(magnitude >> 2) : 8'd255;
        automatic logic [8:0] val = 9'(base_pwm) + 9'(contrib);

        motor_duty_o = val < 8'd255 ? val[7:0] : 8'd255;

        if (response < 0) motor_dir_o = FORWARD;
        else if (response > 0)  motor_dir_o = REVERSE;
        else begin
            motor_dir_o = COAST;
            motor_duty_o = 0;
        end
    end

endmodule
