#include <sys/select.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <fcntl.h>

int main(int argc, char** args) {
	int fin = open(args[1], O_RDWR);
	int fstdin = 0;
	int fout = open(args[2], O_RDWR);

	fd_set fds_in;
	fd_set fds_out;
	char buffer[4096];

	for (;;) {
		FD_ZERO(&fds_in);
		FD_ZERO(&fds_out);
		FD_SET(fin, &fds_in);
		FD_SET(fstdin, &fds_in);
		FD_SET(fout, &fds_out);

		select(fin + 1, &fds_in, &fds_out, NULL, NULL);

		if (FD_ISSET(fin, &fds_in)) {
			int res = read(fin, buffer, 4096);
			if (res > 0) {
				write(fout, buffer, res);
			}
		}

		if (FD_ISSET(fstdin, &fds_in)) {
			int res = read(fstdin, buffer, 4096);
			if (res > 0) {
				write(fout, buffer, res);
			}
		}
		sleep(1);
	}
}