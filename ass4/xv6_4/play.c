#include "types.h"
#include "stat.h"
#include "user.h"
#include "fcntl.h"

int
main(int argc, char *argv[])
{	
	printf(1, "main starting\n");
	
	// O_RDONLY | O_WRONLY | O_RDWR
	int fd = open("hello.txt", O_RDONLY|O_CREATE);
	
	printf(1, "file created with fd %d\n", fd);
	
	for (;;);
	
	printf(1, "main exiting\n");
	
	exit();
}

