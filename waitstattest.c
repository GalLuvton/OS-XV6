// Test that fork fails gracefully.
// Tiny executable so that the limit can be filling the proc table.

#include "types.h"
#include "stat.h"
#include "user.h"

#define N  1000
#define NONBLOCKING 0
#define BLOCKING    1
/*
void
printf(int fd, char *s, ...)
{
  write(fd, s, strlen(s));
}
*/

int
foo(int i)
{
	int pid;
	
	pid = fork();
	if(pid == 0)
	{
	  sleep(5);
	  exit(i);
	}
	return pid;
}

void
wait_test(void)
{
	int status;
	int i;
	printf(1, "wait test\n");

	for (i=0; i<100; i++){
		foo(i);
		wait(&status);
		printf(1, "status: %d \n",status);
	}
}

void
waitpid_nonblock_test(void)
{
	int options = NONBLOCKING;
	int status;
	int pid;
	int i;
	printf(1, "waitpid test\n");
    for (i=0; i<100; i++){
		pid = foo(i);
		waitpid(pid,&status,options);
		printf(1, "status: %d; options: %d \n",status,options);
	}
}

void
waitpid_block_test(void)
{
	int options = BLOCKING;
	int status;
	int pid;
	int i;
	printf(1, "waitpid test\n");

    for (i=0; i<100; i++){
		pid = foo(i);
		waitpid(pid,&status,options);
		printf(1, "status: %d; options: %d \n",status,options);
	}
}

void
wait_stat_test(void)
{
	int wTime;
	int rTime;
	int ioTime;
	int i;
	printf(1, "wait_stat test\n");

    for (i=0; i<100; i++){
		foo(i);
		wait_stat(&wTime,&rTime,&ioTime);
		printf(1, "runnable time: %d; running time: %d; sleeping time: %d \n",wTime,rTime, ioTime);
	}
}

int
main(void)
{
	int i;
	char buffer[10];
	
	for (;;){
		printf(1, "input please\n");
		read(0, buffer, 10);
		i = buffer[0]-'0';
		switch (i){
			case 1:
			wait_test();
			break;
			case 2:
			waitpid_nonblock_test();
			break;
			case 3:
			waitpid_block_test();
			break;
			case 4:
			wait_stat_test();
			break;
			default:
			exit(0);
		}
	}
}