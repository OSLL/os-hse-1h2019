#include <stdio.h>
#include <unistd.h>
#include <sys/epoll.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define BUFFER_SIZE 1024
#define true 1

int main(int argc, char* argv[]) {
    if (argc != 3) {
        fprintf(stderr, "wrong number of arguments\n");
        return 1;
    }
    
    int out_pipe_fd = open(argv[1], O_RDWR); 
    if (out_pipe_fd < 0) {
        fprintf(stderr, "could not open out pipe\n");
    }
    
    int in_pipe_fd = open(argv[2], O_RDWR);
    if (in_pipe_fd < 0) {
        fprintf(stderr, "could not open in pipe\n");
    }

    int epoll_fd = epoll_create1(0); 
    if(epoll_fd == -1) {
        fprintf(stderr, "Could not create epoll descriptor\n");
        return 1;
    }
 
    struct epoll_event event_console;
    event_console.events = EPOLLIN;
    event_console.data.fd = STDIN_FILENO;

    struct epoll_event event_pipe;
    event_pipe.events = EPOLLIN;
    event_pipe.data.fd = in_pipe_fd;

    if(epoll_ctl(epoll_fd, EPOLL_CTL_ADD, STDIN_FILENO, &event_console)) {
        fprintf(stderr, "Could not add file stdin file descriptor to epoll\n");
        close(epoll_fd);
        return 1;
    }

    if(epoll_ctl(epoll_fd, EPOLL_CTL_ADD, in_pipe_fd, &event_pipe)) {
        fprintf(stderr, "Could not add input pipe descriptor to epoll\n");
        close(epoll_fd);
        return 1;
    }

    size_t bytes_read;
    char buffer[BUFFER_SIZE];
    struct epoll_event events[2];

    while(true) {
        int event_num = epoll_wait(epoll_fd, events, 2, -1);
        for(int i = 0; i < event_num; i++) {
            bytes_read = read(events[i].data.fd, buffer, BUFFER_SIZE);
            if (events[i].data.fd == STDIN_FILENO) {
                write(out_pipe_fd, buffer, bytes_read);
            } else {
                write(STDOUT_FILENO, buffer, bytes_read);
            }
        }
    }
 
    if(close(epoll_fd)) {
      fprintf(stderr, "Could not close epoll properly\n");
      return 1;
    }
    return 0;
}
