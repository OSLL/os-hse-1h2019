#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define BUF_SIZE 64

int mode = 0; //O_NONBLOCK;

void read_package(int readfd, char buff[]) {
    read(readfd, buff, BUF_SIZE);
}

void send_package(int writefd, char buff[BUF_SIZE + 1]) {
    write(writefd, buff, BUF_SIZE);
}

void main_cycle(int readfd, int writefd) {

    struct timeval tv;
    int retval;

    fd_set rfds;
    fd_set wfds;

    char to_print_buff[BUF_SIZE + 1];
    char to_send_buff[BUF_SIZE + 1];

    int need_to_send = 0;

    while (1) {
        FD_ZERO(&rfds);
        FD_SET(readfd, &rfds);
        FD_SET(0, &rfds); // stdin
        FD_ZERO(&wfds);
        if (need_to_send) {
            FD_SET(writefd, &wfds);
        }

        retval = select(10, &rfds, &wfds, NULL, NULL);

        if (FD_ISSET(0, &rfds)) {
            // printf("Debug: reading\n");
            memset(to_send_buff, 0, sizeof(to_send_buff));
            // if (scanf("%64[^\n]s", to_send_buff)) {
            if (scanf("%64s", to_send_buff)) {
                need_to_send = 1;
            }
        }
        if (FD_ISSET(readfd, &rfds)) {
            read_package(readfd, to_print_buff);
            // printf("Debug: receiving %s\n", to_print_buff);
            printf("%s", to_print_buff);
            fflush(stdout);
        }
        if (FD_ISSET(writefd, &wfds)) {
            if (need_to_send) {
                // printf("Debug: sending %s\n", to_send_buff);
                send_package(writefd, to_send_buff);
                need_to_send = 0;
            }
        }
    }

} 

int main(int argc, char** argv) {
    if (argc != 3) {
        printf("Please provide 2 arguments - input pipe and output pipe\n");
        return -1;
    }

    char* input_pipe = argv[1];
    char* output_pipe = argv[2];
    int readfd = open(input_pipe, mode | O_RDWR | O_NONBLOCK);
    int writefd = open(output_pipe, mode | O_RDWR);
    main_cycle(readfd, writefd);
}