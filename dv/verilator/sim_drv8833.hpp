#ifndef SIM_DRV8833_H
#define SIM_DRV8833_H

#include <functional>
#include <cstdint>

enum DRV8833Mode {
    INVALID = -1,
    FORWARD = 0,
    BACKWARD,
    COAST,
    BRAKE
};

struct DRV8833ModeInfo {
    DRV8833Mode mode;
    uint8_t duty;
};

using DRV8833Callback = std::function<void()>;

struct DRV8833Decoder {

    DRV8833Callback channelA_notify, channelB_notify;

    void tick(uint8_t a, uint8_t) {
        
    }
    
}

#endif
