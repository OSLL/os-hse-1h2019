#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/select.h>
#include <limits.h>

const int N = 256;

int fd; 
char *fifo = "/tmp/fifo"; 
char buf1[N], buf2[N]; 
fd_set set;

void proc_write() {
    fd = open(fifo, O_WRONLY); 
    FD_ZERO(&set);
    FD_SET(fd, &set);
    fgets(buf2, N, stdin); 
    int res_select = select(fd + 1, NULL, &set, NULL, NULL);
    if (res_select != 0 && res_select != -1) {
       write(fd, buf2, strlen(buf2)+1); 
    }
    close(fd); 
}

void proc_read() {
    fd = open(fifo, O_RDONLY); 
    FD_ZERO(&set);
    FD_SET(fd, &set);
    int res_select = select(fd + 1, &set, NULL, NULL, NULL);
    if (res_select != 0 && res_select != -1) {
        read(fd, buf1, sizeof(buf1)); 
        printf("User2: %s\n", buf1); 
    }
    close(fd); 
}

int main(int argc, char **argv) 
{ 

    /*
    Usage: argc >= 1 && argv[1] is id
    in one terminal ./chat 1
    on second terminal ./chat 2
    user with id = 1 starts the communication
    */

    if (argc < 2) {
        puts("arc should be more than one (id)");
        exit(1);
    }

    int id = atoi(argv[1]);

    mkfifo(fifo, 0666); 
    
    while (1) { 
        if (id == 1) {
            proc_write();
            proc_read();
        } else {
            proc_read();
            proc_write();
        }
    } 

    return 0; 
} 
