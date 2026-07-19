
#include "peripherals.h"

volatile uint32_t timer_interrupt_count;

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

static void uart_putnumber(int32_t num) {
    if (num < 0) {
        uart_putc('-');
        num = -num;
    }
    
    int divisor = 1;
    while (num / divisor >= 10)
        divisor *= 10;
    while (divisor > 0) {
        char digit = num / divisor + '0';
        uart_putc(digit);

        num = num % divisor;
        divisor /= 10;
    }
}

static uint64_t timer_read_mtime(void) {
    uint32_t hi0;
    uint32_t lo;
    uint32_t hi1;

    do {
        hi0 = TIMER->MTIME_HI;
        lo = TIMER->MTIME_LO;
        hi1 = TIMER->MTIME_HI;
    } while (hi0 != hi1);

    return ((uint64_t)hi1 << 32) | lo;
}

static void timer_write_mtimecmp(uint64_t value) {
    TIMER->MTIMECMP_LO = 0xFFFFFFFFu;
    TIMER->MTIMECMP_HI = (uint32_t)(value >> 32);
    TIMER->MTIMECMP_LO = (uint32_t)value;
}

static void timer_enable_interrupts(void) {
    asm volatile ("csrs mie, %0" :: "r"(1u << 7));
    asm volatile ("csrs mstatus, %0" :: "r"(1u << 3));
}

static void timer_init(void) {
    timer_write_mtimecmp(timer_read_mtime() + TIMER_PERIOD_TICKS);
    TIMER->CONTROL = TIMER_CONTROL_ENABLE | TIMER_CONTROL_IRQ_ENABLE;
    timer_enable_interrupts();
}

static volatile int print = 0;

void machine_timer_handler(void) {
    timer_interrupt_count++;
    print = 1;
    timer_write_mtimecmp(timer_read_mtime() + TIMER_PERIOD_TICKS);
}


int main(void) {
    UART->BAUD = 2;
    uart_puts("Hello World!\n");
    timer_init();

    while (1) {
        if (print) {
            uart_putnumber(QUAD->X);
            uart_putc('\n');
            print = 0;
        }
    }
}

