
import pp_pkg::*;

module pp_top #(
    parameter ibex_pkg::regfile_e RegFile = ibex_pkg::RegFileFPGA
) (
    input clk,
    input rst_n,
    input [1:0] quad_x,
    input [1:0] quad_y,
    input uart_rx,
    output uart_tx,
    output [1:0] motor_x,
    output [1:0] motor_y,
    output servo
);

typedef enum {
    CORE,
    DBG_HOST
} bus_host_e;

typedef enum {
    RAM,
    UART,
    GPIO,
    PWM,
    PID,
    QUAD,
    TIMER,
    DBG_DEV
} bus_device_e;

localparam bit DBG = 1;
localparam int unsigned DbgHwBreakNum = (DBG == 1) ?    2 :    0;
localparam bit          DbgTriggerEn  = (DBG == 1) ? 1'b1 : 1'b0;

localparam logic [31:0] UARTSize      = 4 * 1024;
localparam logic [31:0] UARTStart     = 32'h80000000;
localparam logic [31:0] UARTMask      = ~(UARTSize-1);

localparam logic [31:0] GPIOSize      = 4 * 1024;
localparam logic [31:0] GPIOStart     = 32'h80001000;
localparam logic [31:0] GPIOMask      = ~(GPIOSize-1);

localparam logic [31:0] PWMSize       = 4 * 1024;
localparam logic [31:0] PWMStart      = 32'h80002000;
localparam logic [31:0] PWMMask       = ~(PWMSize-1);

localparam logic [31:0] TimerSize     = 4 * 1024;
localparam logic [31:0] TimerStart    = 32'h80003000;
localparam logic [31:0] TimerMask     = ~(TimerSize-1);

localparam logic [31:0] PIDSize       = 1 * 1024;
localparam logic [31:0] PIDStart      = 32'h80004000;
localparam logic [31:0] PIDMask       = ~(PIDSize-1);

localparam logic [31:0] QuadSize      = 1 * 1024;
localparam logic [31:0] QuadStart     = 32'h80004400;
localparam logic [31:0] QuadMask      = ~(QuadSize-1);

localparam logic [31:0] DEBUG_SIZE    = 64 * 1024; // 64 KiB
localparam logic [31:0] DEBUG_START   = 32'h1a110000;
localparam logic [31:0] DEBUG_MASK    = ~(DEBUG_SIZE-1);


localparam int NrDevices = DBG ? 8 : 7;
localparam int NrHosts   = DBG ? 2 : 1;

localparam int Core = 0;

    // Interrupts.
    logic timer_irq;
    logic uart_irq;
    logic pid_irq;

    // Host signals.
    logic        host_req      [NrHosts];
    logic        host_gnt      [NrHosts];
    logic [31:0] host_addr     [NrHosts];
    logic        host_we       [NrHosts];
    logic [ 3:0] host_be       [NrHosts];
    logic [31:0] host_wdata    [NrHosts];
    logic        host_rvalid   [NrHosts];
    logic [31:0] host_rdata    [NrHosts];
    logic        host_err      [NrHosts];

    // Device signals.
    logic        device_req    [NrDevices];
    logic        device_gnt    [NrDevices];
    logic [31:0] device_addr   [NrDevices];
    logic        device_we     [NrDevices];
    logic [ 3:0] device_be     [NrDevices];
    logic [31:0] device_wdata  [NrDevices];
    logic        device_rvalid [NrDevices];
    logic [31:0] device_rdata  [NrDevices];
    logic        device_err    [NrDevices];

    // Instruction fetch signals.
    logic        core_instr_req;
    logic        core_instr_gnt;
    logic        core_instr_rvalid;
    logic [31:0] core_instr_addr;
    logic [31:0] core_instr_rdata;
    logic        core_instr_rdata_intg;
    logic        core_instr_sel_dbg;

    logic        mem_instr_req;
    logic [31:0] mem_instr_rdata;
    logic        dbg_instr_req;

    logic        dbg_device_req;
    logic [31:0] dbg_device_addr;
    logic        dbg_device_we;
    logic [ 3:0] dbg_device_be;
    logic [31:0] dbg_device_wdata;
    logic        dbg_device_rvalid;
    logic [31:0] dbg_device_rdata;

// uart_rx_fifo u_rx_fifo(
//     .clk(clk),
//     .rst_n(rst_n),
//     .uart_rx(uart_rx),
//     .bf_data(fifo_data),
//     .bf_read(fifo_read),
//     .bf_empty(fifo_empty)
// );


// uart_tx_fifo u_tx_fifo(
//     .clk(clk),
//     .rst_n(rst_n),
//     .uart_tx_o(uart_tx),
//     .data_i(tx_data),
//     .data_valid_i(tx_valid),
//     .flush_p(tx_flush),
//     .busy_o(tx_busy)
// );

prim_ram_2p #() u_instr_mem ();

bus #(
    .HostCount  (NrHosts),
    .DeviceCount(NrDevices),
    .BufferMax  ()
 ) u_bus (
    .clk             (clk),
    .rst_ni          (rst_n),

    .host_req_i      (host_req),
    .host_gnt_o      (host_gnt),
    .host_addr_i     (host_addr),
    .host_we_i       (host_we),
    .host_be_i       (host_be),
    .host_wdata_i    (host_wdata),
    .host_rvalid_o   (host_rvalid),
    .host_rdata_o    (host_rdata),
    .host_err_o      (host_err),

    .device_req_o    (device_req),
    .device_gnt_i    (device_gnt),
    .device_addr_o   (device_addr),
    .device_we_o     (device_we),
    .device_be_o     (device_be),
    .device_wdata_o  (device_wdata),
    .device_rvalid_i (device_rvalid),
    .device_rdata_i  (device_rdata),
    .device_err_i    (device_err),

    .device_addr_base(),
    .device_addr_mask()
);


