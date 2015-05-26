#include "types.h"
#include "stat.h"
#include "user.h"

int
main(int argc, char *argv[])
{
	int pid;
	
	printf(1, "main starting\n");
	
	if ((pid = fork()) > 0){
		int i = 6;
		i++;
		exit();
	}
	else {
		wait();
	}
	
	printf(1, "main exiting\n");
	
	exit();
}

