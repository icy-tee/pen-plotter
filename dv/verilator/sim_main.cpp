
#include <Vtop_verilator.h>

#include <verilated.h>
#include <cstdio>
#include <cstdint>
#include <cstring>

#include "sim_drv8833.hpp"
#include "sim_pp_system.hpp"
#include "sim_pwm.hpp"

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
    
    VerilatedContext context;
    context.commandArgs(argc, argv);

    PPSystem system(&context);

    system.set_servo_decode_cb([](PWMInfo info) {
        switch (info.kind) {
            case PWMKind::PERIODIC:
                printf("{period:%zu, on:%zu, duty:%f}\n", info.period, info.on_duration, info.duty);
                break;
            case PWMKind::ON:
                puts("{duty:100%}");
                break;
            case PWMKind::OFF:
                puts("{duty:0%}");
                break;
            case PWMKind::INVALID:
                puts("{invalid}");
                break;
        }
        fflush(stdout);
    });

    system.set_drv8833_ch_decode_cb(0, [](DRV8833Info info) {
        printf("{fwd: %f, bwd: %f, cst: %f, brk: %f}\n", info.fwd_ratio, info.bwd_ratio, info.cst_ratio, info.brk_ratio);                             
    });
    
    system.set_drv8833_ch_decode_cb(1, [](DRV8833Info info) {
        // printf("{fwd: %f, bwd: %f, cst: %f, brk: %f}\n", info.fwd_ratio, info.bwd_ratio, info.cst_ratio, info.brk_ratio);                             
    });

    system.set_uart_decode_cb([](uint8_t output) {
        printf("%c", output);
        fflush(stdout);
    });

    system.reset();

    for (size_t cycles = 0; cycles < max_cycles; cycles++) {
        system.tick();
    }

    return 0;
}
