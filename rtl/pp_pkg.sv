package pp_pkg;

    typedef enum logic [1:0] {
        COAST, FORWARD, REVERSE, BRAKE
    } md_mode_e;

    typedef enum logic [7:0] {
        STS, RST, SET, GET, STR
    } instr_e;

    typedef logic signed [31:0] q32_t; // int s31b
    typedef logic signed [31:0] q16_16_t; // fixed point s15b.16b

endpackage
