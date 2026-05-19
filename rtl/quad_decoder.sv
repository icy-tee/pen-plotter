
import pp_pkg::*;

typedef enum logic [1:0] {
    AB_ZERO, A_LEADS_B, AB_ONE, B_LEADS_A
} quad_state_e;

module quad_decoder(
    input clk,
    input rst_n,
    input A_i,
    input B_i,

    output q32_t tick_position
);
    logic A_i_latch, B_i_latch;

    quad_state_e state;
    quad_state_e next_state;
    q32_t tick_val;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_position <= 0;
            A_i_latch <= 0;
            B_i_latch <= 0;
            state <= AB_ZERO;
        end else begin
            A_i_latch <= A_i;
            B_i_latch <= B_i;
            state <= next_state;
            tick_position <= tick_position + tick_val;
        end
    end

    always_comb begin
        next_state = AB_ZERO; tick_val = 0;
        casez ({state, A_i_latch, B_i_latch})
            {AB_ZERO, '0, '0}: begin next_state = AB_ZERO; end
            {AB_ZERO, '1, '0}: begin next_state = A_LEADS_B; tick_val = 1; end
            {AB_ZERO, '0, '1}: begin next_state = B_LEADS_A; tick_val = -1; end
            {A_LEADS_B, '0, '0}: begin next_state = AB_ZERO; tick_val = -1; end
            {A_LEADS_B, '1, '0}: begin next_state = A_LEADS_B; end
            {A_LEADS_B, '1, '1}: begin next_state = AB_ONE; tick_val = 1; end
            {B_LEADS_A, '0, '0}: begin next_state = AB_ZERO; tick_val = 1; end
            {B_LEADS_A, '0, '1}: begin next_state = B_LEADS_A; end
            {B_LEADS_A, '1, '1}: begin next_state = AB_ONE; tick_val = -1; end
            {AB_ONE, '1, '1}: begin next_state = AB_ONE; end
            {AB_ONE, '1, '0}: begin next_state = A_LEADS_B; tick_val = -1; end
            {AB_ONE, '0, '1}: begin next_state = B_LEADS_A; tick_val = 1; end
            default: begin next_state = AB_ZERO; tick_val = 0; end
        endcase
    end

endmodule
