#ifndef SIM_PWM_H
#define SIM_PWM_H

#include <cstddef>
#include <cstdint>
#include <functional>

enum class PWMKind {
    INVALID = -1,
    PERIODIC,
    STABLE
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

    size_t stable_timeout = 1000000; // 1*10^6 Cycles  
    size_t stable_counter = 0;

    bool prev_rising_edge = false;
    bool on_active = false;
    size_t on_duration = 0, off_duration = 0;
    uint8_t prev_pwm = 0;

    PWMCallback notify;

    void reset(void) {
        prev_rising_edge = false;
        on_active = false;
        on_duration = 0;
        off_duration = 0;
        prev_pwm = 0;
        stable_counter = 0;
    }

    // lsb is pwm signal
    void tick(uint8_t pwm) {
        
        if (pwm != prev_pwm) {
            if (pwm == 0 && prev_pwm == 1) { // falling edge
                on_active = false;
            } else if (pwm == 1 && prev_pwm == 0) { // rising edge
                if (!on_active && prev_rising_edge) {
                    size_t period = on_duration + off_duration;
                    if (notify) notify({PWMKind::PERIODIC, period, on_duration, off_duration, (double)on_duration/period});
                    off_duration = 0;
                    on_duration = 0;
                }
                prev_rising_edge = true;
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
                if (notify) notify({PWMKind::STABLE, 0, 0, 0, 0.0});
            } else {
                if (notify) notify({PWMKind::STABLE, 0, 0, 0, 1.0});
            }

            prev_rising_edge = false;
            on_duration = 0;
            off_duration = 0;
            stable_counter = 0;
            
        }
        prev_pwm = pwm;
    }

};
 

#endif
