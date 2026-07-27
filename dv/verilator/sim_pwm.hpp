#ifndef SIM_PWM_H
#define SIM_PWM_H

#include <functional>
#include <cstdint>

using PWMCallback = std::function<void(size_t period, size_t on_duration)>;

struct PWMDecoder {

    size_t on_duration = 0;
    size_t off_duration = 0;
    uint8_t prev_pwm = 0;

    PWMCallback notify;

    // lsb is pwm signal
    void tick(uint8_t pwm) {
        
        if (pwm == 0 && prev_pwm == 0) {
            off_duration ++;
        } else if (pwm == 1 && prev_pwm == 1) {
            on_duration ++;
        } else if (pwm == 1 && prev_pwm == 0) {
            // do nothing, handled by state machine
        } else if (pwm == 0 && prev_pwm == 1) {
            notify(on_duration + off_duration, on_duration);
            on_duration = 0;
            off_duration = 0;
        }
        
        prev_pwm = pwm;
    }

    };
 

#endif
