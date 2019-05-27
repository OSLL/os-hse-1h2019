#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>

void read_data(int fifo_in, char *buf, int buf_size) {
    int rc = read(fifo_in, buf, buf_size);
    printf("Got message: %s\n", buf);
}

void write_data(int fifo_out, char *data) {
    int rc = write(fifo_out, data, strlen(data));
}

#define STDIN 0

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Argumets: <in fifo> <out fifo> <buffer length>");
        return 0;
    }
    char *pipe_in_name = argv[1];
    int fd_in = open(pipe_in_name, O_RDWR);
    char *pipe_out_name = argv[2];
    int fd_out = open(pipe_out_name, O_RDWR);
    int bytes_n = atoi(argv[3]);
    while (1) {
        fd_set readfds;
        fd_set writefds;
        FD_ZERO(&readfds);
        FD_ZERO(&writefds);
        FD_SET(STDIN, &readfds);
        FD_SET(fd_in, &readfds);
        FD_SET(fd_out, &writefds);
        select(fd_in + 1, &readfds, NULL, NULL, NULL);
        if (FD_ISSET(STDIN, &readfds)) {
            char buf[bytes_n];
            scanf("%s", buf);
            select(fd_out + 1, NULL, &writefds, NULL, NULL);
            write_data(fd_out, buf);
        }
        if (FD_ISSET(fd_in, &readfds)) {
            char buf[bytes_n];
            read_data(fd_in, buf, 100);
        }
    }
}