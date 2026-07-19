#ifndef SIM_QUAD_H
#define SIM_QUAD_H

#include <stdint.h>

struct QuadInjector {
    enum STATE { AB_ZERO, AB, BA, AB_ONE } state = AB_ZERO;
    int ticks = 0, ticks_for_next = 0;

    void tick_forward(int ticks_for_next ) {
        if (++ticks >= ticks_for_next) {
            ticks = 0;

            switch (state) {
                case AB_ZERO: state = AB; break;
                case AB: state = AB_ONE; break;
                case AB_ONE: state = BA; break;
                case BA: state = AB_ZERO; break;
            }
        }
    }
    
    void tick_backward(int ticks_for_next) {
        if (++ticks >= ticks_for_next) {
            ticks = 0;

            switch (state) {
                case AB_ZERO: state = BA; break;
                case BA: state = AB_ONE; break;
                case AB_ONE: state = AB; break;
                case AB: state = AB_ZERO; break;
            }
        }
    }

    uint8_t A() {
        switch (state) {
            case AB_ZERO: return 0;
            case AB: return 1;
            case BA: return 0;
            case AB_ONE: return 1;
        }
        return 0;
    }

    uint8_t B() {
        switch (state) {
            case AB_ZERO: return 0;
            case BA: return 1;
            case AB: return 0;
            case AB_ONE: return 1;
        }
        return 0;
    }
};

#endif
