#ifndef SIM_UART_H
#define SIM_UART_H

#include <cstddef>
#include <cstdint>
#include <functional>

enum class UARTState { IDLE, START, DATA, STOP } ;
using UARTCallback = std::function<void(uint8_t byte)>;

struct UARTInjector {
    UARTState state = UARTState::IDLE;

    bool data_ready = false;
    uint8_t data = 0;
    size_t ticks = 0, bit = 0;
    size_t ticks_per_baud = 5208;

    void reset(void) {
        state = UARTState::IDLE;
        data_ready = false;
        data = 0;
        ticks = 0;
        bit = 0;
    }

    bool inject(const uint8_t val) {
        if (data_ready || state != UARTState::IDLE)
            return false;
        data_ready = true;
        data = val;
        return true;
    }

    uint8_t tick(void) {
        ticks++;
        switch(state) {
            case UARTState::IDLE:
                if (data_ready) {
                    data_ready = false;
                    ticks = 0;
                    state = UARTState::START;
                }
                return 0b1;
            case UARTState::START: {
                if (ticks == ticks_per_baud - 1) {
                    bit = 0;
                    ticks = 0;
                    state = UARTState::DATA;
                }
                return 0b0;
            }
            case UARTState::DATA:
                if (ticks == ticks_per_baud - 1) {
                    ticks = 0;
                    if (++bit >= 8) {
                        state = UARTState::STOP;
                        return 0b1;
                    }
                }
                return (data >> bit) & 1;
            case UARTState::STOP:
                if (ticks == ticks_per_baud - 1)
                    state = UARTState::IDLE;
                return 0b1;
        }
        return 0b1;
    }
};

struct UARTDecoder {
    UARTState state = UARTState::IDLE;
    UARTCallback notify;
    int ticks = 0, val = 0, bit = 0, ticks_per_baud = 5208;

    void reset(void) {
        state = UARTState::IDLE;
        ticks = 0;
        val = 0;
        bit = 0;
    }

    void tick(uint8_t tx_in) {
        ticks++;
        switch(state) {
            case UARTState::IDLE:
                if (!tx_in) { state = UARTState::START; ticks = 0; val = 0; }
                break;
            case UARTState::START: {
                if (ticks == (ticks_per_baud - 1) / 2) {
                    bit = 0;
                    ticks = 0;
                    state = UARTState::DATA;
                }
                break;
            }
            case UARTState::DATA:
                if (ticks == ticks_per_baud - 1) {
                    val |= (tx_in & 1) << bit;
                    ticks = 0;
                    if (++bit >= 8) state = UARTState::STOP;
                }
                break;
            case UARTState::STOP:
                if (ticks == ticks_per_baud - 1) {
                    state = UARTState::IDLE;
                    if (notify) notify(val);
                }
                break;
        }
    }
};

#endif
