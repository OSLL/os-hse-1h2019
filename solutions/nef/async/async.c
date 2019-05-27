#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stddef.h>
#include <unistd.h>
#include <stdio.h>

#define BUF_SIZE 4096

int main(int argc, char **argv)
{
	if (argc != 3) {
		printf("USAGE: %s <inpipe> <outpipe>\n", argv[0]);
		return 0;
	}

	char *user_buf[BUF_SIZE];
	char *in_buf[BUF_SIZE];
	char *in_pipe = argv[1];
	char *out_pipe = argv[2];

	int m = STDIN_FILENO;
	int infd = open(in_pipe, O_RDONLY | O_NONBLOCK);
	if (infd < 0) {
		printf("In pipe opening failed\n");
		return 0;
	}
	m = infd > m ? infd : m;
	int outfd = open(out_pipe, O_WRONLY);
	if (outfd < 0) {
		printf("Out pipe opening failed\n");
		return 0;
	}

	fd_set rdfds;
	do {
		FD_ZERO(&rdfds);
		FD_SET(STDIN_FILENO, &rdfds);
		FD_SET(infd, &rdfds);
		struct timeval timeout;
		int r = select(m + 1, &rdfds, NULL, NULL, NULL);
		if (r < 0) {
			printf("Error when selecting\n");
			return 0;
		}
		if (FD_ISSET(STDIN_FILENO, &rdfds)) {
			int r = read(STDIN_FILENO, user_buf, BUF_SIZE);
			write(outfd, user_buf, r);
		}
		if (FD_ISSET(infd, &rdfds)) {
			int r = read(infd, in_buf, BUF_SIZE);
			write(STDOUT_FILENO, in_buf, r);
		}
	} while (1);
}
