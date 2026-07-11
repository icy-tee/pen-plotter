
#include <Vtop_verilator.h>

#include <verilated.h>
#include <stdio.h>
#include <fcntl.h>

struct QuadInjector {
    enum STATE { AB_ZERO, AB, BA, AB_ONE} state = AB_ZERO;
    int ticks = 0, ticks_for_next = 0;

    void tick_forward(int ticks_for_next ) {
        if (++ticks >= ticks_for_next) {
            ticks = 0;

            switch (state) {
                case AB_ZERO: state = AB; break;
                case AB: state = AB_ONE; break;
                case AB_ONE: state = BA; break;
                case BA: state = AB_ZERO; break;
            }
        }
    }

    
    void tick_backward(int ticks_for_next) {
        if (++ticks >= ticks_for_next) {
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

    bool tick(uint8_t tx_in, uint8_t &tx_data) {
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
                    tx_data = val;
                    state = IDLE;
                    return true;
                }
                break;
        }
        return false;
    }
};


void tick(Vtop_verilator *instance, int cycles) {
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

    Vtop_verilator *pptop = new Vtop_verilator{contextp};
    UARTDecoder uart_tx;

    uart_tx.ticks_per_baud = 50000000 / 9600;
    pptop->uart_rx = 1;

    pptop->rst_n = 0;
    tick(pptop, 2);
    pptop->rst_n = 1;
    tick(pptop, 2);

    int received = 0;
    while (!contextp->gotFinish()) {
        uint8_t output;
        if (uart_tx.tick(pptop->uart_tx, output)) {
            printf("received byte: 0x%02x '%c'\n", output, output);
            fflush(stdout);

            if (++received >= 12) {
                break;
            }
        }

        pptop->uart_rx = 1;
        tick(pptop, 1);
    }

    delete pptop;
    delete contextp;

    return 0;
}
