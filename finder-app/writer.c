#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>
#include <fcntl.h>
#include <sys/types.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
extern int errno;

int main(int argc, char* args[]) 
{
	char* write_file = args[1];
	char* write_str = args[2];
	openlog("writer", LOG_CONS | LOG_PID | LOG_NDELAY | LOG_PERROR, LOG_LOCAL1);
	if (write_file == NULL || write_str == NULL) {
	   syslog(LOG_ERR, "Invalid arguments.");
	   return 1;
	}
	syslog(LOG_USER, "Reading file %s", write_file);
	int fd = creat(write_file, 0644);
	if (fd == -1) {
		syslog(LOG_ERR, "error: %s", strerror(errno));
		return 1;
	}

	syslog(LOG_USER, "Writing string %s to %s", write_str, write_file);
	ssize_t nr;
	nr = write(fd, write_str, strlen(write_str));
	if (nr == -1) {
		syslog(LOG_ERR, "error writing file: %s", strerror(errno));
		return 1;
	}
	
	close(fd);
	return 0;
}
