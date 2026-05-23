
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/prctl.h>

#define SP_X 0
#define SP_Y 1
#define KP 2
#define KD 3
#define RD 4
#define ANGLE 5

#define START_X (744*(4))
#define START_Y (744*(-2))

// RECT SETTINGS
#define SMALL_LENGTH (744*0.25)
#define BIG_LENGTH (744*4*0.25)
#define POINTS 12

// CIRCLE SETTINGS
#define SAMPLES 32
#define RADIUS 1 * 744 // inch * TPI

// SERVO SETTINGS
#define SERVO_DOWN 150
#define SERVO_UP 90

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
    uint8_t command = 2;
    int32_t q = (int32_t)(val * 65536.0);
    write(file, &command, 1);
    write(file, &loc, 1);
    write(file, &q, 4);
}


struct { int32_t x; int32_t y; bool down; } positions[POINTS] = {
    [0] = {START_X, START_Y, true},
    [1] = {START_X + BIG_LENGTH, START_Y, true},
    [2] = {START_X + BIG_LENGTH, START_Y + BIG_LENGTH, true},
    [3] = {START_X, START_Y + BIG_LENGTH, true},
    [4] = {START_X, START_Y, false},
    [5] = {START_X + SMALL_LENGTH, START_Y, true},
    [6] = {START_X, START_Y + SMALL_LENGTH, false},
    [7] = {START_X + (SMALL_LENGTH * 2), START_Y, true},
    [8] = {START_X, START_Y + (SMALL_LENGTH * 2), false},
    [9] = {START_X + (SMALL_LENGTH * 3), START_Y, true},
    [10] = {START_X, START_Y + (SMALL_LENGTH * 3), false},
    [11] = {0, 0, false},
};


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

    size_t index = 0;
    bool started = false;
    bool center = true;

    send_set_command_q16_16(out_fd, KP, 0.5);
    send_set_command_q16_16(out_fd, KD, 0.5);
    send_set_command_q16_16(out_fd, RD, 10);

    sleep(1);
    
    send_set_command_u32(out_fd, SP_X, START_X);
    send_set_command_u32(out_fd, SP_Y, START_Y);

    bool running = true;
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
               
                #if DOTTED
                send_set_command_angle(out_fd, ANGLE, index % 2 == 0 ? SERVO_DOWN : SERVO_UP);
                #elif RECTANGLE
                send_set_command_angle(out_fd, ANGLE, positions[index].down ? SERVO_DOWN : SERVO_UP);
                #else
                send_set_command_angle(out_fd, ANGLE, index > 0 ? SERVO_DOWN : SERVO_UP);
                #endif
                
                index++;

                #if defined(RECTANGLE)
                send_set_command_u32(out_fd, SP_X, positions[index].x);
                send_set_command_u32(out_fd, SP_Y, positions[index].y);
                usleep(100000);
                #elif defined(CIRCLE)

                #ifdef CENTER_EVERY_OTHER
                center = !center;
                if (center) {
                    send_set_command_u32(out_fd, SP_X, START_X);
                    send_set_command_u32(out_fd, SP_Y, START_Y);
                } else {
                    send_set_command_u32(out_fd, SP_X, START_X + RADIUS * cosf((float)index/SAMPLES * 6.28f));
                    send_set_command_u32(out_fd, SP_Y, START_Y + RADIUS * sinf((float)index/SAMPLES * 6.28f));
                }
                #else 
                send_set_command_u32(out_fd, SP_X, START_X + RADIUS * cosf((float)(index-1)/SAMPLES * 6.28f));
                send_set_command_u32(out_fd, SP_Y, START_Y + RADIUS * sinf((float)(index-1)/SAMPLES * 6.28f));
                #endif
                #endif

                break;        
            }
        }
        #if defined(CIRCLE)
        if (index == SAMPLES + 2) break;
        #elif defined(RECTANGLE)
        if (index == POINTS - 1) break;
        #endif 
    }
    
    send_set_command_angle(out_fd, ANGLE, SERVO_UP);
    sleep(1);
    send_set_command_u32(out_fd, SP_X, 0);
    send_set_command_u32(out_fd, SP_Y, 0);
            
    if (out_fd == in_fd) {
        close(out_fd);
    } else {
        close(in_fd);
        close(out_fd);
    }
}
