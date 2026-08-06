#ifndef SIM_PP_SYSTEM_H
#define SIM_PP_SYSTEM_H

#include <Vtop_verilator.h>

#include <cstdio>
#include <verilated.h>
#include <cassert>
#include <memory>
#include <utility>
#include <queue>

#include "peripherals/sim_quad.hpp"
#include "peripherals/sim_drv8833.hpp"
#include "peripherals/sim_pwm.hpp"
#include "peripherals/sim_uart.hpp"

class PPSystem {
public:

    static constexpr size_t SysClockRate = 50'000'000;
    static constexpr size_t BaudRate = 9'600;
    static constexpr size_t DRV8833Rate = 25'000;
    
    explicit PPSystem(VerilatedContext *contextp) :
        contextp(contextp), instance(std::make_unique<Vtop_verilator>(contextp))
    {
        uart_rx_injector.ticks_per_baud = SysClockRate / BaudRate;
        uart_tx_decoder.ticks_per_baud = SysClockRate / BaudRate;

        drv8833.cycles_for_period = SysClockRate / DRV8833Rate;
    }

    ~PPSystem() {
        instance->final();
    }

    void cycle() {
        instance->clk = 0;
        instance->eval();
        contextp->timeInc(1);
        instance->clk = 1;
        instance->eval();
        contextp->timeInc(1);
    }

    void reset(void) {
        drv8833.reset();

        while (!enqueued_uart_rx.empty()) enqueued_uart_rx.pop();
        
        uart_rx_injector.reset();
        uart_tx_decoder.reset();

        servo.reset();
        quadx.reset();
        quady.reset();

        instance->clk = 0;
        instance->quad_x = 0;
        instance->quad_y = 0;
        instance->uart_rx = 1;

        instance->rst_n = 1;
        instance->eval();
        instance->rst_n = 0;
        instance->eval();

        cycle();
        cycle();

        instance->rst_n = 1;
        cycle();
    }

    void tick(void) {

        uart_tx_decoder.tick(instance->uart_tx);

        if (!enqueued_uart_rx.empty()) {
            if (uart_rx_injector.inject(enqueued_uart_rx.front()))
                enqueued_uart_rx.pop();
        }

        instance->uart_rx = uart_rx_injector.tick();

        servo.tick(instance->servo);

        double fwdx = drv8833.current_info[0].fwd_ratio;
        double bwdx = drv8833.current_info[0].bwd_ratio;
        double fwdy = drv8833.current_info[1].fwd_ratio;
        double bwdy = drv8833.current_info[1].bwd_ratio;

        if (fwdx > 0.3) quadx.increase_ticks(2000.0 / fwdx);
        if (bwdx > 0.3) quadx.decrease_ticks(2000.0 / bwdx);

        if (fwdy > 0.3) quady.increase_ticks(2000.0 / fwdy);
        if (bwdy > 0.3) quady.decrease_ticks(2000.0 / bwdy);

        instance->quad_x = (quadx.A() << 0 | quadx.B() << 1);
        instance->quad_y = (quady.A() << 0 | quady.B() << 1);

        drv8833.tick(instance->motor_x & 0b11, instance->motor_y & 0b11);

        cycle();
    }

    void uart_enqueue(uint8_t val) {
        enqueued_uart_rx.push(val);
    }

    void set_drv8833_ch_decode_cb(size_t idx, DRV8833Callback cb) {
        assert(idx < DRV8833Decoder::ChannelCount);
        if (idx < DRV8833Decoder::ChannelCount) {
            drv8833.notify[idx] = std::move(cb);
        }
    }

    void set_uart_decode_cb(UARTCallback cb) {
        uart_tx_decoder.notify = std::move(cb);
    }

    void set_servo_decode_cb(PWMCallback cb) {
        servo.notify = std::move(cb);
    }

private:
    VerilatedContext *contextp;
    std::unique_ptr<Vtop_verilator> instance;

    std::queue<uint8_t> enqueued_uart_rx;

    QuadInjector quadx;
    QuadInjector quady;
    UARTDecoder uart_tx_decoder;
    UARTInjector uart_rx_injector;
    DRV8833Decoder drv8833;
    PWMDecoder servo;
};

#endif
