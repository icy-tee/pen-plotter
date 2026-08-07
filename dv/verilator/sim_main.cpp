
#include <Vtop_verilator.h>
#include <Vtop_verilator__Dpi.h>
#include <verilated.h>
#include "svdpi.h"

#include <cstdio>
#include <deque>
#include <cstring>
#include <cstdlib>
#include <fcntl.h>

#include "sim_pp_system.hpp"
#include "sim_mmio.hpp"

struct Settings {
  size_t max_cycles = 6'000'000;
  bool piped = false; // output tx to '/tmp/uart_tx', input rx from '/tmp/uart_rx'
  int rx_pipe = -1, tx_pipe = -1;
};

struct Status {
    std::deque<std::string> buf {  };
    std::deque<OBITransaction> pending_transactions {  };
    std::deque<OBITransaction> transactions {  };
    uint64_t next_transaction_sequence = 0;
    DRV8833Info x {  };
    DRV8833Info y {  };
    bool pid_irq = false;
    size_t pwm_period = 0;
    double pwm_duty = 0.0;
} status;


void print_status(const Settings &stgs, const Status &sts) {
    printf("\033[2J");
    printf("\033[H");
    printf("pwm: p%zu, d%.0f%%\n", sts.pwm_period, sts.pwm_duty);
    printf("x: fwd%.2f bwd%.2f cst%.2f brk%.2f\n", sts.x.fwd_ratio, sts.x.bwd_ratio, sts.x.cst_ratio, sts.x.brk_ratio);
    printf("y: fwd%.2f bwd%.2f cst%.2f brk%.2f\n", sts.y.fwd_ratio, sts.y.bwd_ratio, sts.y.cst_ratio, sts.y.brk_ratio);
    printf("pid irq: %s\n", sts.pid_irq ? "on" : "off");

    if (!stgs.piped) {
        printf("uart:\n");
        for (std::string const &line : sts.buf) {
            printf("%s\n", line.c_str());
        }
    }

    printf("obi:\n");
    for (const OBITransaction &tr : sts.transactions) {
        printf(
            "#%llu %s @ 0x%08X: ",
            static_cast<unsigned long long>(tr.sequence),
            to_string(classify_address(tr.addr)),
            tr.addr
        );
        if (tr.we) printf("write 0x%.8X (0x%.1X)", tr.wdata, tr.be);
        else printf("read 0x%.8X (0x%.1X)", tr.rdata, tr.be);
        printf("\n");
    }
}

void host_gnt_received(const svBitVecVal *addr, const svBitVecVal *wdata, svBit we, const svBitVecVal *be) {
    status.pending_transactions.push_back({
        status.next_transaction_sequence++,
        addr[0],
        wdata[0],
        we != 0,
        static_cast<uint8_t>(be[0] & 0xF),
        0,
        false,
    });
}

void host_rvalid_received(const svBitVecVal *rdata, svBit err) {
    if (status.pending_transactions.empty()) {
        std::fprintf(stderr, "Received an OBI response without a pending request\n");
        std::abort();
    }

    OBITransaction completed = status.pending_transactions.front();
    status.pending_transactions.pop_front();
    completed.rdata = rdata[0];
    completed.err = err != 0;

    status.transactions.push_back(completed);
    if (status.transactions.size() > 20)
        status.transactions.pop_front();
}

void pid_irq_received(svBit sts) {
    status.pid_irq = sts;
}

int main(int argc, const char **argv) { // usage: [name] [--cycles N]

    Settings settings;
    
    for (size_t i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--cycles", sizeof("--cycles")) == 0) {
            if (i + 1 >= argc) {
                printf("Expected argument\nusage: %s [--cycles N]\n", argv[0]);
                return 1;
            } else {
                settings.max_cycles = atoi(argv[++i]); // TODO: add error handling/sanitation
            }
        } else if (strncmp(argv[i], "--piped", sizeof("--piped")) == 0) {
            settings.piped = true;
        } else {
            printf("Unrecognized argument\nusage: %s [--cycles N]\n", argv[0]);
            return 1;
        }
    }

    if (settings.piped) {
        settings.tx_pipe = open("/tmp/uart_tx", O_RDWR | O_NONBLOCK); // so they dont block
        settings.rx_pipe = open("/tmp/uart_rx", O_RDWR | O_NONBLOCK);

        if (settings.rx_pipe == -1 || settings.tx_pipe == -1) {
            fprintf(stderr, "error: opening pipes failed {rx_pipe=%d,tx_pipe=%d}\n", settings.rx_pipe, settings.tx_pipe);
            exit(-1);
        }
    }

    VerilatedContext context;
    context.commandArgs(argc, argv);

    PPSystem system(&context);
    std::string uart_tmp;

    system.set_servo_decode_cb([&](PWMInfo info) {
        switch (info.kind) {
            case PWMKind::PERIODIC:
                status.pwm_period = info.period;
                status.pwm_duty = info.duty * 100;
                break;
            case PWMKind::STABLE:
                status.pwm_period = 0;
                status.pwm_duty = info.duty * 100;
                break;
            case PWMKind::INVALID:
                break;
        }
    });

    system.set_drv8833_ch_decode_cb(0, [&](DRV8833Info info) {
        status.x = info;
    });
    
    system.set_drv8833_ch_decode_cb(1, [&](DRV8833Info info) {
        status.y = info;
    });

    system.set_uart_decode_cb([&](uint8_t output) {

        if (!settings.piped) {
            if (output == '\n') {
                status.buf.push_back(uart_tmp);
                uart_tmp.clear();

                if (status.buf.size() > 32) {
                    status.buf.pop_front();
                }
            } else if (output != '\r') {
                uart_tmp.push_back(output);
            }
        } else {
            (void)write(settings.tx_pipe, &output, 1);
        }
    });

    system.reset();

    char buf = 0;
    for (size_t cycles = 0; cycles < settings.max_cycles; cycles++) {
        if (settings.piped && read(settings.rx_pipe, &buf, 1) > 0) {
            system.uart_enqueue(buf);
        }
        
        system.tick();

        if (cycles % 10'000 == 0) {
            print_status(settings, status);
        }
    }

    return 0;
}
