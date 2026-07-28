#ifndef SIM_PWM_H
#define SIM_PWM_H

#include <functional>
#include <cstdint>

enum PWMKind {
    INVALID = -1,
    PERIODIC,
    ON,
    OFF  
};

struct PWMInfo {
    PWMKind kind;
    size_t period;
    size_t on_duration;
    size_t off_duration;
    double duty;
};

using PWMCallback = std::function<void(PWMInfo)>;

struct PWMDecoder {

    size_t stable_timeout = 1000000; // 25*10^6 Cycles ~ 1/2 second   
    size_t stable_counter = 0;

    bool on_active = false;
    size_t on_duration = 0, off_duration = 0;
    uint8_t prev_pwm = 0;

    PWMCallback notify;

    // lsb is pwm signal
    void tick(uint8_t pwm) {
        
        if (pwm != prev_pwm) {
            if (pwm == 0 && prev_pwm == 1) { // falling edge
                on_active = false;
            } else if (pwm == 1 && prev_pwm == 0) { // rising edge
                if (!on_active) {
                    size_t period = on_duration + off_duration;
                    if (notify) notify({PWMKind::PERIODIC, period, on_duration, off_duration, (double)on_duration/period});
                    off_duration = 0;
                    on_duration = 0;
                }
                on_active = true;
            }
            stable_counter = 0;
        } else {
            stable_counter ++;
        }
        
        if (on_active) {
            on_duration ++;
        } else {
            off_duration ++;
        }

        if (stable_counter >= stable_timeout) {
            if (pwm == 0) {
                if (notify) notify({PWMKind::OFF});
            } else {
                if (notify) notify({PWMKind::ON});
            }
            stable_counter = 0;
        }
        prev_pwm = pwm;
    }

};
 

#endif
