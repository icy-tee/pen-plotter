
module prgm_pwm (
    input logic clk,
    input logic rst_n,
    input logic [31:0] period_i,
    input logic [31:0] width_i,
    output logic pwm_o
);
    logic enabled;
    logic [31:0] counter, width;

    assign enabled = period_i != 32'd0;
    assign width = (width_i > period_i) ? period_i : width_i;
    assign pwm_o = enabled && (counter < width);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'd0;
        end else begin
            if (enabled && counter < period_i - 32'd1) begin
                counter <= counter + 32'd1;
            end else begin
                counter <= 32'd0;
            end
        end
    end
endmodule
