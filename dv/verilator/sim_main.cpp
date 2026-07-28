
#include <Vtop_verilator.h>

#include <verilated.h>
#include <cstdio>
#include <deque>
#include <cstring>

#include "sim_drv8833.hpp"
#include "sim_pp_system.hpp"
#include "sim_pwm.hpp"

struct Status {
    std::deque<std::string> &buf;
    DRV8833Info x {  };
    DRV8833Info y {  };
    size_t pwm_period = 0;
    double pwm_duty = 0.0;
};

void print_status(const Status &sts) {
    printf("\033[2J");
    printf("\033[H");
    printf("pwm: p%zu, d%.0f%%\n", sts.pwm_period, sts.pwm_duty);
    printf("x: fwd%.2f bwd%.2f cst%.2f brk%.2f\n", sts.x.fwd_ratio, sts.x.bwd_ratio, sts.x.cst_ratio, sts.x.brk_ratio);
    printf("y: fwd%.2f bwd%.2f cst%.2f brk%.2f\n", sts.y.fwd_ratio, sts.y.bwd_ratio, sts.y.cst_ratio, sts.y.brk_ratio);
    printf("uart:\n");
    for (std::string &line : sts.buf) {
        printf("%s\n", line.c_str());
    }
}

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


    std::deque<std::string> uart_lines;
    std::string uart_tmp;

    Status sts { uart_lines };

    system.set_servo_decode_cb([&](PWMInfo info) {
        switch (info.kind) {
            case PWMKind::PERIODIC:
                sts.pwm_period = info.period;
                sts.pwm_duty = info.duty * 100;
                break;
            case PWMKind::STABLE:
                sts.pwm_period = 0;
                sts.pwm_duty = info.duty * 100;
                break;
            case PWMKind::INVALID:
                break;
        }
    });

    system.set_drv8833_ch_decode_cb(0, [&](DRV8833Info info) {
        sts.x = info;
    });
    
    system.set_drv8833_ch_decode_cb(1, [&](DRV8833Info info) {
        sts.y = info;
    });


    system.set_uart_decode_cb([&](uint8_t output) {
        if (output == '\n') {
            uart_lines.push_back(uart_tmp);
            uart_tmp.clear();

            if (uart_lines.size() > 32) {
                uart_lines.pop_front();
            }
        } else if (output != '\r') {
            uart_tmp.push_back(output);
        }
    });

    system.reset();

    for (size_t cycles = 0; cycles < max_cycles; cycles++) {
        system.tick();

        if (cycles % 10'000 == 0) {
            print_status(sts);
        }
    }

    return 0;
}
