#ifndef SIM_PP_SYSTEM_H
#define SIM_PP_SYSTEM_H

#include <Vtop_verilator.h>

#include <verilated.h>

#include "sim_quad.hpp"
#include "sim_drv8833.hpp"
#include "sim_pwm.hpp"
#include "sim_uart.hpp"

class PPSystem {
public:
    PPSystem(VerilatedContext *contextp) {
        this->instance = new Vtop_verilator{contextp};

        uart_rx.ticks_per_baud = 50000000 / 9600;
        uart_tx.ticks_per_baud = 50000000 / 9600;
    }

    ~PPSystem() {
        delete this->instance;
    }

    void cycle() {
        instance->clk = 0;
        instance->eval();
        instance->clk = 1;
        instance->eval();
    }

    void reset(void) {
        instance->rst_n = 1;
        instance->eval();
        instance->rst_n = 0;
        instance->eval();
        instance->rst_n = 1;
        instance->eval();
    }

    void tick(void) {

        uart_tx.tick(instance->uart_tx);
        servo.tick(instance->servo);

        instance->quad_x = (quadx.A() << 0 | quadx.B() << 1);
        instance->quad_y = (quady.A() << 0 | quady.B() << 1);

        drv8833.tick(instance->motor_x & 0b11, instance->motor_y & 0b11);

        cycle();
    }

    void uart_inject(uint8_t val) {
        // uart_tx
    }

    void set_drv8833_ch_decode_cb(size_t idx, DRV8833Callback cb) {
        assert(idx < CHANNEL_COUNT);
        if (idx < CHANNEL_COUNT) {
            drv8833.notify[idx] = cb;
        }
    }

    void set_uart_decode_cb(UARTCallback cb) {
        uart_tx.notify = cb;
    }

    void set_servo_decode_cb(PWMCallback cb) {
        servo.notify = cb;
    }

    private:
    Vtop_verilator *instance;

    QuadInjector quadx;
    QuadInjector quady;

    UARTDecoder uart_tx;
    UARTInjector uart_rx;

    DRV8833Decoder drv8833;

    PWMDecoder servo;
};

#endif
