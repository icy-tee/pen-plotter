#ifndef SIM_QUAD_HPP
#define SIM_QUAD_HPP

#include <cstddef>
#include <cstdint>

struct QuadInjector {
    enum State { AB_ZERO, AB, BA, AB_ONE } state = AB_ZERO;
    size_t ticks = 0;

    void reset(void) {
        state = AB_ZERO;
        ticks = 0;
    }

    void increase_ticks(int ticks_for_next ) {
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
    
    void decrease_ticks(int ticks_for_next) {
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

    uint8_t A(void) {
        switch (state) {
            case AB_ZERO: return 0;
            case AB: return 1;
            case BA: return 0;
            case AB_ONE: return 1;
        }
        return 0;
    }

    uint8_t B(void) {
        switch (state) {
            case AB_ZERO: return 0;
            case BA: return 1;
            case AB: return 0;
            case AB_ONE: return 1;
        }
        return 0;
    }
};

#endif // SIM_QUAD_HPP
