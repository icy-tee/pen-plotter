#ifndef SIM_UART_H
#define SIM_UART_H

#include <stdint.h>

enum UARTState { IDLE, START, DATA, STOP } ;

struct UARTInjector {
    UARTState state;
    uint8_t val;
    int ticks = 0, bit = 0, ticks_per_baud = 5208;

    bool tick(bool has_byte, uint8_t byte) {
        ticks++;
        switch(state) {
            case IDLE:
                if (has_byte) {
                    ticks = 0;
                    val = byte;
                    state = START;
                }
                return true;
            case START: {
                if (ticks == ticks_per_baud - 1) {
                    bit = 0;
                    ticks = 0;
                    state = DATA;
                }
                return false;
            }
            case DATA:
                if (ticks == ticks_per_baud - 1) {
                    ticks = 0;
                    if (++bit >= 8) {
                        state = STOP;
                        return true;
                    }
                }
                return (val >> bit) & 1;
            case STOP:
                if (ticks == ticks_per_baud - 1)
                    state = IDLE;
                return true;
        }
        return true;
    }
};

struct UARTDecoder {
    UARTState state = IDLE;
    int ticks = 0, val = 0, bit = 0, ticks_per_baud = 5208;

    bool tick(uint8_t tx_in, uint8_t &tx_data) {
        ticks++;
        switch(state) {
            case IDLE:
                if (!tx_in) { state = START; ticks = 0; val = 0; }
                break;
            case START: {
                if (ticks == (ticks_per_baud - 1) / 2) {
                    bit = 0;
                    ticks = 0;
                    state = DATA;
                }
                break;
            }
            case DATA:
                if (ticks == ticks_per_baud - 1) {
                    val |= (tx_in & 1) << bit;
                    ticks = 0;
                    if (++bit >= 8) state = STOP;
                }
                break;
            case STOP:
                if (ticks == ticks_per_baud - 1) {
                    tx_data = val;
                    state = IDLE;
                    return true;
                }
                break;
        }
        return false;
    }
};

#endif
