
#include <Vtop_verilator.h>

#include <cstdint>
#include <verilated.h>
#include <stdio.h>
#include <fcntl.h>

#include "sim_pp_system.hpp"

int main(int argc, const char **argv) { // usage: [name] [--cycles N]
    size_t max_cycles = 6000000;

    for (size_t i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--cycles", sizeof("--cycles")) == 0) {
            if (i + 1 >= argc) {
                printf("Expected argument\nusage: %s [--cycles N]\n", argv[0]);
                return 1;
            } else {
                max_cycles = atoi(argv[++i]);
            }
        } else {
            printf("Unrecognized argument\nusage: %s [--cycles N]\n", argv[0]);
            return 1;
        }
    }
    
    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);

    {
        PPSystem system(contextp);

        system.set_servo_decode_cb([](size_t period, size_t on_duration) {
            float duty = (float)(on_duration) / period;
            printf("period: %zu, on: %zu, duty: %f\n", period, on_duration, duty);
            fflush(stdout);
        });

        system.set_uart_decode_cb([](uint8_t output) {
            printf("%c", output);
            fflush(stdout);
        });

        system.reset();

        size_t cycles = 0;
        for (size_t cycles = 0; cycles < max_cycles; cycles++) {
            system.tick();
        }
    }

    delete contextp;

    return 0;
}
