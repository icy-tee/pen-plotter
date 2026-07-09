

import pp_pkg::i32_t;

typedef enum logic [1:0] {
    AB_ZERO, A_LEADS_B, AB_ONE, B_LEADS_A
} quad_state_e;

module quad_decoder(
    input clk,
    input rst_n,
    input clr_i,
    input A_i,
    input B_i,

    output i32_t tick_position
);
    logic [1:0] A_i_latch, B_i_latch;

    quad_state_e state;
    quad_state_e next_state;
    i32_t tick_val;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_position <= 0;
            A_i_latch <= 0;
            B_i_latch <= 0;
            state <= AB_ZERO;
        end else begin
            A_i_latch <= { A_i, A_i_latch[1] };
            B_i_latch <= { B_i, B_i_latch[1] };
            state <= next_state;

            if (clr_i)
                tick_position <= 0;
            else
                tick_position <= tick_position + tick_val;
        end
    end

    always_comb begin
        next_state = AB_ZERO; tick_val = 0;
        casez ({state, A_i_latch[0], B_i_latch[0]})
            {AB_ZERO, 1'b0, 1'b0}: begin next_state = AB_ZERO; end
            {AB_ZERO, 1'b1, 1'b0}: begin next_state = A_LEADS_B; tick_val = 1; end
            {AB_ZERO, 1'b0, 1'b1}: begin next_state = B_LEADS_A; tick_val = -1; end
            {A_LEADS_B, 1'b0, 1'b0}: begin next_state = AB_ZERO; tick_val = -1; end
            {A_LEADS_B, 1'b1, 1'b0}: begin next_state = A_LEADS_B; end
            {A_LEADS_B, 1'b1, 1'b1}: begin next_state = AB_ONE; tick_val = 1; end
            {B_LEADS_A, 1'b0, 1'b0}: begin next_state = AB_ZERO; tick_val = 1; end
            {B_LEADS_A, 1'b0, 1'b1}: begin next_state = B_LEADS_A; end
            {B_LEADS_A, 1'b1, 1'b1}: begin next_state = AB_ONE; tick_val = -1; end
            {AB_ONE, 1'b1, 1'b1}: begin next_state = AB_ONE; end
            {AB_ONE, 1'b1, 1'b0}: begin next_state = A_LEADS_B; tick_val = -1; end
            {AB_ONE, 1'b0, 1'b1}: begin next_state = B_LEADS_A; tick_val = 1; end
            default: begin next_state = AB_ZERO; tick_val = 0; end
        endcase
    end

endmodule
