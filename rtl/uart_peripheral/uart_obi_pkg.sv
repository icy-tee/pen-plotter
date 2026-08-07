package uart_obi_pkg;
    typedef enum logic [2:0] {
        DISABLED,
        STATUS,
        TX,
        RX,
        BAUD
    } register_e;

    typedef enum logic [7:0] {
        BAUD_DISABLED = 'h00,
        BAUD_4800     = 'h01,
        BAUD_9600     = 'h02,
        BAUD_19200    = 'h03,
        BAUD_38400    = 'h04,
        BAUD_57600    = 'h05,
        BAUD_115200   = 'h06,
        BAUD_230400   = 'h07
    } baud_e;

    localparam int unsigned STSLane  = 'h000;
    localparam int unsigned BaudLane = 'h004;
    localparam int unsigned TXLane   = 'h008;
    localparam int unsigned RXLane   = 'h00C;
endpackage
