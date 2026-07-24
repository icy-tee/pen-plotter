package pp_pkg;

typedef logic signed [31:0] i32_t; // int s31b
typedef logic signed [31:0] q16_16_t; // fixed point s15b.16b

typedef enum integer {
    ImplGeneric,
    ImplQuartus
} impl_e;

typedef enum logic [1:0] {
    COAST, FORWARD, REVERSE, BRAKE
} md_mode_e;

endpackage
