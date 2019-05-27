#include <stdio.h> 
#include <string.h> 
#include <fcntl.h> 
#include <sys/stat.h> 
#include <sys/types.h> 
#include <unistd.h> 

int main(int argc, char *argv[]) {
	if (argc != 3) {
		printf("ARgs wrong format\n");
		return 0;
	}	

	const char* in = argv[1], *out = argv[2];

	int BUFF_SIZE = 1024;

	char buff_in[BUFF_SIZE], buff_out[BUFF_SIZE]; 

	

	int fd = open(in, O_RDWR);
	int fd2 = open(out, O_RDWR);
	// printf("LEL\n");
	
	while(1) {
		fd_set wfs, rfs;
		struct timeval tv;
		int retval;

		// printf("OPENED\n");

		FD_ZERO(&rfs);
		FD_SET(0, &rfs);
		FD_SET(fd2, &rfs);

		FD_ZERO(&wfs);
		FD_SET(fd, &wfs);

		tv.tv_sec = 2;
		tv.tv_usec = 0;

		retval = select(fd2 + 1, &rfs, &wfs, 0, &tv);

		if (FD_ISSET(0, &rfs)) {
			fgets(buff_in, BUFF_SIZE, stdin);
			
			tv.tv_sec = 2;
			tv.tv_usec = 0;

			retval = select(fd2 + 1, 0, &wfs, 0, &tv);

			if (FD_ISSET(fd, &wfs)) {
				write(fd, buff_in, BUFF_SIZE);
			}
		}

		if (FD_ISSET(fd2, &rfs)) {
			read(fd2, buff_out, BUFF_SIZE);
			printf("User: %s\n", buff_out);
		}

		if (retval == -1) {
			printf("ERROR\n");
		} else if (!retval) {
			printf("No input\n");
		}
	}
	
	close(fd);
	close(fd2);
}