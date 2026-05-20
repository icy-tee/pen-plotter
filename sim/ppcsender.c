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

void send_set_command_u32(int file, uint8_t loc) {
    char *tok = strtok(NULL, " ");
    uint8_t command = 2;
    uint32_t bytes = atoi(tok);
    write(file, &command, 1);
    write(file, &loc, 1);
    write(file, &bytes, 4);
}

void send_set_command_angle(int file, uint8_t loc) {
    char *tok = strtok(NULL, " ");
    uint8_t command = 2;
    float angle = atof(tok);
    angle *= 65535.0 / 180.0;
    uint32_t bytes = (uint32_t)angle;
    write(file, &command, 1);
    write(file, &loc, 1);
    write(file, &bytes, 4);
}

void send_set_command_q16_16(int file, uint8_t loc) {
    char *tok = strtok(NULL, " ");
    uint8_t command = 2;
    int32_t q = (int32_t)(atof(tok) * 65536.0);
    write(file, &command, 1);
    write(file, &loc, 1);
    write(file, &q, 4);
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
                case 3: {
                    //printf("STABLE!\n");
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
            } else if (strcmp(tok, "rst") == 0) {
                command = 1;
                write(out_fd, &command, 1);  
            } else if (strcmp(tok, "setx") == 0) {
                send_set_command_u32(out_fd, 0);
            } else if (strcmp(tok, "sety") == 0) {
                send_set_command_u32(out_fd, 1);
            } else if (strcmp(tok, "setKp") == 0) {
                send_set_command_q16_16(out_fd, 2);
            } else if (strcmp(tok, "setKd") == 0) {
                send_set_command_q16_16(out_fd, 3);
            } else if (strcmp(tok, "setRd") == 0) {
                send_set_command_u32(out_fd, 4);
            } else if (strcmp(tok, "servo") == 0) {
                send_set_command_angle(out_fd, 5);  
            } else if (strcmp(tok, "go") == 0) {
                send_set_command_u32(out_fd, 0);
                send_set_command_u32(out_fd, 1);  
            } else if (strcmp(tok, "str") == 0) {
                command = 4;
                write(out_fd, &command, 1);
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
