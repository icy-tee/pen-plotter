package pp_pkg;

    typedef enum logic [1:0] {
        COAST, FORWARD, REVERSE, BRAKE
    } md_mode_e;

    typedef enum logic [7:0] {
        STS, RST, FWDX, REVX, BRKX, CSTX, FWDY, REVY, BRKY, CSTY, STR
    } instr_e;

endpackage
