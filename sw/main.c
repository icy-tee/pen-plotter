#include <stdint.h>

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

#define UART ((volatile UARTRegisterLayout*)0x80000000)
#define UART_RX_EMPTY 0x80
#define UART_RX_FULL  0x40
#define UART_TX_EMPTY  0x20
#define UART_TX_FULL 0x10

static void uart_putc(char c) {
   while ((UART->STATUS & UART_TX_FULL)) {
       asm volatile ("nop");
   }

   UART->TX.ONE_WIDTH = (uint8_t)c;
}

static void uart_puts(const char *str) {
   for (int i = 0; str[i] != '\0'; i++) {
       uart_putc(str[i]);
   }
}


int main(void) {
    UART->BAUD = 2;
    uart_puts("Hello World!");

    while (1) {
        asm volatile ("nop");
    }
}

