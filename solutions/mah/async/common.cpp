#include <bits/stdc++.h>
#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
#include<sys/types.h>
#include<string.h>
#include<sys/wait.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>


using namespace std;

const int BUFFER_SIZE = 4096;
char buffer[BUFFER_SIZE];

int main(int argc, char* argv[]) {
// #ifdef LOCAL
    // freopen("input.txt", "r", stdin);
    // freopen("output.txt", "w", stdout);
// #endif
    // ios_base::sync_with_stdio(false);

    if (argc != 3) {
        printf("fifo in and fifo out should be arguments");
    }

    int fd1 = open(argv[1], O_RDWR);
    int fd2 = open(argv[2], O_RDWR);

    while(true) {
        fd_set read_set;
        fd_set write_set;
        struct timeval tv;
        tv.tv_sec = 10000000;
        tv.tv_usec = 0;
        FD_ZERO(&read_set);
        FD_ZERO(&write_set);
        FD_SET(fd1, &read_set);
        FD_SET(fd2, &write_set);
        FD_SET(0, &read_set);

        int retval = select(fd1 + 10, &read_set, &write_set, NULL, &tv);

        if (retval == 0 || retval == -1) {
            continue;
        }
        if (FD_ISSET(0, &read_set)) {
            int data_got = scanf("%s", buffer);
            write(fd2, buffer, strlen(buffer));
        }
        if (FD_ISSET(fd1, &read_set)) {
            long data_procceded = read(fd1, buffer, BUFFER_SIZE);
            printf("Message: %s", buffer);
        }

        fflush(stdout);
    }


    return 0;
}


