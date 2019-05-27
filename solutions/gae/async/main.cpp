#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <cstring>
#include <fcntl.h>

int main(int argc, char **argv) {
    if (argc != 3) {
        printf("usage: ./program in_pipe out_pipe");
        return 0;
    }
    printf("in: %s,\n out: %s\n", argv[1], argv[2]);
    fflush(stdout);

    int fin_fd = open(argv[1], O_RDWR);
    printf("opens r success\n");
    int fout_fd = open(argv[2], O_RDWR);
    printf("opens w success\n");
    int stdin_fd = 0;
    int max_fd = 0;
    if (fin_fd > max_fd) {
        max_fd = fin_fd;
    }
    if (fout_fd > max_fd) {
        max_fd = fout_fd;
    }
    max_fd++;
    fd_set in_fds;
    fd_set out_fds;
    struct timeval tv;
    int retval;

    /* Watch stdin (fd 0) to see when it has input. */

    FD_ZERO(&in_fds);
    FD_ZERO(&out_fds);
    FD_SET(fin_fd, &in_fds);
    FD_SET(stdin_fd, &in_fds);
    FD_SET(fout_fd, &out_fds);

    /* Wait up to five seconds. */

    tv.tv_sec = 2;
    tv.tv_usec = 0;

    const int MAXIMUM_MESSAGES = 20;
    char sendQueue[MAXIMUM_MESSAGES][4096];
    char buf[4096];
    int startQueue = 0;
    int endQueue = 0;

    printf("start loop\n");
    fflush(stdout);
    for (;;) {

        FD_CLR(fin_fd, &in_fds);
        FD_CLR(stdin_fd, &in_fds);
        FD_CLR(fout_fd, &out_fds);
        FD_SET(fin_fd, &in_fds);
        FD_SET(stdin_fd, &in_fds);
        FD_SET(fout_fd, &out_fds);
        retval = select(max_fd, &in_fds, &out_fds, NULL, &tv);
        fflush(stdout);
        /* Don't rely on the value of tv now! */

        if (retval == -1) {
            perror("retval == -1");
        } else if (retval) {
            if (FD_ISSET(fin_fd, &in_fds)) {
                printf("start reading from pipe\n");
                read(fin_fd, buf, 4096);
                printf("message: %s\n", buf);
            }
            if (FD_ISSET(stdin_fd, &in_fds)) {
                read(stdin_fd, buf, 4096);
                strcpy(sendQueue[endQueue], buf);
                endQueue++;
                endQueue %= MAXIMUM_MESSAGES;
                printf("added in queue: %s", buf);
            }
            if (FD_ISSET(fout_fd, &out_fds)) {
                while (startQueue != endQueue) {
                    printf("start send: %s", sendQueue[startQueue]);
                    write(fout_fd, sendQueue[startQueue], strlen(sendQueue[startQueue]));
                    printf("sent: %s", sendQueue[startQueue]);
                    startQueue++;
                    startQueue %= MAXIMUM_MESSAGES;

                }
            }
        }
        fflush(stdout);
        sleep(1);
    }
    exit(EXIT_SUCCESS);
}
