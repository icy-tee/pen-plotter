
module pp_system #(
    parameter ibex_pkg::regfile_e RegFile = ibex_pkg::RegFileFPGA,
    parameter string SRAMInitFile = ""
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

assign servo = '0; // WILL BE REMOVED AND REPLACED WITH GENERAL PWM

typedef enum {
    CoreD
} bus_host_e;

typedef enum {
    Ram,
    Uart,
    Gpio,
    Pwm,
    Pid, // peripheral decodes X/Y access
    Quad, // peripheral decodes X/Y access
    Timer,
    DbgDev
} bus_device_e;

localparam logic [31:0] MemSize       = 128 * 1024;
localparam logic [31:0] MemStart      = 32'h00100000;
localparam logic [31:0] MemMask       = ~(MemSize-1);

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

localparam int NrDevices = 7;
localparam int NrHosts   = 1;

localparam int Core = 0;

// Interrupts.
logic timer_irq;
logic uart_irq;
logic pid_irq;

assign timer_irq = 1'b0;
assign uart_irq = 1'b0;
assign pid_irq = 1'b0;

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
logic        mem_instr_req;
logic [31:0] mem_instr_rdata;

assign mem_instr_req = core_instr_req &
        ((core_instr_addr & cfg_device_addr_mask[Ram]) == cfg_device_addr_base[Ram]);
assign core_instr_gnt = mem_instr_req;
assign core_instr_rdata = mem_instr_rdata;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        core_instr_rvalid <= 1'b0;
    end else begin
        core_instr_rvalid <= core_instr_gnt;
    end
end


logic [31:0] cfg_device_addr_base [NrDevices];
logic [31:0] cfg_device_addr_mask [NrDevices];

assign cfg_device_addr_base[Ram]   = MemStart;
assign cfg_device_addr_mask[Ram]   = MemMask;
assign cfg_device_addr_base[Uart]  = UARTStart;
assign cfg_device_addr_mask[Uart]  = UARTMask;
assign cfg_device_addr_base[Gpio]  = GPIOStart;
assign cfg_device_addr_mask[Gpio]  = GPIOMask;
assign cfg_device_addr_base[Pwm]   = PWMStart;
assign cfg_device_addr_mask[Pwm]   = PWMMask;
assign cfg_device_addr_base[Quad]  = QuadStart;
assign cfg_device_addr_mask[Quad]  = QuadMask;
assign cfg_device_addr_base[Pid]   = PIDStart;
assign cfg_device_addr_mask[Pid]   = PIDMask;
assign cfg_device_addr_base[Timer] = TimerStart;
assign cfg_device_addr_mask[Timer] = TimerMask;

