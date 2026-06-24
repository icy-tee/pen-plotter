package uart_obi_pkg;
    typedef enum logic [2:0] {
        DISABLED,
        STATUS,
        TX,
        RX,
        BAUD
    } register_e;

    localparam int unsigned STSLane  = 'h000;
    localparam int unsigned BaudLane = 'h001;
    localparam int unsigned TXLane   = 'h002;
    localparam int unsigned RXLane   = 'h003;
endpackage
