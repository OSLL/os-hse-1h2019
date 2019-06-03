#include <sys/epoll.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

int main(int argc, char **argv) {
    char *fin = argv[1];
    char *fout = argv[2];

    int fdin = open(fin, O_RDWR);
    int fdout = open(fout, O_RDWR);
    int fdstdin = 0;
    printf("%d %d\n", fdin, fdout); 

    int epoll_fd = epoll_create(1);
    if (epoll_fd == -1) {
        puts("Wtf1");
    }
    struct epoll_event ev_stdin, ev_fin, ev_fout, events[10];

    ev_stdin.events = EPOLLIN;
    ev_stdin.data.fd = fdstdin;
    if(epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fdstdin, &ev_stdin) == -1) 
        puts("WTF2");

    ev_fin.events = EPOLLIN;
    ev_fin.data.fd = fdin;
    if(epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fdin, &ev_fin) == -1)
        puts("WTF3");

    ev_fout.events = EPOLLOUT;
    ev_fout.data.fd = fdout;
    if(epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fdout, &ev_fout) == -1)
        puts("WTF4");

    while(1) {
        int nfds = epoll_wait(epoll_fd, events, 10, -1);
        for (int i = 0; i < nfds; i++) {
            if (events[i].data.fd == fdstdin) {
                //puts("stdin");
                char buf[4096];
                int res = read(fdstdin, buf, 4096);
                write(fdout, buf, res);
            }
            if(events[i].data.fd == fdin) {
                char buf[4096];
                //puts("fin");
                int res = read(fdin, buf, 4096);
                write(fdout, buf, res);
            }
            /*if(events[i].data.fd == fdout) {
                char buf[4096];
                puts("fout");
            }*/

        }
    } 
}