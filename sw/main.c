
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

static uint32_t read_u32_le(const uint8_t bytes[4]) {
    return ((uint32_t)bytes[0] << 0)
         | ((uint32_t)bytes[1] << 8)
         | ((uint32_t)bytes[2] << 16)
         | ((uint32_t)bytes[3] << 24);
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
}

static void pid_enable_interrupts(void) {
    asm volatile ("csrs mie, %0" :: "r"(1u << 16));
}

static void enable_interrupts(void) {
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

static volatile int stable_x = 1;
static volatile int stable_y = 1;

void pid_interrupt_handler(void) {
    const uint32_t status = PID->STATUS;
    uint32_t acknowledged = 0;

    if (status & PID_INT_XSTABLE_bm) {
        stable_x = 1;
        acknowledged |= PID_INT_XSTABLE_bm;
    }

    if (status & PID_INT_YSTABLE_bm) {
        stable_y = 1;
        acknowledged |= PID_INT_YSTABLE_bm;
    }

    if (acknowledged != 0) {
        PID->STATUS = acknowledged;
    }
}

int main(void) {
    UART->BAUD = 2;

    pid_enable_interrupts();
    timer_init();

    enable_interrupts();

    PWM->PERIOD = 1000000; // 50 Hz or 20ms
    PWM->WIDTH  = 50000;   // 1 ms

    volatile uint32_t status;

    uint8_t command[6] = { 0 };
    uint8_t len = 0;
    uint8_t finished = 0;
    uint8_t streaming = 0;

    uint8_t message_sent = 0;

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

        if (!message_sent && stable_x && stable_y) {
            uart_putc(3);
            message_sent = 1;
        }

        if (finished) {
            switch(command[0]) {
                case 0:
                    uart_putc(0);
                    uart_putc(3);
                    break;
                case 1:
                    QUAD->X = 1;
                    PID->X.SET_POINT = 0;
                    QUAD->Y = 1;
                    PID->Y.SET_POINT = 0;
                    break;
                case 2:
                    switch(command[1]) {
                        case 0: {
                            const int32_t setpoint = (int32_t)read_u32_le(&command[2]);
                            if (PID->X.SET_POINT != setpoint) {
                                PID->X.SET_POINT = setpoint;
                                stable_x = 0;
                                message_sent = 0;
                            }
                            break;
                        }
                        case 1: {
                            const int32_t setpoint = (int32_t)read_u32_le(&command[2]);
                            if (PID->Y.SET_POINT != setpoint) {
                                PID->Y.SET_POINT = setpoint;
                                stable_y = 0;
                                message_sent = 0;
                            }
                            break;
                        }
                        case 2: {
                            const q16_16_t kp = (q16_16_t)read_u32_le(&command[2]);
                            PID->X.KP = kp;
                            PID->Y.KP = kp;
                            break;
                        }
                        case 3: {
                            const q16_16_t kd = (q16_16_t)read_u32_le(&command[2]);
                            PID->X.KD = kd;
                            PID->Y.KD = kd;
                            break;
                        }
                        case 4: {
                            const uint32_t rs = read_u32_le(&command[2]);
                            PID->X.RS = rs;
                            PID->Y.RS = rs;
                            break;
                        }
                        case 5: {
                            uint32_t angle = read_u32_le(&command[2]); // 0 is 0, 65535 is 180

                            angle = angle >= 65535 ? 65535 : angle;

                            PWM->WIDTH = 50000 + (50000 * angle) / 66535;
                            
                            break;
                        }
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

