#include <sys/epoll.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>

#define MAX_EVENTS 10
#define BUFFER_SIZE 1024

int main(int argc, char *argv[]) {
    if (argc != 3) {
        return 1;
    }

    int out_fd = open(argv[2], O_RDWR);
    int in_fd = open(argv[1], O_RDWR);
    int epoll_fd = epoll_create1(0);
    if (out_fd == -1 || in_fd == -1 || epoll_fd == -1) {
        return 1;
    }

    struct epoll_event in_event, stdin_event;

    in_event.events = EPOLLIN;
    in_event.data.fd = in_fd;

    stdin_event.events = EPOLLIN;
    stdin_event.data.fd = STDIN_FILENO;

    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, in_fd, &in_event);
    epoll_ctl(epoll_fd, EPOLL_CTL_ADD, STDIN_FILENO, &stdin_event);

    int event_count;
    size_t bytes_read;
    char buffer[BUFFER_SIZE];
    struct epoll_event events[MAX_EVENTS];

    while (1) {
        event_count = epoll_wait(epoll_fd, events, MAX_EVENTS, -1);
        for (int i = 0; i < event_count; i++) {
            bytes_read = read(events[i].data.fd, buffer, BUFFER_SIZE);

            if (events[i].data.fd == STDIN_FILENO) {
                write(out_fd, buffer, bytes_read);
            } else {
                write(STDOUT_FILENO, buffer, bytes_read);
            }
        }
    }

    close(epoll_fd);
    return 0;
}
