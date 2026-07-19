
#include <Vtop_verilator.h>

#include <verilated.h>
#include <stdio.h>
#include <fcntl.h>

#include "sim_quad.hpp"
#include "sim_uart.hpp"


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
    UARTInjector uart_rx;
    QuadInjector quadx;
    QuadInjector quady;

    uart_rx.ticks_per_baud = 50000000 / 9600;
    uart_tx.ticks_per_baud = 50000000 / 9600;

    pptop->clk = 0;
    pptop->rst_n = 1;
    pptop->eval();
    pptop->rst_n = 0;
    pptop->eval();
    tick(pptop, 2);
    pptop->rst_n = 1;
    tick(pptop, 2);

    char buf;
    while (!contextp->gotFinish()) {
        bool has_bool = false;
        if (uart_rx.state == UARTState::START) {
            // has_bool = true;
            if (has_bool) { printf("injecting byte: 0x%02x\n", (uint8_t)'A'); fflush(stdout); }
        }

        uint8_t output;
        if (uart_tx.tick(pptop->uart_tx, output)) {
            printf("%c", output);
            fflush(stdout);
        }
        // pptop->uart_rx = uart_rx.tick(has_bool, 'A');

        quadx.tick_forward(2000);
        pptop->quad_x = (quadx.A() << 1) | (quadx.B() << 0);

        
        tick(pptop, 1);
    }

    delete pptop;
    delete contextp;

    return 0;
}
