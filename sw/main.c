#include <stdint.h>

typedef struct {
    volatile uint32_t STATUS;
    volatile uint32_t BAUD;
    union {
        volatile uint8_t ONE_WIDTH;
        volatile uint16_t TWO_WIDTH;
        volatile uint32_t FOUR_WIDTH;
    } TX;
    volatile uint32_t RX;
} UARTRegisterLayout;

#define UART ((volatile UARTRegisterLayout*)0x80000000)

int main(void) {
    UART->BAUD = 2;
    while (1) {
        UART->TX.ONE_WIDTH = 'B';
    }
}
