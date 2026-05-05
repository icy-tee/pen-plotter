
#include "obj_dir/Vpp_top.h"
#include "obj_dir/Vpp_top_pp_top.h"

#include <verilated.h>
#include <stdio.h>
#include <fcntl.h>

struct QuadInjector {
    enum STATE { AB_ZERO, AB, BA, AB_ONE} state = AB_ZERO;
    int ticks = 0, ticks_for_next = 12500000;

    void tick_forward() {
        if (++ticks == ticks_for_next) {
            ticks = 0;

            switch (state) {
                case AB_ZERO: state = AB; break;
                case AB: state = AB_ONE; break;
                case AB_ONE: state = BA; break;
                case BA: state = AB_ZERO; break;
            }
        }
    }

    
    void tick_backward() {
        if (++ticks == ticks_for_next) {
            ticks = 0;

            switch (state) {
                case AB_ZERO: state = BA; break;
                case BA: state = AB_ONE; break;
                case AB_ONE: state = AB; break;
                case AB: state = AB_ZERO; break;
            }
        }
    }

    uint8_t A() {
        switch (state) {
            case AB_ZERO: return 0;
            case AB: return 1;
            case BA: return 0;
            case AB_ONE: return 1;
        }
        return 0;
    }

    uint8_t B() {
        switch (state) {
            case AB_ZERO: return 0;
            case BA: return 1;
            case AB: return 0;
            case AB_ONE: return 1;
        }
        return 0;
    }
};

struct UARTInjector {
    enum STATE { IDLE, START, DATA, STOP } state = IDLE;
    uint8_t val;
    int ticks = 0, bit = 0, ticks_per_baud = 5208;

    bool tick(bool has_byte, uint8_t byte) {
        ticks++;
        switch(state) {
            case IDLE:
                if (has_byte) {
                    ticks = 0;
                    val = byte;
                    state = START;
                }
                return true;
            case START: {
                if (ticks == ticks_per_baud - 1) {
                    bit = 0;
                    ticks = 0;
                    state = DATA;
                }
                return false;
            }
            case DATA:
                if (ticks == ticks_per_baud - 1) {
                    ticks = 0;
                    if (++bit >= 8) {
                        state = STOP;
                        return true;
                    }
                }
                return (val >> bit) & 1;
            case STOP:
                if (ticks == ticks_per_baud - 1)
                    state = IDLE;
                return true;
        }
        return true;
    }
};

struct UARTDecoder {
    enum STATE { IDLE, START, DATA, STOP } state = IDLE;
    int ticks = 0, val = 0, bit = 0, ticks_per_baud = 5208;

    void tick(int handle, uint8_t tx_in) {
        ticks++;
        switch(state) {
            case IDLE:
                if (!tx_in) { state = START; ticks = 0; val = 0; }
                break;
            case START: {
                if (ticks == (ticks_per_baud - 1) / 2) {
                    bit = 0;
                    ticks = 0;
                    state = DATA;
                }
                break;
            }
            case DATA:
                if (ticks == ticks_per_baud - 1) {
                    val |= (tx_in & 1) << bit;
                    ticks = 0;
                    if (++bit >= 8) state = STOP;
                }
                break;
            case STOP:
                if (ticks == ticks_per_baud - 1) {
                    (void)write(handle, &val, 1);
                    state = IDLE;
                }
                break;
        }   
    }
};


void tick(Vpp_top *instance, int cycles) {
    for (int i = 0; i < cycles; i++) {
        instance->clk = 0;
        instance->eval();
        instance->clk = 1;
        instance->eval();
    }
}


int main(int argc, const char **argv) {
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);

    int input = open("uart_rx", O_RDONLY | O_NONBLOCK);
    int output = open("uart_tx", O_RDWR | O_NONBLOCK);
    printf("input fd=%d  output fd=%d\n", input, output); fflush(stdout);

    Vpp_top *pptop = new Vpp_top{contextp};
    UARTDecoder uart_tx;
    UARTInjector uart_rx;
    QuadInjector quadx;
    QuadInjector quady;

    uart_rx.ticks_per_baud = 50000000 / 9600;
    uart_tx.ticks_per_baud = 50000000 / 9600;

    pptop->rst_n = 0;
    tick(pptop, 2);
    pptop->rst_n = 1;
    tick(pptop, 2);

    auto modex = pptop->pp_top->x_dir;
    auto modey = pptop->pp_top->y_dir;
    auto dutyx = pptop->pp_top->x_duty;
    auto dutyy = pptop->pp_top->y_duty;

    char buf;
    while (!contextp->gotFinish()) {
        bool has_bool = false;
        if (uart_rx.state == UARTInjector::IDLE) {
            has_bool = read(input, &buf, 1) > 0;
            if (has_bool) { printf("injecting byte: 0x%02x\n", (uint8_t)buf); fflush(stdout); }
        }

        switch (modex) {
            case 1: quadx.tick_forward(); break;
            case 2: quadx.tick_backward(); break;
            default: break;
        }
        
        switch (modey) {
            case 1: quady.tick_forward(); break;
            case 2: quady.tick_backward(); break;
            default: break;
        }        

        // quadx.tick();
        pptop->quad_x = (quadx.A() << 1) | (quadx.B() << 0);
        pptop->quad_y = (quady.A() << 1) | (quady.B() << 0);
        pptop->uart_rx = uart_rx.tick(has_bool, (uint8_t)buf);

        uart_tx.tick(output, pptop->uart_tx);

        tick(pptop, 1);

        if (modex != pptop->pp_top->x_dir || dutyx != pptop->pp_top->x_duty) {
              printf("x: mode=%d duty=%d\n", pptop->pp_top->x_dir, pptop->pp_top->x_duty); fflush(stdout);
        }

        if (modey != pptop->pp_top->y_dir || dutyy != pptop->pp_top->y_duty) {
              printf("y: mode=%d duty=%d\n", pptop->pp_top->y_dir, pptop->pp_top->y_duty); fflush(stdout);
        }

        modex = pptop->pp_top->x_dir;
        modey = pptop->pp_top->y_dir;
        dutyx = pptop->pp_top->x_duty;
        dutyy = pptop->pp_top->y_duty;
    }

    delete pptop;
    delete contextp;

    return 0;
}
