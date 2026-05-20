
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <termios.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/prctl.h>

void read_exact(int fd, size_t n, void *buf) {
    for (int i = 0; i < n; i++) {
        read(fd, buf + i, 1);
    }
}

void send_set_command_u32(int file, uint8_t loc, uint32_t val) {
    uint8_t command = 2;
    write(file, &command, 1);
    write(file, &loc, 1);
    write(file, &val, 4);
}

void send_set_command_angle(int file, uint8_t loc, float angle) {
    uint8_t command = 2;
    angle *= 65535.0 / 180.0;
    uint32_t bytes = (uint32_t)angle;
    write(file, &command, 1);
    write(file, &loc, 1);
    write(file, &bytes, 4);
}

void send_set_command_q16_16(int file, uint8_t loc, float val) {
    char *tok = strtok(NULL, " ");
    uint8_t command = 2;
    int32_t q = (int32_t)(val * 65536.0);
    write(file, &command, 1);
    write(file, &loc, 1);
    write(file, &q, 4);
}

int main(int argc, char **argv) {
    if (argc == 1) {
        printf("usage: ./rect (sim [out] [in] | act [port])\n");
        return 0;
    }

    int out_fd = -1, in_fd = -1;
    
    const char* mode = argv[1];
    if (strcmp(mode, "sim") == 0 && argc >= 2) {
        const char *out = (argc > 2) ? argv[2] : "uart_rx";
        const char *in = (argc > 3) ? argv[3] : "uart_tx";

        out_fd = open(out, O_WRONLY);
        in_fd = open(in, O_RDONLY);
    } else if (strcmp(mode, "act") == 0 && argc >= 2) {
        const char *port = (argc > 2) ? argv[2] : "/dev/ttyUSB0";

        out_fd = in_fd = open(port, O_RDWR | O_NOCTTY | O_NONBLOCK);

        if (out_fd < 0) { perror("open"); return 1; }

        struct termios tty = {};
        tcgetattr(out_fd, &tty);
        cfmakeraw(&tty);
        cfsetospeed(&tty, B9600);
        cfsetispeed(&tty, B9600);
        tty.c_cflag |= CS8 | CLOCAL;
        tty.c_cflag &= ~CRTSCTS;
        tcsetattr(out_fd, TCSANOW, &tty);
        fcntl(out_fd, F_SETFL, fcntl(out_fd, F_GETFL) & ~O_NONBLOCK);
    } else {
        printf("usage: ./sender (sim [out] [in] | act [port])\n");
        return 0;
    }

    int stability_pipe[2];
    if (pipe(stability_pipe) == -1) {
        goto end;
    }

    #define START_X (744*4)
    #define START_Y (744*0)
    #define LENGTH 744

    struct { int32_t x; int32_t y; } positions[6] = {
      [0] = {START_X, START_Y},
      [1] = {START_X + LENGTH, START_Y},
      [2] = {START_X + LENGTH, START_Y + LENGTH},
      [3] = {START_X, START_Y + LENGTH},
      [4] = {START_X, START_Y},
      [5] = {0, 0},
    };
    size_t index = 0;
    bool started = false;

    int proc = fork();
    bool running = true;
    if (proc == 0) {
        prctl(PR_SET_PDEATHSIG, SIGKILL);
        while (running) {
            uint8_t packet_type;
            read_exact(in_fd, 1, &packet_type);

            switch (packet_type) {
                case 0: {
                    uint8_t version;
                    read_exact(in_fd, 1, &version);
                    break;
                }
                case 1:
                case 2: {
                    int32_t ticks;
                    read_exact(in_fd, 4, &ticks);
                    break;
                }
                case 3: {
                    printf("STABLE!\n");
                    uint8_t one = 1;
                    write(stability_pipe[1], &one, 1);
                    break;        
                }
            }
        }
    } else {
        while (running) {
            if (index > 6) {
                send_set_command_angle(out_fd, 5, 0);
                break;
            }

            if (!started) {
                send_set_command_angle(out_fd, 5, 90);
                sleep(1);
                send_set_command_u32(out_fd, 0, positions[index].x);
                send_set_command_u32(out_fd, 1, positions[index].y);
                index++;
                started = true;
            } else {
                uint8_t msg = 0;
                read(stability_pipe[0], &msg, 1);
                if (msg == 1) {
                    send_set_command_u32(out_fd, 0, positions[index].x);
                    send_set_command_u32(out_fd, 1, positions[index].y);
                    index++;
                }
            }
        }
    }

    end:

    if (out_fd == in_fd) {
        close(out_fd);
    } else {
        close(in_fd);
        close(out_fd);
    }
}
