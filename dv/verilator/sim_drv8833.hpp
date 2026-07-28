#ifndef SIM_DRV8833_H
#define SIM_DRV8833_H

#include <cstring>
#include <functional>
#include <cstdint>
#include <memory>

#define CHANNEL_COUNT 2

enum DRV8833Mode {
    FORWARD = 0, // IN1: 1, IN2: 0
    BACKWARD,    // IN1: 0, IN2: 1
    COAST,       // IN1: 0, IN2: 0
    BRAKE,       // IN1: 1, IN2: 1
    LENGTH
};

struct DRV8833Info {
    double fwd_ratio;
    double bwd_ratio;
    double cst_ratio;
    double brk_ratio;
};

using DRV8833Callback = std::function<void(DRV8833Info)>;

struct DRV8833Decoder {

    static const size_t cycles_for_period = 2000; // known bc `pwm.sv` uses default of 25 KHz for PWM freq and 50 MHz is Sys freq

    static inline DRV8833Info percentage_of(size_t channel[DRV8833Mode::LENGTH]) {
        return {
            (double)channel[DRV8833Mode::FORWARD] / cycles_for_period,
            (double)channel[DRV8833Mode::BACKWARD] / cycles_for_period,
            (double)channel[DRV8833Mode::COAST] / cycles_for_period,
            (double)channel[DRV8833Mode::BRAKE] / cycles_for_period,
        };
    }

    size_t cycles = 0;
    size_t channel[CHANNEL_COUNT][DRV8833Mode::LENGTH] = {  };

    DRV8833Callback notify[CHANNEL_COUNT] = {  };

    void tick(uint8_t in1, uint8_t in2) { // a -> IN1 IN2, b -> IN3 IN4

        uint8_t in[CHANNEL_COUNT] = {in1, in2};

        for (size_t j = 0; j < CHANNEL_COUNT; j++) {
            uint8_t state =  in[j] & 0b11;

            switch (state) {
                case 0b00:
                    channel[j][DRV8833Mode::COAST]++;
                    break;
                case 0b01:
                    channel[j][DRV8833Mode::FORWARD]++;
                    break;
                case 0b10:
                    channel[j][DRV8833Mode::BACKWARD]++;
                    break;
                case 0b11:
                    channel[j][DRV8833Mode::BRAKE]++;
                    break;
            }
        }

        if (cycles + 1 == cycles_for_period) {
            cycles = 0;

            for (size_t j = 0; j < CHANNEL_COUNT; j++) {
                if (notify[j]) notify[j](percentage_of(channel[j]));

                memset(channel[j], 0, sizeof(channel[j]));
            }
        } else {
            cycles ++;
        }       
    }
    
};

#endif