ibex_top #(
    .MHPMCounterNum              (10),
    .RV32M                       (ibex_pkg::RV32MFast),
    .RV32B                       (ibex_pkg::RV32BNone),
    .RegFile                     (RegFile),
    .DbgTriggerEn                (DbgTriggerEn),
    .DbgHwBreakNum               (DbgHwBreakNum),
    .DmAddrMask                  (),
    .DmHaltAddr                  ()
 ) u_ibex (
    .clk_i                    (clk),
    .rst_ni                   (rst_n),
    .test_en_i                (1'b0),

    .ram_cfg_icache_tag_i     ('0),
    .ram_cfg_rsp_icache_tag_o ('0),
    .ram_cfg_icache_data_i    ('0),
    .ram_cfg_rsp_icache_data_o('0),

    .hart_id_i                (32'b0),
    .boot_addr_i              (32'h00100000),

    .instr_req_o              (core_instr_req),
    .instr_gnt_i              (core_instr_gnt),
    .instr_rvalid_i           (core_instr_rvalid),
    .instr_addr_o             (core_instr_addr),
    .instr_rdata_i            (core_instr_rdata),
    .instr_rdata_intg_i       (),
    .instr_err_i              ('0),

    .data_req_o               (host_req[Core]),
    .data_gnt_i               (host_gnt[Core]),
    .data_rvalid_i            (host_rvalid[Core]),
    .data_we_o                (host_we[Core]),
    .data_be_o                (host_be[Core]),
    .data_addr_o              (host_addr[Core]),
    .data_wdata_o             (host_wdata[Core]),
    .data_wdata_intg_o        (),
    .data_rdata_i             (host_rdata[Core]),
    .data_rdata_intg_i        (),
    .data_err_i               (host_err[Core]),

    .irq_software_i           ('0),
    .irq_timer_i              ('0),
    .irq_external_i           (1'b0),
    .irq_fast_i               ({15'b0}),
    .irq_nm_i                 (1'b0),

    .scramble_key_valid_i     ('0),
    .scramble_key_i           ('0),
    .scramble_nonce_i         ('0),
    .scramble_req_o           (),

    .debug_req_i              (),
    .crash_dump_o             (),
    .double_fault_seen_o      (),

    .fetch_enable_i           ('1),
    .alert_minor_o            (),
    .alert_major_internal_o   (),
    .alert_major_bus_o        (),
    .core_sleep_o             (),

    .scan_rst_ni              (),
    .lockstep_cmp_en_o        (),

    .data_req_shadow_o        (),
    .data_we_shadow_o         (),
    .data_be_shadow_o         (),
    .data_addr_shadow_o       (),
    .data_wdata_shadow_o      (),
    .data_wdata_intg_shadow_o (),
    .instr_req_shadow_o       (),
    .instr_addr_shadow_o      ()
);

// pid_controller u_pid_x(
//     .clk                    (clk),
//     .rst_n                  (rst_n),
//     .proportional_constant_i(kp),
//     .derivative_constant_i  (kd),
//     .sample_rate_i          (sample_rate[25:0]),
//     .process_variable_i     (tick_pos_x),
//     .setpoint_i             (setpoint_x),
//     .stable_o               (stable_x),
//     .motor_dir_o            (x_dir),
//     .motor_duty_o           (x_duty)
// );


// pid_controller u_pid_y(
//     .clk                    (clk),
//     .rst_n                  (rst_n),
//     .proportional_constant_i(kp),
//     .derivative_constant_i  (kd),
//     .sample_rate_i          (sample_rate[25:0]),
//     .process_variable_i     (tick_pos_y),
//     .setpoint_i             (setpoint_y),
//     .stable_o               (stable_y),
//     .motor_dir_o            (y_dir),
//     .motor_duty_o           (y_duty)
// );


// md_controller u_x_motor_controller(
//     .clk(clk),
//     .rst_n(rst_n),
//     .mode(x_dir),
//     .duty(x_duty),
//     .in1(motor_x[0]),
//     .in2(motor_x[1])
// );


// md_controller u_y_motor_controller(
//     .clk(clk),
//     .rst_n(rst_n),
//     .mode(y_dir),
//     .duty(y_duty),
//     .in1(motor_y[0]),
//     .in2(motor_y[1])
// );


// servo_pwm u_servo (
//     .clk    (clk),
//     .rst_n  (rst_n),
//     .angle_i(servo_angle),
//     .pwm_o  (servo)
// );

// quad_decoder u_x_quad(
//     .clk(clk),
//     .rst_n(rst_n & quad_rst_n),
//     .A_i(quad_x[0]),
//     .B_i(quad_x[1]),
//     .tick_position(tick_pos_x)
// );


// quad_decoder u_y_quad(
//     .clk(clk),
//     .rst_n(rst_n & quad_rst_n),
//     .A_i(quad_y[0]),
//     .B_i(quad_y[1]),
//     .tick_position(tick_pos_y)
// );

endmodule