ram_2p #(
  .Depth      ( MemSize / 4 ),
  .MemInitFile( SRAMInitFile )
 ) ram_2p (
  .clk_i     (clk),
  .rst_ni    (rst_n),
  .a_req_i   (device_req[Ram]),
  .a_we_i    (device_we[Ram]),
  .a_be_i    (device_be[Ram]),
  .a_addr_i  (device_addr[Ram]),
  .a_wdata_i (device_wdata[Ram]),
  .a_rvalid_o(device_rvalid[Ram]),
  .a_rdata_o (device_rdata[Ram]),

  .b_req_i   (mem_instr_req),
  .b_we_i    (1'b0),
  .b_be_i    (4'b0),
  .b_addr_i  (core_instr_addr),
  .b_wdata_i (32'b0),
  .b_rvalid_o(),
  .b_rdata_o (mem_instr_rdata)
);

bus #(
    .HostCount  (NrHosts),
    .DeviceCount(NrDevices)
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

    .device_addr_base(cfg_device_addr_base),
    .device_addr_mask(cfg_device_addr_mask)
);

ibex_top #(
    .MHPMCounterNum              (10),
    .RV32M                       (ibex_pkg::RV32MFast),
    .RV32B                       (ibex_pkg::RV32BNone),
    .RegFile                     (RegFile),
    .DbgTriggerEn                (),
    .DbgHwBreakNum               (),
    .DmAddrMask                  (),
    .DmHaltAddr                  ()
 ) u_ibex (
    .clk_i                    (clk),
    .rst_ni                   (rst_n),
    .test_en_i                (1'b0),

    .ram_cfg_icache_tag_i     ('0),
    .ram_cfg_rsp_icache_tag_o (),
    .ram_cfg_icache_data_i    ('0),
    .ram_cfg_rsp_icache_data_o(),

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
    .irq_timer_i              (timer_irq),
    .irq_external_i           (1'b0),
    .irq_fast_i               ({13'b0, pid_irq, uart_irq}),
    .irq_nm_i                 (1'b0),

    .scramble_key_valid_i     ('0),
    .scramble_key_i           ('0),
    .scramble_nonce_i         ('0),
    .scramble_req_o           (),

    .debug_req_i              (1'b0),
    .crash_dump_o             (),
    .double_fault_seen_o      (),

    .fetch_enable_i           ('1),
    .alert_minor_o            (),
    .alert_major_internal_o   (),
    .alert_major_bus_o        (),
    .core_sleep_o             (),

    .scan_rst_ni              (1'b1),
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

uart_obi #(
    .ClockRate   (50_000_000)
 ) u_uart (
    .clk          (clk),
    .rst_ni       (rst_n),
    .rx_i         (uart_rx),
    .tx_o         (uart_tx),
    .req_i        (device_req[Uart]),
    .gnt_o        (device_gnt[Uart]),
    .addr_i       (device_addr[Uart]),
    .we_i         (device_we[Uart]),
    .be_i         (device_be[Uart]),
    .wdata_i      (device_wdata[Uart]),
    .rvalid_o     (device_rvalid[Uart]),
    .rdata_o      (device_rdata[Uart]),
    .err_o        (device_err[Uart])
);

logic [31:0] ticks_x, ticks_y;

obi_quad u_quad (
    .clk     (clk),
    .rst_ni  (rst_n),

    .quad_x_i(quad_x),
    .quad_y_i(quad_y),

    .hw_quad_x(ticks_x),
    .hw_quad_y(ticks_y),

    .req_i   (device_req[Quad]),
    .gnt_o   (device_gnt[Quad]),
    .addr_i  (device_addr[Quad]),
    .we_i    (device_we[Quad]),
    .be_i    (device_be[Quad]),
    .wdata_i (device_wdata[Quad]),
    .rvalid_o(device_rvalid[Quad]),
    .rdata_o (device_rdata[Quad]),
    .err_o   (device_err[Quad])
);

obi_pid u_pid (
    .clk      (clk),
    .rst_ni   (rst_n),

    .hw_pv_x_i(ticks_x),
    .hw_pv_y_i(ticks_y),

    .motor_x_o(motor_x),
    .motor_y_o(motor_y),

    .req_i   (device_req[Pid]),
    .gnt_o   (device_gnt[Pid]),
    .addr_i  (device_addr[Pid]),
    .we_i    (device_we[Pid]),
    .be_i    (device_be[Pid]),
    .wdata_i (device_wdata[Pid]),
    .rvalid_o(device_rvalid[Pid]),
    .rdata_o (device_rdata[Pid]),
    .err_o   (device_err[Pid])
);

obi_stub u_gpio_stub (
    .clk     (clk),
    .rst_ni  (rst_n),

    .req_i   (device_req[Gpio]),
    .gnt_o   (device_gnt[Gpio]),
    .addr_i  (device_addr[Gpio]),
    .we_i    (device_we[Gpio]),
    .be_i    (device_be[Gpio]),
    .wdata_i (device_wdata[Gpio]),
    .rvalid_o(device_rvalid[Gpio]),
    .rdata_o (device_rdata[Gpio]),
    .err_o   (device_err[Gpio])
);

obi_stub u_pwm_stub (
    .clk     (clk),
    .rst_ni  (rst_n),

    .req_i   (device_req[Pwm]),
    .gnt_o   (device_gnt[Pwm]),
    .addr_i  (device_addr[Pwm]),
    .we_i    (device_we[Pwm]),
    .be_i    (device_be[Pwm]),
    .wdata_i (device_wdata[Pwm]),
    .rvalid_o(device_rvalid[Pwm]),
    .rdata_o (device_rdata[Pwm]),
    .err_o   (device_err[Pwm])
);

obi_stub u_timer_stub (
    .clk     (clk),
    .rst_ni  (rst_n),

    .req_i   (device_req[Timer]),
    .gnt_o   (device_gnt[Timer]),
    .addr_i  (device_addr[Timer]),
    .we_i    (device_we[Timer]),
    .be_i    (device_be[Timer]),
    .wdata_i (device_wdata[Timer]),
    .rvalid_o(device_rvalid[Timer]),
    .rdata_o (device_rdata[Timer]),
    .err_o   (device_err[Timer])
);

endmodule
