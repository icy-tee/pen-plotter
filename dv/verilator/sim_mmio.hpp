#ifndef SIM_MMIO_HPP
#define SIM_MMIO_HPP

#include <cstdint>

#define RAM_START   (0x0010'0000)
#define UART_START  (0x8000'0000)
#define GPIO_START  (0x8000'1000)
#define PWM_START   (0x8000'2000)
#define TIMER_START (0x8000'3000)
#define PID_START   (0x8000'4000)
#define QUAD_START  (0x8000'4400)

#define RAM_SIZE (128 * 1024)
#define UART_SIZE (4 * 1024)
#define GPIO_SIZE (4 * 1024)
#define PWM_SIZE (4 * 1024)
#define TIMER_SIZE (4 * 1024)
#define PID_SIZE (1 * 1024)
#define QUAD_SIZE (1 * 1024)

struct OBITransaction {
    uint64_t sequence;
    uint32_t addr;
    uint32_t wdata;
    bool we;
    uint8_t be;
    uint32_t rdata;
    bool err;
};

enum class Peripheral : uint32_t {
    INVALID = 0,
    RAM,
    UART,
    GPIO,
    PWM,
    TIMER,
    PID,
    QUAD,
};

constexpr const char* to_string(Peripheral peripheral) {
    switch (peripheral) {
        case Peripheral::INVALID: return "INVALID";
        case Peripheral::RAM:     return "RAM";
        case Peripheral::UART:    return "UART";
        case Peripheral::GPIO:    return "GPIO";
        case Peripheral::PWM:     return "PWM";
        case Peripheral::PID:     return "PID";
        case Peripheral::QUAD:    return "QUAD";
        case Peripheral::TIMER:   return "TIMER";
    }
}

Peripheral classify_address(uint32_t addr) {
    if      (RAM_START   <= addr && addr < RAM_START + RAM_SIZE)     return Peripheral::RAM;   
    else if (UART_START  <= addr && addr < UART_START + UART_SIZE)   return Peripheral::UART;   
    else if (GPIO_START  <= addr && addr < GPIO_START + GPIO_SIZE)   return Peripheral::GPIO;   
    else if (PWM_START   <= addr && addr < PWM_START + PWM_SIZE)     return Peripheral::PWM;   
    else if (TIMER_START <= addr && addr < TIMER_START + TIMER_SIZE) return Peripheral::TIMER;   
    else if (PID_START   <= addr && addr < PID_START + PID_SIZE)     return Peripheral::PID;   
    else if (QUAD_START  <= addr && addr < QUAD_START + QUAD_SIZE)   return Peripheral::QUAD;
    else return Peripheral::INVALID;  
}


#endif // SIM_MMIO_HPP
