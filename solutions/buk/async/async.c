#include "stdio.h"
#include "unistd.h"
#include "fcntl.h"
#include "stdlib.h"
#include "string.h"
#include "sys/epoll.h"


int main(int argc, char** args) {
    printf("test\n");
    char* in = args[1];
    char* out = args[2];
    printf("%s\n", in);
    printf("%s\n", out);
    int fdout = open(out, O_RDWR);
    printf("%d\n", fdout);
    int fdin = open(in, O_RDWR);
    printf("%d\n", fdin);

    int efd = epoll_create1(0);
    if (efd == -1) {
        perror("epoll_create1");
        exit(-1);
    }
    struct epoll_event evin;
    evin.events = EPOLLIN;
    evin.data.fd = fdin;
    if(epoll_ctl(efd, EPOLL_CTL_ADD, fdin, &evin) == -1) {
        perror("epoll_ctl in");
        exit(-1);
    }
    printf("evin\n");
    struct epoll_event evout;
    evout.events = EPOLLOUT | EPOLLET;
    evout.data.fd = fdout;
    if(epoll_ctl(efd, EPOLL_CTL_ADD, fdout, &evout) == -1) {
        perror("epoll_ctl out");
        exit(-1);
    }
    printf("evout\n");
    struct epoll_event evstdin;
    evstdin.events = EPOLLIN | EPOLLET;
    evstdin.data.fd = fileno(stdin);
    if(epoll_ctl(efd, EPOLL_CTL_ADD, fileno(stdin), &evstdin) == -1) {
        perror("epoll_ctl stdin");
        exit(-1);
    }
    printf("evstdin\n");
    

    struct epoll_event event;
    const size_t bufsize = 100000;
    char readbuf[bufsize];
    char writebuf[bufsize];
    size_t writebeg = 0;
    size_t writeend = 0;
    size_t readbeg = 0;
    int readend = 0;
    for(;;) {
        printf("wait\n");
        int cnt = epoll_wait(efd, &event, 1, -1);
        printf("get\n");

        if(cnt == -1) {
            perror("epoll_wait");
            exit(-1);
        }
        if(event.data.fd == fdin) {
            printf("fdin\n");
            size_t readc = read(event.data.fd, readbuf, bufsize);
            write(fileno(stdout), readbuf, readc);
        }
        else if(event.data.fd == fdout) {
            printf("fdout\n");
            size_t writec = write(event.data.fd, writebuf, writeend);
            printf("%ld\n", writec);
            writeend = 0;
        } 
        else if(event.data.fd == fileno(stdin)) {
            printf("stdin\n");
            size_t readc = read(event.data.fd, &writebuf, bufsize);
            //printf("%ld\n", read);
            //printf("%s", writebuf);
            writeend = readc;
        }
    }
}

