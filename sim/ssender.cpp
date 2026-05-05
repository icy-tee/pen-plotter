
#include <string>
#include <iostream>
#include <sstream>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <cstdint>
#include <cstdio>
#include <sys/select.h>


static bool read_exact(int fd, void *buf, size_t n) {
    uint8_t *p = (uint8_t *)buf;
    size_t got = 0;
    while (got < n) {
        ssize_t r = read(fd, p + got, n - got);
        if (r <= 0) return false;
        got += r;
    }
    return true;
}

int main(int argc, char **argv) {

    const char *port = (argc > 1) ? argv[1] : "/dev/ttyUSB0";

    int back = open("uart_tx", O_RDONLY);
    int output = open(port, O_WRONLY | O_NOCTTY);
    if (output < 0) {
        perror("open");
        return 1;
    }

    if (isatty(output)) {
        struct termios tty = {};
        tcgetattr(output, &tty);
        cfmakeraw(&tty);
        cfsetospeed(&tty, B9600);
        tty.c_cflag |= CS8 | CLOCAL;
        tty.c_cflag &= ~CRTSCTS;
        tcsetattr(output, TCSANOW, &tty);
    }

    bool running = true;
    while (running) {
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(0, &fds);
        FD_SET(back, &fds);

        select(back + 1, &fds, NULL, NULL, NULL);

        if (FD_ISSET(back, &fds)) {
            char chr; int pos;
            if (read(back, &chr, 1) > 0) {
                switch (chr) {
                    case 0:
                        if (read_exact(back, &chr, 1))
                            printf("STATUS OK: VERS %d\n", chr);
                        break;
                    case 1:
                        if (read_exact(back, &pos, 4))
                            printf("X ticks: %d\n", pos);
                        break;
                    case 2:
                        if (read_exact(back, &pos, 4))
                            printf("Y ticks: %d\n", pos);
                        break;
                }
                fflush(stdout);
            }
        }

        if (FD_ISSET(0, &fds)) {
            std::string line;
            if (!std::getline(std::cin, line)) { running = false; break; }
            std::stringstream linestream(line);

            std::string token;
            std::getline(linestream, token, ' ');
            if (token == "quit") running = false;
            else if (token == "sts") {
                uint8_t command = 0;
                write(output, &command, 1);
            }
            else if (token == "rst") {
                uint8_t command = 1;
                write(output, &command, 1);
            }
            else if (token == "fx") {
                std::getline(linestream, token, ' ');
                uint8_t command[2] = {2, (uint8_t)std::stoi(token)};
                write(output, command, 2);
            }
            else if (token == "rx") {
                std::getline(linestream, token, ' ');
                uint8_t command[2] = {3, (uint8_t)std::stoi(token)};
                write(output, command, 2);
            }
            else if (token == "bx") {
                uint8_t command = 4;
                write(output, &command, 1);
            }
            else if (token == "cx") {
                uint8_t command = 5;
                write(output, &command, 1);
            }
            else if (token == "fy") {
                std::getline(linestream, token, ' ');
                uint8_t command[2] = {6, (uint8_t)std::stoi(token)};
                write(output, command, 2);
            }
            else if (token == "ry") {
                std::getline(linestream, token, ' ');
                uint8_t command[2] = {7, (uint8_t)std::stoi(token)};
                write(output, command, 2);
            }
            else if (token == "by") {
                uint8_t command = 8;
                write(output, &command, 1);
            }
            else if (token == "cy") {
                uint8_t command = 9;
                write(output, &command, 1);
            }
        }
    }

    close(output);
    close(back);
    return 0;
}
