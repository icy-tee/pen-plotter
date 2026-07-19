#ifndef PERIPHERALS_H
#define PERIPHERALS_H

#include <stdint.h>

typedef int32_t q16_16_t;

typedef struct {
    volatile uint32_t CONTROL;
    volatile uint32_t MTIME_LO;
    volatile uint32_t MTIME_HI;
    volatile uint32_t MTIMECMP_LO;
    volatile uint32_t MTIMECMP_HI;
} TimerRegisterLayout;

typedef struct {
    volatile uint32_t STATUS;
    volatile uint32_t BAUD;
    union {
        volatile uint8_t ONE_WIDTH;
        volatile uint16_t TWO_WIDTH;
        volatile uint32_t FOUR_WIDTH;
    } TX;
    volatile uint8_t RX;
} UARTRegisterLayout;

typedef struct {
    volatile int32_t X;
    volatile int32_t Y;
} QuadRegisterLayout;

typedef struct {
    volatile q16_16_t KP;
    volatile q16_16_t KD;
    volatile uint32_t RS;
    volatile int32_t SET_POINT;
} PIDRegisterLayout;

typedef struct {
    volatile uint32_t PERIOD;
    volatile uint32_t WIDTH;
} PWMRegisterLayout;

#define UART_RX_EMPTY 0x80
#define UART_RX_FULL 0x40
#define UART_TX_EMPTY 0x20
#define UART_TX_FULL 0x10

#define TIMER_CONTROL_ENABLE 0x1
#define TIMER_CONTROL_IRQ_ENABLE 0x2
#define TIMER_PERIOD_TICKS 5000000ull

#define UART ((volatile UARTRegisterLayout *)0x80000000)
#define PWM ((volatile PWMRegisterLayout *)0x80002000)
#define TIMER ((volatile TimerRegisterLayout *)0x80003000)
#define PID_X ((volatile PIDRegisterLayout *)0x80004000)
#define PID_Y ((volatile PIDRegisterLayout *)0x80004010)
#define QUAD ((volatile QuadRegisterLayout*)0x80004400)

#endif // PERIPHERALS_H
