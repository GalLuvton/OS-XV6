#include "types.h"
#include "stat.h"
#include "user.h"

#define NONBLOCKING 0
#define BLOCKING    1

int
main(int argc, char *argv[])
{
	int pid;
	
	if (argc < 2){
		exit(0);
	}
	
	pid = atoi(argv[1]);
	printf(1, "got pid %d\n", pid);
	if (!pid){
		exit(0);
	}
	wait_jobid(pid);
	printf(1, "playground done\n");
	return 0;
}