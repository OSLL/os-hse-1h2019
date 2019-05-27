#include <stdio.h> 
#include <string.h> 
#include <fcntl.h> 
#include <sys/stat.h> 
#include <sys/types.h> 
#include <unistd.h> 

int main(int argc, char const *argv[]) {
	if (argc != 3) {
		printf("Program should have 2 arguments: the pipe name strings.\n");
		printf("For example: /tmp/mypipe1 /tmp/mypipe2\n");
	}
	const char *mypipe1 = argv[1];
	const char *mypipe2 = argv[2];
	mkfifo(mypipe1, 0666);
	mkfifo(mypipe2, 0666);

	for (;;) {
		char str[BUFSIZ]; // maximum length of input
		int fd1 = open(mypipe1, O_RDWR);
		int fd2 = open(mypipe2, O_RDWR);

		struct timeval tvr;
		tvr.tv_sec = 1;
		tvr.tv_usec = 0;

		fd_set rfds;
		FD_ZERO(&rfds);
		FD_SET(0, &rfds);
		FD_SET(fd1, &rfds);
		select(fd1 + 1, &rfds, NULL, NULL, &tvr);
		
		//stdin
		if (FD_ISSET(0, &rfds)) {
			fgets(str, BUFSIZ, stdin);
			write(fd2, str, strlen(str) + 1); 
			close(fd1);
		}
		//from pipe
		if (FD_ISSET(fd1, &rfds)) {
			read(fd1, str, BUFSIZ); 
			printf("%s", str); 
			close(fd1);
		}
		close(fd2);
	}
	return 0; 
}