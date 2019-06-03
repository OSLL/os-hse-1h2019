#include<stdio.h>
#include<sys/epoll.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>  

const int EVENTS_SIZE = 3;
const int BUF_SIZE = 1024;

int main(int argc, char* argv[]) {
    if (argc < 3) {
        printf("require 2 arguments\n");
        return -1;
    }  

    int pipe_w = open(argv[2], O_RDWR);
    if (pipe_w == -1) {
        printf("write pipe open err\n");
        return -1;
    }    

    int pipe_r = open(argv[1], O_RDWR);
    if (pipe_r == -1) {
        printf("read pipe open err\n");
        return -1;
    }    

    // printf("pipe opend\n");
    int efd = epoll_create(EVENTS_SIZE);

    struct epoll_event read_pipe_ev = {0};
    struct epoll_event write_pipe_ev = {0};
    struct epoll_event read_user = {0};

    read_pipe_ev.events = EPOLLIN;
    read_pipe_ev.data.fd = pipe_r;

    write_pipe_ev.events = EPOLLOUT;
    write_pipe_ev.data.fd = pipe_w;

    read_user.events = EPOLLIN;
    read_user.data.fd = STDIN_FILENO;

    // printf("base init done\n");

    if (epoll_ctl( efd, EPOLL_CTL_ADD, pipe_r, &read_pipe_ev ) != 0 ) {
        printf("read pipe err\n");
        return -1;
    }

    if (epoll_ctl( efd, EPOLL_CTL_ADD, pipe_w, &write_pipe_ev ) != 0 ) {
        printf("write pipe err\n");
        return -1;
    }

    if (epoll_ctl( efd, EPOLL_CTL_ADD, STDIN_FILENO, &read_user) != 0 ) {
        printf("stdin fd err\n");
        return -1;
    }

    struct epoll_event events[EVENTS_SIZE];
    int data_len = 0;

    // printf("init done\n");
    char buf[BUF_SIZE];

    while(1) {
        int ready = epoll_wait(efd, events, EVENTS_SIZE, -1);
        for (int i = 0; i < ready; ++i) {
            int fd = events[i].data.fd;
            if (fd == STDIN_FILENO) {
                data_len = read(fd, buf, BUF_SIZE);
                // printf("%d %s\n", data_len, buf);
            }

            if (fd == pipe_r) {
                read(fd, buf, BUF_SIZE);
                printf("%s", buf);
            }

            if (fd == pipe_w && data_len > 0) {
                write(fd, buf, data_len);
                data_len = 0;
            }
        }
    }
}