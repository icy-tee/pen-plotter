
#include "peripherals.h"

volatile uint32_t timer_interrupt_count;

static void uart_putc(char c) {
   while ((UART->STATUS & UART_TX_FULL)) {
       asm volatile ("nop");
   }

   UART->TX.ONE_WIDTH = (uint8_t)c;
}

static void uart_putw(uint32_t w) {
    while ((UART->STATUS & UART_TX_FULL)) {
        asm volatile ("nop");
    }

    UART->TX.FOUR_WIDTH = w;
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
    timer_init();

    uint8_t command[6] = { 0 };
    uint8_t len = 0;
    uint8_t finished = 0;
    uint8_t streaming = 0;

    while (1) {
        if ((UART->STATUS & UART_RX_EMPTY) != UART_RX_EMPTY) {
            command[len++] = UART->RX;

            if (len == 1) {
                finished = (command[0] == 0 || command[0] == 1 || command[0] == 4);
            }
            if (len == 6) {
                finished = 1;
            }
        }

        if (streaming && print) {
            uart_putc(1);
            uart_putw(QUAD->X);
            uart_putc(2);
            uart_putw(QUAD->Y);
            print = 0;
        }

        if (finished) {
            switch(command[0]) {
                case 0:
                    uart_putc(0);
                    uart_putc(3);
                    break;
                case 1:
                    // reset
                    break;
                case 2:
                    switch(command[1]) {
                        case 0: PID_X->SET_POINT = *(uint32_t*)(&command[2]); break;
                        case 1: PID_Y->SET_POINT = *(uint32_t*)(&command[2]); break;
                        case 2: PID_X->KP = *(uint32_t*)(&command[2]); PID_Y->KP = *(uint32_t*)(&command[2]); break;
                        case 3: PID_X->KD = *(uint32_t*)(&command[2]); PID_Y->KD = *(uint32_t*)(&command[2]); break;
                        case 4: PID_X->RS = *(uint32_t*)(&command[2]); PID_Y->RS = *(uint32_t*)(&command[2]); break;
                        case 5: break;
                    }
                    break;
                case 4:
                    streaming = !streaming;
                    break;
            }
            len = 0;
            finished = 0;
        }
    }
}

