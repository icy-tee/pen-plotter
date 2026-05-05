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

int main(int argc, char **argv) {
    if (argc == 1) {
        printf("usage: ./sender (sim [out] [in] | act [port])\n");
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
                    printf("STATUS: OK... VERS %d\n", version);    
                    break;
                }
                case 1: {
                    int32_t ticks;
                    read_exact(in_fd, 4, &ticks);
                    printf("X TICKS: %d %X\n", ticks, ticks);
                    break;
                }
                case 2: {
                    int32_t ticks;
                    read_exact(in_fd, 4, &ticks);
                    printf("Y TICKS: %d %X\n", ticks, ticks);
                    break;
                }
            }
        }
    } else {
        while (running) {
            char buffer[128];
            fgets(buffer, sizeof(buffer), stdin);

            char *tok = strtok(buffer, " \n");
            uint8_t command = 0;
            uint8_t duty = 0;
            if (strcmp(tok, "quit") == 0) {
                running = false;
            } else if (strcmp(tok, "sts") == 0) {
                command = 0;
                write(out_fd, &command , 1);
            } else if (strcmp(tok, "fx") == 0) {
                command = 2;
                char *tok = strtok(NULL, " ");
                duty = atoi(tok);
                write(out_fd, &command, 1);
                write(out_fd, &duty, 1);
            } else if (strcmp(tok, "rx") == 0) {
                command = 3;
                char *tok = strtok(NULL, " ");
                duty = atoi(tok);
                write(out_fd, &command, 1);
                write(out_fd, &duty, 1);
            } else if (strcmp(tok, "bx") == 0) {
                command = 4;
                write(out_fd, &command , 1);
            } else if (strcmp(tok, "cx") == 0) {
                command = 5;
                write(out_fd, &command , 1);
            } else if (strcmp(tok, "fy") == 0) {
                command = 6;
                char *tok = strtok(NULL, " ");
                duty = atoi(tok);
                write(out_fd, &command, 1);
                write(out_fd, &duty, 1);
            } else if (strcmp(tok, "ry") == 0) {
                command = 7;
                char *tok = strtok(NULL, " ");
                duty = atoi(tok);
                write(out_fd, &command, 1);
                write(out_fd, &duty, 1);
            } else if (strcmp(tok, "by") == 0) {
                command = 8;
                write(out_fd, &command , 1);
            } else if (strcmp(tok, "cy") == 0) {
                command = 9;
                write(out_fd, &command , 1);
            }
        }
    }

    if (out_fd == in_fd) {
        close(out_fd);
    } else {
        close(in_fd);
        close(out_fd);
    }
}
