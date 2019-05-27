#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

#define BUFFSZ 1000

int main(int args, char** argv) {
    if (args < 3)
        printf("Not enough parameters!\n");

    int fd_in;
    char buff_in[BUFFSZ];
    int fd_out;
    char buff_out[BUFFSZ];
    int pos_out = 0;

    fd_in = open(argv[1], O_RDWR);
    fd_out = open(argv[2], O_RDWR);
    if (fd_in == -1 || fd_out == -1) {
        fprintf(stderr, "Cant'open fifo!\n");
        return 0;
    }

    fd_set in;
    fd_set out;
    struct timeval time;
    time.tv_sec = 10;
    time.tv_usec = 500000;

    while (1) {
        FD_ZERO(&in);
        FD_SET(0, &in);
        FD_ZERO(&out);
        FD_SET(fd_out, &out);
        FD_SET(fd_in, &in);
        select(50, &in, NULL, NULL, &time);

        if (FD_ISSET(0, &in)) {
            pos_out += read(0, buff_out + pos_out, BUFFSZ - pos_out);
            buff_out[pos_out] = '\0';
        }

        write(fd_out, buff_out, pos_out);
        pos_out = 0;

        if (FD_ISSET(fd_in, &in)) {
            int sz = read(fd_in, buff_in, BUFFSZ);
            write(1, "Message: ", 9);
            write(1, buff_in, sz);
        }
    }

    return 0;
}
